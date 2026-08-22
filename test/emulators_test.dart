import 'package:flutter_test/flutter_test.dart';

import 'package:emc_helpline/core/backend/emulators.dart';

/// Ces tests tournent avec `USE_EMULATORS` non défini, donc `useEmulators` est
/// faux : c'est le comportement de production qui est vérifié ici. La branche
/// émulateur est couverte par le test de bout en bout côté backend.
void main() {
  group('une URL est utile à l\'adresse de qui va l\'appeler', () {
    test('une URL signée de production passe intacte', () {
      // Hors mode émulateur, rien n'est réécrit : l'URL est signée, et changer
      // un seul caractère invaliderait la signature.
      const signed =
          'https://storage.googleapis.com/bucket/evidence/abc/1.png?X-Goog-Signature=deadbeef';

      expect(reachableFromDevice(signed), signed);
    });

    test('le mode par défaut est la production', () {
      // Un build qui ne reçoit pas le drapeau ne doit pas pouvoir viser le
      // portable d'un développeur.
      expect(useEmulators, isFalse);
      expect(
        reachableFromDevice('http://127.0.0.1:9199/v0/b/bucket/o?name=x'),
        'http://127.0.0.1:9199/v0/b/bucket/o?name=x',
      );
    });

    test('l\'hôte par défaut est celui de l\'émulateur Android', () {
      expect(emulatorHost, '10.0.2.2');
    });

    test('ce qui n\'est pas une URL est rendu tel quel', () {
      expect(reachableFromDevice(''), '');
      expect(reachableFromDevice('pas une url'), 'pas une url');
    });
  });
}
