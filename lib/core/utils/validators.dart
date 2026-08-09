/// Why a step or a field is not acceptable yet.
///
/// The provider and the validators return one of these rather than a sentence:
/// they have no `BuildContext`, and the wording belongs to the ARB files. The
/// widget turns it into text with `ValidationMessageLabel.text`.
enum ValidationMessage {
  chooseWho,
  chooseAge,
  chooseGender,
  chooseIncident,
  choosePlatform,
  chooseEvidence,
  chooseAssistance,
  chooseAssistanceType,
  chooseUrgency,
  missingPseudo,
  missingPhone,
  invalidPhone,
  invalidUrl,
}

/// Validation of the free-text fields of a report.
///
/// Each method returns `null` when the value is acceptable. Empty values are
/// always accepted here: whether a field is *required* is decided per step by
/// `ReportProvider`, not per field.
class Validators {
  const Validators._();

  /// Moroccan numbers are 10 digits locally (06…) or 12 with the +212 prefix.
  /// We stay permissive to accommodate foreign numbers, and only reject what is
  /// obviously not a phone number.
  static const int _minPhoneDigits = 9;
  static const int _maxPhoneDigits = 15;

  static bool isBlank(String? value) => value == null || value.trim().isEmpty;

  static ValidationMessage? phone(String? value) {
    if (isBlank(value)) return null;
    final digits = value!.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < _minPhoneDigits || digits.length > _maxPhoneDigits) {
      return ValidationMessage.invalidPhone;
    }
    return null;
  }

  /// Accepts a bare domain too (`exemple.com`), like `LauncherUtils.openWebPage`
  /// which prepends the scheme itself.
  static ValidationMessage? url(String? value) {
    if (isBlank(value)) return null;
    final raw = value!.trim();
    final normalized = raw.startsWith('http://') || raw.startsWith('https://')
        ? raw
        : 'https://$raw';
    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.host.isEmpty || !uri.host.contains('.')) {
      return ValidationMessage.invalidUrl;
    }
    return null;
  }
}
