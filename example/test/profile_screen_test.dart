import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:extended_nested_scroll_view_example/profile_screen.dart';

void main() {
  testWidgets('profile builds: banner, pinned TabBar, tab lists', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await tester.pump();

    expect(find.byType(ExtendedNestedScrollView), findsOneWidget);
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.byType(Tab),
        findsNWidgets(3)); // Posts, Obras, Música
    expect(find.byKey(const ValueKey<String>('grid-posts')), findsOneWidget);
  });

  testWidgets('headerStretch lets the banner overscroll below 0 and rebound',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await tester.pump();

    final state = tester.state<ExtendedNestedScrollViewState>(
        find.byType(ExtendedNestedScrollView));

    // Pull down from the top of the active tab grid.
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(TabBarView)));
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

  testWidgets('pull-to-refresh fires with a stock RefreshIndicator',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await tester.pump();

    // Overscroll the banner far enough to arm the pull indicator, then release.
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(TabBarView)));
    for (var i = 0; i < 40; i++) {
      await gesture.moveBy(const Offset(0, 12));
      await tester.pump();
    }
    await gesture.up();
    await tester.pump();
    // The Material RefreshIndicator is now in its refreshing state.
    expect(find.byType(RefreshProgressIndicator), findsOneWidget,
        reason: 'a hard pull must arm the Material RefreshIndicator');
    // Let the 3s onRefresh future finish and the dismiss animation settle.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.byType(RefreshProgressIndicator), findsNothing,
        reason: 'the indicator must dismiss once onRefresh completes');
  });
}