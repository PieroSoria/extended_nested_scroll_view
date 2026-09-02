import 'dart:math' as math;

import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sliver_tools/sliver_tools.dart';

/// A faithful, self-contained mirror of the real `ProfilePage` from the
/// `feature_profile` package, stripped of app-specific deps (`core`, `domain`,
/// `flutter_bloc`, `go_router`, `material_ui`, `refresh_custom`).
///
/// The same structure and logic is preserved so it doubles as a runnable
/// proof that `ExtendedNestedScrollView(headerStretch: true)` makes the banner
/// stretch AND lets `CustomRefreshIndicator` pull-to-refresh fire:
///
///   * a stretchable `SliverAppBar` banner ([ProfileBannerSliverAppBar]);
///   * a `SliverStack` + `MultiSliver` that floats the info section over the
///     banner via `SliverPositioned.fill(top: positionInfo(offset))`;
///   * an `ExtendedSliverOverlapAbsorber` wrapping the whole stack;
///   * a pinned `SliverAppBar` with a `TabBar` buffer holder;
///   * three tab lists (`GridPostsWidget`, `ListWorkWidget`, `ListMusicWidget`).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController scrollControllerGlobal;
  final globaloffsetValue = ValueNotifier<double>(0);
  double speedFactor = 3.0;

  // Base top offset of the floating card, resolved once instead of on every
  // scroll notification (target platform is effectively constant).
  late final double _cardBaseTop;

  @override
  void initState() {
    super.initState();
    _cardBaseTop = defaultTargetPlatform == TargetPlatform.android ? 210.0 : 230.0;
    _tabController = TabController(length: 3, vsync: this);
    scrollControllerGlobal = ScrollController();
    scrollControllerGlobal.addListener(_listener);
  }

  // Throttle redundant notifier emissions: scroll notifications fire on every
  // pointer/tick, but the floating card only cares when the value actually
  // changes. Skipping no-op writes avoids needless rebuilds of the overlay.
  void _listener() {
    final double offset = scrollControllerGlobal.offset;
    if (offset != globaloffsetValue.value) {
      globaloffsetValue.value = offset;
    }
  }

  double positionInfo(double value) => math.max(
        0.0,
        _cardBaseTop - (value / (value < 0 ? 1 : speedFactor)),
      );

  @override
  void dispose() {
    _tabController.dispose();
    scrollControllerGlobal.removeListener(_listener);
    scrollControllerGlobal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    // The whole nested scroll tree is built once and never rebuilt on scroll.
    // Only the small overlay pieces that actually depend on the scroll offset
    // subscribe to `globaloffsetValue` (the floating info card and the
    // collapsing title), which keeps per-frame work to a minimum.
    return Scaffold(
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: ExtendedNestedScrollView(
          headerStretch: true,
          controller: scrollControllerGlobal,
          physics: const ClampingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
              final handle =
                  ExtendedNestedScrollView.sliverOverlapAbsorberHandleFor(
                    context,
                  );
              return [
                ExtendedSliverOverlapAbsorber(
                  handle: handle,
                  sliver: SliverStack(
                    children: [
                      MultiSliver(
                        children: [
                          const ProfileBannerSliverAppBar(),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 140),
                          ),
                          ProfileTabBarSliverAppBar(
                            tabController: _tabController,
                            globalOffsetValue: globaloffsetValue,
                          ),
                        ],
                      ),
                      // Floating info card: only this overlay repaints on scroll.
                      SliverPositioned.fill(
                        top: 0,
                        child: ValueListenableBuilder<double>(
                          valueListenable: globaloffsetValue,
                          builder: (context, offsetValue, _) => Padding(
                            padding:
                                EdgeInsets.only(top: positionInfo(offsetValue)),
                            child: const ProfileInfoAndAchievementsSection(),
                          ),
                        ),
                      ),
                      ProfileSettingsButton(size: size),
                    ],
                  ),
                ),
              ];
            },
            body: Builder(
              builder: (context) {
                final handle =
                    ExtendedNestedScrollView.sliverOverlapAbsorberHandleFor(
                      context,
                    );
                return TabBarView(
                  controller: _tabController,
                  children: [
                    GridPostsWidget(handle: handle),
                    ListWorkWidget(handle: handle),
                    const ListMusicWidget(),
                  ],
                );
              },
              ),
            ),
          ),
        );
  }
}

/// SliverAppBar encargado de mostrar el banner expandible.
class ProfileBannerSliverAppBar extends StatelessWidget {
  const ProfileBannerSliverAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      stretch: true,
      expandedHeight: 200,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        collapseMode: CollapseMode.pin,
        background: const ColoredBox(
          color: Colors.deepPurple,
          child: Center(
            child: FlutterLogo(size: 96),
          ),
        ),
      ),
    );
  }
}

/// SliverAppBar que incluye el título dinámico colapsable y el TabBar persistente.
class ProfileTabBarSliverAppBar extends StatelessWidget {
  const ProfileTabBarSliverAppBar({
    super.key,
    required this.tabController,
    required this.globalOffsetValue,
  });

  final TabController tabController;
  final ValueNotifier<double> globalOffsetValue;

  @override
  Widget build(BuildContext context) {
    final texts = Theme.of(context).textTheme;

    return SliverAppBar(
      pinned: true,
      primary: true,
      title: ValueListenableBuilder<double>(
        valueListenable: globalOffsetValue,
        builder: (context, offsetValue, child) {
          final bool isCollapsed = offsetValue > 250;

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: isCollapsed
                ? Text(
                    'Jane Appleseed',
                    key: const ValueKey('profile_header_text'),
                    style: texts.titleLarge,
                  )
                : const SizedBox.shrink(key: ValueKey('empty_header')),
          );
        },
      ),
      bottom: TabBar(
        controller: tabController,
        indicatorColor: Colors.pinkAccent,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: Colors.pinkAccent,
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(icon: Icon(Icons.grid_view_rounded), text: 'Posts'),
          Tab(icon: Icon(Icons.menu_book_rounded), text: 'Obras'),
          Tab(icon: Icon(Icons.music_note_rounded), text: 'Música'),
        ],
      ),
    );
  }
}

/// Sección con la información de perfil (avatar, datos) y lista de logros.
class ProfileInfoAndAchievementsSection extends StatelessWidget {
  const ProfileInfoAndAchievementsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: const [
          InfoProfileWidget(),
          _SectionAchievementsHeader(title: 'Logros', linkText: 'Ver todos'),
        ],
      ),
    );
  }
}

/// Botón flotante superior derecho para acceder a Configuración.
class ProfileSettingsButton extends StatelessWidget {
  const ProfileSettingsButton({super.key, required this.size});

  final Size size;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return SliverPositioned.fill(
      left: size.width - 55,
      bottom: (size.height / 1.25) -
          (defaultTargetPlatform == TargetPlatform.iOS ? 25 : 0),
      child: Container(
        width: 34,
        height: 34,
        margin: EdgeInsets.only(top: padding.top, right: 10),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.1),
        ),
        child: const Icon(
          Icons.settings_outlined,
          color: Colors.white,
          size: 25,
        ),
      ),
    );
  }
}

class _SectionAchievementsHeader extends StatelessWidget {
  final String title;
  final String linkText;

  const _SectionAchievementsHeader({required this.title, required this.linkText});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final colors = themeData.colorScheme;
    final texts = themeData.textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: texts.titleSmall),
              GestureDetector(
                onTap: () {},
                child: Text(
                  linkText,
                  style: texts.labelSmall?.copyWith(color: colors.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 80,
          child: Row(
            children: [
              SizedBox(width: 16),
              _AchievementCard(),
              SizedBox(width: 12),
              _AchievementCard(),
              SizedBox(width: 12),
              _AchievementCard(),
            ],
          ),
        ),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.emoji_events_outlined),
    );
  }
}

class InfoProfileWidget extends StatelessWidget {
  const InfoProfileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(radius: 40),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Jane Appleseed', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('@jane'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GridPostsWidget extends StatelessWidget {
  const GridPostsWidget({super.key, required this.handle});

  final ExtendedSliverOverlapAbsorberHandle handle;

  @override
  Widget build(BuildContext context) {
    // Best practice: put the RefreshIndicator on the tab's OWN scroll view,
    // NOT wrapping the whole ExtendedNestedScrollView. This way the pull
    // displacement only affects this tab's list and never shoves the tab bar
    // or reveals a blank gap between the tab bar and the grid.
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        key: const ValueKey<String>('grid-posts'),
        // ClampingScrollPhysics removes the over-scroll/bounce that otherwise
        // drags the grid down and leaves a blank gap on pull-to-refresh.
        physics: const ClampingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          ExtendedSliverOverlapInjector(handle: handle),
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => Container(
                key: ValueKey<String>('grid-cell-$i'),
                color: Colors.primaries[i % Colors.primaries.length].shade300,
              ),
              childCount: 30,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onRefresh() async {
    await Future<void>.delayed(const Duration(seconds: 3));
  }
}

class ListWorkWidget extends StatelessWidget {
  const ListWorkWidget({super.key, required this.handle});

  final ExtendedSliverOverlapAbsorberHandle handle;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future<void>.delayed(const Duration(seconds: 3));
      },
      child: CustomScrollView(
        key: const ValueKey<String>('list-work'),
        physics: const ClampingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          ExtendedSliverOverlapInjector(handle: handle),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => ListTile(
                title: Text('Obra ${i + 1}'),
                leading: const Icon(Icons.menu_book),
              ),
              childCount: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class ListMusicWidget extends StatelessWidget {
  const ListMusicWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 300,
            child: Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.music_note, size: 48),
                const SizedBox(height: 8),
                Text('Tu música', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 240),
              ],
            )),
          ),
        ),
      ],
    );
  }
}