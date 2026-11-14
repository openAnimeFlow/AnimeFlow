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
import android.util.Half;
import androidx.media3.common.GlTextureInfo;
import androidx.media3.common.util.GlUtil;
import androidx.media3.common.util.Util;
import androidx.media3.effect.DefaultGlObjectsProvider;
import androidx.media3.effect.GlShaderProgram;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import androidx.test.platform.app.InstrumentationRegistry;
import java.nio.ByteBuffer;
import java.util.HashMap;
import java.util.IdentityHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.junit.Test;
import org.junit.runner.RunWith;

/**
 * Independent CPU evaluation of the original convolution expressions, not GPU readback golden
 * files.
 */
@RunWith(AndroidJUnit4.class)
public class Anime4kEfficiencyProgramTest {
  @Test
  public void completePresetMatchesCpuAcrossScaleBranchesAndRuntimeSwitches() throws Exception {
    Context context = InstrumentationRegistry.getInstrumentation().getContext();
    EGLDisplay display = GlUtil.getDefaultEglDisplay();
    EGLContext eglContext =
        GlUtil.createEglContext(
            EGL14.EGL_NO_CONTEXT, display, 3, GlUtil.EGL_CONFIG_ATTRIBUTES_RGBA_8888);
    EGLSurface surface = GlUtil.createFocusedPlaceholderEglSurface(eglContext, display);
    SwitchableVideoEffect config = new SwitchableVideoEffect(PlatformVideoEffect.NONE);
    GlShaderProgram program = config.toGlShaderProgram(context, false);
    DefaultGlObjectsProvider provider = new DefaultGlObjectsProvider();
    GlTextureInfo[] output = {null};
    program.setOutputListener(
        new GlShaderProgram.OutputListener() {
          @Override
          public void onOutputFrameAvailable(GlTextureInfo texture, long timeUs) {
            output[0] = texture;
          }
        });
    program.setErrorListener(
        Runnable::run,
        error -> {
          throw new AssertionError(error);
        });
    List<ShaderPassPlan.Pass> passes =
        ShaderPassPlan.parse(
            Util.loadAsset(context, "efficiency.json"));
    try {
      for (int[] source : new int[][] {{8, 6}, {7, 5}}) {
        int width = source[0], height = source[1];
        float[][][] input = new float[height][width][4];
        ByteBuffer bytes = ByteBuffer.allocateDirect(width * height * 4);
        for (int y = 0; y < height; y++)
          for (int x = 0; x < width; x++) {
            int[] rgba = {
              (x * 47 + y * 29) % 256, x < width / 2 ? 30 : 220, (x + y) % 2 == 0 ? 40 : 190, 255
            };
            for (int c = 0; c < 4; c++) {
              input[y][x][c] = rgba[c] / 255f;
              bytes.put((byte) rgba[c]);
            }
          }
        bytes.flip();
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
              bytes);
          for (int[] target :
              new int[][] {{6, 4}, {8, 6}, {12, 9}, {16, 12}, {24, 18}, {25, 19}, {40, 30}}) {
            int w = target[0], h = target[1];
            float[][][] reference =
                reference(
                    context, new ShaderPassPlan(passes, width, height, w, h), input, w, h);
            for (PlatformVideoEffect mode :
                new PlatformVideoEffect[] {
                  PlatformVideoEffect.NONE,
                  PlatformVideoEffect.SHADER_BUNDLE,
                  PlatformVideoEffect.NONE,
                  PlatformVideoEffect.SHADER_BUNDLE
                }) {
              config.setConfiguration(mode, w, h, mode == PlatformVideoEffect.SHADER_BUNDLE ? ShaderFixtures.load(context, "efficiency") : null);
              output[0] = null;
              program.queueInputFrame(provider, inputTexture, 0);
              assertNotNull(output[0]);
              assertEquals(w, output[0].width);
              assertEquals(h, output[0].height);
              GlUtil.focusFramebufferUsingCurrentContext(output[0].fboId, w, h);
              ByteBuffer actual = ByteBuffer.allocateDirect(w * h * 4);
              GLES20.glReadPixels(0, 0, w, h, GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, actual);
              GlUtil.checkGlError();
              int maxError = 0, changed = 0;
              for (int y = 0; y < h; y++)
                for (int x = 0; x < w; x++) {
                  for (int c = 0; c < 3; c++) {
                    int plain =
                        quantize(
                            sample(
                                input,
                                (x + .5f) * width / w - .5f,
                                (y + .5f) * height / h - .5f,
                                c));
                    int expected =
                        mode == PlatformVideoEffect.NONE ? plain : quantize(reference[y][x][c]);
                    int value = actual.get((y * w + x) * 4 + c) & 255;
                    maxError = Math.max(maxError, Math.abs(expected - value));
                    if (Math.abs(value - plain) > 3) changed++;
                  }
                  assertEquals(255, actual.get((y * w + x) * 4 + 3) & 255);
                }
              assertTrue(
                  mode
                      + " "
                      + width
                      + "x"
                      + height
                      + " -> "
                      + w
                      + "x"
                      + h
                      + " max error="
                      + maxError,
                  maxError <= 4);
              if (mode == PlatformVideoEffect.SHADER_BUNDLE)
                assertTrue("Restore must affect even non-upscaled output", changed > 5);
              program.releaseOutputFrame(output[0]);
            }
            program.flush();
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

  private static float[][][] reference(
      Context context, ShaderPassPlan plan, float[][][] original, int width, int height)
      throws Exception {
    Map<ShaderPassPlan.Node, float[][][]> values = new IdentityHashMap<>();
    for (ShaderPassPlan.Step step : plan.steps) {
      Map<String, float[][][]> inputs = new HashMap<>();
      for (int i = 0; i < step.inputs.length; i++)
        inputs.put(
            step.pass.bindings.get(i).name,
            step.inputs[i].slot < 0 ? original : values.get(step.inputs[i]));
      String code = Util.loadAsset(context, step.pass.asset);
      float[][][] pixels = evaluatePass(step, inputs, code);
      // Every production intermediate is RGBA16F. Preserve its rounding between passes.
      for (float[][] row : pixels)
        for (float[] pixel : row)
          for (int c = 0; c < 4; c++) {
            pixel[c] = Half.toFloat(Half.toHalf(pixel[c]));
          }
      values.put(step.output, pixels);
    }
    float[][][] result = values.get(plan.result);
    float[][][] output = new float[height][width][4];
    for (int y = 0; y < height; y++)
      for (int x = 0; x < width; x++)
        for (int c = 0; c < 3; c++) {
          output[y][x][c] =
              sample(
                  result,
                  (x + .5f) * result[0].length / width - .5f,
                  (y + .5f) * result.length / height - .5f,
                  c);
        }
    return output;
  }

  private static float[][][] evaluatePass(
      ShaderPassPlan.Step step, Map<String, float[][][]> inputs, String code) {
    int w = step.output.width, h = step.output.height;
    float[][][] result = new float[h][w][4];
    if (step.pass.source.contains("Clamp_Highlights")) {
      boolean clamp = step.pass.hook.equals("PREKERNEL");
      boolean horizontal = inputs.containsKey("MAIN");
      for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++) {
          if (clamp) {
            float[][][] image = inputs.get("HOOKED"), stats = inputs.get("STATSMAX");
            float luma =
                at(image, x, y, w, h, 0) * .299f
                    + at(image, x, y, w, h, 1) * .587f
                    + at(image, x, y, w, h, 2) * .114f;
            float excess = Math.max(0, luma - at(stats, x, y, w, h, 0));
            for (int c = 0; c < 4; c++) result[y][x][c] = at(image, x, y, w, h, c) - excess;
          } else {
            float[][][] image = inputs.get(horizontal ? "MAIN" : "STATSMAX");
            for (int d = -2; d <= 2; d++) {
              int xx = x + (horizontal ? d : 0), yy = y + (horizontal ? 0 : d);
              float value =
                  horizontal
                      ? sample(image, xx, yy, 0) * .299f
                          + sample(image, xx, yy, 1) * .587f
                          + sample(image, xx, yy, 2) * .114f
                      : sample(image, xx, yy, 0);
              result[y][x][0] = Math.max(result[y][x][0], value);
            }
          }
        }
    } else if (step.pass.source.contains("AutoDownscale")) {
      for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++)
          for (int c = 0; c < 4; c++) result[y][x][c] = at(inputs.get("HOOKED"), x, y, w, h, c);
    } else if (code.contains("-Depth-to-Space")) {
      float[][][] feature = inputs.get("conv2d_last_tf"), image = inputs.get("MAIN");
      for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++)
          for (int c = 0; c < 4; c++) {
            result[y][x][c] = at(image, x, y, w, h, c) + feature[y / 2][x / 2][(y % 2) * 2 + x % 2];
          }
    } else {
      Map<String, String> macros = new HashMap<>();
      Matcher definitions =
          Pattern.compile("#define (go_\\d+|g_\\d+)(?:\\([^\\n]*?\\))? ([^\\n]+)").matcher(code);
      while (definitions.find()) macros.put(definitions.group(1), definitions.group(2));
      Matcher terms =
          Pattern.compile(
                  "mat4\\(([^)]+)\\) \\* (go_\\d+|g_\\d+)(?:\\((-?[0-9.]+), (-?[0-9.]+)\\))?")
              .matcher(code);
      int count = 0;
      while (terms.find()) {
        count++;
        float[] matrix = numbers(terms.group(1));
        String macro = macros.get(terms.group(2));
        Matcher texture = Pattern.compile("(\\w+)_tex(?:Off)?\\(").matcher(macro);
        assertTrue(texture.find());
        float[][][] image = inputs.get(texture.group(1));
        assertNotNull(image);
        boolean relu = macro.contains("max("), negative = macro.contains("max(-");
        float dx = terms.group(3) == null ? 0 : Float.parseFloat(terms.group(3));
        float dy = terms.group(4) == null ? 0 : Float.parseFloat(terms.group(4));
        for (int y = 0; y < h; y++)
          for (int x = 0; x < w; x++)
            for (int k = 0; k < 4; k++) {
              float value =
                  sample(
                      image,
                      (x + .5f) * image[0].length / w - .5f + dx,
                      (y + .5f) * image.length / h - .5f + dy,
                      k);
              if (relu) value = Math.max(0, negative ? -value : value);
              for (int c = 0; c < 4; c++) result[y][x][c] += matrix[k * 4 + c] * value;
            }
      }
      assertTrue(count == 9 || count == 18 || count == 14);
      Matcher bias = Pattern.compile("result \\+= vec4\\(([^)]+)\\)").matcher(code);
      assertTrue(bias.find());
      float[] b = numbers(bias.group(1));
      boolean residual = code.contains("return result + MAIN_tex");
      for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++)
          for (int c = 0; c < 4; c++) {
            result[y][x][c] += b[c] + (residual ? at(inputs.get("MAIN"), x, y, w, h, c) : 0);
          }
    }
    return result;
  }

  private static float[] numbers(String value) {
    String[] tokens = value.split(",");
    float[] result = new float[tokens.length];
    for (int i = 0; i < tokens.length; i++) result[i] = Float.parseFloat(tokens[i].trim());
    return result;
  }

  private static int quantize(float value) {
    return Math.round(Math.max(0, Math.min(1, value)) * 255);
  }

  private static float at(float[][][] image, int x, int y, int w, int h, int c) {
    return sample(
        image, (x + .5f) * image[0].length / w - .5f, (y + .5f) * image.length / h - .5f, c);
  }

  private static float sample(float[][][] image, float x, float y, int c) {
    int ix = (int) Math.floor(x), iy = (int) Math.floor(y);
    float fx = x - ix, fy = y - iy;
    int x0 = Math.max(0, Math.min(image[0].length - 1, ix)),
        x1 = Math.max(0, Math.min(image[0].length - 1, ix + 1));
    int y0 = Math.max(0, Math.min(image.length - 1, iy)),
        y1 = Math.max(0, Math.min(image.length - 1, iy + 1));
    return (image[y0][x0][c] * (1 - fx) + image[y0][x1][c] * fx) * (1 - fy)
        + (image[y1][x0][c] * (1 - fx) + image[y1][x1][c] * fx) * fy;
  }
}
