import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_translations.dart';
import '../../core/utils/icon_utils.dart';
import '../../providers/report_provider.dart';
import '../../providers/theme_provider.dart';

class EmcChatbotScreen extends StatefulWidget {
  const EmcChatbotScreen({super.key});

  @override
  State<EmcChatbotScreen> createState() => _EmcChatbotScreenState();
}

class _EmcChatbotScreenState extends State<EmcChatbotScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _messages = [
    {
      'sender': 'bot',
      'text': 'Bonjour ! Je suis le Chatbot EMC Helpline 🤖.\nTu as été redirigé ici car tu as plus de 12 ans.\nJe suis là pour t\'écouter, t\'aider et te guider en toute confidentialité.\nComment puis-je t\'aider aujourd\'hui ?',
    },
  ];

  final List<String> _quickQuestions = [
    'Comment bloquer un harceleur ?',
    'On a partagé une photo de moi sans mon accord',
    'Un inconnu me demande des informations privées',
    'Poursuivre mon formulaire de signalement',
  ];

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    if (text == 'Poursuivre mon formulaire de signalement') {
      Navigator.pop(context);
      final reportProvider = Provider.of<ReportProvider>(context, listen: false);
      reportProvider.nextWizardStep();
      return;
    }

    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _inputController.clear();
    });

    _scrollToBottom();

    // Simulated Bot Response
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'sender': 'bot',
          'text': _generateBotAnswer(text),
        });
      });
      _scrollToBottom();
    });
  }

  String _generateBotAnswer(String userText) {
    final lower = userText.toLowerCase();
    if (lower.contains('bloquer') || lower.contains('harcel')) {
      return '🛡️ Pour bloquer un utilisateur :\n1. Ne lui réponds plus.\n2. Fais des captures d\'écran des messages comme preuve.\n3. Clique sur les 3 petits points de son profil et choisis "Bloquer et Signaler".\n\nSouhaites-tu poursuivre ton dossier de signalement officiel sur EMC Helpline ?';
    } else if (lower.contains('photo') || lower.contains('image')) {
      return '⚠️ Si une photo privée circule :\n1. Ne t\'inquiète pas, tu n\'es pas responsable.\n2. Ne supprime pas les preuves.\n3. Remplis notre formulaire de signalement EMC Helpline pour qu\'un spécialiste intervienne rapidement.';
    } else if (lower.contains('conseiller') || lower.contains('humain') || lower.contains('contact')) {
      return '📞 Tu peux contacter nos conseillers humains gratuitement par :\n• WhatsApp : +212 624 405 889\n• Police : 19 | Gendarmerie : 177\n\nTu peux aussi cliquer sur l\'onglet Contact en bas !';
    } else {
      return 'Merci pour ton message. Pour ta sécurité, ne partage jamais ton nom de famille ou ton adresse en ligne.\nSi tu vis une situation difficile, clique sur "Poursuivre le formulaire" pour envoyer un dossier anonyme à nos experts.';
    }
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
    final reportProvider = Provider.of<ReportProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final lang = reportProvider.currentLanguage;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.cardBgDark : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: IconUtils.buildIcon(
                FontAwesomeIcons.robot,
                color: AppColors.primaryOrange,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chatbot EMC (+12 ans)',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    'Assistant Virtuel • En ligne',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark ? AppColors.accentCyan : AppColors.whatsappGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Option pour revenir au formulaire de signalement
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              reportProvider.nextWizardStep();
            },
            child: const Text(
              'Formulaire ->',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.primaryOrange,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Partner Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? AppColors.cardBgDark : AppColors.whatsappBgLight,
            child: Row(
              children: [
                Image.asset('assets/images/cmrpi.png', height: 20, width: 20, errorBuilder: (c, e, s) => const SizedBox()),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppTranslations.getText('cmrpi_partner', lang),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isBot = msg['sender'] == 'bot';

                return Align(
                  alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isBot
                          ? (isDark ? AppColors.cardBgDark : Colors.white)
                          : AppColors.primaryOrange,
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
                      msg['text']!,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: isBot
                            ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                            : Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Quick Suggestion Chips
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _quickQuestions.length,
              itemBuilder: (context, index) {
                final q = _quickQuestions[index];
                final isFormAction = q == 'Poursuivre mon formulaire de signalement';

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    backgroundColor: isFormAction
                        ? AppColors.primaryOrange.withValues(alpha: 0.15)
                        : (isDark ? AppColors.cardBgDark : Colors.white),
                    side: BorderSide(
                      color: isFormAction
                          ? AppColors.primaryOrange
                          : (isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    label: Text(
                      q,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isFormAction ? FontWeight.bold : FontWeight.normal,
                        color: isFormAction
                            ? AppColors.primaryOrange
                            : (isDark ? AppColors.accentCyan : AppColors.primaryBlue),
                      ),
                    ),
                    onPressed: () => _sendMessage(q),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Input Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardBgDark : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      style: TextStyle(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Écris ta question ici...',
                        hintStyle: TextStyle(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          fontSize: 13.5,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        filled: true,
                        fillColor: isDark ? AppColors.bgDark : AppColors.bgLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                    ),
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    onPressed: () => _sendMessage(_inputController.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
