import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:emc_helpline/core/utils/reference_code.dart';

void main() {
  group('the code cannot be guessed', () {
    test('carries at least 50 bits of entropy', () {
      final bits = ReferenceCode.payloadLength * (log(32) / log(2));

      // The old REF-EMC-2026-NNNNNN was 900 000 possibilities — about 20 bits,
      // enumerable in an afternoon. Anything below 50 puts every child's case
      // within reach of a script.
      expect(bits, greaterThanOrEqualTo(50));
      expect(ReferenceCode.alphabet.length, 32);
    });

    test('draws on the full alphabet', () {
      final seen = <String>{};
      for (var i = 0; i < 400; i++) {
        seen.addAll(
          ReferenceCode.payloadOf(ReferenceCode.generate())!.split(''),
        );
      }

      expect(
        seen.length,
        ReferenceCode.alphabet.length,
        reason: 'a character never drawn is entropy not actually there',
      );
    });

    test('does not repeat itself', () {
      final codes = List.generate(2000, (_) => ReferenceCode.generate());

      expect(codes.toSet(), hasLength(codes.length));
    });
  });

  group('the code can be read out loud', () {
    test('never uses a character that reads as another', () {
      for (final ambiguous in ['I', 'L', 'O', 'U']) {
        expect(
          ReferenceCode.alphabet,
          isNot(contains(ambiguous)),
          reason: '$ambiguous is read back as something else over the phone',
        );
      }
    });

    test('is grouped, prefixed and uppercase', () {
      expect(
        ReferenceCode.generate(),
        matches(RegExp(r'^EMC(-[0-9A-Z]{4}){3}$')),
      );
      expect(ReferenceCode.example, matches(RegExp(r'^EMC(-[0-9A-Z]{4}){3}$')));
    });
  });

  group('what the user types is matched by meaning, not by shape', () {
    const canonical = 'EMC-4K7P-W9XM-2QTR';
    final payload = ReferenceCode.payloadOf(canonical);

    test('accepts the canonical form', () {
      expect(payload, '4K7PW9XM2QTR');
    });

    test('forgives case, spacing and missing dashes', () {
      for (final variant in [
        'emc-4k7p-w9xm-2qtr',
        'EMC4K7PW9XM2QTR',
        '  EMC 4K7P W9XM 2QTR  ',
        '4K7PW9XM2QTR',
        '4k7p-w9xm-2qtr',
      ]) {
        expect(ReferenceCode.payloadOf(variant), payload, reason: variant);
      }
    });

    test('forgives the confusions the alphabet could not remove', () {
      // A child dictating over the phone says "O" for zero and "l" for one.
      expect(ReferenceCode.payloadOf('EMC-O123-4567-89AB'), '0123456789AB');
      expect(ReferenceCode.payloadOf('EMC-I123-4567-89AB'), '1123456789AB');
      expect(ReferenceCode.payloadOf('EMC-l123-4567-89AB'), '1123456789AB');
    });

    test('rejects what cannot be a code', () {
      for (final invalid in ['', '   ', 'EMC', '4K7P', 'REF-EMC-2026-123456']) {
        expect(ReferenceCode.isWellFormed(invalid), isFalse, reason: invalid);
      }
      expect(ReferenceCode.payloadOf(null), isNull);
    });

    test(
      'a 12-character payload starting with EMC is not mistaken for a prefix',
      () {
        // Length is what tells the two apart: 12 bare, 15 prefixed.
        expect(ReferenceCode.payloadOf('EMC123456789'), 'EMC123456789');
        expect(ReferenceCode.payloadOf('EMC-EMC1-2345-6789'), 'EMC123456789');
      },
    );

    test('every generated code round-trips through its own display form', () {
      for (var i = 0; i < 200; i++) {
        final code = ReferenceCode.generate();
        final parsed = ReferenceCode.payloadOf(code);
        expect(parsed, isNotNull);
        expect(ReferenceCode.format(parsed!), code);
      }
    });
  });
}
