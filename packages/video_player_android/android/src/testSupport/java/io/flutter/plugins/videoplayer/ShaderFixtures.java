package io.flutter.plugins.videoplayer;

final class ShaderFixtures {
  static String copy() {
    return "{\"version\":1,\"passes\":[{\"asset\":\"copy\",\"hook\":\"MAIN\",\"save\":\"MAIN\",\"width\":\"MAIN.w\",\"height\":\"MAIN.h\",\"when\":\"1\",\"bindings\":[]}],\"shaders\":{\"copy\":\"#version"
               + " 300 es\\n"
               + "precision highp float; out vec4 outColor; void main(){outColor=vec4(1.0);}\"}}";
  }
}
