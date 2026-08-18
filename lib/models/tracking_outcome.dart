import 'report_enums.dart';

/// Where a case stands. Mirrors `REPORT_STATUSES` in `functions/src/config.ts`,
/// member names verbatim — the same contract the report enums follow.
enum ReportStatus { received, inReview, contacted, closed }

/// What a lookup gives back: a status and the two facts that let the user
/// recognise their own case. Never the report itself.
///
/// The reference code is the only credential there is, so what it unlocks is
/// deliberately thin. Someone reading it over a shoulder — or finding it on a
/// shared phone, which is the case this app exists for — learns where a case
/// stands, and nothing more.
class TrackedReport {
  const TrackedReport({
    required this.referenceCode,
    required this.status,
    this.createdAt,
    this.incidentType,
    this.urgencyLevel,
  });

  final String referenceCode;

  /// `null` when the server sent a status this build does not know — a newer
  /// backend against an older app. Shown as a neutral message rather than
  /// guessed at.
  final ReportStatus? status;

  final DateTime? createdAt;
  final IncidentType? incidentType;
  final UrgencyLevel? urgencyLevel;
}

/// The four things that can come of typing a reference number.
sealed class TrackingOutcome {
  const TrackingOutcome();
}

final class TrackingFound extends TrackingOutcome {
  const TrackingFound(this.report);
  final TrackedReport report;
}

/// The number is well formed but matches nothing.
final class TrackingNotFound extends TrackingOutcome {
  const TrackingNotFound();
}

/// The number cannot be one at all. Told apart from [TrackingNotFound] so a
/// typo reads as a typo, and so it costs no lookup.
final class TrackingMalformed extends TrackingOutcome {
  const TrackingMalformed();
}

/// The lookup could not be made. Says nothing about whether the case exists.
final class TrackingUnavailable extends TrackingOutcome {
  const TrackingUnavailable();
}

/// Reads a case back from the backend. `null` means no such case; a throw means
/// the lookup failed, which is not the same thing and must not be shown as one.
typedef ReportLookup = Future<TrackedReport?> Function(String referenceCode);

/// Parses an enum member name off the wire, or `null` if this build does not
/// know it. Never throws: a backend that grows a new value must not crash an
/// app that has not been updated.
T? enumByName<T extends Enum>(List<T> values, Object? name) {
  if (name is! String) return null;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}
