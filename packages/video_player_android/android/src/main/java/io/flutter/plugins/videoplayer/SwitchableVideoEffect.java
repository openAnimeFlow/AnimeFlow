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

    Configuration(PlatformVideoEffect effect, int outputWidth, int outputHeight) {
      this.effect = effect;
      this.outputWidth = outputWidth;
      this.outputHeight = outputHeight;
    }
  }

  private volatile Configuration configuration;

  SwitchableVideoEffect(PlatformVideoEffect effect) {
    configuration = new Configuration(effect, 0, 0);
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
    configuration = new Configuration(effect, width, height);
  }

  @Override
  public GlShaderProgram toGlShaderProgram(Context context, boolean useHdr)
      throws VideoFrameProcessingException {
    return new SwitchableVideoShaderProgram(context, useHdr, this);
  }
}
