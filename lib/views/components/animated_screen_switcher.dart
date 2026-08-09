import 'package:flutter/material.dart';

/// Cross-fades between screens, building **only the visible one**.
///
/// This replaced an `IndexedStack`, which lays out and paints every child. The
/// app nests two of them — four tabs, one of which holds an eleven-step wizard
/// — so roughly fifteen screens and every `GlassContainer` blur they contain
/// were alive on each frame. On an emulator that meant 8.6s to the first frame,
/// ~190 skipped frames, and the system reclaiming memory under the pressure.
///
/// Screens do not keep widget state across a switch. That is safe here: the
/// step screens seed their `TextEditingController`s from `ReportProvider` in
/// `initState`, so nothing the user typed is lost. Scroll positions do reset.
class AnimatedScreenSwitcher extends StatelessWidget {
  const AnimatedScreenSwitcher({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 280),
  });

  final int index;
  final List<Widget> children;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.03),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      // Sizes to the incoming screen rather than to the largest of both, so a
      // tall screen leaving does not stretch the one arriving.
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[...previousChildren, ?currentChild],
      ),
      child: KeyedSubtree(key: ValueKey<int>(index), child: children[index]),
    );
  }
}
