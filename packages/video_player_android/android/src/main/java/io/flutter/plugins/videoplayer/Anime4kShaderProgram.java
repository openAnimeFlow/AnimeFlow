// Copyright 2026 The AnimeFlow Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license in the LICENSE file.

package io.flutter.plugins.videoplayer;

import android.content.Context;
import android.opengl.GLES20;
import androidx.media3.common.VideoFrameProcessingException;
import androidx.media3.common.util.GlProgram;
import androidx.media3.common.util.GlUtil;
import androidx.media3.common.util.Size;
import androidx.media3.common.util.UnstableApi;
import androidx.media3.common.util.Util;
import androidx.media3.effect.BaseGlShaderProgram;
import java.io.IOException;

/**
 * Four source-resolution convolutions followed by 2x depth-to-space and the original RGB residual.
 * All GL objects belong to this player and are used/released on Media3's GL thread.
 */
@UnstableApi
final class Anime4kShaderProgram extends BaseGlShaderProgram {
  private static final String VERTEX_SHADER =
      "#version 300 es\n"
          + "in vec4 aFramePosition;\nout vec2 vTexCoord;\n"
          + "void main() { gl_Position = aFramePosition;"
          + " vTexCoord = aFramePosition.xy * 0.5 + 0.5; }\n";
  private final GlProgram[] programs = new GlProgram[5];
  // Signed, unclamped CNN features must never pass through an RGBA8 render target.
  private final int[] featureTextures = new int[2];
  private final int[] featureFbos = new int[2];
  private int width;
  private int height;

  Anime4kShaderProgram(Context context) throws VideoFrameProcessingException {
    super(/* useHighPrecisionColorComponents= */ false, /* texturePoolCapacity= */ 1);
    try {
      String version = GLES20.glGetString(GLES20.GL_VERSION);
      GlUtil.checkGlException(
          version != null && version.startsWith("OpenGL ES 3"),
          "Anime4K requires OpenGL ES 3 and RGBA16F color attachments");
      for (int i = 0; i < programs.length; i++) {
        programs[i] =
            new GlProgram(
                VERTEX_SHADER,
                Util.loadAsset(context, "animeflow/anime4k/cnn_x2_s_" + i + ".glsl"));
        programs[i].setBufferAttribute("aFramePosition", GlUtil.getNormalizedCoordinateBounds(), 4);
      }
    } catch (IOException | GlUtil.GlException failure) {
      try {
        release();
      } catch (VideoFrameProcessingException cleanupFailure) {
        failure.addSuppressed(cleanupFailure);
      }
      throw new VideoFrameProcessingException(failure);
    }
  }

  @Override
  public Size configure(int inputWidth, int inputHeight) throws VideoFrameProcessingException {
    try {
      int[] maxTextureSize = new int[1];
      GLES20.glGetIntegerv(GLES20.GL_MAX_TEXTURE_SIZE, maxTextureSize, 0);
      GlUtil.checkGlException(
          inputWidth > 0
              && inputHeight > 0
              && inputWidth <= maxTextureSize[0] / 2
              && inputHeight <= maxTextureSize[0] / 2,
          "Anime4K 2x output exceeds the GPU texture size limit");
      deleteFeatures();
      for (int i = 0; i < featureTextures.length; i++) {
        featureTextures[i] = GlUtil.createTexture(inputWidth, inputHeight, true);
        featureFbos[i] = GlUtil.createFboForTexture(featureTextures[i]);
        GlUtil.checkGlException(
            GLES20.glCheckFramebufferStatus(GLES20.GL_FRAMEBUFFER)
                == GLES20.GL_FRAMEBUFFER_COMPLETE,
            "Anime4K requires renderable RGBA16F textures");
      }
      width = inputWidth;
      height = inputHeight;
      for (GlProgram program : programs) {
        program.setFloatsUniform("uInputPt", new float[] {1f / width, 1f / height});
      }
      return new Size(width * 2, height * 2);
    } catch (GlUtil.GlException failure) {
      try {
        deleteFeatures();
      } catch (GlUtil.GlException cleanupFailure) {
        failure.addSuppressed(cleanupFailure);
      }
      throw new VideoFrameProcessingException(failure);
    }
  }

  @Override
  public void drawFrame(int inputTexId, long presentationTimeUs)
      throws VideoFrameProcessingException {
    // BaseGlShaderProgram owns the final output FBO. Restore it after the intermediate passes.
    int[] outputFbo = new int[1];
    GLES20.glGetIntegerv(GLES20.GL_FRAMEBUFFER_BINDING, outputFbo, 0);
    try {
      for (int i = 0; i < 4; i++) {
        GlUtil.focusFramebufferUsingCurrentContext(featureFbos[i % 2], width, height);
        draw(programs[i], i == 0 ? inputTexId : featureTextures[(i - 1) % 2]);
      }
      GlUtil.focusFramebufferUsingCurrentContext(outputFbo[0], width * 2, height * 2);
      programs[4].setSamplerTexIdUniform("uFeatures", featureTextures[1], 1);
      draw(programs[4], inputTexId);
    } catch (GlUtil.GlException failure) {
      throw new VideoFrameProcessingException(failure, presentationTimeUs);
    } finally {
      GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, outputFbo[0]);
      GLES20.glViewport(0, 0, width * 2, height * 2);
    }
  }

  private static void draw(GlProgram program, int inputTexId) throws GlUtil.GlException {
    program.use();
    program.setSamplerTexIdUniform("uInput", inputTexId, 0);
    program.bindAttributesAndUniforms();
    GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);
    GlUtil.checkGlError();
  }

  private void deleteFeatures() throws GlUtil.GlException {
    // Attempt every deletion even if a driver reports an error for one resource.
    GlUtil.GlException failure = null;
    for (int i = 0; i < featureTextures.length; i++) {
      try {
        if (featureFbos[i] != 0) GlUtil.deleteFbo(featureFbos[i]);
      } catch (GlUtil.GlException e) {
        failure = e;
      } finally {
        featureFbos[i] = 0;
      }
      try {
        if (featureTextures[i] != 0) GlUtil.deleteTexture(featureTextures[i]);
      } catch (GlUtil.GlException e) {
        failure = e;
      } finally {
        featureTextures[i] = 0;
      }
    }
    if (failure != null) throw failure;
  }

  @Override
  public void release() throws VideoFrameProcessingException {
    VideoFrameProcessingException failure = null;
    try {
      super.release();
    } catch (VideoFrameProcessingException e) {
      failure = e;
    }
    try {
      deleteFeatures();
    } catch (GlUtil.GlException e) {
      failure = new VideoFrameProcessingException(e);
    }
    for (int i = 0; i < programs.length; i++) {
      try {
        if (programs[i] != null) programs[i].delete();
      } catch (GlUtil.GlException e) {
        failure = new VideoFrameProcessingException(e);
      } finally {
        programs[i] = null;
      }
    }
    if (failure != null) throw failure;
  }
}
