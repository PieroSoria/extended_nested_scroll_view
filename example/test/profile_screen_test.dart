import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart'
    as ext;
import 'package:extended_nested_scroll_view_example/profile_screen.dart';

void main() {
  testWidgets('profile screen builds and stretches the banner', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await tester.pump();
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.text('Jane Appleseed'), findsOneWidget);

    // Pull down from the top of the active tab: with headerStretch the banner
    // must overscroll (render its stretch effect) instead of clamping.
    final state = tester.state<ext.ExtendedNestedScrollViewState>(
        find.byType(ext.ExtendedNestedScrollView));
    final gesture = await tester
        .startGesture(tester.getCenter(find.byKey(const ValueKey<String>('tab-0'))));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(0, 12));
      await tester.pump();
    }
    expect(state.outerController.position.pixels, lessThan(0),
        reason: 'headerStretch must let the banner overscroll below 0');
    await gesture.up();
    await tester.pumpAndSettle();
    expect(state.outerController.position.pixels, 0,
        reason: 'releasing must spring the banner back to the top');
  });
}