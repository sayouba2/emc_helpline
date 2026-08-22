/// What the assistant recognises, in the three languages the app speaks.
///
/// The matching used to be French keywords and a `contains`, so a message in
/// Arabic always fell through to the default answer — on an app whose audience
/// is substantially Arabic-speaking. The badge said BÊTA, which made it honest
/// rather than useful.
library;

/// The canned topics the simulated assistant can answer.
enum BotTopic { blocking, photo, humanContact, fallback }

/// Strips what varies between two spellings of the same word.
///
/// Matching Arabic on raw text barely works. Three things get in the way, and
/// all three are ordinary in what someone types on a phone:
///
/// - **Diacritics** (harakat) are optional and usually omitted, but not always.
/// - **Alef** has four written forms — `ا أ إ آ` — used interchangeably.
/// - **Teh marbuta** `ة` is often typed `ه`, and **alef maqsura** `ى` as `ي`.
///
/// French has its own version of the same problem: someone in a hurry types
/// `harcelement`, not `harcèlement`. So accents come off too, and the whole
/// thing is lowercased.
///
/// Also strips the Arabic-Indic digits, which are not matched on but would
/// otherwise break a word in two.
String normalizeForMatching(String input) {
  final buffer = StringBuffer();

  for (final rune in input.toLowerCase().runes) {
    final char = String.fromCharCode(rune);

    // Harakat and tatweel: decoration, never meaning.
    if (rune >= 0x064B && rune <= 0x0652) continue;
    if (rune == 0x0640) continue;

    buffer.write(_foldings[char] ?? char);
  }

  return buffer.toString();
}

const Map<String, String> _foldings = {
  // Arabic letters written more than one way.
  'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا',
  'ة': 'ه',
  'ى': 'ي',
  'ؤ': 'و',
  'ئ': 'ي',
  // French accents, dropped because nobody types them into a chat box.
  'à': 'a', 'â': 'a', 'ä': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'î': 'i', 'ï': 'i',
  'ô': 'o', 'ö': 'o',
  'ù': 'u', 'û': 'u', 'ü': 'u',
  'ç': 'c',
};

/// The words that point at each topic, already normalised.
///
/// Kept as data rather than woven into the matching code so that a native
/// speaker reviewing the Arabic can add to the list without reading Dart. Roots
/// rather than whole words wherever possible — Arabic attaches prefixes and
/// suffixes freely, so `حظر` catches `الحظر`, `حظره`, `يحظر`.
final Map<BotTopic, List<String>> _keywords = {
  BotTopic.blocking: [
    // fr
    'bloquer', 'bloque', 'harcel', 'insulte', 'menace', 'intimid',
    // ar — bloquer, harcèlement, insulte, menace, importuner
    'حظر', 'حجب', 'تحرش', 'مضايق', 'شتم', 'سب', 'تهديد', 'ازعاج', 'إزعاج',
    // en
    'block', 'harass', 'bully', 'insult', 'threat',
  ],
  BotTopic.photo: [
    // fr
    'photo', 'image', 'capture', 'video', 'vidéo', 'nue', 'intime',
    // ar — photo, image, vidéo, diffusion, intime
    'صور', 'صوره', 'فيديو', 'نشر', 'خاصه', 'حميم', 'فضيحه',
    // en
    'photo', 'picture', 'image', 'video', 'nude', 'intimate',
  ],
  BotTopic.humanContact: [
    // fr
    'conseiller', 'humain', 'contact', 'parler', 'quelqu', 'appeler', 'aide',
    // ar — conseiller, humain, parler, contacter, aide, téléphone
    'مستشار', 'انسان', 'شخص', 'تحدث', 'اتكلم', 'اتصال', 'مساعده', 'هاتف',
    // en
    'adviser', 'advisor', 'human', 'contact', 'talk', 'someone', 'help',
  ],
};

/// Normalised once at load rather than on every keystroke.
final Map<BotTopic, List<String>> _normalized = {
  for (final entry in _keywords.entries)
    entry.key: [for (final word in entry.value) normalizeForMatching(word)],
};

/// Which canned reply a free-text message maps to.
///
/// First match wins, in the order the topics are declared. `blocking` comes
/// before `photo` on purpose: "on a diffusé ma photo et il me menace" is a
/// harassment case first, and the blocking answer is the one that says what to
/// do in the next five minutes.
BotTopic topicFor(String userText) {
  final haystack = normalizeForMatching(userText);
  if (haystack.trim().isEmpty) return BotTopic.fallback;

  for (final entry in _normalized.entries) {
    for (final word in entry.value) {
      if (haystack.contains(word)) return entry.key;
    }
  }
  return BotTopic.fallback;
}
