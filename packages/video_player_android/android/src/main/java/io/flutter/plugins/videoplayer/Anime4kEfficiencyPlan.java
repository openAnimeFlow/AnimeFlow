// Copyright 2026 The AnimeFlow Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license in the LICENSE file.
package io.flutter.plugins.videoplayer;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/** Restricted MPV hook planner for the bundled preset; independent of GL and playback timing. */
final class Anime4kEfficiencyPlan {
  static final class Binding {
    final String name;
    final boolean sampler;
    final boolean dimensions;

    Binding(JSONObject json) throws JSONException {
      name = json.getString("name");
      sampler = json.getBoolean("sampler");
      dimensions = json.getBoolean("dimensions");
    }
  }

  static final class Pass {
    final String asset, source, hook, save, width, height, condition;
    final List<Binding> bindings = new ArrayList<>();

    Pass(JSONObject json) throws JSONException {
      asset = json.getString("asset");
      source = json.getString("source");
      hook = json.getString("hook");
      save = json.getString("save");
      width = json.getString("width");
      height = json.getString("height");
      condition = json.getString("when");
      JSONArray list = json.getJSONArray("bindings");
      for (int i = 0; i < list.length(); i++) bindings.add(new Binding(list.getJSONObject(i)));
    }
  }

  static final class Node {
    final int width, height;
    int uses;
    int slot = -1;

    Node(int width, int height) {
      this.width = width;
      this.height = height;
    }
  }

  static final class Step {
    final Pass pass;
    final Node[] inputs;
    final Node output;

    Step(Pass pass, Node[] inputs, Node output) {
      this.pass = pass;
      this.inputs = inputs;
      this.output = output;
    }
  }

  final List<Step> steps = new ArrayList<>();
  final List<Node> slots = new ArrayList<>();
  final Node result;

  static List<Pass> parse(String json) throws JSONException {
    JSONArray array = new JSONArray(json);
    List<Pass> passes = new ArrayList<>();
    for (int i = 0; i < array.length(); i++) passes.add(new Pass(array.getJSONObject(i)));
    return passes;
  }

  Anime4kEfficiencyPlan(
      List<Pass> passes, int width, int height, int outputWidth, int outputHeight) {
    if (width <= 0 || height <= 0 || outputWidth <= 0 || outputHeight <= 0) {
      throw new IllegalArgumentException("Video and output dimensions must be positive");
    }
    Map<String, Node> saved = new HashMap<>();
    Node original = new Node(width, height);
    saved.put("NATIVE", original);
    saved.put("MAIN", original);
    saved.put("OUTPUT", new Node(outputWidth, outputHeight));
    for (Pass pass : passes) {
      // HOOKED and the current hook name refer to the latest MAIN image at this stage.
      saved.put("HOOKED", saved.get("MAIN"));
      saved.put(pass.hook, saved.get("MAIN"));
      if (evaluate(pass.condition, saved) == 0) continue;
      Node[] inputs = new Node[pass.bindings.size()];
      for (int i = 0; i < inputs.length; i++) {
        inputs[i] = saved.get(pass.bindings.get(i).name);
        if (inputs[i] == null) throw new IllegalArgumentException("Missing shader input");
        inputs[i].uses++;
      }
      Node output = new Node(dimension(pass.width, saved), dimension(pass.height, saved));
      steps.add(new Step(pass, inputs, output));
      String name = pass.save;
      if (name.equals("HOOKED") || name.equals("PREKERNEL")) name = "MAIN";
      saved.put(name, output);
    }
    result = saved.get("MAIN");
    result.uses++;
    // Allocate non-overlapping lifetimes to reusable, same-sized render targets.
    List<Integer> free = new ArrayList<>();
    for (Step step : steps) {
      Node node = step.output;
      for (int i = 0; i < free.size(); i++) {
        Node slot = slots.get(free.get(i));
        if (slot.width == node.width && slot.height == node.height) {
          node.slot = free.remove(i);
          break;
        }
      }
      if (node.slot < 0) {
        node.slot = slots.size();
        slots.add(node);
      }
      for (Node input : step.inputs) {
        if (--input.uses == 0 && input != original) free.add(input.slot);
      }
      if (node.uses == 0) free.add(node.slot);
    }
  }

  private static int dimension(String expression, Map<String, Node> saved) {
    float value = evaluate(expression, saved);
    if (!Float.isFinite(value) || value < .5f || value > Integer.MAX_VALUE / 2f) {
      throw new IllegalArgumentException("Invalid shader dimensions: " + expression);
    }
    return Math.round(value); // MPV uses lroundf for positive FBO dimensions.
  }

  static float evaluate(String expression, Map<String, Node> saved) {
    List<Float> stack = new ArrayList<>();
    for (String token : expression.trim().split("\\s+")) {
      if ("+-*/><".contains(token) && token.length() == 1) {
        float b = stack.remove(stack.size() - 1), a = stack.remove(stack.size() - 1);
        switch (token) {
          case "+":
            stack.add(a + b);
            break;
          case "-":
            stack.add(a - b);
            break;
          case "*":
            stack.add(a * b);
            break;
          case "/":
            stack.add(a / b);
            break;
          case ">":
            stack.add(a > b ? 1f : 0f);
            break;
          case "<":
            stack.add(a < b ? 1f : 0f);
            break;
          default:
            throw new IllegalArgumentException(token);
        }
      } else if (token.endsWith(".w") || token.endsWith(".h")) {
        Node image = saved.get(token.substring(0, token.length() - 2));
        if (image == null) throw new IllegalArgumentException("Unknown shader size: " + token);
        stack.add((float) (token.endsWith(".w") ? image.width : image.height));
      } else {
        stack.add(Float.parseFloat(token));
      }
    }
    if (stack.size() != 1)
      throw new IllegalArgumentException("Invalid shader expression: " + expression);
    return stack.get(0);
  }
}
