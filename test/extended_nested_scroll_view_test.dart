import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart'
    as ext;
import 'package:sliver_tools/sliver_tools.dart';

/// Builds the canonical profile layout used by every test:
///
///   SliverAppBar(stretch, zoomBackground + fadeTitle)
///   + SliverStack (sliver_tools) that floats a user card over the banner
///   + SliverOverlapAbsorber -> pinned SliverPersistentHeader (TabBar)
///   -> TabBarView of three tab lists, each starting with a
///     SliverOverlapInjector.
///
/// [sliverStack] is what the user's original app had: a floaty overlay right
/// under the stretchable banner. Keeping it identical in both the stock and
/// the extended fixture is what lets us prove the stretch problem is inherent
/// to `NestedScrollView`, not to `SliverStack` / `SliverOverlapAbsorber`.
Widget buildProfile({
  required bool extended,
  bool headerStretch = false,
  Future<void> Function()? onRefresh,
}) {
  final Widget scrollView = extended
      ? ext.ExtendedNestedScrollView(
          headerStretch: headerStretch,
          headerSliverBuilder: (context, _) {
            final handle = ext.ExtendedNestedScrollView
                .sliverOverlapAbsorberHandleFor(context);
            return headerSlivers(handle, sliverStack: true);
          },
          body: Builder(builder: (context) => bodyFor(context)),
        )
      : NestedScrollView(
          headerSliverBuilder: (context, _) {
            final handle =
                NestedScrollView.sliverOverlapAbsorberHandleFor(context);
            return headerSlivers(handle, sliverStack: true);
          },
          body: Builder(builder: (context) => bodyFor(context)),
        );
  if (onRefresh == null) {
    return MaterialApp(home: Scaffold(body: _withTabs(scrollView)));
  }
  return MaterialApp(
    home: Scaffold(
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: _withTabs(scrollView),
      ),
    ),
  );
}

/// Context used to resolve the overlap handle for the body. The body is built
/// under `ext.ExtendedNestedScrollView`'s `State` via a [Builder] so the static
/// handle lookup keeps working exactly like it does in a real `NestedScrollView`.
final BuildContext contextOfBody = throw UnimplementedError();

Widget _withTabs(Widget scrollView) {
  return Builder(
    builder: (context) => DefaultTabController(
      length: 3,
      child: scrollView,
    ),
  );
}

/// Resolves the overlap absorber handle from the [Builder] context inside the
/// body. The `body` is injected by `ExtendedNestedScrollView` underneath its
/// `_Inherited*` widget, so this exercises the documented contract: the body's
/// context sits below the nested view, and the static handle lookup brings the
/// pinned-header overlap into each tab list via `SliverOverlapInjector`.
ext.SliverOverlapAbsorberHandle extendedHandleOf(BuildContext context) {
  return ext.ExtendedNestedScrollView.sliverOverlapAbsorberHandleFor(context);
}

List<Widget> headerSlivers(Object? handle, {required bool sliverStack}) {
  return <Widget>[
    const SliverAppBar(
      pinned: false,
      stretch: true,
      expandedHeight: 240,
      toolbarHeight: 0,
      backgroundColor: Colors.deepPurple,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        stretchModes: <StretchMode>[
          StretchMode.zoomBackground,
          StretchMode.fadeTitle,
        ],
        title: Text('Profile', style: TextStyle(color: Colors.white)),
        background: Center(child: FlutterLogo(size: 96)),
      ),
    ),
    if (sliverStack)
      SliverStack(
        children: <Widget>[
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
          const SliverPositioned(
            top: -70,
            left: 16,
            right: 16,
            child: _UserCard(),
          ),
        ],
      ),
    const SliverToBoxAdapter(child: SizedBox(height: 80)),
    ext.SliverOverlapAbsorber(
      handle: handle as ext.SliverOverlapAbsorberHandle,
      sliver: const SliverPersistentHeader(
        pinned: true,
        delegate: _TabBarDelegate(),
      ),
    ),
  ];
}

Widget bodyFor(BuildContext context) {
  final handle = extendedHandleOf(context);
  return TabBarView(
    children: <Widget>[
      tabList(handle, tab: 0),
      tabList(handle, tab: 1),
      tabList(handle, tab: 2),
    ],
  );
}

Widget tabList(ext.SliverOverlapAbsorberHandle handle, {required int tab}) {
  return Builder(
    builder: (context) => CustomScrollView(
      key: ValueKey<String>('tab-$tab'),
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        ext.SliverOverlapInjector(handle: handle),
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _PostTile(index: index, tab: tab),
              childCount: 16,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _stockTabList(SliverOverlapAbsorberHandle handle, {required int tab}) {
  return Builder(
    builder: (context) => CustomScrollView(
      key: ValueKey<String>('tab-$tab'),
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        SliverOverlapInjector(handle: handle),
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _PostTile(index: index, tab: tab),
              childCount: 16,
            ),
          ),
        ),
      ],
    ),
  );
}

class _PostTile extends StatelessWidget {
  const _PostTile({required this.index, required this.tab});

  final int index;
  final int tab;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Colors.black12, blurRadius: 4),
        ],
      ),
      child: Center(
        child: Text('Tab $tab · Post $index'),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: const Center(child: Text('User card')),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate();

  static const double _height = 48;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Colors.white,
      elevation: 2,
      child: const TabBar(
        labelColor: Colors.deepPurple,
        tabs: <Widget>[
          Tab(text: 'Grid'),
          Tab(text: 'List'),
          Tab(text: 'About'),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

Future<TestGesture> _dragDown(WidgetTester tester, double dy,
    {int steps = 10}) async {
  final gesture =
      await tester.startGesture(tester.getCenter(find.byKey(const ValueKey<String>('tab-0'))));
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(Offset(0, dy / steps));
    await tester.pump();
  }
  return gesture;
}

void main() {
  testWidgets(
      'stock NestedScrollView + sliver_tools SliverStack: outer stays clamped',
      (tester) async {
    // A plain (unmodified) NestedScrollView layout: stretchable banner plus
    // the sliver_tools SliverStack overlay and a pinned header, wired up with
    // the stock overlap absorber/injector.
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DefaultTabController(
          length: 3,
          child: NestedScrollView(
            headerSliverBuilder: (context, _) {
              final handle =
                  NestedScrollView.sliverOverlapAbsorberHandleFor(context);
              return <Widget>[
                const SliverAppBar(
                  pinned: false,
                  stretch: true,
                  expandedHeight: 240,
                  toolbarHeight: 0,
                  backgroundColor: Colors.deepPurple,
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: <StretchMode>[
                      StretchMode.zoomBackground,
                      StretchMode.fadeTitle,
                    ],
                    title: Text('Profile',
                        style: TextStyle(color: Colors.white)),
                    background: Center(child: FlutterLogo(size: 96)),
                  ),
                ),
                SliverStack(
                  children: <Widget>[
                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    const SliverPositioned(
                      top: -70,
                      left: 16,
                      right: 16,
                      child: _UserCard(),
                    ),
                  ],
                ),
                SliverOverlapAbsorber(
                  handle: handle,
                  sliver: const SliverPersistentHeader(
                    pinned: true,
                    delegate: _TabBarDelegate(),
                  ),
                ),
              ];
            },
            body: Builder(
              builder: (context) {
                final handle =
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context);
                return TabBarView(
                  children: <Widget>[
                    _stockTabList(handle, tab: 0),
                    _stockTabList(handle, tab: 1),
                    _stockTabList(handle, tab: 2),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    final state =
        tester.state<NestedScrollViewState>(find.byType(NestedScrollView));
    final gesture = await _dragDown(tester, 300);
    await tester.pump();
    expect(state.outerController.position.pixels, 0,
        reason:
            'Stock NestedScrollView clamps the outer scrollable at 0, so the '
            'banner can never stretch; the problem is the nested scroll '
            'coordination, not SliverStack/SliverOverlapAbsorber.');
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets(
      'headerStretch: false keeps the stock, clamped behavior for the outer',
      (tester) async {
    await tester.pumpWidget(buildProfile(extended: true));
    await tester.pump();
    final state = tester.state<ext.ExtendedNestedScrollViewState>(
        find.byType(ext.ExtendedNestedScrollView));
    final gesture = await _dragDown(tester, 120);
    await tester.pump();
    expect(state.outerController.position.pixels, 0);
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets(
      'headerStretch: true lets the outer go negative and rebound to zero',
      (tester) async {
    await tester.pumpWidget(
        buildProfile(extended: true, headerStretch: true));
    await tester.pump();
    final state = tester.state<ext.ExtendedNestedScrollViewState>(
        find.byType(ext.ExtendedNestedScrollView));
    final gesture = await _dragDown(tester, 120);
    await tester.pump();
    final stretched = state.outerController.position.pixels;
    expect(stretched, lessThan(-40),
        reason: 'pulling down from the very top must stretch the header');
    // Easing back up while still holding removes a little of the stretch.
    await gesture.moveBy(const Offset(0, -40));
    await tester.pump();
    final eased = state.outerController.position.pixels;
    expect(eased, greaterThan(stretched));
    expect(eased, lessThanOrEqualTo(0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(state.outerController.position.pixels, 0,
        reason: 'releasing must spring back to the top');
  });

  testWidgets('CustomRefreshIndicator triggers without exceptions',
      (tester) async {
    var refreshed = 0;
    await tester.pumpWidget(buildProfile(
      extended: true,
      headerStretch: true,
      onRefresh: () async {
        refreshed += 1;
      },
    ));
    await tester.pump();
    // Needs ~viewportHeight * 0.25 of real outer pixels to arm the indicator.
    final gesture = await _dragDown(tester, 800);
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(refreshed, 1,
        reason:
            'the stretch emits ScrollUpdateNotification with real delta at '
            'depth 0, which arm a RefreshIndicator on Android without any '
            'OverscrollNotification/glow');
    // Let the indicator retract; the Future-based refresh completes instantly.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}