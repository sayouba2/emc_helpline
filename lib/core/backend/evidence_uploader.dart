import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;

import '../../models/submission_outcome.dart';
import 'emulators.dart';

/// Sends the screenshots to Cloud Storage and returns the paths the server
/// will accept.
///
/// The bucket is closed to clients, so nothing is written directly: the
/// function hands out one signed URL per object, bound to a content type and
/// valid for minutes, and the upload goes there.
typedef SignedUpload = ({
  String uploadUrl,
  String storagePath,

  /// `PUT` against a signed Cloud Storage URL; `POST` against the emulator's
  /// own endpoint, which is the only upload path that works locally.
  String method,
  Map<String, String> headers,
});

/// Asks the backend for one signed URL. Injectable so the uploader can be
/// driven in tests without a Firebase project — the transfer logic below is
/// where the interesting behaviour lives.
typedef UploadUrlRequester =
    Future<SignedUpload> Function({
      required String idempotencyKey,
      required String contentType,
      required int sizeBytes,
    });

class EvidenceUploader {
  EvidenceUploader({
    required String region,
    http.Client? client,
    UploadUrlRequester? requestUploadUrl,
  }) : _client = client ?? http.Client(),
       _requestUploadUrl = requestUploadUrl ?? _callableRequester(region);

  final http.Client _client;
  final UploadUrlRequester _requestUploadUrl;

  /// Paths already uploaded, by idempotency key.
  ///
  /// A retry re-sends the report, not the screenshots. Without this, someone on
  /// a bad connection would push the same megabytes again on every attempt —
  /// exactly the situation where the connection is the problem.
  final Map<String, List<String>> _uploaded = {};

  /// Sizes above this are refused before leaving the phone. Mirrors
  /// `MAX_EVIDENCE_BYTES` in `functions/src/config.ts`.
  static const int maxBytes = 8 * 1024 * 1024;

  /// Combien de captures un signalement peut porter. Mirroir de
  /// `MAX_EVIDENCE_FILES` dans `functions/src/config.ts` : le sélecteur s'y
  /// arrête, faute de quoi le serveur refuserait le lot entier après coup.
  static const int maxFiles = 10;

  static const Duration _perFileTimeout = Duration(seconds: 60);

  static const Map<String, String> _contentTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };

  /// Uploads what has not been uploaded yet for this submission.
  ///
  /// Throws [SubmissionException] with [SubmissionFailure.network] when the
  /// transfer fails. That is not the same as a failed *send*: nothing has been
  /// filed, so the retry is clean — whereas `timeout` tells the user their
  /// report may already be recorded, which would be a lie here.
  Future<List<String>> upload({
    required String idempotencyKey,
    required List<String> localPaths,
  }) async {
    if (localPaths.isEmpty) return const [];

    final cached = _uploaded[idempotencyKey];
    if (cached != null && cached.length == localPaths.length) return cached;

    final paths = <String>[];
    try {
      for (final localPath in localPaths) {
        paths.add(await _uploadOne(idempotencyKey, localPath));
      }
    } on SubmissionException {
      rethrow;
    } on FirebaseFunctionsException {
      rethrow; // The caller maps a functions error; it is not a transfer fault.
    } on TimeoutException {
      throw const SubmissionException(SubmissionFailure.network);
    } on SocketException {
      throw const SubmissionException(SubmissionFailure.network);
    } on http.ClientException {
      throw const SubmissionException(SubmissionFailure.network);
    }

    _uploaded[idempotencyKey] = paths;
    return paths;
  }

  /// Forgets a submission's uploads once it has been filed or abandoned.
  void forget(String idempotencyKey) => _uploaded.remove(idempotencyKey);

  Future<String> _uploadOne(String idempotencyKey, String localPath) async {
    final file = File(localPath);
    final bytes = await file.readAsBytes();
    final contentType = _contentTypeOf(localPath);

    if (contentType == null) {
      // The server would refuse it anyway. Failing here spends no upload and
      // no rate-limit budget on something that cannot be accepted.
      throw const SubmissionException(SubmissionFailure.server);
    }
    if (bytes.length > maxBytes) {
      // Its own failure, not a server error: this one the user can fix by
      // removing the screenshot, and telling them our servers broke would
      // leave them stuck on a problem that was theirs to solve.
      throw const SubmissionException(SubmissionFailure.evidenceTooLarge);
    }

    final signed = await _requestUploadUrl(
      idempotencyKey: idempotencyKey,
      contentType: contentType,
      sizeBytes: bytes.length,
    );

    // L'URL vient d'un processus qui voit l'émulateur sur sa propre boucle
    // locale. Ce téléphone, non — voir `reachableFromDevice`.
    final request =
        http.Request(
            signed.method,
            Uri.parse(reachableFromDevice(signed.uploadUrl)),
          )
          // Signed into the URL. Cloud Storage refuses the write if this header
          // does not match what the function declared.
          ..headers['Content-Type'] = contentType
          ..headers.addAll(signed.headers)
          ..bodyBytes = bytes;

    final response = await http.Response.fromStream(
      await _client.send(request).timeout(_perFileTimeout),
    );

    if (response.statusCode >= 500) {
      // Cloud Storage itself is unwell. Telling the user to check their wifi
      // would send them looking in the wrong place.
      throw const SubmissionException(SubmissionFailure.server);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      // Usually a 403 on an expired URL — the user sat on the summary for a
      // quarter of an hour. Retrying asks for a fresh one.
      throw const SubmissionException(SubmissionFailure.network);
    }

    return signed.storagePath;
  }

  static UploadUrlRequester _callableRequester(String region) {
    return ({
      required String idempotencyKey,
      required String contentType,
      required int sizeBytes,
    }) async {
      final callable = FirebaseFunctions.instanceFor(
        region: region,
      ).httpsCallable('requestEvidenceUploadUrl');

      final result = await callable.call<Object?>({
        'idempotencyKey': idempotencyKey,
        'contentType': contentType,
        'sizeBytes': sizeBytes,
      });

      final data = result.data;
      if (data is! Map) {
        throw const SubmissionException(SubmissionFailure.server);
      }

      final uploadUrl = data['uploadUrl'];
      final storagePath = data['storagePath'];
      if (uploadUrl is! String || storagePath is! String) {
        throw const SubmissionException(SubmissionFailure.server);
      }

      final method = data['method'];
      final headers = data['headers'];
      return (
        uploadUrl: uploadUrl,
        storagePath: storagePath,
        // `PUT` is what a signed Cloud Storage URL expects; the emulator wants
        // `POST`. Defaulting keeps an older backend working.
        method: method is String ? method : 'PUT',
        headers: headers is Map
            ? {
                for (final entry in headers.entries)
                  entry.key.toString(): entry.value.toString(),
              }
            : const <String, String>{},
      );
    };
  }

  /// Recognised from the extension, and it has to be one the server allows —
  /// `image_picker` can hand back a HEIC on iOS, which is not in the list.
  static String? _contentTypeOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0) return null;
    return _contentTypes[path.substring(dot + 1).toLowerCase()];
  }
}
