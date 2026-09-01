import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart'
    as ext;

void main() {
  testWidgets('canonical banner (sibling) renders stretch visually',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DefaultTabController(
          length: 3,
          child: ext.ExtendedNestedScrollView(
            headerStretch: true,
            headerSliverBuilder: (context, _) {
              final handle = ext.ExtendedNestedScrollView
                  .sliverOverlapAbsorberHandleFor(context);
              return <Widget>[
                const SliverAppBar(
                  stretch: true,
                  expandedHeight: 200,
                  toolbarHeight: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: [
                      StretchMode.zoomBackground,
                      StretchMode.blurBackground,
                    ],
                    collapseMode: CollapseMode.pin,
                    background: ColoredBox(color: Colors.deepPurple),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ext.ExtendedSliverOverlapAbsorber(
                  handle: handle,
                  sliver: const SliverPersistentHeader(
                    pinned: true,
                    delegate: _TabPointerDelegate(),
                  ),
                ),
              ];
            },
            body: Builder(builder: (context) {
              final handle = ext.ExtendedNestedScrollView
                  .sliverOverlapAbsorberHandleFor(context);
              return TabBarView(children: [
                _list(handle, 0),
                _list(handle, 1),
                _list(handle, 2),
              ]);
            }),
          ),
        ),
      ),
    ));
    await tester.pump();

    final state = tester.state<ext.ExtendedNestedScrollViewState>(
        find.byType(ext.ExtendedNestedScrollView));

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(TabBarView)));
    for (var i = 0; i < 12; i++) {
      await gesture.moveBy(const Offset(0, 12));
      await tester.pump();
    }
    expect(state.outerController.position.pixels, lessThan(0));

    final bannerElement = find.byType(SliverAppBar).evaluate().single;
    final render = bannerElement.findRenderObject()! as RenderSliver;
    final g = render.geometry!;
    final fsbBox = find
        .descendant(
          of: find.byType(SliverAppBar),
          matching: find.byType(FlexibleSpaceBar),
        )
        .evaluate()
        .single
        .findRenderObject()! as RenderBox;
    debugPrint(
        'PAINT=${g.paintExtent} MAXPAINT=${g.maxPaintExtent} overlap=${render.constraints.overlap} '
        'px=${state.outerController.position.pixels} flexMaxH=${fsbBox.constraints.maxHeight}');
    expect(fsbBox.constraints.maxHeight, greaterThan(200.0),
        reason: 'banner FlexibleSpaceBar must be told to grow past 200 to zoom/blur');
  });
}

class _TabPointerDelegate extends SliverPersistentHeaderDelegate {
  const _TabPointerDelegate();
  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      const Material(child: SizedBox(height: 48));
  @override
  bool shouldRebuild(covariant _TabPointerDelegate old) => false;
}

Widget _list(ext.ExtendedSliverOverlapAbsorberHandle handle, int tab) {
  return CustomScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    slivers: [
      ext.ExtendedSliverOverlapInjector(handle: handle),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => Container(height: 100, color: Colors.amber.shade200),
          childCount: 20,
        ),
      ),
    ],
  );
}