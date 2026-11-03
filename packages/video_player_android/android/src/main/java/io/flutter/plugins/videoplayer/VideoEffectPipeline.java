// Copyright 2026 The AnimeFlow Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license in the LICENSE file.

package io.flutter.plugins.videoplayer;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.media3.common.C;
import androidx.media3.common.Effect;
import androidx.media3.common.Format;
import androidx.media3.common.util.Size;
import androidx.media3.common.util.UnstableApi;
import androidx.media3.exoplayer.DecoderReuseEvaluation;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.exoplayer.Renderer;
import androidx.media3.exoplayer.analytics.AnalyticsListener;
import androidx.media3.effect.RgbFilter;
import io.flutter.view.TextureRegistry.SurfaceProducer;
import java.util.Collections;
import java.util.List;

/** Per-player effect and output-surface lifecycle. No decoded pixels cross the Dart bridge. */
@UnstableApi
public final class VideoEffectPipeline implements AnalyticsListener {
  private final ExoPlayer player;
  private final SurfaceProducer surface;
  private boolean surfaceAvailable;
  private boolean disposed;
  private int width;
  private int height;

  public VideoEffectPipeline(
      ExoPlayer player, SurfaceProducer surface, PlatformVideoEffect initialEffect) {
    this.player = player;
    this.surface = surface;
    // Even NONE opts in before prepare, so effects can be changed during playback.
    player.setVideoEffects(effectsFor(initialEffect));
    player.addAnalyticsListener(this);
  }

  public void setEffect(PlatformVideoEffect effect) {
    if (disposed) throw new IllegalStateException("Video effect pipeline is disposed");
    player.setVideoEffects(effectsFor(effect));
    signalOutputSize();
  }

  private static List<Effect> effectsFor(PlatformVideoEffect effect) {
    switch (effect) {
      case NONE:
        return Collections.emptyList();
      case DEBUG_GRAYSCALE:
        return Collections.singletonList(RgbFilter.createGrayscaleFilter());
      default:
        throw new IllegalArgumentException("Unsupported video effect: " + effect);
    }
  }

  @Override
  public void onVideoInputFormatChanged(
      @NonNull EventTime eventTime,
      @NonNull Format format,
      @Nullable DecoderReuseEvaluation decoderReuseEvaluation) {
    if (disposed || format.width <= 0 || format.height <= 0) return;
    // Use input metadata: waiting for output-size events can deadlock the first frame.
    // Media3's effect pipeline normalizes pixel aspect ratio and rotation before output.
    float ratio = format.pixelWidthHeightRatio;
    int nextWidth = Math.max(1, Math.round(format.width * (ratio > 0 ? ratio : 1)));
    int nextHeight = format.height;
    if (format.rotationDegrees == 90 || format.rotationDegrees == 270) {
      int swap = nextWidth;
      nextWidth = nextHeight;
      nextHeight = swap;
    }
    if (width == nextWidth && height == nextHeight) return;
    width = nextWidth;
    height = nextHeight;
    if (surfaceAvailable) bindSurface();
  }

  public void onSurfaceAvailable() {
    if (disposed) return;
    surfaceAvailable = true;
    bindSurface();
  }

  public void onSurfaceCleanup() {
    surfaceAvailable = false;
  }

  private void bindSurface() {
    if (width > 0 && height > 0) surface.setSize(width, height);
    // setSize may change the backing surface; always obtain it afterwards.
    player.setVideoSurface(surface.getSurface());
    signalOutputSize();
  }

  private void signalOutputSize() {
    if (disposed || !surfaceAvailable || width <= 0 || height <= 0) return;
    for (int index = 0; index < player.getRendererCount(); index++) {
      if (player.getRendererType(index) == C.TRACK_TYPE_VIDEO) {
        player.createMessage(player.getRenderer(index))
            .setType(Renderer.MSG_SET_VIDEO_OUTPUT_RESOLUTION)
            .setPayload(new Size(width, height))
            .send();
      }
    }
  }

  public void dispose() {
    if (disposed) return;
    disposed = true;
    surfaceAvailable = false;
    player.removeAnalyticsListener(this);
    // ExoPlayer owns and releases the effect programs when the player is released.
  }
}
