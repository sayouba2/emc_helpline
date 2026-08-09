import 'package:flutter/material.dart';

/// A page body that scrolls, with a scrollbar that stays visible.
///
/// The default mobile scrollbar only fades in once you are already scrolling,
/// which is too late: arriving on a wizard step, nothing tells you whether
/// anything continues below the fold. Here the thumb is drawn as soon as the
/// content overflows — and Flutter draws nothing at all when it does not, so
/// a short step stays clean.
///
/// The scrollbar also honours the text direction, so it sits on the left in
/// Arabic.
class ScrollablePage extends StatefulWidget {
  const ScrollablePage({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  State<ScrollablePage> createState() => _ScrollablePageState();
}

class _ScrollablePageState extends State<ScrollablePage> {
  // `thumbVisibility` needs a controller shared with the scroll view.
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _controller,
        padding: widget.padding,
        child: widget.child,
      ),
    );
  }
}
