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

  testWidgets('pull-to-refresh lives on each tab (not on the whole scroll)',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await tester.pump();

    final state = tester.state<ExtendedNestedScrollViewState>(
        find.byType(ExtendedNestedScrollView));
    final inner = state.innerController.position;

    // The per-tab RefreshIndicator exists at rest (verified when idle; mid-pull
    // the TabBarView lazily disposes offscreen children so the finder is empty).
    expect(find.byType(RefreshIndicator), findsAtLeastNWidgets(1),
        reason: 'each tab owns its own RefreshIndicator (not the whole scroll)');

    // Pull down hard from the top: the banner stretches (outer < 0) but the
    // grid's inner scroll must stay parked at 0 — no blank gap below the tab bar.
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(TabBarView)));
    for (var i = 0; i < 40; i++) {
      await gesture.moveBy(const Offset(0, 12));
      await tester.pump();
    }
    expect(state.outerController.position.pixels, lessThan(0),
        reason: 'the banner must stretch while pulling from the top');
    expect(inner.pixels, greaterThanOrEqualTo(0),
        reason: 'the grid (inner) must not be dragged below 0 while the banner '
            'stretches; got inner.pixels=${inner.pixels}');

    await gesture.up();
    await tester.pumpAndSettle();
    expect(state.outerController.position.pixels, 0,
        reason: 'releasing must spring the banner back to the top');
  });
}