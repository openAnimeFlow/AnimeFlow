package io.flutter.plugins.videoplayer;

import android.content.Context;
import androidx.media3.common.util.Util;
import org.json.JSONArray;
import org.json.JSONObject;

final class ShaderFixtures {
  static String copy() {
    return "{\"version\":1,\"passes\":[{\"asset\":\"copy\",\"hook\":\"MAIN\",\"save\":\"MAIN\",\"width\":\"MAIN.w\",\"height\":\"MAIN.h\",\"when\":\"1\",\"bindings\":[]}],\"shaders\":{\"copy\":\"#version 300 es\\nprecision highp float; out vec4 outColor; void main(){outColor=vec4(1.0);}\"}}";
  }
  static ShaderBundle load(Context context, String name) throws Exception {
    JSONArray passes = new JSONArray(Util.loadAsset(context, name + ".json"));
    JSONObject shaders = new JSONObject();
    for (int i = 0; i < passes.length(); i++) {
      String asset = passes.getJSONObject(i).getString("asset");
      shaders.put(asset, Util.loadAsset(context, asset));
    }
    return new ShaderBundle(new JSONObject().put("version", 1).put("passes", passes).put("shaders", shaders).toString());
  }
}
