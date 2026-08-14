import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/icon_utils.dart';
import 'interactive_card.dart';

/// What marks the selected option.
enum ChoiceMarker {
  /// A radio dot on the trailing edge — for lists where one answer is expected.
  radio,

  /// A check that only appears once chosen — lighter, for long lists.
  check,

  /// Nothing beyond the border and colour change.
  none,
}

/// One selectable answer, laid out as a row.
///
/// Every step used to hand-roll this: same shape, seven slightly different
/// paddings, radii, shadows and selected states. One component means the
/// wizard reads as a single form, and the `selected` semantics that screen
/// readers announce can no longer be forgotten on a screen.
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.subtitle,
    this.badge,
    this.accentColor = AppColors.primaryBlue,
    this.iconBackground,
    this.marker = ChoiceMarker.radio,
  });

  final String label;
  final dynamic icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String? subtitle;
  final String? badge;

  /// Colours the icon, the border and the label when selected. Steps that carry
  /// their own meaning — urgency, platform brands — pass their own.
  final Color accentColor;
  final Color? iconBackground;
  final ChoiceMarker marker;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InteractiveCard(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.whatsappBg : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? accentColor : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color:
                        iconBackground ??
                        (isSelected
                            ? accentColor.withValues(alpha: 0.14)
                            : AppColors.bg),
                    shape: BoxShape.circle,
                  ),
                  child: IconUtils.buildIcon(
                    icon,
                    color: accentColor,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              style: AppTextStyles.cardTitle.copyWith(
                                fontSize: 15,
                                color: isSelected
                                    ? accentColor
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            _Badge(text: badge!, color: accentColor),
                          ],
                        ],
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: AppTextStyles.cardSubtitle.copyWith(
                            fontSize: 12.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (marker != ChoiceMarker.none) ...[
                  const SizedBox(width: 10),
                  _Marker(
                    marker: marker,
                    isSelected: isSelected,
                    color: accentColor,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The same choice as a tile, for the two-column layouts.
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.subtitle,
    this.accentColor = AppColors.primaryBlue,
    this.iconBackground,
  });

  final String label;
  final dynamic icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String? subtitle;
  final Color accentColor;
  final Color? iconBackground;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: InteractiveCard(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.whatsappBg : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? accentColor : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: _Marker(
                  marker: ChoiceMarker.radio,
                  isSelected: isSelected,
                  color: accentColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color:
                      iconBackground ??
                      (isSelected
                          ? accentColor.withValues(alpha: 0.14)
                          : AppColors.bg),
                  shape: BoxShape.circle,
                ),
                child: IconUtils.buildIcon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardTitle.copyWith(
                  fontSize: 14,
                  color: isSelected ? accentColor : AppColors.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardSubtitle.copyWith(
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({
    required this.marker,
    required this.isSelected,
    required this.color,
  });

  final ChoiceMarker marker;
  final bool isSelected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (marker == ChoiceMarker.check) {
      return Icon(
        Icons.check_circle_rounded,
        size: 20,
        color: isSelected ? color : Colors.transparent,
      );
    }
    return Icon(
      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
      size: 20,
      color: isSelected ? color : AppColors.border,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
