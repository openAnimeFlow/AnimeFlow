// Copyright 2026 The AnimeFlow Authors. All rights reserved.
// Use of this source code is governed by the BSD license in the LICENSE file.
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
import androidx.media3.effect.DefaultGlObjectsProvider;
import androidx.media3.effect.GlShaderProgram;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import androidx.test.platform.app.InstrumentationRegistry;
import java.nio.ByteBuffer;
import org.junit.Test;
import org.junit.runner.RunWith;

@RunWith(AndroidJUnit4.class)
public class SwitchableVideoShaderProgramTest {
  @Test
  public void externalSourceReplacementAndSkippedPassesUseCurrentBundle() throws Exception {
    Context context = InstrumentationRegistry.getInstrumentation().getContext();
    EGLDisplay display = GlUtil.getDefaultEglDisplay();
    EGLContext eglContext =
        GlUtil.createEglContext(
            EGL14.EGL_NO_CONTEXT, display, 3, GlUtil.EGL_CONFIG_ATTRIBUTES_RGBA_8888);
    EGLSurface surface = GlUtil.createFocusedPlaceholderEglSurface(eglContext, display);
    SwitchableVideoEffect effect = new SwitchableVideoEffect(PlatformVideoEffect.NONE);
    GlShaderProgram program = effect.toGlShaderProgram(context, false);
    GlObjectsProvider provider = new DefaultGlObjectsProvider();
    GlTextureInfo input = provider.createBuffersForTexture(GlUtil.createTexture(2, 2, false), 2, 2);
    GlTextureInfo[] frame = {null};
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
      GlUtil.focusFramebufferUsingCurrentContext(input.fboId, 2, 2);
      GLES20.glClearColor(0, 0, 1, 1);
      GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);
      for (int mode = 0; mode < 4; mode++) {
        org.json.JSONObject json = new org.json.JSONObject(ShaderFixtures.copy());
        json.getJSONObject("shaders")
            .put(
                "copy",
                json.getJSONObject("shaders")
                    .getString("copy")
                    .replace(
                        "vec4(1.0)",
                        mode == 0 ? "vec4(1.0,0.0,0.0,1.0)" : "vec4(0.0,1.0,0.0,1.0)"));
        if (mode == 2) json.getJSONArray("passes").getJSONObject(0).put("when", "0");
        effect.setConfiguration(
            mode == 3 ? PlatformVideoEffect.NONE : PlatformVideoEffect.SHADER_BUNDLE,
            2,
            2,
            mode == 3 ? null : new ShaderBundle(json.toString()));
        program.queueInputFrame(provider, input, mode);
        assertNotNull(frame[0]);
        GlUtil.focusFramebufferUsingCurrentContext(frame[0].fboId, 2, 2);
        ByteBuffer pixels = ByteBuffer.allocateDirect(16);
        GLES20.glReadPixels(0, 0, 2, 2, GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, pixels);
        for (int c = 0; c < 3; c++)
          assertEquals(c == Math.min(mode, 2) ? 255 : 0, pixels.get(c) & 255);
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
}
