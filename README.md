# extended_nested_scroll_view

[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD--3--Clause-blue.svg)](LICENSE)

A drop-in replacement for Flutter's [`NestedScrollView`] that fixes a real gap
in the stock widget: **the header never stretches**. It also keeps every tab
list scrolling independently under a pinned header and works out of the box
with `RefreshIndicator` / `CustomRefreshIndicator`.

It is a vendored copy of Flutter's `NestedScrollView` with a small, opt-in
override. You can swap `NestedScrollView` → `ExtendedNestedScrollView` one-for-one;
every existing parameter, the overlap-absorber pattern and the outer/inner
controller behavior stay identical.

## The problem

`SliverAppBar.stretch: true` plus `FlexibleSpaceBar.stretchModes` (e.g.
`zoomBackground` + `fadeTitle`) only render when the outer scrollable is
allowed to overscroll below `0`. Stock `NestedScrollView` **clamps** the outer
offset at `0` during the pull-down gesture (`applyClampedDragUpdate`), so the
stretch effect never fires — a long-standing Flutter limitation
(flutter/flutter#54059).

The header also shows none of this when you pull down from the top of a tab;
the inner list just bounces/clamps invisibly and `CustomRefreshIndicator`
complains that `NestedScrollView.sliverOverlapAbsorberHandleFor` can't find its
view.

## The fix

`ExtendedNestedScrollView(headerStretch: true)` intercepts the pull-down while
*every* scrollable (banner + inner lists) is parked at its leading edge and
routes the delta to the outer position via an overscroll that goes **below
zero**, with `BouncingScrollPhysics`-style friction, so the banner actually
stretches and spring-backs on release. The `RefreshIndicator` still arms
because the stretch emits real `ScrollUpdateNotification`s at depth 0 (no
Android overscroll glow).

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  extended_nested_scroll_view:
    git:
      url: https://github.com/your-org/extended_nested_scroll_view
```

## Usage

Swap the widget and flip the flag:

```dart
ExtendedNestedScrollView(
  headerStretch: true,
  headerSliverBuilder: (context, boxIsScrolled) {
    final handle = ExtendedNestedScrollView.sliverOverlapAbsorberHandleFor(context);
    return <Widget>[
      const SliverAppBar(
        pinned: false,
        stretch: true,                  // ← must be true to stretch
        expandedHeight: 240,
        toolbarHeight: 0,
        flexibleSpace: FlexibleSpaceBar(
          stretchModes: <StretchMode>[
            StretchMode.zoomBackground,
            StretchMode.fadeTitle,
          ],
          background: Center(child: FlutterLogo(size: 96)),
        ),
      ),
      // Any pinned, stretched header goes here, optionally wrapped in a
      // SliverStack (from sliver_tools) to float content over the banner.
      SliverOverlapAbsorber(
        handle: handle,
        sliver: const SliverPersistentHeader(pinned: true, delegate: MyTabBarDelegate()),
      ),
    ];
  },
  body: Builder(
    builder: (context) {
      final handle = ExtendedNestedScrollView.sliverOverlapAbsorberHandleFor(context);
      return TabBarView(
        children: <Widget>[
          TabList(handle: handle),
          TabList(handle: handle),
        ],
      );
    },
  ),
)
```

Each tab list is a `CustomScrollView` (with `AlwaysScrollableScrollPhysics`)
that starts with a `SliverOverlapInjector(handle: handle)` so content sits
correctly below the pinned header. Wrap the whole view in a
`RefreshIndicator` for pull-to-refresh.

A complete, runnable profile screen lives in [`example/`](example).

> **Note:** the enum names `StretchMode`, the overlap widgets
> (`SliverOverlapAbsorber`, `SliverOverlapInjector`, `SliverOverlapAbsorberHandle`)
> and `NestedScrollView`/`NestedScrollViewState` are re-exported by this package
> as their own types, so if you import both `material.dart` and this package you
> may need to hide the stock ones or use a prefix.

## API

| Member | Description |
| --- | --- |
| `headerStretch` (bool, default `false`) | When `true`, a pull-down from the very top overscrolls the header so it can stretch. Keep it `false` for byte-for-byte stock behavior. |
| `outerController` / `innerController` | Same as stock. |
| `sliverOverlapAbsorberHandleFor` | Same as stock. |

`headerStretch: false` reproduces the stock widget exactly (the knob is off by
default), so this is a safe drop-in.

## Example

```bash
cd example
flutter pub get
flutter run
```

## Tests

The package ships tests that prove the fix:

- stock `NestedScrollView` + `SliverStack` keeps the outer clamped at `0`
  (the stretch problem is the coordination, not `SliverStack`);
- `headerStretch: false` keeps clamped behavior;
- `headerStretch: true` lets the outer go negative and rebound to zero;
- `RefreshIndicator` triggers without exceptions.

```bash
flutter test
```

## License

BSD 3-Clause. The adapted `nested_scroll_view.dart` is derived from
[Flutter](https://github.com/flutter/flutter) (BSD-3-Clause) —
see [`LICENSE`](LICENSE) for the full text and attribution.

[`NestedScrollView`]: https://api.flutter.dev/flutter/widgets/NestedScrollView-class.html