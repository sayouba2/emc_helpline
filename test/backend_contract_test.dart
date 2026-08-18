import 'dart:async';
import 'dart:io' show File, SocketException;

import 'package:flutter_test/flutter_test.dart';

import 'package:emc_helpline/core/backend/evidence_uploader.dart';
import 'package:emc_helpline/core/backend/firebase_backend.dart';
import 'package:emc_helpline/core/backend/report_payload.dart';
import 'package:emc_helpline/core/utils/validators.dart';
import 'package:emc_helpline/models/report_enums.dart';
import 'package:emc_helpline/models/report_model.dart';
import 'package:emc_helpline/models/submission_outcome.dart';
import 'package:emc_helpline/models/tracking_outcome.dart';

const _complete = ReportModel(
  whoFor: WhoFor.self,
  ageGroup: AgeGroup.teen,
  gender: Gender.undisclosed,
  incidentType: IncidentType.threat,
  platform: ReportPlatform.whatsapp,
  urgencyLevel: UrgencyLevel.notUrgent,
  assistanceNeeded: AssistanceNeed.none,
  evidenceUrl: 'https://exemple.ma/post/1',
);

void main() {
  group('the wire contract', () {
    test('sends enum member names, which the server matches literally', () {
      final payload = reportPayload(_complete);

      expect(payload['whoFor'], 'self');
      expect(payload['ageGroup'], 'teen');
      expect(payload['incidentType'], 'threat');
      expect(payload['platform'], 'whatsapp');
      expect(payload['assistanceNeeded'], 'none');
      expect(payload['urgencyLevel'], 'notUrgent');
    });

    // Renaming a Dart enum member is a change of contract, not a rename: the
    // server lists these names in functions/src/schema.ts and refuses anything
    // else. This is the test that says so out loud.
    test('every enum value the server accepts is spelled the same here', () {
      expect(WhoFor.values.map((v) => v.name), ['self', 'someoneElse']);
      expect(AgeGroup.values.map((v) => v.name), [
        'child',
        'teen',
        'adult',
        'undisclosed',
      ]);
      expect(Gender.values.map((v) => v.name), [
        'female',
        'male',
        'undisclosed',
      ]);
      expect(IncidentType.values.map((v) => v.name), [
        'hateSpeech',
        'discrimination',
        'defamation',
        'identityTheft',
        'intimateImages',
        'threat',
        'other',
      ]);
      expect(ReportPlatform.values.map((v) => v.name), [
        'whatsapp',
        'instagram',
        'tiktok',
        'facebook',
        'onlineGame',
        'messenger',
      ]);
      expect(AssistanceNeed.values.map((v) => v.name), [
        'wanted',
        'none',
        'unsure',
      ]);
      expect(AssistanceType.values.map((v) => v.name), [
        'legal',
        'psychological',
        'both',
        'unsure',
      ]);
      expect(UrgencyLevel.values.map((v) => v.name), [
        'urgent',
        'notUrgent',
        'unsure',
      ]);
    });

    // The strongest version of the check above: read what the server actually
    // declares, rather than a copy of it written down here. Two files in two
    // languages that have to agree, kept honest by the only thing that can — a
    // test that fails the day they stop.
    test(
      'matches the enum lists the server declares, read from its source',
      () {
        final source = File('functions/src/schema.ts').readAsStringSync();

        List<String> declared(String name) {
          final match = RegExp(
            'const $name = \\[(.*?)\\] as const;',
            dotAll: true,
          ).firstMatch(source);
          expect(match, isNotNull, reason: '$name not found in schema.ts');
          return RegExp(
            '"([^"]+)"',
          ).allMatches(match!.group(1)!).map((m) => m.group(1)!).toList();
        }

        expect(declared('WHO_FOR'), WhoFor.values.map((v) => v.name).toList());
        expect(
          declared('AGE_GROUP'),
          AgeGroup.values.map((v) => v.name).toList(),
        );
        expect(declared('GENDER'), Gender.values.map((v) => v.name).toList());
        expect(
          declared('INCIDENT_TYPE'),
          IncidentType.values.map((v) => v.name).toList(),
        );
        expect(
          declared('PLATFORM'),
          ReportPlatform.values.map((v) => v.name).toList(),
        );
        expect(
          declared('ASSISTANCE_NEED'),
          AssistanceNeed.values.map((v) => v.name).toList(),
        );
        expect(
          declared('ASSISTANCE_TYPE'),
          AssistanceType.values.map((v) => v.name).toList(),
        );
        expect(
          declared('URGENCY_LEVEL'),
          UrgencyLevel.values.map((v) => v.name).toList(),
        );
      },
    );

    // The console can only set a status the app knows how to display; a fifth
    // one added server-side would leave users reading "statut mis à jour" and
    // nothing else.
    test('knows every status the console can set', () {
      final config = File('functions/src/config.ts').readAsStringSync();
      final block = RegExp(
        r'REPORT_STATUSES = \[(.*?)\] as const;',
        dotAll: true,
      ).firstMatch(config);

      expect(block, isNotNull);
      final declared = RegExp(
        '"([^"]+)"',
      ).allMatches(block!.group(1)!).map((m) => m.group(1)!).toList();

      expect(declared, ReportStatus.values.map((v) => v.name).toList());
    });

    test(
      'the description length the server enforces is the one we enforce',
      () {
        // If these drift, the client lets through a report the server rejects,
        // and the user sees a failure they cannot act on.
        final config = File('functions/src/config.ts').readAsStringSync();
        final declared = RegExp(
          r'MIN_DESCRIPTION_LENGTH = (\d+)',
        ).firstMatch(config);

        expect(declared, isNotNull);
        expect(int.parse(declared!.group(1)!), Validators.minDescriptionLength);
      },
    );

    test('omits empty free-text fields rather than sending blanks', () {
      final payload = reportPayload(
        _complete.copyWith(description: '   ', evidenceUrl: '  '),
      );

      expect(payload.containsKey('description'), isFalse);
      expect(payload.containsKey('evidenceUrl'), isFalse);
    });

    test('trims what it does send', () {
      final payload = reportPayload(
        _complete.copyWith(description: '  du texte  '),
      );

      expect(payload['description'], 'du texte');
    });
  });

  group('contact details', () {
    final withContact = _complete.copyWith(
      assistanceType: AssistanceType.legal,
      pseudo: 'HérosDiscret42',
      contactPhone: '0612345678',
    );

    test('never leave the phone when help was not requested', () {
      // The server drops them too. They are left out here as well so a report
      // its author believes is anonymous does not carry their number across the
      // network on its way to being discarded.
      for (final need in [AssistanceNeed.none, AssistanceNeed.unsure]) {
        final payload = reportPayload(
          withContact.copyWith(assistanceNeeded: need),
        );

        expect(payload.containsKey('pseudo'), isFalse, reason: need.name);
        expect(payload.containsKey('contactPhone'), isFalse, reason: need.name);
        expect(
          payload.containsKey('assistanceType'),
          isFalse,
          reason: need.name,
        );
      }
    });

    test('are sent when it was', () {
      final payload = reportPayload(
        withContact.copyWith(assistanceNeeded: AssistanceNeed.wanted),
      );

      expect(payload['pseudo'], 'HérosDiscret42');
      expect(payload['contactPhone'], '0612345678');
      expect(payload['assistanceType'], 'legal');
    });
  });

  group('screenshots', () {
    test('local paths are never passed off as storage paths', () {
      // ReportModel.evidenceFilePaths holds paths on the phone; they mean
      // nothing to the server, which only accepts paths it issued through
      // requestEvidenceUploadUrl. Sending one would be rejected — and would
      // also leak the phone's directory layout.
      final payload = reportPayload(
        _complete.copyWith(evidenceFilePaths: const ['/data/user/0/shot.png']),
      );

      expect(payload['evidencePaths'], isEmpty);
    });

    test('carries the storage paths the uploader came back with', () {
      final payload = reportPayload(
        _complete.copyWith(evidenceFilePaths: const ['/data/user/0/shot.png']),
        evidencePaths: const ['evidence/abc12345/deadbeef.png'],
      );

      expect(payload['evidencePaths'], ['evidence/abc12345/deadbeef.png']);
    });

    test('are recognised as needing an upload', () {
      expect(
        needsEvidenceUpload(
          const ReportModel(evidenceFilePaths: ['/data/user/0/shot.png']),
        ),
        isTrue,
      );
      expect(needsEvidenceUpload(_complete), isFalse);
    });

    test('the size limit is the one the server enforces', () {
      final config = File('functions/src/config.ts').readAsStringSync();
      final declared = RegExp(
        r'MAX_EVIDENCE_BYTES = (\d+) \* 1024 \* 1024',
      ).firstMatch(config);

      expect(declared, isNotNull);
      expect(
        int.parse(declared!.group(1)!) * 1024 * 1024,
        EvidenceUploader.maxBytes,
      );
    });
  });

  group('what the user is told when it fails', () {
    test('no connection reads as no connection', () {
      expect(
        failureFor(const SocketException('no route to host')),
        SubmissionFailure.network,
      );
      expect(failureForCode('unavailable'), SubmissionFailure.network);
    });

    test('a timeout keeps its own category', () {
      // It is the one case where the report may already be filed, and the
      // message says the retry will not count twice. Folding it into `network`
      // would replace that with advice to check the wifi.
      expect(
        failureFor(TimeoutException('too slow')),
        SubmissionFailure.timeout,
      );
      expect(failureForCode('deadline-exceeded'), SubmissionFailure.timeout);
    });

    test('our own bugs are never told to the user as their fault', () {
      for (final code in [
        'unauthenticated', // App Check or anonymous auth refused
        'invalid-argument', // the client sent something the server rejects
        'permission-denied',
        'failed-precondition',
        'resource-exhausted',
        'internal',
      ]) {
        expect(failureForCode(code), SubmissionFailure.server, reason: code);
      }
    });

    test(
      'accepts the prefixed form the platform channel sometimes returns',
      () {
        expect(
          failureForCode('functions/unavailable'),
          SubmissionFailure.network,
        );
        expect(
          failureForCode('functions/deadline-exceeded'),
          SubmissionFailure.timeout,
        );
      },
    );

    test('leaves what it does not recognise alone', () {
      // Unmapped travels on and the provider records `unknown`, which is
      // honest — better than guessing a category and telling the user to do
      // the wrong thing.
      expect(failureForCode('some-new-code'), isNull);
      expect(failureFor(StateError('boom')), isNull);
    });
  });
}
