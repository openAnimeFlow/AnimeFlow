// Copyright 2026 The AnimeFlow Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license in the LICENSE file.
package io.flutter.plugins.videoplayer;

import static org.junit.Assert.*;

import android.content.Context;
import android.opengl.EGL14;
import android.opengl.EGLContext;
import android.opengl.EGLDisplay;
import android.opengl.EGLSurface;
import android.opengl.GLES20;
import androidx.media3.common.GlObjectsProvider;
import androidx.media3.common.GlTextureInfo;
import androidx.media3.common.util.GlUtil;
import androidx.media3.common.util.Size;
import androidx.media3.common.util.Util;
import androidx.media3.effect.DefaultGlObjectsProvider;
import androidx.media3.effect.GlShaderProgram;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import androidx.test.platform.app.InstrumentationRegistry;
import java.nio.ByteBuffer;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.junit.Test;
import org.junit.runner.RunWith;

/** Real-device pixel tests: compare all five GPU passes with independent CPU convolution. */
@RunWith(AndroidJUnit4.class)
public class Anime4kShaderProgramTest {
  @Test
  public void externalSourceReplacementAndSkippedPassesUseCurrentBundle() throws Exception {
    Context context = InstrumentationRegistry.getInstrumentation().getContext();
    EGLDisplay display = GlUtil.getDefaultEglDisplay();
    EGLContext eglContext = GlUtil.createEglContext(EGL14.EGL_NO_CONTEXT, display, 3, GlUtil.EGL_CONFIG_ATTRIBUTES_RGBA_8888);
    EGLSurface surface = GlUtil.createFocusedPlaceholderEglSurface(eglContext, display);
    SwitchableVideoEffect effect = new SwitchableVideoEffect(PlatformVideoEffect.NONE);
    GlShaderProgram program = effect.toGlShaderProgram(context, false);
    GlObjectsProvider provider = new DefaultGlObjectsProvider();
    GlTextureInfo input = provider.createBuffersForTexture(GlUtil.createTexture(2, 2, false), 2, 2);
    GlTextureInfo[] frame = {null};
    program.setOutputListener(new GlShaderProgram.OutputListener() {
      @Override public void onOutputFrameAvailable(GlTextureInfo output, long timeUs) { frame[0] = output; }
    });
    program.setErrorListener(Runnable::run, error -> { throw new AssertionError(error); });
    try {
      GlUtil.focusFramebufferUsingCurrentContext(input.fboId, 2, 2);
      GLES20.glClearColor(0, 0, 1, 1);
      GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);
      for (int mode = 0; mode < 4; mode++) {
        org.json.JSONObject json = new org.json.JSONObject(ShaderFixtures.copy());
        json.getJSONObject("shaders").put("copy", json.getJSONObject("shaders").getString("copy")
            .replace("vec4(1.0)", mode == 0 ? "vec4(1.0,0.0,0.0,1.0)" : "vec4(0.0,1.0,0.0,1.0)"));
        if (mode == 2) json.getJSONArray("passes").getJSONObject(0).put("when", "0");
        effect.setConfiguration(mode == 3 ? PlatformVideoEffect.NONE : PlatformVideoEffect.SHADER_BUNDLE,
            2, 2, mode == 3 ? null : new ShaderBundle(json.toString()));
        program.queueInputFrame(provider, input, mode);
        assertNotNull(frame[0]);
        GlUtil.focusFramebufferUsingCurrentContext(frame[0].fboId, 2, 2);
        ByteBuffer pixels = ByteBuffer.allocateDirect(16);
        GLES20.glReadPixels(0, 0, 2, 2, GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, pixels);
        for (int c = 0; c < 3; c++) assertEquals(c == Math.min(mode, 2) ? 255 : 0, pixels.get(c) & 255);
        program.releaseOutputFrame(frame[0]);
        frame[0] = null;
      }
    } finally {
      program.release();
      input.release();
      GlUtil.destroyEglSurface(display, surface);
      GlUtil.destroyEglContext(display, eglContext);
      EGL14.eglTerminate(display);
    }
  }

  @Test
  public void frameBoundarySwitchesPreservePixelsAndBackpressureAcrossFlushAndResize()
      throws Exception {
    Context context = InstrumentationRegistry.getInstrumentation().getContext();
    EGLDisplay display = GlUtil.getDefaultEglDisplay();
    EGLContext eglContext =
        GlUtil.createEglContext(
            EGL14.EGL_NO_CONTEXT, display, 3, GlUtil.EGL_CONFIG_ATTRIBUTES_RGBA_8888);
    EGLSurface surface = GlUtil.createFocusedPlaceholderEglSurface(eglContext, display);
    SwitchableVideoEffect effect = new SwitchableVideoEffect(PlatformVideoEffect.NONE);
    GlShaderProgram program = effect.toGlShaderProgram(context, false);
    GlObjectsProvider provider = new DefaultGlObjectsProvider();
    int[] ready = {0};
    int[] processed = {0};
    GlTextureInfo[] frame = {null};
    program.setInputListener(
        new GlShaderProgram.InputListener() {
          @Override
          public void onReadyToAcceptInputFrame() {
            ready[0]++;
          }

          @Override
          public void onInputFrameProcessed(GlTextureInfo input) {
            processed[0]++;
          }
        });
    program.setOutputListener(
        new GlShaderProgram.OutputListener() {
          @Override
          public void onOutputFrameAvailable(GlTextureInfo output, long timeUs) {
            frame[0] = output;
          }
        });
    program.setErrorListener(
        Runnable::run,
        error -> {
          throw new AssertionError(error);
        });
    try {
      for (int size = 0; size < 2; size++) {
        int width = size == 0 ? 8 : 7;
        int height = size == 0 ? 6 : 5;
        ByteBuffer pixels = ByteBuffer.allocateDirect(width * height * 4);
        float[][][] input = new float[height][width][4];
        for (int y = 0; y < height; y++)
          for (int x = 0; x < width; x++) {
            int[] rgba = {
              (x * 47 + y * 29) % 256, x < width / 2 ? 30 : 220, (x + y) % 2 == 0 ? 40 : 190, 255
            };
            for (int c = 0; c < 4; c++) {
              pixels.put((byte) rgba[c]);
              input[y][x][c] = rgba[c] / 255f;
            }
          }
        pixels.flip();
        float[][][] features = input;
        for (int pass = 0; pass < 4; pass++)
          features =
              convolve(
                  features,
                  Util.loadAsset(context, "x2_" + pass + ".glsl"),
                  pass == 0);
        int texture = GlUtil.createTexture(width, height, false);
        GlTextureInfo inputTexture = provider.createBuffersForTexture(texture, width, height);
        try {
          GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texture);
          GLES20.glTexSubImage2D(
              GLES20.GL_TEXTURE_2D,
              0,
              0,
              0,
              width,
              height,
              GLES20.GL_RGBA,
              GLES20.GL_UNSIGNED_BYTE,
              pixels);
          for (int i = 0; i < 30; i++) {
            PlatformVideoEffect selected =
                i % 3 == 0
                    ? PlatformVideoEffect.NONE
                    : i % 3 == 1
                        ? PlatformVideoEffect.SHADER_BUNDLE
                        : PlatformVideoEffect.DEBUG_GRAYSCALE;
            effect.setConfiguration(selected, selected == PlatformVideoEffect.SHADER_BUNDLE ? width * 2 : width, selected == PlatformVideoEffect.SHADER_BUNDLE ? height * 2 : height, selected == PlatformVideoEffect.SHADER_BUNDLE ? ShaderFixtures.load(context, "x2") : null);
            int available = ready[0];
            int consumed = processed[0];
            frame[0] = null;
            program.queueInputFrame(provider, inputTexture, i);
            assertEquals(consumed + 1, processed[0]);
            assertEquals("No new input while the output is in use", available, ready[0]);
            assertNotNull(frame[0]);
            boolean upscale = selected == PlatformVideoEffect.SHADER_BUNDLE;
            int outWidth = width * (upscale ? 2 : 1);
            int outHeight = height * (upscale ? 2 : 1);
            assertEquals(outWidth, frame[0].width);
            assertEquals(outHeight, frame[0].height);
            ByteBuffer actual = ByteBuffer.allocateDirect(outWidth * outHeight * 4);
            GlUtil.focusFramebufferUsingCurrentContext(frame[0].fboId, outWidth, outHeight);
            GLES20.glReadPixels(
                0, 0, outWidth, outHeight, GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, actual);
            int cnnChanged = 0;
            for (int y = 0; y < outHeight; y++)
              for (int x = 0; x < outWidth; x++) {
                for (int c = 0; c < 3; c++) {
                  float expected;
                  if (upscale) {
                    float base = bilinear(input, x / 2f - .25f, y / 2f - .25f, c);
                    expected = base + features[y / 2][x / 2][(y % 2) * 2 + x % 2];
                    if (Math.abs(
                            (actual.get((y * outWidth + x) * 4 + c) & 255) - Math.round(base * 255))
                        > 3) cnnChanged++;
                  } else if (selected == PlatformVideoEffect.DEBUG_GRAYSCALE) {
                    expected =
                        input[y][x][0] * .2126f + input[y][x][1] * .7152f + input[y][x][2] * .0722f;
                  } else {
                    expected = input[y][x][c];
                  }
                  int expectedByte = Math.round(Math.max(0, Math.min(1, expected)) * 255);
                  assertTrue(
                      "Pixel mismatch after switch " + i,
                      Math.abs(expectedByte - (actual.get((y * outWidth + x) * 4 + c) & 255)) <= 3);
                }
              }
            if (upscale) assertTrue("CNN must differ from resize", cnnChanged > 20);
            // Updating the requested mode must not invalidate a still-owned output frame.
            effect.setConfiguration(PlatformVideoEffect.NONE, outWidth, outHeight, null);
            program.releaseOutputFrame(frame[0]);
            assertEquals(available + 1, ready[0]);
            if (i % 5 == 0) program.flush();
          }
        } finally {
          inputTexture.release();
        }
      }
    } finally {
      program.release();
      GlUtil.destroyEglSurface(display, surface);
      GlUtil.destroyEglContext(display, eglContext);
      EGL14.eglTerminate(display);
    }
  }

  @Test
  public void gpuMatchesCpuModelAcrossResizeAndFreshProgram() throws Exception {
    Context context = InstrumentationRegistry.getInstrumentation().getContext();
    EGLDisplay display = GlUtil.getDefaultEglDisplay();
    EGLContext eglContext =
        GlUtil.createEglContext(
            EGL14.EGL_NO_CONTEXT, display, 3, GlUtil.EGL_CONFIG_ATTRIBUTES_RGBA_8888);
    EGLSurface surface = GlUtil.createFocusedPlaceholderEglSurface(eglContext, display);
    try {
      for (int instance = 0; instance < 2; instance++) {
        ShaderBundleProgram program = new ShaderBundleProgram(ShaderFixtures.load(context, "x2"));
        try {
          checkPixels(context, program, 8, 6);
          checkPixels(context, program, 7, 5);
        } finally {
          program.release();
        }
      }
    } finally {
      GlUtil.destroyEglSurface(display, surface);
      GlUtil.destroyEglContext(display, eglContext);
      EGL14.eglTerminate(display);
    }
  }

  private void checkPixels(Context context, ShaderBundleProgram program, int width, int height)
      throws Exception {
    float[][][] input = new float[height][width][4];
    ByteBuffer bytes = ByteBuffer.allocateDirect(width * height * 4);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int[] rgba = {
          (x * 47 + y * 29) % 256, x < width / 2 ? 30 : 220, (x + y) % 2 == 0 ? 40 : 190, 255
        };
        for (int c = 0; c < 4; c++) {
          input[y][x][c] = rgba[c] / 255f;
          bytes.put((byte) rgba[c]);
        }
      }
    }
    bytes.flip();
    float[][][] features = input;
    for (int pass = 0; pass < 4; pass++) {
      features =
          convolve(
              features,
              Util.loadAsset(context, "x2_" + pass + ".glsl"),
              pass == 0);
    }

    int inputTexture = GlUtil.createTexture(width, height, false);
    int outputTexture = 0;
    int outputFbo = 0;
    try {
      GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, inputTexture);
      GLES20.glTexSubImage2D(
          GLES20.GL_TEXTURE_2D,
          0,
          0,
          0,
          width,
          height,
          GLES20.GL_RGBA,
          GLES20.GL_UNSIGNED_BYTE,
          bytes);

      outputTexture = GlUtil.createTexture(width * 2, height * 2, false);
      outputFbo = GlUtil.createFboForTexture(outputTexture);
      GlUtil.focusFramebufferUsingCurrentContext(outputFbo, width * 2, height * 2);
      program.draw(inputTexture, width, height, width * 2, height * 2, 0);
      ByteBuffer output = ByteBuffer.allocateDirect(width * height * 16);
      GLES20.glReadPixels(
          0, 0, width * 2, height * 2, GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, output);
      GlUtil.checkGlError();
      int changedFromBilinear = 0;
      int maxError = 0;
      for (int y = 0; y < height * 2; y++) {
        for (int x = 0; x < width * 2; x++) {
          float residual = features[y / 2][x / 2][(y % 2) * 2 + x % 2];
          for (int c = 0; c < 3; c++) {
            float base = bilinear(input, x / 2f - 0.25f, y / 2f - 0.25f, c);
            int expected = Math.round(Math.max(0, Math.min(1, base + residual)) * 255);
            int actual = output.get((y * width * 2 + x) * 4 + c) & 255;
            maxError = Math.max(maxError, Math.abs(expected - actual));
            if (Math.abs(actual - Math.round(base * 255)) > 3) changedFromBilinear++;
          }
          assertEquals(255, output.get((y * width * 2 + x) * 4 + 3) & 255);
        }
      }
      // Allow half-float feature rounding and the final RGBA8 conversion.
      assertTrue("GPU/CPU maximum channel error: " + maxError, maxError <= 3);
      assertTrue("The CNN must change pixels, not just resize", changedFromBilinear > 20);
    } finally {
      if (outputFbo != 0) GlUtil.deleteFbo(outputFbo);
      if (outputTexture != 0) GlUtil.deleteTexture(outputTexture);
      GlUtil.deleteTexture(inputTexture);
    }
  }

  private static float[][][] convolve(float[][][] input, String shader, boolean first) {
    int height = input.length;
    int width = input[0].length;
    float[][][] output = new float[height][width][4];
    Matcher terms =
        Pattern.compile("mat4\\(([^)]+)\\) \\* go_([01])\\((-?[0-9.]+), (-?[0-9.]+)\\)")
            .matcher(shader);
    int termCount = 0;
    while (terms.find()) {
      termCount++;
      float[] matrix = numbers(terms.group(1));
      boolean negative = terms.group(2).equals("1");
      int dx = (int) Float.parseFloat(terms.group(3));
      int dy = (int) Float.parseFloat(terms.group(4));
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          float[] pixel = input[clamp(y + dy, height)][clamp(x + dx, width)];
          for (int c = 0; c < 4; c++) {
            for (int k = 0; k < 4; k++) {
              float value = first ? pixel[k] : Math.max(negative ? -pixel[k] : pixel[k], 0);
              output[y][x][c] += matrix[k * 4 + c] * value;
            }
          }
        }
      }
    }
    assertEquals(first ? 9 : 18, termCount);
    Matcher bias = Pattern.compile("result \\+= vec4\\(([^)]+)\\)").matcher(shader);
    assertTrue(bias.find());
    float[] values = numbers(bias.group(1));
    for (float[][] row : output)
      for (float[] pixel : row) {
        for (int c = 0; c < 4; c++) pixel[c] += values[c];
      }
    return output;
  }

  private static float[] numbers(String source) {
    String[] parts = source.split(",");
    float[] result = new float[parts.length];
    for (int i = 0; i < parts.length; i++) result[i] = Float.parseFloat(parts[i].trim());
    return result;
  }

  private static int clamp(int value, int size) {
    return Math.max(0, Math.min(size - 1, value));
  }

  private static float bilinear(float[][][] image, float x, float y, int c) {
    int x0 = (int) Math.floor(x);
    int y0 = (int) Math.floor(y);
    float fx = x - x0;
    float fy = y - y0;
    int h = image.length;
    int w = image[0].length;
    return (image[clamp(y0, h)][clamp(x0, w)][c] * (1 - fx)
                + image[clamp(y0, h)][clamp(x0 + 1, w)][c] * fx)
            * (1 - fy)
        + (image[clamp(y0 + 1, h)][clamp(x0, w)][c] * (1 - fx)
                + image[clamp(y0 + 1, h)][clamp(x0 + 1, w)][c] * fx)
            * fy;
  }
}
