import 'package:flutter_test/flutter_test.dart';

import 'package:emc_helpline/views/chatbot/bot_topics.dart';

void main() {
  group('the assistant answers in every language the app speaks', () {
    test('French', () {
      expect(topicFor('comment bloquer quelqu un'), BotTopic.blocking);
      expect(topicFor('il a publié ma photo'), BotTopic.photo);
      expect(topicFor('je veux parler à un conseiller'), BotTopic.humanContact);
    });

    test('Arabic', () {
      // The case this whole file exists for. Before, every one of these fell
      // through to the default answer.
      expect(topicFor('كيف أحظر شخصاً'), BotTopic.blocking);
      expect(topicFor('نشر صورتي'), BotTopic.photo);
      expect(topicFor('أريد التحدث مع مستشار'), BotTopic.humanContact);
    });

    test('English', () {
      expect(topicFor('how do I block him'), BotTopic.blocking);
      expect(topicFor('he shared my picture'), BotTopic.photo);
      expect(topicFor('can I talk to someone'), BotTopic.humanContact);
    });

    test('and falls back rather than guessing', () {
      expect(topicFor('bonjour'), BotTopic.fallback);
      expect(topicFor(''), BotTopic.fallback);
      expect(topicFor('   '), BotTopic.fallback);
      expect(topicFor('مرحبا'), BotTopic.fallback);
    });
  });

  group('what someone actually types', () {
    test('Arabic without the diacritics nobody puts in', () {
      // Harakat are optional in writing and usually left out. Both spellings
      // have to reach the same answer.
      expect(topicFor('تحرش'), BotTopic.blocking);
      expect(topicFor('تَحَرُّش'), BotTopic.blocking);
    });

    test('any of the four ways of writing alef', () {
      for (final spelling in ['احظر', 'أحظر', 'إحظر', 'آحظر']) {
        expect(topicFor(spelling), BotTopic.blocking, reason: spelling);
      }
    });

    test('teh marbuta typed as heh, alef maqsura as yeh', () {
      expect(topicFor('مساعدة'), BotTopic.humanContact);
      expect(topicFor('مساعده'), BotTopic.humanContact);
    });

    test('French without the accents nobody types in a hurry', () {
      expect(topicFor('harcèlement'), BotTopic.blocking);
      expect(topicFor('harcelement'), BotTopic.blocking);
      expect(topicFor('vidéo'), BotTopic.photo);
      expect(topicFor('video'), BotTopic.photo);
    });

    test('any capitalisation', () {
      expect(topicFor('BLOQUER'), BotTopic.blocking);
      expect(topicFor('Photo'), BotTopic.photo);
    });

    test('a word inside a sentence, with punctuation around it', () {
      expect(
        topicFor("quelqu'un me menace, qu'est-ce que je fais ?"),
        BotTopic.blocking,
      );
    });

    test('Arabic prefixes and suffixes, which attach freely', () {
      // The keyword list holds roots for exactly this reason.
      for (final form in ['الحظر', 'حظره', 'يحظر', 'وحظر']) {
        expect(topicFor(form), BotTopic.blocking, reason: form);
      }
    });
  });

  group('when two topics could match', () {
    test('harassment wins over the photo answer', () {
      // "They shared my photo and he is threatening me" is a harassment case
      // first: the blocking answer is the one that says what to do in the next
      // five minutes.
      expect(
        topicFor('il a diffusé ma photo et il me menace'),
        BotTopic.blocking,
      );
    });
  });

  group('normalisation', () {
    test('leaves an ordinary sentence recognisable', () {
      expect(normalizeForMatching('Bonjour'), 'bonjour');
      expect(normalizeForMatching('حظر'), 'حظر');
    });

    test('removes harakat and tatweel without eating letters', () {
      expect(normalizeForMatching('تَحَرُّش'), normalizeForMatching('تحرش'));
      expect(normalizeForMatching('مســاعدة'), normalizeForMatching('مساعدة'));
    });

    test('is idempotent', () {
      for (final input in ['harcèlement', 'تَحَرُّش', 'أحظر', 'Photo']) {
        final once = normalizeForMatching(input);
        expect(normalizeForMatching(once), once, reason: input);
      }
    });
  });
}
