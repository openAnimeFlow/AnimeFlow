# iOS video shader bundles

This local fork preserves `video_player_avfoundation` 2.11.1 playback and adds
effects to **iOS texture players**. macOS and platform views reject effect options.
Pass a non-null `VideoPlayerOptions.videoEffects` at creation to opt in, then use
`setVideoEffectConfiguration` to change the effect, bundle, or physical output size.
Omitting the option keeps the upstream texture path.

The application owns and loads its preset files.
`VideoShaderBundle(manifest:, shaders:)` snapshots their contents; this package
does not know the application's asset layout or include application presets.
Android accepts GLES 3 fragment sources; iOS accepts Metal sources.
The same pass manifest semantics apply to both: version 1, MAIN before PREKERNEL,
HOOKED aliases the current MAIN, NATIVE is the original input, OUTPUT is the physical
destination, and SAVE creates/replaces a named image. Width, height, and when use
postfix expressions with finite numbers, `name.w`, `name.h`, and `+ - * / > <`.
An input whose producer was skipped by a condition must still exist at execution.

## Metal fragment contract

Each `shaders[pass.asset]` is a complete Metal library exporting:

```metal
#include <metal_stdlib>
using namespace metal;
struct VideoVertex { float4 position [[position]]; float2 uv; };
fragment float4 videoFragment(
    VideoVertex in [[stage_in]],
    constant float2 *sizes [[buffer(0)]],
    texture2d<float> input [[texture(0)]]) {
  constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear);
  return input.sample(s, in.uv);
}
```

`bindings[i]` maps to `texture(i)` when `sampler` is true and to `sizes[i]`
(width, height) when `dimensions` is true. Indices are never compacted, including
unused/optimized-out arguments. At most 16 bindings per pass are supported.
Coordinates start at the top left. Use clamp-to-edge, linear sampling for MPV
equivalence. Intermediates are RGBA16Float, cleared to zero before every pass and
reused only after their last read. Final output is opaque BGRA8 with RGB clamped
to [0,1]. The AVFoundation output feeding this pipeline is tone-mapped BT.709 SDR;
this API does not preserve HDR output. Dimensions are limited to 8192 per axis.

## Scheduling and ownership

Compilation and rendering run on a per-player serial worker queue. A new decoded
frame replaces any pending frame rather than accumulating GPU work. Flutter receives
the last completed IOSurface, or the source while the first effect frame is pending.
Thus enabling an effect can initially display the unprocessed image. A paused video
is reprocessed when its configuration changes, without seeking or rebuilding AVPlayer.
This design can add a frame of presentation latency and does not promise first-use
compilation will be invisible.

CVPixelBufferPool owns output allocation; buffers retained by Flutter are never
overwritten. GPU completion is awaited on the worker before publishing a buffer
to Flutter's separate renderer. Resize invalidates the plan and targets. Disabling
releases intermediate textures but retains the most recent bundle's compiled pipelines.
Replacing the bundle evicts those pipelines. Disposal stops publication immediately
and releases GPU resources after queued work drains. Processing errors are reported
once for the failed configuration; changing the configuration permits recovery.
On iOS resign-active, new GPU submissions stop and any already-submitted command
buffer completes before the app backgrounds. Resume schedules the cached video
frame again, including while playback is paused.

## Package validation

From this package's directory on a Mac with Xcode and its Metal toolchain:

```sh
bash tool/test_shaders.sh
```

The runner compiles the native implementation, executes graph and GPU regressions,
and compiles the built-in vertex/copy shaders for iPhoneOS. All fixtures are small
synthetic shaders and pixel buffers defined in `darwin/Tests`. No host app, preset
directory, or files outside this package are needed. A Metal GPU is required;
missing GPU support fails the run instead of skipping it.

Applications should separately validate their own presets and playback integration
on iPhone, including rotation, color, resizing, paused switches, background/resume,
seeks, disposal, and sustained GPU frame time. Mac GPU tests do not replace iPhone
playback integration tests.
