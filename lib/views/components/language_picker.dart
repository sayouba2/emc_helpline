import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/icon_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/report_provider.dart';

/// The language chooser, shared by the header pill and the settings screen.
///
/// It lived inside the header. Settings is where people look for it, but the
/// header keeps its flag pill: a child who cannot read the current language
/// recognises a flag without reading anything, and that shortcut matters more
/// here than the usual "settings owns everything" rule.
Future<void> showLanguagePicker(BuildContext context) {
  final provider = Provider.of<ReportProvider>(context, listen: false);
  final l10n = AppLocalizations.of(context);
  final current = Localizations.localeOf(context).languageCode;

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.chooseLanguage,
              style: AppTextStyles.cardTitle.copyWith(
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            for (final option in const [
              (code: 'fr', flag: '🇫🇷'),
              (code: 'ar', flag: '🇲🇦'),
              (code: 'en', flag: '🇬🇧'),
            ])
              _LanguageTile(
                code: option.code,
                flag: option.flag,
                label: switch (option.code) {
                  'ar' => l10n.languageArabic,
                  'en' => l10n.languageEnglish,
                  _ => l10n.languageFrench,
                },
                isSelected: current == option.code,
                onTap: () {
                  provider.setLocale(Locale(option.code));
                  Navigator.pop(sheetContext);
                },
              ),
          ],
        ),
      ),
    ),
  );
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.code,
    required this.flag,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String code;
  final String flag;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.whatsappBg : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: Text(flag, style: const TextStyle(fontSize: 24)),
          title: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary,
            ),
          ),
          trailing: isSelected
              ? IconUtils.buildIcon(
                  FontAwesomeIcons.circleCheck,
                  color: AppColors.primaryBlue,
                  size: 18,
                )
              : null,
          onTap: onTap,
        ),
      ),
    );
  }
}
