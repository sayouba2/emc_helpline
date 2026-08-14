import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/icon_utils.dart';
import '../../l10n/app_localizations.dart';

class EmcChatbotScreen extends StatefulWidget {
  const EmcChatbotScreen({super.key});

  @override
  State<EmcChatbotScreen> createState() => _EmcChatbotScreenState();
}

class _EmcChatbotScreenState extends State<EmcChatbotScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// `null` text means "the localised greeting", resolved at build time so the
  /// opening message follows a language change.
  final List<({bool isBot, String? text})> _messages = [
    (isBot: true, text: null),
  ];

  /// Which canned reply a free-text message maps to. The matching is keyword
  /// based and French-only for now — see the note in `_answerFor`.
  _BotTopic _topicFor(String userText) {
    final lower = userText.toLowerCase();
    if (lower.contains('bloquer') || lower.contains('harcel')) {
      return _BotTopic.blocking;
    }
    if (lower.contains('photo') || lower.contains('image')) {
      return _BotTopic.photo;
    }
    if (lower.contains('conseiller') ||
        lower.contains('humain') ||
        lower.contains('contact')) {
      return _BotTopic.humanContact;
    }
    return _BotTopic.fallback;
  }

  String _answerFor(_BotTopic topic, AppLocalizations l10n) => switch (topic) {
    _BotTopic.blocking => l10n.chatbotAnswerBlock,
    _BotTopic.photo => l10n.chatbotAnswerPhoto,
    _BotTopic.humanContact => l10n.chatbotAnswerContact,
    _BotTopic.fallback => l10n.chatbotAnswerDefault,
  };

  void _sendMessage(String text, AppLocalizations l10n) {
    if (text.trim().isEmpty) return;

    // Le chatbot ne pilote pas le wizard : il rend la main à l'étape d'où il a
    // été ouvert, l'utilisateur poursuit ensuite avec "Suivant".
    if (text == l10n.chatbotBackToForm) {
      Navigator.pop(context);
      return;
    }

    final answer = _answerFor(_topicFor(text), l10n);

    setState(() {
      _messages.add((isBot: false, text: text));
      _inputController.clear();
    });

    _scrollToBottom();

    // Simulated Bot Response
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _messages.add((isBot: true, text: answer)));
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final quickQuestions = [
      l10n.chatbotQuestionBlock,
      l10n.chatbotQuestionPhoto,
      l10n.chatbotQuestionPrivacy,
      l10n.chatbotBackToForm,
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            // Avatar avec la pastille verte : le statut se lit d'un coup d'œil
            // avant même la ligne de texte.
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: IconUtils.buildIcon(
                    FontAwesomeIcons.robot,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                PositionedDirectional(
                  bottom: 0,
                  end: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.whatsappGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          l10n.chatbotTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Les réponses sont scriptées : le badge le dit plutôt
                      // que de laisser croire à un vrai conseiller.
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.whatsappGreen),
                        ),
                        child: Text(
                          l10n.chatbotBetaBadge,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.whatsappGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    l10n.chatbotStatus,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            // Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isBot = msg.isBot;
                  final text = msg.text ?? l10n.chatbotGreeting;

                  return Align(
                    alignment: isBot
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8,
                      ),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isBot ? Colors.white : AppColors.primaryOrange,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(isBot ? 4 : 18),
                          bottomRight: Radius.circular(isBot ? 18 : 4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: isBot ? AppColors.textPrimary : Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Quick Suggestion Chips
            SizedBox(
              height: 52,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: quickQuestions.length,
                itemBuilder: (context, index) {
                  final q = quickQuestions[index];
                  final isFormAction = q == l10n.chatbotBackToForm;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      backgroundColor: isFormAction
                          ? AppColors.primaryOrange.withValues(alpha: 0.15)
                          : Colors.white,
                      side: BorderSide(
                        color: isFormAction
                            ? AppColors.primaryOrange
                            : AppColors.border,
                      ),
                      label: Text(
                        q,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isFormAction
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isFormAction
                              ? AppColors.primaryOrange
                              : AppColors.primaryBlue,
                        ),
                      ),
                      onPressed: () => _sendMessage(q, l10n),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Input Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: l10n.chatbotInputHint,
                          hintStyle: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13.5,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: AppColors.bg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (value) => _sendMessage(value, l10n),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: l10n.a11ySendMessage,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        minimumSize: const Size(48, 48),
                      ),
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () =>
                          _sendMessage(_inputController.text, l10n),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The canned topics the simulated assistant can answer.
enum _BotTopic { blocking, photo, humanContact, fallback }
