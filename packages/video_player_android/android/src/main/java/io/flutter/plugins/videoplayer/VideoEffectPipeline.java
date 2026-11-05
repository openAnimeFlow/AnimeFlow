// Copyright 2026 The AnimeFlow Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license in the LICENSE file.

package io.flutter.plugins.videoplayer;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.media3.common.C;
import androidx.media3.common.ColorInfo;
import androidx.media3.common.Format;
import androidx.media3.common.util.Size;
import androidx.media3.common.util.UnstableApi;
import androidx.media3.exoplayer.DecoderReuseEvaluation;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.exoplayer.Renderer;
import androidx.media3.exoplayer.analytics.AnalyticsListener;
import io.flutter.view.TextureRegistry.SurfaceProducer;
import java.util.Collections;

/** Per-player effect and output-surface lifecycle. No decoded pixels cross the Dart bridge. */
@UnstableApi
public final class VideoEffectPipeline implements AnalyticsListener {
  private final ExoPlayer player;
  private final SurfaceProducer surface;
  private boolean surfaceAvailable;
  private boolean disposed;
  private int width;
  private int height;
  private int outputWidth, outputHeight;
  private PlatformVideoEffect effect;
  private final SwitchableVideoEffect switchableEffect;
  @Nullable private Format inputFormat;

  public VideoEffectPipeline(
      ExoPlayer player, SurfaceProducer surface, PlatformVideoEffect initialEffect) {
    this.player = player;
    this.surface = surface;
    effect = initialEffect;
    // Register once. Re-registering streams on each toggle can block ExoPlayer's render thread
    // while old GPU frames drain, then time out a concurrent SurfaceProducer surface replacement.
    switchableEffect = new SwitchableVideoEffect(initialEffect);
    player.setVideoEffects(Collections.singletonList(switchableEffect));
    player.addAnalyticsListener(this);
  }

  public void setEffect(PlatformVideoEffect effect) {
    setEffect(
        effect,
        outputWidth == 0 ? null : (long) outputWidth,
        outputHeight == 0 ? null : (long) outputHeight);
  }

  public void setEffect(
      PlatformVideoEffect effect, @Nullable Long targetWidth, @Nullable Long targetHeight) {
    if (disposed) throw new IllegalStateException("Video effect pipeline is disposed");
    if ((targetWidth == null) != (targetHeight == null)
        || (targetWidth != null
            && (targetWidth <= 0
                || targetHeight <= 0
                || targetWidth > Integer.MAX_VALUE
                || targetHeight > Integer.MAX_VALUE))) {
      throw new IllegalArgumentException("Output dimensions must both be positive or null");
    }
    int nextWidth = targetWidth == null ? 0 : targetWidth.intValue();
    int nextHeight = targetHeight == null ? 0 : targetHeight.intValue();
    if (this.effect == effect && outputWidth == nextWidth && outputHeight == nextHeight) return;
    if ((effect == PlatformVideoEffect.ANIME4K_X2S
            || effect == PlatformVideoEffect.ANIME4K_EFFICIENCY)
        && inputFormat != null
        && ColorInfo.isTransferHdr(inputFormat.colorInfo)) {
      throw new IllegalArgumentException("Anime4K currently supports SDR video only");
    }
    switchableEffect.setConfiguration(effect, nextWidth, nextHeight);
    this.effect = effect;
    outputWidth = nextWidth;
    outputHeight = nextHeight;
    // Layout determines a stable surface size for off/efficiency. Only a real size change
    // needs rebinding; toggling a preset must not reset Media3's first-frame presentation.
    if (inputFormat != null && updateOutputSize(inputFormat) && surfaceAvailable) bindSurface();
  }

  @Override
  public void onVideoInputFormatChanged(
      @NonNull EventTime eventTime,
      @NonNull Format format,
      @Nullable DecoderReuseEvaluation decoderReuseEvaluation) {
    if (disposed || format.width <= 0 || format.height <= 0) return;
    inputFormat = format;
    if (updateOutputSize(format) && surfaceAvailable) bindSurface();
  }

  private boolean updateOutputSize(Format format) {
    Size outputSize = getOutputSize(format);
    int nextWidth = outputSize.getWidth();
    int nextHeight = outputSize.getHeight();
    if (width == nextWidth && height == nextHeight) return false;
    width = nextWidth;
    height = nextHeight;
    return true;
  }

  /** Whether Flutter has supplied the physical display size. */
  public boolean hasDisplaySize() {
    return outputWidth > 0;
  }

  /** Expected texture dimensions, including the currently selected effect. */
  public Size getOutputSize(Format format) {
    if (outputWidth > 0 && effect != PlatformVideoEffect.ANIME4K_X2S) {
      return new Size(outputWidth, outputHeight);
    }
    Size size = outputSizeForFormat(format);
    return effect == PlatformVideoEffect.ANIME4K_X2S
        ? new Size(size.getWidth() * 2, size.getHeight() * 2)
        : size;
  }

  /** Initial output dimensions shared by the surface and Flutter initialization. */
  public static Size outputSizeForFormat(Format format) {
    if (format.width <= 0 || format.height <= 0) return new Size(0, 0);
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
    return new Size(nextWidth, nextHeight);
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
        player
            .createMessage(player.getRenderer(index))
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
