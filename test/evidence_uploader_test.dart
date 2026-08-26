import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:emc_helpline/core/backend/evidence_uploader.dart';
import 'package:emc_helpline/models/submission_outcome.dart';

late Directory _tmp;
const String _key = '18f2c3a4b5c6d7e8-EMC4K7PW9XM2QTR';

/// Records what the backend was asked for, and hands back a signed URL.
class _FakeBackend {
  _FakeBackend({this.method = 'PUT', this.headers = const {}});

  /// Le backend décide du verbe et des en-têtes : `PUT` vers une URL signée en
  /// production, `POST` avec un jeton admin vers l'émulateur.
  final String method;
  final Map<String, String> headers;

  final List<({String contentType, int sizeBytes})> requests = [];
  int _next = 0;

  Future<SignedUpload> call({
    required String idempotencyKey,
    required String contentType,
    required int sizeBytes,
  }) async {
    requests.add((contentType: contentType, sizeBytes: sizeBytes));
    final n = _next++;
    return (
      uploadUrl: 'https://storage.example/signed/$n',
      storagePath: 'evidence/abc12345/object$n.png',
      method: method,
      headers: headers,
    );
  }
}

String _writeFile(String name, {int bytes = 32}) {
  final file = File('${_tmp.path}/$name')..writeAsBytesSync(Uint8List(bytes));
  return file.path;
}

void main() {
  setUp(() {
    _tmp = Directory.systemTemp.createTempSync('emc_evidence');
  });

  tearDown(() {
    _tmp.deleteSync(recursive: true);
  });

  group('uploading', () {
    test(
      'sends each file and returns the paths the server will accept',
      () async {
        final backend = _FakeBackend();
        final sent = <String>[];
        final uploader = EvidenceUploader(
          region: 'europe-west1',
          requestUploadUrl: backend.call,
          client: MockClient((request) async {
            sent.add(request.headers['Content-Type'] ?? '');
            return http.Response('', 200);
          }),
        );

        final paths = await uploader.upload(
          idempotencyKey: _key,
          localPaths: [_writeFile('a.png'), _writeFile('b.jpg')],
        );

        expect(paths, [
          'evidence/abc12345/object0.png',
          'evidence/abc12345/object1.png',
        ]);
        // The content type is signed into the URL: Cloud Storage refuses a write
        // whose header does not match what the function declared.
        expect(sent, ['image/png', 'image/jpeg']);
        expect(backend.requests.map((r) => r.contentType), [
          'image/png',
          'image/jpeg',
        ]);
      },
    );

    test('does nothing when there is nothing to send', () async {
      final backend = _FakeBackend();
      final uploader = EvidenceUploader(
        region: 'europe-west1',
        requestUploadUrl: backend.call,
        client: MockClient((_) async => http.Response('', 200)),
      );

      expect(
        await uploader.upload(idempotencyKey: _key, localPaths: const []),
        isEmpty,
      );
      expect(backend.requests, isEmpty);
    });

    test('a retry re-sends the report, not the screenshots', () async {
      // The situation this exists for is a bad connection. Pushing the same
      // megabytes again on every attempt is exactly the wrong response to it.
      final backend = _FakeBackend();
      var transfers = 0;
      final uploader = EvidenceUploader(
        region: 'europe-west1',
        requestUploadUrl: backend.call,
        client: MockClient((_) async {
          transfers++;
          return http.Response('', 200);
        }),
      );
      final files = [_writeFile('a.png')];

      final first = await uploader.upload(
        idempotencyKey: _key,
        localPaths: files,
      );
      final second = await uploader.upload(
        idempotencyKey: _key,
        localPaths: files,
      );

      expect(second, first);
      expect(transfers, 1);
    });

    test('suit le verbe et les en-têtes que le backend choisit', () async {
      // En production, PUT vers une URL signée. Contre l'émulateur, POST avec
      // le jeton admin — parce que l'émulateur ne sait pas signer d'URL, et
      // qu'un signalement portant une capture échouait donc toujours en local.
      final backend = _FakeBackend(
        method: 'POST',
        headers: const {'Authorization': 'Bearer owner'},
      );
      String? seenMethod;
      String? seenAuth;
      final uploader = EvidenceUploader(
        region: 'europe-west1',
        requestUploadUrl: backend.call,
        client: MockClient((request) async {
          seenMethod = request.method;
          seenAuth = request.headers['Authorization'];
          return http.Response('', 200);
        }),
      );

      await uploader.upload(
        idempotencyKey: _key,
        localPaths: [_writeFile('a.png')],
      );

      expect(seenMethod, 'POST');
      expect(seenAuth, 'Bearer owner');
    });

    test('a new submission uploads again', () async {
      final backend = _FakeBackend();
      final uploader = EvidenceUploader(
        region: 'europe-west1',
        requestUploadUrl: backend.call,
        client: MockClient((_) async => http.Response('', 200)),
      );
      final files = [_writeFile('a.png')];

      await uploader.upload(idempotencyKey: _key, localPaths: files);
      uploader.forget(_key);
      await uploader.upload(idempotencyKey: _key, localPaths: files);

      expect(backend.requests, hasLength(2));
    });
  });

  group('what the user is told when a transfer fails', () {
    Future<SubmissionFailure?> failureFrom(MockClient client) async {
      final uploader = EvidenceUploader(
        region: 'europe-west1',
        requestUploadUrl: _FakeBackend().call,
        client: client,
      );
      try {
        await uploader.upload(
          idempotencyKey: _key,
          localPaths: [_writeFile('a.png')],
        );
        return null;
      } on SubmissionException catch (error) {
        return error.failure;
      }
    }

    // Never `timeout`: that message tells the user their report may already be
    // recorded. Nothing has been filed at this point, so it would be a lie —
    // and it would discourage the retry, which is clean.
    test('a dropped connection reads as a connection problem', () async {
      expect(
        await failureFrom(
          MockClient((_) async => throw const SocketException('no route')),
        ),
        SubmissionFailure.network,
      );
    });

    test('a transfer that hangs reads as a connection problem', () async {
      expect(
        await failureFrom(
          MockClient((_) async => throw TimeoutException('too slow')),
        ),
        SubmissionFailure.network,
      );
    });

    test('an expired signed URL reads as a connection problem', () async {
      // A 403 here almost always means the user sat on the summary past the
      // URL's lifetime. Retrying asks for a fresh one.
      expect(
        await failureFrom(MockClient((_) async => http.Response('', 403))),
        SubmissionFailure.network,
      );
    });

    test('a failing bucket is not blamed on the connection', () async {
      // Telling someone to check their wifi when Cloud Storage is down sends
      // them looking in the wrong place.
      expect(
        await failureFrom(MockClient((_) async => http.Response('', 503))),
        SubmissionFailure.server,
      );
    });
  });

  group('what never leaves the phone', () {
    Future<SubmissionFailure?> failureFor(String localPath) async {
      final uploader = EvidenceUploader(
        region: 'europe-west1',
        requestUploadUrl: _FakeBackend().call,
        client: MockClient(
          (_) async => throw StateError('should not have been sent'),
        ),
      );
      try {
        await uploader.upload(idempotencyKey: _key, localPaths: [localPath]);
        return null;
      } on SubmissionException catch (error) {
        return error.failure;
      }
    }

    test('a file the server would refuse is never uploaded', () async {
      // image_picker can hand back a HEIC on iOS. Failing here spends no
      // transfer and no rate-limit budget on something that cannot be accepted.
      expect(
        await failureFor(_writeFile('photo.heic')),
        SubmissionFailure.server,
      );
      expect(
        await failureFor(_writeFile('noextension')),
        SubmissionFailure.server,
      );
    });

    test(
      'un fichier trop lourd a son propre message, pas « erreur serveur »',
      () async {
        // Celui-là, l'utilisateur peut le régler : retirer la capture. Lui dire
        // que nos serveurs ont échoué le laisse bloqué sur un problème qui était
        // le sien à résoudre.
        expect(
          await failureFor(
            _writeFile('huge.png', bytes: EvidenceUploader.maxBytes + 1),
          ),
          SubmissionFailure.evidenceTooLarge,
        );
      },
    );

    test('le plafond du client est celui du serveur', () {
      final config = File('functions/src/config.ts').readAsStringSync();
      final declared = RegExp(r'MAX_EVIDENCE_FILES = (\d+)').firstMatch(config);

      expect(declared, isNotNull);
      expect(int.parse(declared!.group(1)!), EvidenceUploader.maxFiles);
    });
  });
}
