import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/theme_provider.dart';

class StepperWidget extends StatelessWidget {
  final int currentStep; // 1, 2, 3, or 4

  const StepperWidget({
    super.key,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final steps = [
      {'num': 1, 'label': 'Contexte'},
      {'num': 2, 'label': 'Profil'},
      {'num': 3, 'label': 'Incident'},
      {'num': 4, 'label': 'Résumé'},
    ];

    return Container(
      color: isDark ? AppColors.bgDark : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: steps.map((s) {
              final stepNum = s['num'] as int;
              final label = s['label'] as String;
              final isCompleted = stepNum < currentStep;
              final isActive = stepNum == currentStep;

              return Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primaryOrange
                          : (isCompleted
                              ? (isDark ? AppColors.accentCyan : AppColors.primaryBlue)
                              : (isDark ? AppColors.cardBgDark : AppColors.bgLight)),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive
                            ? AppColors.primaryOrange
                            : (isCompleted
                                ? (isDark ? AppColors.accentCyan : AppColors.primaryBlue)
                                : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                        width: 2,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppColors.primaryOrange.withValues(alpha: 0.35),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                          : Text(
                              '$stepNum',
                              style: TextStyle(
                                color: (isActive || isCompleted)
                                    ? Colors.white
                                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      color: isActive
                          ? AppColors.primaryOrange
                          : (isCompleted
                              ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Glowing Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: currentStep / 4,
              backgroundColor: isDark ? AppColors.cardBgDark : AppColors.borderLight,
              color: AppColors.primaryOrange,
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}
