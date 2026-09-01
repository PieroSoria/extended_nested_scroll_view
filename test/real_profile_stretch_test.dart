import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart'
    as ext;
import 'package:sliver_tools/sliver_tools.dart';

/// Reproduces the *exact* header layout of the user's real `ProfilePage`:
///
///   ExtendedSliverOverlapAbsorber                       <- wraps everything
///     -> SliverStack
///          |- MultiSliver
///          |    |- ProfileBannerSliverAppBar (stretch:true, zoom+blur)
///          |    |- SliverToBoxAdapter(SizedBox(140))
///          |    |- ProfileTabBarSliverAppBar (pinned, TabBar)
///          |- SliverPositioned.fill(top: positionInfo) info card
///          |- SliverPositioned.fill settings button
///   -> TabBarView of 3 tab lists
///
/// The banner lives *inside* the absorber+stack rather than as a sibling, which
/// is the difference from the canonical setup already tested.
Widget buildRealProfile({bool headerStretch = true}) {
  return MaterialApp(
    home: Scaffold(
      body: DefaultTabController(
        length: 3,
        child: ext.ExtendedNestedScrollView(
          headerStretch: headerStretch,
          headerSliverBuilder: (context, _) {
            final handle = ext.ExtendedNestedScrollView
                .sliverOverlapAbsorberHandleFor(context);
            return <Widget>[
              ext.ExtendedSliverOverlapAbsorber(
                handle: handle,
                sliver: SliverStack(
                  children: <Widget>[
                    MultiSliver(
                      children: <Widget>[
                        const _Banner(),
                        const SliverToBoxAdapter(child: SizedBox(height: 140)),
                        const _PinnedTabBar(),
                      ],
                    ),
                    const SliverPositioned.fill(
                      top: 210,
                      child: SizedBox(height: 120, child: Text('info card')),
                    ),
                  ],
                ),
              ),
            ];
          },
          body: Builder(
            builder: (context) {
              final handle = ext.ExtendedNestedScrollView
                  .sliverOverlapAbsorberHandleFor(context);
              return TabBarView(
                children: <Widget>[
                  _tab(handle, 'grid'),
                  _tab(handle, 'list'),
                  _tab(handle, 'music'),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

Widget _tab(ext.ExtendedSliverOverlapAbsorberHandle handle, String tag) {
  return CustomScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    slivers: <Widget>[
      ext.ExtendedSliverOverlapInjector(handle: handle),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => SizedBox(height: 60, child: Center(child: Text('$tag $i'))),
          childCount: 20,
        ),
      ),
    ],
  );
}

class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      stretch: true,
      expandedHeight: 200,
      toolbarHeight: 0,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        collapseMode: CollapseMode.pin,
        background: const ColoredBox(color: Colors.deepPurple),
      ),
    );
  }
}

class _PinnedTabBar extends StatelessWidget {
  const _PinnedTabBar();

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      bottom: const TabBar(
        tabs: [
          Tab(text: 'Posts'),
          Tab(text: 'Obras'),
          Tab(text: 'Música'),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('real layout: headerStretch overscrolls the outer below 0',
      (tester) async {
    await tester.pumpWidget(buildRealProfile());
    await tester.pump();

    final state = tester.state<ext.ExtendedNestedScrollViewState>(
        find.byType(ext.ExtendedNestedScrollView));

    final gesture = await tester.startGesture(
        tester.getCenter(find.byType(TabBarView)));
    for (var i = 0; i < 12; i++) {
      await gesture.moveBy(const Offset(0, 12));
      await tester.pump();
    }
    expect(state.outerController.position.pixels, lessThan(0),
        reason: 'headerStretch must push the outer to overscroll below 0');

    // Visual check: the banner's FlexibleSpaceBar must be laid out taller than
    // its expandedHeight while stretched (that is what paints zoom/blur).
    final fsbBox = find
        .descendant(
          of: find.byType(_Banner),
          matching: find.byType(FlexibleSpaceBar),
        )
        .evaluate()
        .single
        .findRenderObject()! as RenderBox;
    expect(fsbBox.constraints.maxHeight, greaterThan(200.0),
        reason: 'the FlexibleSpaceBar box must be told to grow past '
            'expandedHeight to paint zoom/blur; got maxHeight=${fsbBox.constraints.maxHeight}');

    await gesture.up();
    await tester.pumpAndSettle();
    expect(state.outerController.position.pixels, 0,
        reason: 'releasing must rebound the outer back to 0');
  });

  // Regression for the "extra <= 0.0" crash: the app tripped it when the OUTER
// was in negative stretch overscroll AND the INNER was also slightly
// over-scrolled below 0, then a frame/re-layout re-ran _getMetrics via
// applyNewDimensions (third else-branch). We reproduce that diagonal state by
// pulling the whole scroll into overscroll and forcing a re-layout mid-motion
// via a surface-size change.
  testWidgets(
      'regression: re-layout with outer+inner overscrolled does not trip extra<=0',
      (tester) async {
    await tester.pumpWidget(buildRealProfile());
    await tester.pump();

    final state = tester.state<ext.ExtendedNestedScrollViewState>(
        find.byType(ext.ExtendedNestedScrollView));

    // Drag the active grid down hard so both the outer (banner) and the inner
    // list go into negative overscroll — the exact diagonal state of the crash.
    final center = tester.getCenter(find.byType(TabBarView));
    final down = await tester.startGesture(center, pointer: 7);
    for (var i = 0; i < 18; i++) {
      await down.moveBy(const Offset(0, 16));
      await tester.pump();
    }
    expect(state.outerController.position.pixels, lessThan(0),
        reason: 'the outer banner must be over-scrolled negative first');

    // While the ballistic is settling, force a re-layout (viewport changes size);
    // applyNewDimensions then re-runs _getMetrics with outer < 0.
    await tester.binding.setSurfaceSize(const Size(402, 700));
    await tester.pump();
    await tester.binding.setSurfaceSize(const Size(402, 500));
    await tester.pump();

    expect(tester.takeException(), isNull,
        reason: 're-laying out during a double overscroll must not assert');
    await down.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull,
        reason: 'no assertion (extra <= 0.0) while re-laying out during a stretch');
    expect(state.outerController.position.pixels, 0,
        reason: 'releasing after the re-layout must rebound the outer back to 0');
  });
}