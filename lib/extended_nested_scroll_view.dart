/// `ExtendedNestedScrollView` — a drop-in replacement for Flutter's
/// `NestedScrollView` that fixes its most complained about limitations:
///
///  * **Stretch headers**: lets the outer `SliverAppBar` render its
///    `FlexibleSpaceBar.stretchModes` (zoom/parallax banner) when the user
///    pulls down from the top of a tab (see
///    [ExtendedNestedScrollView.headerStretch]).
///  * **Overlap helpers**: exposes
///    [ExtendedNestedScrollView.sliverOverlapAbsorberHandleFor] so tabs can
///    align below pinned headers without `NestedScrollView.sliverOverlapAbsorberHandleFor`
///    asserting.
library;

export 'src/extended_nested_scroll_view.dart';