// Copyright 2026 The AnimeFlow Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license in the LICENSE file.
package io.flutter.plugins.videoplayer;

import android.content.Context;
import android.opengl.GLES20;
import androidx.annotation.Nullable;
import androidx.media3.common.GlObjectsProvider;
import androidx.media3.common.GlTextureInfo;
import androidx.media3.common.VideoFrameProcessingException;
import androidx.media3.common.util.GlProgram;
import androidx.media3.common.util.GlUtil;
import androidx.media3.common.util.UnstableApi;
import androidx.media3.effect.GlShaderProgram;
import java.util.concurrent.Executor;

/**
 * Single-output backpressure keeps frame-boundary effect/size changes safe: a texture is resized
 * only after its consumer returns it. No stream registration or playback-thread wait is needed.
 */
@UnstableApi
final class SwitchableVideoShaderProgram implements GlShaderProgram {
  private final Context context;
  private final boolean useHdr;
  private final SwitchableVideoEffect configuration;
  private final GlProgram copyProgram;
  @Nullable private Anime4kShaderProgram anime4k;
  @Nullable private Anime4kEfficiencyProgram efficiency;
  @Nullable private GlTextureInfo output;
  private boolean outputInUse;
  private int cnnWidth;
  private int cnnHeight;
  private InputListener inputListener = new InputListener() {};
  private OutputListener outputListener = new OutputListener() {};
  private Executor errorExecutor = Runnable::run;
  private ErrorListener errorListener =
      error -> android.util.Log.e("VideoPlayer", "GPU effect failed", error);

  SwitchableVideoShaderProgram(Context context, boolean useHdr, SwitchableVideoEffect configuration)
      throws VideoFrameProcessingException {
    this.context = context;
    this.useHdr = useHdr;
    this.configuration = configuration;
    try {
      copyProgram =
          new GlProgram(
              "attribute vec4 aFramePosition; varying vec2 vTexCoord;"
                  + "void main(){gl_Position=aFramePosition;vTexCoord=aFramePosition.xy*0.5+0.5;}",
              "precision highp float; uniform sampler2D uInput; uniform int uGrayscale;varying vec2"
                  + " vTexCoord; void main(){vec4 c=texture2D(uInput,vTexCoord);"
                  + "gl_FragColor=uGrayscale==1?vec4(vec3(dot(c.rgb,vec3(0.2126,0.7152,0.0722))),c.a):c;}");
      copyProgram.setBufferAttribute("aFramePosition", GlUtil.getNormalizedCoordinateBounds(), 4);
    } catch (GlUtil.GlException e) {
      throw new VideoFrameProcessingException(e);
    }
  }

  @Override
  public void setInputListener(InputListener listener) {
    inputListener = listener;
    if (!outputInUse) listener.onReadyToAcceptInputFrame();
  }

  @Override
  public void setOutputListener(OutputListener listener) {
    outputListener = listener;
  }

  @Override
  public void setErrorListener(Executor executor, ErrorListener listener) {
    errorExecutor = executor;
    errorListener = listener;
  }

  @Override
  public void queueInputFrame(GlObjectsProvider provider, GlTextureInfo input, long timeUs) {
    if (outputInUse) throw new IllegalStateException("Output frame has not been released");
    SwitchableVideoEffect.Configuration settings = configuration.getConfiguration();
    PlatformVideoEffect effect = settings.effect;
    boolean upscale = effect == PlatformVideoEffect.ANIME4K_X2S;
    boolean fullChain = effect == PlatformVideoEffect.ANIME4K_EFFICIENCY;
    try {
      if (fullChain && useHdr)
        throw new VideoFrameProcessingException(
            "Anime4K efficiency currently supports SDR video only");
      if (fullChain && efficiency == null) efficiency = new Anime4kEfficiencyProgram(context);
      if (upscale) {
        if (useHdr)
          throw new VideoFrameProcessingException(
              "Anime4K CNN x2 S currently supports SDR video only");
        if (anime4k == null) anime4k = new Anime4kShaderProgram(context);
        if (cnnWidth != input.width || cnnHeight != input.height) {
          anime4k.configure(input.width, input.height);
          cnnWidth = input.width;
          cnnHeight = input.height;
        }
      }
      int width = input.width * (upscale ? 2 : 1);
      int height = input.height * (upscale ? 2 : 1);
      // Keep the output stable across off/efficiency changes when the viewport is known.
      if (!upscale && settings.outputWidth > 0) {
        width = settings.outputWidth;
        height = settings.outputHeight;
      }
      if (output == null || output.width != width || output.height != height) {
        if (output != null) {
          output.release();
          output = null;
        }
        int texture = GlUtil.createTexture(width, height, useHdr);
        try {
          output = provider.createBuffersForTexture(texture, width, height);
        } catch (GlUtil.GlException e) {
          GlUtil.deleteTexture(texture);
          throw e;
        }
      }
      GlUtil.focusFramebufferUsingCurrentContext(output.fboId, width, height);
      if (fullChain) {
        efficiency.draw(input.texId, input.width, input.height, width, height, timeUs);
      } else if (upscale) {
        anime4k.drawFrame(input.texId, timeUs);
      } else {
        copyProgram.use();
        copyProgram.setSamplerTexIdUniform("uInput", input.texId, 0);
        copyProgram.setIntUniform(
            "uGrayscale", effect == PlatformVideoEffect.DEBUG_GRAYSCALE ? 1 : 0);
        copyProgram.bindAttributesAndUniforms();
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);
        GlUtil.checkGlError();
      }
      outputInUse = true;
      inputListener.onInputFrameProcessed(input);
      outputListener.onOutputFrameAvailable(output, timeUs);
    } catch (VideoFrameProcessingException | GlUtil.GlException e) {
      errorExecutor.execute(() -> errorListener.onError(VideoFrameProcessingException.from(e)));
    }
  }

  @Override
  public void releaseOutputFrame(GlTextureInfo texture) {
    if (texture != output || !outputInUse) return;
    outputInUse = false;
    inputListener.onReadyToAcceptInputFrame();
  }

  @Override
  public void signalEndOfCurrentInputStream() {
    outputListener.onCurrentOutputStreamEnded();
  }

  @Override
  public void flush() {
    outputInUse = false;
    inputListener.onFlush();
    inputListener.onReadyToAcceptInputFrame();
  }

  @Override
  public void release() throws VideoFrameProcessingException {
    VideoFrameProcessingException failure = null;
    try {
      if (output != null) output.release();
    } catch (GlUtil.GlException e) {
      failure = new VideoFrameProcessingException(e);
    } finally {
      output = null;
      outputInUse = false;
    }
    try {
      if (anime4k != null) anime4k.release();
    } catch (VideoFrameProcessingException e) {
      failure = e;
    } finally {
      anime4k = null;
    }
    try {
      copyProgram.delete();
    } catch (GlUtil.GlException e) {
      failure = new VideoFrameProcessingException(e);
    }
    try {
      if (efficiency != null) efficiency.release();
    } catch (VideoFrameProcessingException e) {
      failure = e;
    } finally {
      efficiency = null;
    }
    if (failure != null) throw failure;
  }
}
