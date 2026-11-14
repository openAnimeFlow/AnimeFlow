# video\_player\_android

The Android implementation of [`video_player`][1].

## Usage

This package is [endorsed][2], which means you can simply use `video_player`
normally. This package will be automatically included in your app when you do,
so you do not need to add it to your `pubspec.yaml`.

However, if you `import` this package to use any of its APIs directly, you
should add it to your `pubspec.yaml` as usual.

## Local GPU extension

This fork supports application-supplied shader bundles for
Android texture playback. Algorithms and preset resources belong to the caller.

Native shader tests use synthetic fixtures in `android/src/testSupport`,
`android/src/test` and `android/src/androidTest`. They require no host application
assets. Run `:video_player_android:testDebugUnitTest` and
`:video_player_android:connectedDebugAndroidTest` from a Flutter Android host that
depends on this package. Preset-specific integration tests belong to that host.

## Known issues

Using `VideoViewType.platformView` is not currently recommended on Android due to a known [issue][3] affecting platform views on Android.

[1]: https://pub.dev/packages/video_player
[2]: https://flutter.dev/to/endorsed-federated-plugin
[3]: https://github.com/flutter/flutter/issues/164899
