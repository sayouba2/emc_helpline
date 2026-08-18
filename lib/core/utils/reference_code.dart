import 'dart:math';

/// The number handed to the user at the end of a report, and the only key to
/// their case afterwards.
///
/// It is a bearer token: whoever knows it can look up the case, because there
/// is no account to authenticate against. So it has to be unguessable —
/// `REF-EMC-2026-123456` was not. Six digits is 900 000 possibilities, which an
/// attacker enumerates in an afternoon; the payload here is 60 bits, about
/// 10^18.
///
/// It also has to survive being read out loud by a frightened child over the
/// phone, which is why the alphabet drops every look-alike character and
/// [payloadOf] forgives the confusions that remain.
class ReferenceCode {
  const ReferenceCode._();

  /// Crockford's base32: the digits and letters minus `I`, `L`, `O` and `U`.
  /// The first three because they are read back as `1`, `1` and `0`; `U`
  /// because dropping it keeps the generator from spelling something a child
  /// would be embarrassed to dictate.
  static const String alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

  static const String prefix = 'EMC';

  /// A well-formed code, for field hints and documentation. Not a real case.
  static const String example = 'EMC-4K7P-W9XM-2QTR';

  /// 12 characters of 5 bits. Groups of four, because that is how people read
  /// back a code they did not choose.
  static const int payloadLength = 12;
  static const int _groupSize = 4;

  /// What a mistyped character most likely meant.
  static const Map<String, String> _aliases = {'O': '0', 'I': '1', 'L': '1'};

  /// A fresh code in canonical form, e.g. `EMC-4K7P-W9XM-2QTR`.
  ///
  /// [Random.secure] rather than [Random]: the sequence must not be
  /// predictable from a previous code. This is the client-side stand-in — once
  /// the backend exists the server allocates the code, and it is the server
  /// that guarantees uniqueness.
  static String generate([Random? random]) {
    final rng = random ?? Random.secure();
    final payload = List.generate(
      payloadLength,
      (_) => alphabet[rng.nextInt(alphabet.length)],
    ).join();
    return format(payload);
  }

  /// Canonical display form: the prefix, then groups of four.
  static String format(String payload) {
    final groups = <String>[];
    for (var i = 0; i < payload.length; i += _groupSize) {
      groups.add(payload.substring(i, min(i + _groupSize, payload.length)));
    }
    return '$prefix-${groups.join('-')}';
  }

  /// The 12 significant characters of [input], or `null` when it cannot be a
  /// reference code.
  ///
  /// Accepts what a user actually types: lower case, missing or extra dashes,
  /// spaces, with or without the `EMC` prefix, and `O` for `0` or `I`/`l` for
  /// `1`. Comparing two codes means comparing their payloads — never the
  /// strings.
  static String? payloadOf(String? input) {
    if (input == null) return null;

    final buffer = StringBuffer();
    for (final char in input.toUpperCase().split('')) {
      final resolved = _aliases[char] ?? char;
      // Anything else — dashes, spaces, punctuation — is decoration.
      if (alphabet.contains(resolved)) buffer.write(resolved);
    }
    var payload = buffer.toString();

    // `EMC` is itself made of alphabet characters, so it survives the strip
    // above. Length tells the two cases apart without ambiguity: a bare
    // payload is 12 characters, a prefixed one is 15.
    if (payload.length == prefix.length + payloadLength &&
        payload.startsWith(prefix)) {
      payload = payload.substring(prefix.length);
    }

    return payload.length == payloadLength ? payload : null;
  }

  /// Whether [input] could be a reference code at all.
  ///
  /// Worth checking before a lookup: it turns "you typed it wrong" into its own
  /// message instead of "no such case", and it spends no server call — nor any
  /// of the rate-limit budget that protects the codes — on input that cannot
  /// match.
  static bool isWellFormed(String? input) => payloadOf(input) != null;
}
