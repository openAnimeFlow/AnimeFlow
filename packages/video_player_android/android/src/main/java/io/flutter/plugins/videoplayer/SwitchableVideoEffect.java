// Copyright 2026 The AnimeFlow Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license in the LICENSE file.
package io.flutter.plugins.videoplayer;

import android.content.Context;
import androidx.media3.common.VideoFrameProcessingException;
import androidx.media3.common.util.UnstableApi;
import androidx.media3.effect.GlEffect;
import androidx.media3.effect.GlShaderProgram;

/** One stable effect chain; the GL thread snapshots the requested effect at each input frame. */
@UnstableApi
final class SwitchableVideoEffect implements GlEffect {
  static final class Configuration {
    final PlatformVideoEffect effect;
    final int outputWidth, outputHeight;
    final ShaderBundle bundle;

    Configuration(PlatformVideoEffect effect, int outputWidth, int outputHeight, ShaderBundle bundle) {
      this.effect = effect;
      this.bundle = bundle;
      this.outputWidth = outputWidth;
      this.outputHeight = outputHeight;
    }
  }

  private volatile Configuration configuration;

  SwitchableVideoEffect(PlatformVideoEffect effect) {
    configuration = new Configuration(effect, 0, 0, null);
  }

  PlatformVideoEffect getEffect() {
    return configuration.effect;
  }

  void setEffect(PlatformVideoEffect effect) {
    setConfiguration(effect, configuration.outputWidth, configuration.outputHeight);
  }

  Configuration getConfiguration() {
    return configuration;
  }

  void setConfiguration(PlatformVideoEffect effect, int width, int height) {
    setConfiguration(effect, width, height, null);
  }

  void setConfiguration(PlatformVideoEffect effect, int width, int height, ShaderBundle bundle) {
    if ((effect == PlatformVideoEffect.SHADER_BUNDLE) != (bundle != null)) throw new IllegalArgumentException("Shader bundle configuration mismatch");
    configuration = new Configuration(effect, width, height, bundle);
  }

  @Override
  public GlShaderProgram toGlShaderProgram(Context context, boolean useHdr)
      throws VideoFrameProcessingException {
    return new SwitchableVideoShaderProgram(context, useHdr, this);
  }
}
