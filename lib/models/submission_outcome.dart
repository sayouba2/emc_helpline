import 'report_model.dart';

/// Why a report could not be sent.
///
/// The provider stores one of these rather than a sentence — it has no
/// `BuildContext` — and the error screen turns it into text through
/// `SubmissionFailureLabel`. The cases are deliberately coarse: the user needs
/// to know whether to retry now, retry later, or reach the team another way,
/// and nothing finer than that.
enum SubmissionFailure {
  /// The device has no usable connection. Retrying without doing something
  /// about it will fail again, so the screen says so.
  network,

  /// The request reached the server and the server refused it.
  server,

  /// Nothing came back in time. This is the case where the report *may* have
  /// gone through, which is why every attempt carries the same
  /// [SubmissionAttempt.idempotencyKey].
  timeout,

  /// Anything else. Reaching this in production means the transport threw
  /// something the mapping does not cover yet.
  unknown,
}

/// Thrown by a [ReportSubmitter] that could not deliver the report.
class SubmissionException implements Exception {
  const SubmissionException(this.failure);

  final SubmissionFailure failure;

  @override
  String toString() => 'SubmissionException(${failure.name})';
}

/// One attempt at filing a report.
///
/// [idempotencyKey] is generated once per report and reused by every retry.
/// Without it, a send that times out after the server committed would file the
/// same report twice as soon as the user pressed "Réessayer" — and a duplicate
/// case is not a cosmetic problem here: it means a second person spending time
/// on an incident already being handled.
typedef SubmissionAttempt = ({ReportModel report, String idempotencyKey});

/// Delivers a report and returns the reference code the server assigned.
///
/// Must throw a [SubmissionException] when it fails. This is the seam the
/// backend plugs into: `ReportProvider` needs no change, and the tests inject
/// failures through it rather than pretending.
typedef ReportSubmitter = Future<String> Function(SubmissionAttempt attempt);
