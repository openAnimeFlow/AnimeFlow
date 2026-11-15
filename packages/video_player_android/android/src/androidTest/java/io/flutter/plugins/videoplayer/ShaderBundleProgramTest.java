// Copyright 2026 The AnimeFlow Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license in the LICENSE file.
package io.flutter.plugins.videoplayer;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotSame;
import static org.junit.Assert.assertSame;
import static org.junit.Assert.assertTrue;

import android.opengl.EGL14;
import android.opengl.EGLContext;
import android.opengl.EGLDisplay;
import android.opengl.EGLSurface;
import android.opengl.GLES20;
import androidx.media3.common.GlTextureInfo;
import androidx.media3.common.util.GlProgram;
import androidx.media3.common.util.GlUtil;
import androidx.media3.effect.DefaultGlObjectsProvider;
import androidx.media3.effect.GlShaderProgram;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import java.lang.reflect.Field;
import java.nio.ByteBuffer;
import java.util.Map;
import org.json.JSONArray;
import org.json.JSONObject;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;

/** Real-GL regressions for external shaders, using only package-owned synthetic fixtures. */
@RunWith(AndroidJUnit4.class)
public class ShaderBundleProgramTest {
  private EGLDisplay display;
  private EGLContext context;
  private EGLSurface surface;
  private int input, inputFbo, output, outputFbo;
  private ShaderBundleProgram program;

  @Before
  public void setUp() throws Exception {
    display = GlUtil.getDefaultEglDisplay();
    context =
        GlUtil.createEglContext(
            EGL14.EGL_NO_CONTEXT, display, 3, GlUtil.EGL_CONFIG_ATTRIBUTES_RGBA_8888);
    surface = GlUtil.createFocusedPlaceholderEglSurface(context, display);
    input = GlUtil.createTexture(2, 2, false);
    inputFbo = GlUtil.createFboForTexture(input);
    output = GlUtil.createTexture(2, 2, false);
    outputFbo = GlUtil.createFboForTexture(output);
  }

  private JSONObject bundle(String body) throws Exception {
    JSONObject json = new JSONObject(ShaderFixtures.copy());
    json.getJSONArray("passes")
        .getJSONObject(0)
        .put(
            "bindings",
            new JSONArray()
                .put(
                    new JSONObject()
                        .put("name", "MAIN")
                        .put("sampler", true)
                        .put("dimensions", true)));
    json.getJSONObject("shaders")
        .put(
            "copy",
            "#version 300 es\nprecision highp float;"
                + "in vec2 vTexCoord; uniform sampler2D u_MAIN; uniform vec2 s_MAIN;"
                + "out vec4 outColor; void main(){"
                + body
                + "}");
    return json;
  }

  private void draw(float red, float blue) throws Exception {
    GlUtil.focusFramebufferUsingCurrentContext(inputFbo, 2, 2);
    GLES20.glClearColor(red, 0, blue, 1);
    GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);
    GlUtil.focusFramebufferUsingCurrentContext(outputFbo, 2, 2);
    program.draw(input, 2, 2, 2, 2, 0);
  }

  private void assertPixels(int red, int green, int blue) throws Exception {
    ByteBuffer pixels = ByteBuffer.allocateDirect(16);
    GLES20.glReadPixels(0, 0, 2, 2, GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, pixels);
    GlUtil.checkGlError();
    for (int i = 0; i < 4; i++) {
      assertEquals("red", red, pixels.get(i * 4) & 255);
      assertEquals("green", green, pixels.get(i * 4 + 1) & 255);
      assertEquals("blue", blue, pixels.get(i * 4 + 2) & 255);
      assertEquals("alpha", 255, pixels.get(i * 4 + 3) & 255);
    }
  }

  @Test
  public void optimizedOutDimensionsDoNotBreakCopyShader() throws Exception {
    program =
        new ShaderBundleProgram(
            new ShaderBundle(bundle("outColor=texture(u_MAIN,vTexCoord);").toString()));
    draw(1, 0);
    assertPixels(255, 0, 0);
  }

  @Test
  public void optimizedOutSamplerDoesNotBreakSizeOnlyShader() throws Exception {
    program =
        new ShaderBundleProgram(
            new ShaderBundle(bundle("outColor=vec4(s_MAIN/2.0,0.0,1.0);").toString()));
    draw(0, 1);
    assertPixels(255, 255, 0);
  }

  @Test
  public void discardedFragmentsDoNotRetainPreviousFrame() throws Exception {
    program =
        new ShaderBundleProgram(
            new ShaderBundle(
                bundle("vec4 c=texture(u_MAIN,vTexCoord);if(c.r<0.5)discard;outColor=c;")
                    .toString()));
    draw(1, 0);
    assertPixels(255, 0, 0);
    draw(0, 1);
    assertPixels(0, 0, 0);
    draw(1, 0);
    assertPixels(255, 0, 0);
  }

  @Test
  public void disablingReleasesTargetsButKeepsProgramsUntilReplacementOrDisposal() throws Exception {
    String encoded = bundle("outColor=vec4(1.0,0.0,0.0,1.0);").toString();
    SwitchableVideoEffect effect = new SwitchableVideoEffect(PlatformVideoEffect.NONE);
    SwitchableVideoShaderProgram switcher = new SwitchableVideoShaderProgram(false, effect);
    DefaultGlObjectsProvider provider = new DefaultGlObjectsProvider();
    GlTextureInfo inputTexture = new GlTextureInfo(input, inputFbo, -1, 2, 2);
    GlTextureInfo[] frame = {null};
    switcher.setOutputListener(new GlShaderProgram.OutputListener() {
      @Override
      public void onOutputFrameAvailable(GlTextureInfo texture, long timeUs) {
        frame[0] = texture;
      }
    });
    switcher.setErrorListener(Runnable::run, error -> { throw new AssertionError(error); });
    try {
      GlUtil.focusFramebufferUsingCurrentContext(inputFbo, 2, 2);
      GLES20.glClearColor(0, 0, 1, 1);
      GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);
      effect.setConfiguration(PlatformVideoEffect.SHADER_BUNDLE, 2, 2, new ShaderBundle(encoded));
      switcher.queueInputFrame(provider, inputTexture, 0);
      ShaderBundleProgram cached = (ShaderBundleProgram) field(switcher, "bundleProgram");
      GlProgram compiled = (GlProgram) ((Map<?, ?>) field(cached, "programs")).get("copy");
      int compiledId = programId(compiled);
      int[] targets = ((int[]) field(cached, "textures")).clone();
      assertTrue(targets.length > 0);

      // A request cannot destroy targets while the consumer still owns the current frame.
      effect.setConfiguration(PlatformVideoEffect.NONE, 2, 2, null);
      for (int texture : targets) assertTrue(GLES20.glIsTexture(texture));
      switcher.releaseOutputFrame(frame[0]);
      switcher.queueInputFrame(provider, inputTexture, 1);
      assertTrue(GLES20.glIsProgram(compiledId));
      for (int texture : targets) assertFalse(GLES20.glIsTexture(texture));
      assertEquals(0, ((int[]) field(cached, "textures")).length);
      GlUtil.focusFramebufferUsingCurrentContext(frame[0].fboId, 2, 2);
      assertPixels(0, 0, 255);
      switcher.releaseOutputFrame(frame[0]);

      // Equal contents in a new bundle instance reuse compiled code, even after a size change.
      effect.setConfiguration(PlatformVideoEffect.SHADER_BUNDLE, 4, 4, new ShaderBundle(encoded));
      switcher.queueInputFrame(provider, inputTexture, 2);
      assertSame(cached, field(switcher, "bundleProgram"));
      assertSame(compiled, ((Map<?, ?>) field(cached, "programs")).get("copy"));
      assertEquals(4, frame[0].width);
      assertEquals(4, frame[0].height);
      GlUtil.focusFramebufferUsingCurrentContext(frame[0].fboId, 4, 4);
      assertPixels(255, 0, 0);
      switcher.releaseOutputFrame(frame[0]);

      // A different source under the same asset key must evict the previous program.
      String replacement = encoded.replace("vec4(1.0,0.0,0.0,1.0)", "vec4(0.0,1.0,0.0,1.0)");
      effect.setConfiguration(PlatformVideoEffect.SHADER_BUNDLE, 4, 4, new ShaderBundle(replacement));
      switcher.queueInputFrame(provider, inputTexture, 3);
      assertTrue(((Map<?, ?>) field(cached, "programs")).isEmpty());
      GlUtil.focusFramebufferUsingCurrentContext(frame[0].fboId, 4, 4);
      assertPixels(0, 255, 0);
      switcher.releaseOutputFrame(frame[0]);

      ShaderBundleProgram replacementProgram = (ShaderBundleProgram) field(switcher, "bundleProgram");
      GlProgram replacementCompiled =
          (GlProgram) ((Map<?, ?>) field(replacementProgram, "programs")).get("copy");
      assertNotSame(compiled, replacementCompiled);
      int replacementId = programId(replacementCompiled);
      int replacementCopyId = programId((GlProgram) field(replacementProgram, "copy"));
      // Drivers may recycle a deleted ID for either newly created program.
      if (compiledId != replacementId && compiledId != replacementCopyId) {
        assertFalse(GLES20.glIsProgram(compiledId));
      }
      effect.setConfiguration(PlatformVideoEffect.DEBUG_GRAYSCALE, 4, 4, null);
      switcher.queueInputFrame(provider, inputTexture, 4);
      assertEquals(0, ((int[]) field(replacementProgram, "textures")).length);
      assertTrue(GLES20.glIsProgram(replacementId));
      switcher.releaseOutputFrame(frame[0]);
      switcher.release();
      switcher = null;
      GLES20.glUseProgram(0);
      assertFalse(GLES20.glIsProgram(replacementId));
      GlUtil.checkGlError();
    } finally {
      if (switcher != null) switcher.release();
    }
  }

  // Inspect resource ownership without adding test-only APIs to production classes.
  private static Object field(Object instance, String name) throws Exception {
    Field field = instance.getClass().getDeclaredField(name);
    field.setAccessible(true);
    return field.get(instance);
  }

  private static int programId(GlProgram program) throws Exception {
    program.use();
    int[] id = new int[1];
    GLES20.glGetIntegerv(GLES20.GL_CURRENT_PROGRAM, id, 0);
    GlUtil.checkGlError();
    return id[0];
  }

  @Test
  public void discardedFragmentsDoNotRetainAnotherPassInReusedSlot() throws Exception {
    JSONObject json =
        bundle("vec4 c=texture(u_MAIN,vTexCoord);if(c.r<0.5)discard;outColor=c;");
    JSONObject redPass =
        new JSONObject(ShaderFixtures.copy()).getJSONArray("passes").getJSONObject(0);
    redPass.put("asset", "red").put("save", "UNUSED");
    json.put(
        "passes", new JSONArray().put(redPass).put(json.getJSONArray("passes").getJSONObject(0)));
    json.getJSONObject("shaders")
        .put(
            "red",
            "#version 300 es\nprecision highp float;out vec4 outColor;"
                + "void main(){outColor=vec4(1.0,0.0,0.0,1.0);}");
    ShaderBundle shaderBundle = new ShaderBundle(json.toString());
    ShaderPassPlan plan = new ShaderPassPlan(shaderBundle.passes, 2, 2, 2, 2);
    assertEquals("The two passes must reuse the same render target", 1, plan.slots.size());
    program = new ShaderBundleProgram(shaderBundle);
    draw(0, 1);
    assertPixels(0, 0, 0);
  }

  @After
  public void tearDown() throws Exception {
    if (program != null) program.release();
    GlUtil.deleteFbo(inputFbo);
    GlUtil.deleteFbo(outputFbo);
    GlUtil.deleteTexture(input);
    GlUtil.deleteTexture(output);
    GlUtil.destroyEglSurface(display, surface);
    GlUtil.destroyEglContext(display, context);
    EGL14.eglTerminate(display);
  }
}
