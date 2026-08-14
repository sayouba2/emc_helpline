import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';

class StepperWidget extends StatelessWidget {
  /// The phase being shown, 1 to 4 — what the dots and labels reflect.
  final int currentStep;

  /// How far through the eleven sub-steps the user actually is.
  ///
  /// The bar used to be driven by the phase, so it jumped in quarters and sat
  /// still for the seven sub-steps of phase 3. Progress now moves at every
  /// answer, while the labels keep naming where you are.
  final double progress;

  /// Drops the phase labels when the viewport is too short to carry them —
  /// landscape, mostly. The bar and the dots still say where you are.
  final bool compact;

  const StepperWidget({
    super.key,
    required this.currentStep,
    required this.progress,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = [
      {'num': 1, 'label': l10n.stepperContext},
      {'num': 2, 'label': l10n.stepperProfile},
      {'num': 3, 'label': l10n.stepperIncident},
      {'num': 4, 'label': l10n.stepperSummary},
    ];

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: compact ? 8 : 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: steps.map((s) {
              final stepNum = s['num'] as int;
              final label = s['label'] as String;
              final isCompleted = stepNum < currentStep;
              final isActive = stepNum == currentStep;

              return Expanded(
                child: Semantics(
                  label: l10n.a11yStep(stepNum, steps.length, label),
                  selected: isActive,
                  child: ExcludeSemantics(
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primaryOrange
                                : (isCompleted
                                      ? AppColors.primaryBlue
                                      : AppColors.bg),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isActive
                                  ? AppColors.primaryOrange
                                  : (isCompleted
                                        ? AppColors.primaryBlue
                                        : AppColors.border),
                              width: 2,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: AppColors.primaryOrange.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 10,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : Text(
                                    '$stepNum',
                                    style: TextStyle(
                                      color: isActive
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                          ),
                        ),
                        // The labels are the first thing to go when there is
                        // no room: four of them side by side overflowed as
                        // soon as the user scaled text up.
                        if (!compact) ...[
                          const SizedBox(height: 4),
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isActive
                                  ? AppColors.primaryOrange
                                  : (isCompleted
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: compact ? 8 : 12),
          // Glowing Progress Bar — the dots above already convey the progress,
          // so a screen reader would only repeat itself here.
          ExcludeSemantics(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: AppColors.border,
                color: AppColors.primaryOrange,
                minHeight: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
