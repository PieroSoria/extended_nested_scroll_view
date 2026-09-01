import 'package:flutter/material.dart';

import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:sliver_tools/sliver_tools.dart';

/// A canonical profile screen built on [ExtendedNestedScrollView] with
/// `headerStretch: true`.
///
/// The header is a stretchable `SliverAppBar` (`stretch: true` with
/// `flexibleSpace.stretchModes`) whose `zoomBackground` + `fadeTitle` effects
/// only activate when the outer scrollable is allowed to overscroll below 0.
/// The stock `NestedScrollView` clamps that overscroll away, so without this
/// package the banner never stretches. Here it does, and each tab list still
/// scrolls independently under the pinned header.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const List<String> _tabs = <String>['Grid', 'List', 'About'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: DefaultTabController(
          length: _tabs.length,
          child: ExtendedNestedScrollView(
            headerStretch: true,
            headerSliverBuilder: (context, _) {
              final handle = ExtendedNestedScrollView
                  .sliverOverlapAbsorberHandleFor(context);
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
                    title: Text(
                      'Jane Appleseed',
                      style: TextStyle(color: Colors.white),
                    ),
                    background: Center(child: FlutterLogo(size: 96)),
                  ),
                ),
                // The floating user card sits over the banner. Its height
                // (140) plus the top negative offset (-70) is what makes it
                // peek over the stretched image. The SliverStack from
                // sliver_tools defines the stretchable region, exactly like
                // the nested view that used to be `CustomScrollView` slivers.
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
                // Track the overlap the pinned header creates so each tab
                // list can inject the same spacing below it.
                ExtendedSliverOverlapAbsorber(
                  handle: handle,
                  sliver: SliverPersistentHeader(
                    pinned: true,
                    delegate: _TabBarDelegate(tabs: _tabs),
                  ),
                ),
              ];
            },
            body: Builder(
              builder: (context) {
                final handle = ExtendedNestedScrollView
                    .sliverOverlapAbsorberHandleFor(context);
                return TabBarView(
                  children: <Widget>[
                    _TabList(handle: handle, tab: 0),
                    _TabList(handle: handle, tab: 1),
                    _TabList(handle: handle, tab: 2),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    await Future<void>.delayed(const Duration(seconds: 2));
  }
}

class _TabList extends StatelessWidget {
  const _TabList({required this.handle, required this.tab});

  final ExtendedSliverOverlapAbsorberHandle handle;
  final int tab;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: ValueKey<String>('tab-$tab'),
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        ExtendedSliverOverlapInjector(handle: handle),
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
    );
  }
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
      child: Center(child: Text('Tab ${tab + 1} · Post $index')),
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
  const _TabBarDelegate({required this.tabs});

  final List<String> tabs;

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
      child: TabBar(
        labelColor: Colors.deepPurple,
        tabs: tabs
            .map((String label) => Tab(text: label))
            .toList(growable: false),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) {
    return oldDelegate.tabs != tabs;
  }
}