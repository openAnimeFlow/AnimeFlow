// Copyright 2026 The AnimeFlow Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license in the LICENSE file.
package io.flutter.plugins.videoplayer;

import android.opengl.GLES20;
import androidx.media3.common.VideoFrameProcessingException;
import androidx.media3.common.util.GlProgram;
import androidx.media3.common.util.GlUtil;
import androidx.media3.common.util.UnstableApi;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/** Executes an application-supplied shader graph using signed RGBA16F intermediates. GL-thread only. */
@UnstableApi
final class ShaderBundleProgram {
  private static final String VERTEX =
      "#version 300 es\n"
          + "in vec4 aFramePosition; out vec2 vTexCoord;"
          + "void main(){gl_Position=aFramePosition;vTexCoord=aFramePosition.xy*0.5+0.5;}";
  private final ShaderBundle bundle;
  private final List<ShaderPassPlan.Pass> passes;
  private final Map<String, GlProgram> programs = new HashMap<>();
  private final GlProgram copy;
  private ShaderPassPlan plan;
  private int[] textures = new int[0], fbos = new int[0];
  private int inputWidth, inputHeight, outputWidth, outputHeight;

  ShaderBundleProgram(ShaderBundle bundle) throws VideoFrameProcessingException {
    this.bundle = bundle;
    try {
      String version = GLES20.glGetString(GLES20.GL_VERSION);
      GlUtil.checkGlException(
          version != null && version.startsWith("OpenGL ES 3"),
          "Shader bundles require OpenGL ES 3 and RGBA16F rendering");
      passes = bundle.passes;
      copy =
          new GlProgram(
              VERTEX,
              "#version 300 es\n"
                  + "precision highp float;in vec2 vTexCoord; uniform sampler2D uInput; out vec4"
                  + " outColor;void"
                  + " main(){outColor=vec4(clamp(texture(uInput,vTexCoord).rgb,0.0,1.0),1.0);}");
      copy.setBufferAttribute("aFramePosition", GlUtil.getNormalizedCoordinateBounds(), 4);
    } catch (GlUtil.GlException e) {
      throw new VideoFrameProcessingException(e);
    }
  }

  private void configure(int width, int height, int targetWidth, int targetHeight)
      throws GlUtil.GlException {
    if (plan != null
        && inputWidth == width
        && inputHeight == height
        && outputWidth == targetWidth
        && outputHeight == targetHeight) return;
    deleteTargets();
    plan = null;
    ShaderPassPlan next =
        new ShaderPassPlan(passes, width, height, targetWidth, targetHeight);
    int[] limit = new int[1];
    GLES20.glGetIntegerv(GLES20.GL_MAX_TEXTURE_SIZE, limit, 0);
    GlUtil.checkGlException(
        targetWidth <= limit[0] && targetHeight <= limit[0], "Output exceeds GPU limit");
    textures = new int[next.slots.size()];
    fbos = new int[textures.length];
    for (int i = 0; i < textures.length; i++) {
      ShaderPassPlan.Node slot = next.slots.get(i);
      GlUtil.checkGlException(
          slot.width <= limit[0] && slot.height <= limit[0],
          "Shader intermediate exceeds GPU limit");
      textures[i] = GlUtil.createTexture(slot.width, slot.height, true);
      fbos[i] = GlUtil.createFboForTexture(textures[i]);
      GlUtil.checkGlException(
          GLES20.glCheckFramebufferStatus(GLES20.GL_FRAMEBUFFER) == GLES20.GL_FRAMEBUFFER_COMPLETE,
          "Shader bundles require renderable RGBA16F textures");
    }
    plan = next;
    inputWidth = width;
    inputHeight = height;
    outputWidth = targetWidth;
    outputHeight = targetHeight;
  }

  void draw(int input, int width, int height, int targetWidth, int targetHeight, long timeUs)
      throws VideoFrameProcessingException {
    int[] outputFbo = new int[1];
    GLES20.glGetIntegerv(GLES20.GL_FRAMEBUFFER_BINDING, outputFbo, 0);
    try {
      configure(width, height, targetWidth, targetHeight);
      for (ShaderPassPlan.Step step : plan.steps) {
        GlProgram program = programs.get(step.pass.asset);
        if (program == null) {
          program = new GlProgram(VERTEX, bundle.shaders.get(step.pass.asset));
          program.setBufferAttribute("aFramePosition", GlUtil.getNormalizedCoordinateBounds(), 4);
          programs.put(step.pass.asset, program);
        }
        GlUtil.focusFramebufferUsingCurrentContext(
            fbos[step.output.slot], step.output.width, step.output.height);
        program.use();
        for (int i = 0; i < step.inputs.length; i++) {
          ShaderPassPlan.Binding binding = step.pass.bindings.get(i);
          ShaderPassPlan.Node node = step.inputs[i];
          if (binding.sampler)
            program.setSamplerTexIdUniform(
                "u_" + binding.name, node.slot < 0 ? input : textures[node.slot], i);
          if (binding.dimensions)
            program.setFloatsUniform("s_" + binding.name, new float[] {node.width, node.height});
        }
        program.bindAttributesAndUniforms();
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);
        GlUtil.checkGlError();
      }
      GlUtil.focusFramebufferUsingCurrentContext(outputFbo[0], targetWidth, targetHeight);
      copy.use();
      copy.setSamplerTexIdUniform("uInput", plan.result.slot < 0 ? input : textures[plan.result.slot], 0);
      copy.bindAttributesAndUniforms();
      GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);
      GlUtil.checkGlError();
    } catch (GlUtil.GlException e) {
      throw new VideoFrameProcessingException(e, timeUs);
    } finally {
      GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, outputFbo[0]);
      GLES20.glViewport(0, 0, targetWidth, targetHeight);
    }
  }

  private void deleteTargets() throws GlUtil.GlException {
    GlUtil.GlException failure = null;
    for (int i = 0; i < textures.length; i++) {
      try {
        if (fbos[i] != 0) GlUtil.deleteFbo(fbos[i]);
      } catch (GlUtil.GlException e) {
        failure = e;
      } finally {
        fbos[i] = 0;
      }
      try {
        if (textures[i] != 0) GlUtil.deleteTexture(textures[i]);
      } catch (GlUtil.GlException e) {
        failure = e;
      } finally {
        textures[i] = 0;
      }
    }
    if (failure != null) throw failure;
  }

  void release() throws VideoFrameProcessingException {
    GlUtil.GlException failure = null;
    try {
      deleteTargets();
    } catch (GlUtil.GlException e) {
      failure = e;
    }
    for (GlProgram program : programs.values()) {
      try {
        program.delete();
      } catch (GlUtil.GlException e) {
        failure = e;
      }
    }
    programs.clear();
    try {
      copy.delete();
    } catch (GlUtil.GlException e) {
      failure = e;
    }
    if (failure != null) throw new VideoFrameProcessingException(failure);
  }
}
