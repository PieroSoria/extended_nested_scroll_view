# extended_nested_scroll_view_example

A runnable profile screen that demonstrates the `headerStretch` behavior of the
[`extended_nested_scroll_view`](../) package.

## What it shows

- A stretchable `SliverAppBar` (`stretch: true` / `zoomBackground` + `fadeTitle`).
- A `SliverStack` (from [`sliver_tools`](https://pub.dev/packages/sliver_tools))
  that floats a user card over the banner.
- A pinned header with a `TabBar`, using `ExtendedSliverOverlapAbsorber` /
  `ExtendedSliverOverlapInjector` so three tab lists stay correctly aligned and scroll
  independently.
- `RefreshIndicator` pull-to-refresh, which works because the stretch emits
  real scroll updates at depth 0.

## Run

```bash
cd example
flutter pub get
flutter run
```

## Test

```bash
cd example
flutter test
```