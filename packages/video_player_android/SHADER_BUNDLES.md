# External shader bundles (local fork)

The application owns algorithms, preset names and shader files. This plugin only
executes version 1 GLES 3 bundles. MPV `.glsl` hook files cannot be passed directly:
convert their supported directives into a manifest and GLES fragment sources first.
AnimeFlow does this with `dart tool/generate_android_anime4k.dart`; add `--check`
to verify generated sources. Efficiency resources live in `assets/shaders/android/`;
the five-pass x2 model is a test fixture, not a public effect or app preset.

## Dart API

Opt in before initialization using
`VideoPlayerOptions(videoEffects: const VideoEffectConfiguration())`.
Then load sources using Flutter assets, local files, or another application-owned
loader and submit their contents:

```dart
final bundle = VideoShaderBundle(manifest: manifestJson, shaders: sourcesById);
await controller.setVideoEffectConfiguration(VideoEffectConfiguration(
  effect: VideoEffectType.shaderBundle,
  shaderBundle: bundle,
  outputWidth: 1920,
  outputHeight: 1080,
));
```

`manifestJson` is a non-empty JSON array. `sourcesById` maps each pass's `asset`
identifier to its fragment source. Identifiers are keys, not paths opened by the
plugin. Construction snapshots the sources; equality includes bundle contents.
The wire representation is `{version: 1, passes: [...], shaders: {...}}`.
Changing a source under the same identifier changes the configuration.

Disable using `VideoEffectConfiguration(effect: VideoEffectType.none, ...)`, with
no bundle. Width and height must both be positive or both null; null selects the
normalized input size. Preserve explicit dimensions when toggling to avoid an
unnecessary surface resize. Upscaling output size is explicit, not inferred from
an algorithm name. Existing `anime4kX2S` and `anime4kEfficiency` enum values have
been replaced by `shaderBundle` in this local fork.

## Version 1 pass contract

```json
{
  "asset": "copy.glsl",
  "hook": "MAIN",
  "save": "MAIN",
  "width": "MAIN.w",
  "height": "MAIN.h",
  "when": "1",
  "bindings": [{"name": "MAIN", "sampler": true, "dimensions": true}]
}
```

- Passes execute in array order. Supported hook labels are `MAIN`, then
  `PREKERNEL`. This is a restricted execution contract, not full MPV compatibility.
- `NATIVE` is the original frame; `MAIN` is the latest main image; `HOOKED` and
  the current hook alias refer to that image. `save` names an intermediate image;
  saving `HOOKED` or `PREKERNEL` updates `MAIN`.
- `width`, `height`, and `when` use whitespace-separated postfix expressions:
  finite numeric literals, image `.w` / `.h`, and binary `+ - * / > <`.
  `OUTPUT.w` / `.h` describe the requested output size. Zero `when` skips a pass.
  Dependencies on skipped passes are invalid unless an earlier value exists.
- `bindings` supplies `u_<name>` samplers and/or `s_<name>` size vectors.
  `OUTPUT` is only available to expressions, not as a texture binding.
- Fragment source uses `#version 300 es`, input `vTexCoord` and a fragment output
  such as `outColor`. The plugin provides the full-screen vertex shader.
- Intermediates use signed RGBA16F; the final `MAIN` is resized to the requested
  output, clamped to SDR RGB, and emitted opaque. If every pass is skipped, the
  original input is used. Optional `source` / `description` metadata is diagnostic.

Supported only for Android texture playback, SDR, OpenGL ES 3 with renderable
RGBA16F. Unsupported platforms and platform views do not gain shader support.
Malformed metadata is rejected before replacing the active configuration.
Shader compilation, device limits and dimension-dependent graph errors are
reported asynchronously through the player's existing error path.

Changes are applied at frame boundaries after the consumer releases the output
texture. The effect remains registered with Media3 throughout. Replaced or
disabled bundles release their GPU programs and intermediates on the GL thread;
size-only changes reuse compiled programs. No decoded pixels cross the Dart bridge.

## Validation

Dart tests cover bundle transport and application preset behavior. JVM tests cover
metadata validation, conditional pass planning and surface lifecycle.
`Anime4kShaderProgramTest` and `Anime4kEfficiencyProgramTest` compare device output
against CPU calculations using application-supplied bundles. Gradle includes
application shaders only in test resources / the test APK, never in library assets.
