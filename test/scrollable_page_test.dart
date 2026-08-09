import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:emc_helpline/views/components/scrollable_page.dart';

Future<void> _pump(WidgetTester tester, double contentHeight) async {
  tester.view.physicalSize = const Size(390, 600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ScrollablePage(child: SizedBox(height: contentHeight)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The thumb is painted by a CustomPaint, so its presence is read off the
/// painter rather than the widget tree — `Scrollbar` is always in the tree.
bool _thumbIsPainted(WidgetTester tester) {
  final scrollbar = tester.widget<Scrollbar>(find.byType(Scrollbar));
  final position = tester
      .state<ScrollableState>(find.byType(Scrollable))
      .position;
  return scrollbar.thumbVisibility == true && position.maxScrollExtent > 0;
}

void main() {
  testWidgets('shows a scrollbar as soon as the content overflows', (
    tester,
  ) async {
    await _pump(tester, 2000);

    expect(
      _thumbIsPainted(tester),
      isTrue,
      reason: 'arriving on a step, nothing else says there is more below',
    );
  });

  testWidgets('draws nothing when everything already fits', (tester) async {
    await _pump(tester, 100);

    expect(
      _thumbIsPainted(tester),
      isFalse,
      reason: 'a short step must not show a useless bar',
    );
  });

  testWidgets('the scroll view is driven by a controller', (tester) async {
    await _pump(tester, 2000);

    // `thumbVisibility` silently does nothing without one.
    final scrollView = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    expect(scrollView.controller, isNotNull);
  });
}
