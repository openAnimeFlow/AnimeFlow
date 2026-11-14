package io.flutter.plugins.videoplayer;

import static org.junit.Assert.*;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.json.JSONObject;

@RunWith(RobolectricTestRunner.class)
public class ShaderBundleTest {
  @Test public void rejectsUnknownVersionMissingSourcesAndInvalidGraph() throws Exception {
    JSONObject json = new JSONObject(ShaderFixtures.copy());
    assertThrows(IllegalArgumentException.class, () -> new ShaderBundle(json.put("version", 2).toString()));
    json.put("version", 1);
    json.getJSONObject("shaders").remove("copy");
    assertThrows(IllegalArgumentException.class, () -> new ShaderBundle(json.toString()));
    JSONObject graph = new JSONObject(ShaderFixtures.copy());
    graph.getJSONArray("passes").getJSONObject(0).put("width", "MAIN.w +");
    assertThrows(IllegalArgumentException.class, () -> new ShaderBundle(graph.toString()));
    graph.getJSONArray("passes").getJSONObject(0).put("width", "missing.w");
    assertThrows(IllegalArgumentException.class, () -> new ShaderBundle(graph.toString()));
  }

  @Test public void allSkippedPassesReturnTheOriginalTexture() throws Exception {
    JSONObject json = new JSONObject(ShaderFixtures.copy());
    json.getJSONArray("passes").getJSONObject(0).put("when", "0");
    ShaderBundle bundle = new ShaderBundle(json.toString());
    ShaderPassPlan plan = new ShaderPassPlan(bundle.passes, 16, 9, 32, 18);
    assertTrue(plan.steps.isEmpty());
    assertEquals(-1, plan.result.slot);
  }

  @Test public void replacementUsesContentAndBadConfigurationDoesNotPublish() {
    ShaderBundle first = new ShaderBundle(ShaderFixtures.copy());
    ShaderBundle second = new ShaderBundle(ShaderFixtures.copy().replace("vec4(1.0)", "vec4(0.5)"));
    SwitchableVideoEffect effect = new SwitchableVideoEffect(PlatformVideoEffect.NONE);
    effect.setConfiguration(PlatformVideoEffect.SHADER_BUNDLE, 32, 18, first);
    effect.setConfiguration(PlatformVideoEffect.SHADER_BUNDLE, 32, 18, second);
    assertSame(second, effect.getConfiguration().bundle);
    assertThrows(IllegalArgumentException.class, () -> effect.setConfiguration(PlatformVideoEffect.SHADER_BUNDLE, 32, 18, null));
    assertSame(second, effect.getConfiguration().bundle);
    effect.setConfiguration(PlatformVideoEffect.NONE, 32, 18, null);
    assertNull(effect.getConfiguration().bundle);
  }
}
