package io.flutter.plugins.videoplayer;

import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.json.JSONObject;
import org.json.JSONException;

/** Immutable snapshot validated before publishing to the GL thread. */
final class ShaderBundle {
  final String encoded;
  final List<ShaderPassPlan.Pass> passes;
  final Map<String, String> shaders;

  ShaderBundle(String encoded) {
    this.encoded = encoded;
    try {
      JSONObject json = new JSONObject(encoded);
      if (json.getInt("version") != 1) throw new IllegalArgumentException("Unsupported shader bundle version");
      passes = Collections.unmodifiableList(ShaderPassPlan.parse(json.getJSONArray("passes").toString()));
      if (passes.isEmpty()) throw new IllegalArgumentException("Shader bundle must contain passes");
      JSONObject sources = json.getJSONObject("shaders");
      Map<String, String> loaded = new HashMap<>();
      Set<String> known = new HashSet<>(java.util.Arrays.asList("NATIVE", "MAIN", "OUTPUT"));
      boolean prekernel = false;
      for (ShaderPassPlan.Pass pass : passes) {
        if (!pass.hook.equals("MAIN") && !pass.hook.equals("PREKERNEL")) throw new IllegalArgumentException("Unsupported shader hook");
        if (prekernel && pass.hook.equals("MAIN")) throw new IllegalArgumentException("MAIN must precede PREKERNEL");
        prekernel |= pass.hook.equals("PREKERNEL");
        known.add("HOOKED");
        known.add(pass.hook);
        if (!pass.save.matches("[A-Za-z_][A-Za-z0-9_]*") || pass.save.equals("NATIVE") || pass.save.equals("OUTPUT")) throw new IllegalArgumentException("Invalid saved texture name");
        String source = sources.getString(pass.asset);
        if (source.trim().isEmpty()) throw new IllegalArgumentException("Empty shader source: " + pass.asset);
        loaded.put(pass.asset, source);
        Set<String> bindings = new HashSet<>();
        for (ShaderPassPlan.Binding binding : pass.bindings) {
          if (!known.contains(binding.name) || binding.name.equals("OUTPUT") || !bindings.add(binding.name)) throw new IllegalArgumentException("Invalid shader binding: " + binding.name);
        }
        validateExpression(pass.width, known);
        validateExpression(pass.height, known);
        validateExpression(pass.condition, known);
        known.add(pass.save);
      }
      shaders = Collections.unmodifiableMap(loaded);
    } catch (JSONException e) {
      throw new IllegalArgumentException("Invalid shader bundle", e);
    }
  }

  private static void validateExpression(String expression, Set<String> known) {
    int depth = 0;
    for (String token : expression.trim().split("\\s+")) {
      if (token.length() == 1 && "+-*/><".contains(token)) {
        if (depth < 2) throw new IllegalArgumentException("Invalid shader expression: " + expression);
        depth--;
      } else {
        if (token.endsWith(".w") || token.endsWith(".h")) {
          if (!known.contains(token.substring(0, token.length() - 2))) throw new IllegalArgumentException("Unknown shader dimension: " + token);
        } else if (!Float.isFinite(Float.parseFloat(token))) {
          throw new IllegalArgumentException("Non-finite shader expression");
        }
        depth++;
      }
    }
    if (depth != 1) throw new IllegalArgumentException("Invalid shader expression: " + expression);
  }
}
