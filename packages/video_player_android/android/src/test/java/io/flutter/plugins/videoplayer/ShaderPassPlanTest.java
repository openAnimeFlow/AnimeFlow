package io.flutter.plugins.videoplayer;

import static org.junit.Assert.*;

import androidx.media3.common.util.Util;
import androidx.test.core.app.ApplicationProvider;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;

@RunWith(RobolectricTestRunner.class)
public class ShaderPassPlanTest {
  private List<ShaderPassPlan.Pass> passes;

  @Before
  public void setUp() throws Exception {
    passes =
        ShaderPassPlan.parse(
            new String(getClass().getClassLoader().getResourceAsStream("efficiency.json").readAllBytes(), java.nio.charset.StandardCharsets.UTF_8));
  }

  private ShaderPassPlan plan(int output) {
    return new ShaderPassPlan(passes, 100, 100, output, output);
  }

  private long count(ShaderPassPlan plan, String source) {
    return plan.steps.stream()
        .filter(s -> s.pass.source.equals("Anime4K_" + source + ".glsl"))
        .count();
  }

  @Test
  public void exactThresholdsRespectStrictMpvConditions() {
    for (int target : new int[] {60, 100, 120, 121, 150, 199, 200, 240, 241, 300, 399, 400, 500}) {
      ShaderPassPlan p = plan(target);
      assertEquals(8, count(p, "Restore_CNN_M"));
      assertEquals(4, count(p, "Restore_CNN_S"));
      assertEquals(3, count(p, "Clamp_Highlights"));
      assertEquals(target > 120 ? 9 : 0, count(p, "Upscale_CNN_x2_M"));
      assertEquals(target > 120 && target < 200 ? 1 : 0, count(p, "AutoDownscalePre_x2"));
      assertEquals(target > 240 && target < 400 ? 1 : 0, count(p, "AutoDownscalePre_x4"));
      assertEquals(target > 240 ? 5 : 0, count(p, "Upscale_CNN_x2_S"));
      assertEquals("PREKERNEL", p.steps.get(p.steps.size() - 1).pass.hook);
    }
  }

  @Test
  public void bothAxesMustMeetUpscalingConditions() {
    ShaderPassPlan p = new ShaderPassPlan(passes, 100, 100, 200, 120);
    assertEquals(0, count(p, "Upscale_CNN_x2_M"));
    assertEquals(0, count(p, "Upscale_CNN_x2_S"));
  }

  @Test
  public void oddOutputDimensionsRoundLikeMpv() {
    ShaderPassPlan p = new ShaderPassPlan(passes, 100, 80, 301, 241);
    ShaderPassPlan.Step downscale =
        p.steps.stream()
            .filter(s -> s.pass.source.contains("AutoDownscalePre_x4"))
            .findFirst()
            .get();
    assertEquals(151, downscale.output.width);
    assertEquals(121, downscale.output.height);
    assertEquals(302, p.result.width);
    assertEquals(242, p.result.height);
  }

  @Test
  public void textureLifetimesNeverOverwriteAnInputAndMModelKeepsAllFeatures() {
    for (int target : new int[] {100, 150, 200, 300, 500}) {
      ShaderPassPlan p = plan(target);
      for (ShaderPassPlan.Step step : p.steps) {
        Set<Integer> inputs = new HashSet<>();
        for (ShaderPassPlan.Node input : step.inputs) {
          assertNotEquals(step.output.slot, input.slot);
          inputs.add(input.slot);
        }
        if (step.pass.source.equals("Anime4K_Restore_CNN_M.glsl")
            && step.pass.save.equals("MAIN")) {
          assertEquals(8, inputs.size()); // Seven features plus the original RGB residual.
        }
      }
    }
  }
}
