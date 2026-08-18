import 'dart:async';
import 'dart:io' show SocketException;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import '../../models/report_enums.dart';
import '../../models/submission_outcome.dart';
import '../../models/tracking_outcome.dart';
import 'evidence_uploader.dart';
import 'report_payload.dart';

/// Must match `REGION` in `functions/src/config.ts`. A callable resolved in the
/// wrong region does not fall back — it 404s.
const String backendRegion = 'europe-west1';

/// Slightly under the function's own 30 s budget, so the client gives up first.
///
/// That is on purpose: a client timeout is the case the idempotency key was
/// built for. The retry carries the same key, the server recognises a
/// submission it may already have committed, and returns the original code
/// rather than opening a second case.
const Duration _callTimeout = Duration(seconds: 28);

/// Run against the local Firebase emulators instead of the real project.
///
///     flutter run --dart-define=USE_EMULATORS=true
///
/// This is how the whole workflow can be exercised end to end today: reports
/// really are written, really get a reference number, and really come back on
/// the tracking screen — in a database that lives on this machine. No billing
/// account, no App Check registration, and nothing to clean up afterwards.
///
/// A `const` from the environment rather than a runtime flag, so a release
/// build cannot be talked into pointing at a developer's laptop.
const bool useEmulators = bool.fromEnvironment('USE_EMULATORS');

/// Where the emulators are, seen from the device.
///
/// `10.0.2.2` is how the Android emulator reaches the host machine —
/// `localhost` there means the emulated phone itself. On a physical device,
/// pass the machine's address on the local network:
///
///     --dart-define=EMULATOR_HOST=192.168.1.24
const String emulatorHost = String.fromEnvironment(
  'EMULATOR_HOST',
  defaultValue: '10.0.2.2',
);

/// Brings Firebase up and returns the submitter the provider should use.
///
/// Returns `null` only in debug, and only when Firebase could not start — the
/// app then runs on its local simulation, so the frontend stays workable
/// without a configured project.
///
/// In release it never returns `null`. A backend that failed to start becomes a
/// backend that fails every send, which puts the user on the error screen with
/// a retry and the team's direct line. What must never happen is the
/// simulation running in production: it hands out a reference number for a
/// report that went nowhere, and the child walks away believing help is coming.
/// What `initializeBackend` hands back: how to send a report, and how to look
/// one up. Both `null` means the app runs on its local simulation.
typedef Backend = ({ReportSubmitter? submitter, ReportLookup? lookup});

Future<Backend> initializeBackend() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (useEmulators) {
      // Before anything else touches them. The emulators enforce neither App
      // Check nor the console's provider settings, so this path needs none of
      // the setup the real project does.
      await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
      FirebaseFunctions.instanceFor(
        region: backendRegion,
      ).useFunctionsEmulator(emulatorHost, 5001);
      debugPrint('Backend: emulators at $emulatorHost');
      return (
        submitter: _FirebaseReportSubmitter(
          EvidenceUploader(region: backendRegion),
        ).submit,
        lookup: lookupReport,
      );
    }

    await FirebaseAppCheck.instance.activate(
      // Play Integrity cannot attest an app that Play did not install, so it
      // fails by construction on an emulator or a `flutter run` build. Debug
      // builds use the debug provider and register their token in the console;
      // release builds get Play Integrity with no fallback, because a fallback
      // is the door App Check exists to close.
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleDeviceCheckProvider(),
    );

    return (
      submitter: _FirebaseReportSubmitter(
        EvidenceUploader(region: backendRegion),
      ).submit,
      lookup: lookupReport,
    );
  } catch (error, stackTrace) {
    if (kReleaseMode) {
      debugPrint('Backend unavailable: $error');
      return (
        submitter: (_) =>
            throw const SubmissionException(SubmissionFailure.server),
        // Throwing here too: the tracking screen says "cannot check right now",
        // which is true, rather than "no such case", which would tell someone
        // their report is gone.
        lookup: (_) =>
            throw const SubmissionException(SubmissionFailure.server),
      );
    }
    debugPrint(
      'Firebase did not start, falling back to the local simulation.\n'
      'Reports will NOT be sent anywhere. $error\n$stackTrace',
    );
    return (submitter: null, lookup: null);
  }
}

/// Reads a case back by its reference number.
///
/// Returns `null` for "no such case" and throws for "could not ask" — the
/// tracking screen shows those differently, because telling someone their
/// report does not exist when the network is down would be its own small
/// catastrophe.
Future<TrackedReport?> lookupReport(String referenceCode) async {
  await _ensureSignedIn();

  final callable = FirebaseFunctions.instanceFor(region: backendRegion)
      .httpsCallable(
        'trackReport',
        options: HttpsCallableOptions(timeout: _callTimeout),
      );

  final result = await callable.call<Object?>({'referenceCode': referenceCode});
  final data = result.data;
  if (data is! Map || data['found'] != true) return null;

  final report = data['report'];
  if (report is! Map) return null;

  final createdAt = report['createdAt'];
  return TrackedReport(
    referenceCode: referenceCode,
    status: enumByName(ReportStatus.values, report['status']),
    createdAt: createdAt is String ? DateTime.tryParse(createdAt) : null,
    incidentType: enumByName(IncidentType.values, report['incidentType']),
    urgencyLevel: enumByName(UrgencyLevel.values, report['urgencyLevel']),
  );
}

/// Anonymous sign-in, done before each call rather than once at launch.
///
/// It is not a login: there are no accounts, and the UID exists only so the
/// server can count requests per device. Doing it here keeps launch off the
/// network and survives a session that expired in the background.
Future<void> _ensureSignedIn() async {
  final auth = FirebaseAuth.instance;
  if (auth.currentUser != null) return;
  await auth.signInAnonymously();
}

class _FirebaseReportSubmitter {
  const _FirebaseReportSubmitter(this._uploader);

  final EvidenceUploader _uploader;

  Future<String> submit(SubmissionAttempt attempt) async {
    try {
      await _ensureSignedIn();

      // Before the report, because the report references what this returns.
      // Already-uploaded screenshots are not sent again on a retry.
      final evidencePaths = await _uploader.upload(
        idempotencyKey: attempt.idempotencyKey,
        localPaths: attempt.report.evidenceFilePaths,
      );

      final callable = FirebaseFunctions.instanceFor(region: backendRegion)
          .httpsCallable(
            'submitReport',
            options: HttpsCallableOptions(timeout: _callTimeout),
          );

      final result = await callable.call<Object?>({
        'idempotencyKey': attempt.idempotencyKey,
        'report': reportPayload(attempt.report, evidencePaths: evidencePaths),
      });

      final data = result.data;
      final code = data is Map ? data['referenceCode'] : null;
      _uploader.forget(attempt.idempotencyKey);

      if (code is! String || code.isEmpty) {
        // The call succeeded but the answer is not one we can use. Treating it
        // as a failure is right: the report may well have been filed, and the
        // retry is safe precisely because of the idempotency key.
        throw const SubmissionException(SubmissionFailure.server);
      }
      return code;
    } on SubmissionException {
      rethrow;
    } catch (error) {
      final failure = failureFor(error);
      // Unmapped errors are left to travel: `ReportProvider.submitReport`
      // records them as `unknown`, which is honest, rather than being guessed
      // into a category that would tell the user the wrong thing to do.
      if (failure == null) rethrow;
      throw SubmissionException(failure);
    }
  }
}

/// Which failure the user should be told about, or `null` when we do not know.
///
/// The mapping follows `docs/backend-plan.md` §8.
SubmissionFailure? failureFor(Object error) {
  if (error is SocketException) return SubmissionFailure.network;
  if (error is TimeoutException) return SubmissionFailure.timeout;
  if (error is FirebaseFunctionsException) return failureForCode(error.code);
  if (error is FirebaseAuthException) {
    // Anonymous sign-in failed. Either the provider is off in the console or
    // the device is offline; `network-request-failed` says which.
    return error.code == 'network-request-failed'
        ? SubmissionFailure.network
        : SubmissionFailure.server;
  }
  return null;
}

/// Split out from [failureFor] because a `FirebaseFunctionsException` cannot be
/// built in a unit test, and this is the part worth pinning down.
SubmissionFailure? failureForCode(String rawCode) {
  final code = rawCode.startsWith('functions/')
      ? rawCode.substring('functions/'.length)
      : rawCode;

  return switch (code) {
    // Almost always the phone, not the server — and "check your connection" is
    // something the user can act on, whereas "our servers failed" is not. If
    // the guess is wrong the retry costs nothing.
    'unavailable' => SubmissionFailure.network,

    'deadline-exceeded' => SubmissionFailure.timeout,

    // `unauthenticated` means App Check or anonymous auth was refused, and
    // `invalid-argument` means the client sent something the server rejects.
    // Both are our bugs. Neither is the child's fault, and neither is
    // something they can fix, so they are not told they did anything wrong.
    'unauthenticated' ||
    'permission-denied' ||
    'invalid-argument' ||
    'failed-precondition' ||
    'resource-exhausted' ||
    'aborted' ||
    'internal' ||
    'data-loss' => SubmissionFailure.server,

    _ => null,
  };
}
