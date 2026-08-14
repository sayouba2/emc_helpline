import 'package:flutter/material.dart';
import '../../core/constants/app_text_styles.dart';
import 'scrollable_page.dart';

/// The frame every wizard step sits in: a question, an optional line of
/// context, then the answers.
///
/// Steps used to repeat this header with slightly different sizes, colours and
/// gaps, which made the eleven screens read as eleven forms rather than one.
/// Scrolling and its always-visible bar come with it.
class StepLayout extends StatelessWidget {
  const StepLayout({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ScrollablePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitle,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: AppTextStyles.screenSubtitle,
            ),
          ],
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }
}
