package io.flutter.plugins.videoplayer;

import static org.junit.Assert.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.json.JSONArray;
import org.json.JSONObject;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;

/** Generic graph semantics; all fixtures are defined here, with no application assets. */
@RunWith(RobolectricTestRunner.class)
public class ShaderPassPlanTest {
  private JSONObject pass(String save, String... inputs) throws Exception {
    JSONArray bindings = new JSONArray();
    for (String input : inputs) {
      bindings.put(
          new JSONObject().put("name", input).put("sampler", true).put("dimensions", true));
    }
    return new JSONObject()
        .put("asset", "copy")
        .put("hook", "MAIN")
        .put("save", save)
        .put("width", "HOOKED.w")
        .put("height", "HOOKED.h")
        .put("when", "1")
        .put("bindings", bindings);
  }

  private List<ShaderPassPlan.Pass> passes(JSONObject... descriptors) throws Exception {
    JSONArray array = new JSONArray();
    for (JSONObject descriptor : descriptors) array.put(descriptor);
    return ShaderPassPlan.parse(array.toString());
  }

  @Test
  public void strictConditionsRequireBothOutputAxes() throws Exception {
    List<ShaderPassPlan.Pass> graph =
        passes(
            pass("HOOKED", "MAIN")
                .put("when", "OUTPUT.w NATIVE.w 1.2 * > OUTPUT.h NATIVE.h 1.2 * > *"));
    assertEquals(0, new ShaderPassPlan(graph, 100, 100, 120, 121).steps.size());
    assertEquals(0, new ShaderPassPlan(graph, 100, 100, 121, 120).steps.size());
    assertEquals(1, new ShaderPassPlan(graph, 100, 100, 121, 121).steps.size());
  }

  @Test
  public void dimensionsRoundPositiveHalvesUp() throws Exception {
    ShaderPassPlan plan =
        new ShaderPassPlan(
            passes(
                pass("HOOKED", "MAIN").put("width", "OUTPUT.w 2 /").put("height", "OUTPUT.h 2 /")),
            100,
            80,
            301,
            241);
    assertEquals(151, plan.result.width);
    assertEquals(121, plan.result.height);
  }

  @Test
  public void hooksFollowMainWhileNativeKeepsOriginalDimensions() throws Exception {
    ShaderPassPlan plan =
        new ShaderPassPlan(
            passes(
                pass("HOOKED", "MAIN").put("width", "MAIN.w 2 *"),
                pass("PREKERNEL", "HOOKED", "NATIVE")
                    .put("hook", "PREKERNEL")
                    .put("width", "PREKERNEL.w")
                    .put("height", "NATIVE.h")),
            4,
            3,
            8,
            6);
    assertEquals(8, plan.result.width);
    assertEquals(3, plan.result.height);
    assertSame(plan.steps.get(0).output, plan.steps.get(1).inputs[0]);
    assertEquals(-1, plan.steps.get(1).inputs[1].slot);
  }

  @Test
  public void skippedPassReturnsOriginalAndCannotSupplyNewBindings() throws Exception {
    JSONObject skipped = pass("FEATURE", "MAIN").put("when", "0");
    ShaderPassPlan plan = new ShaderPassPlan(passes(skipped), 4, 3, 8, 6);
    assertTrue(plan.steps.isEmpty());
    assertEquals(-1, plan.result.slot);
    List<ShaderPassPlan.Pass> invalid = passes(skipped, pass("MAIN", "FEATURE"));
    assertThrows(IllegalArgumentException.class, () -> new ShaderPassPlan(invalid, 4, 3, 8, 6));
  }

  @Test
  public void slotsAreReusedOnlyAfterTheLastReadAndMatchDimensions() throws Exception {
    ShaderPassPlan plan =
        new ShaderPassPlan(
            passes(
                pass("FEATURE", "MAIN"),
                pass("TEMP", "FEATURE"),
                pass("MAIN", "FEATURE", "TEMP"),
                pass("UNUSED", "NATIVE"),
                pass("UNUSED_LARGE", "NATIVE").put("width", "NATIVE.w 2 *")),
            4,
            3,
            8,
            6);
    Map<ShaderPassPlan.Node, Integer> lastRead = new HashMap<>();
    for (int i = 0; i < plan.steps.size(); i++) {
      for (ShaderPassPlan.Node input : plan.steps.get(i).inputs) lastRead.put(input, i);
    }
    lastRead.put(plan.result, plan.steps.size());
    for (int i = 0; i < plan.steps.size(); i++) {
      ShaderPassPlan.Step step = plan.steps.get(i);
      for (ShaderPassPlan.Node input : step.inputs) assertNotEquals(input.slot, step.output.slot);
      for (int j = 0; j < i; j++) {
        ShaderPassPlan.Node previous = plan.steps.get(j).output;
        if (previous.slot == step.output.slot) {
          assertTrue(lastRead.getOrDefault(previous, j) < i);
          assertEquals(previous.width, step.output.width);
          assertEquals(previous.height, step.output.height);
        }
      }
    }
    assertEquals(
        4, plan.slots.size()); // Two live inputs, their result, and a different-sized target.
  }

  @Test
  public void nonFiniteDimensionsAreRejected() throws Exception {
    List<ShaderPassPlan.Pass> graph = passes(pass("MAIN", "MAIN").put("width", "1 0 /"));
    assertThrows(IllegalArgumentException.class, () -> new ShaderPassPlan(graph, 4, 3, 8, 6));
  }
}
