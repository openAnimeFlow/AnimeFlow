// Standalone plugin tests; no application resources or Flutter host are required.
#import "ShaderTestSupport.h"

static void TestPlans(void) {
  NSMutableDictionary *a = Pass(@"a", @"UNUSED");
  NSMutableDictionary *b = Pass(@"b", @"HOOKED");
  FVPShaderBundle *bundle = Parse(Bundle(@[ a, b ], @{@"a" : @"source", @"b" : @"source"}));
  NSError *error = nil;
  FVPShaderPlan *plan = [bundle planForWidth:2 height:3 outputWidth:4 outputHeight:6 error:&error];
  Check(plan.slots.count == 1, @"Unused pass target is reused");
  Check(plan.result.width == 2 && plan.result.height == 3, @"Result follows MAIN");
  a[@"when"] = @"OUTPUT.w NATIVE.w >";
  a[@"width"] = @"NATIVE.w 2 *";
  b[@"bindings"] = @[ @{@"name" : @"UNUSED", @"sampler" : @YES, @"dimensions" : @NO} ];
  bundle = Parse(Bundle(@[ a, b ], @{@"a" : @"source", @"b" : @"source"}));
  Check([bundle planForWidth:2 height:3 outputWidth:2 outputHeight:3 error:&error] == nil,
        @"Skipped producer cannot be read");
  plan = [bundle planForWidth:2 height:3 outputWidth:4 outputHeight:6 error:&error];
  Check(plan.steps.count == 2 && plan.slots.count == 2, @"Input never aliases its destination");
  Check(plan.steps[0].output.width == 4, @"Postfix dimensions match Android");
  a[@"width"] = @"1 0 /";
  bundle = Parse(Bundle(@[ a ], @{@"a" : @"source"}));
  Check([bundle planForWidth:2 height:3 outputWidth:4 outputHeight:6 error:&error] == nil,
        @"Nonfinite evaluated sizes are rejected");
  a[@"width"] = @"MISSING.w";
  Check([[FVPShaderBundle alloc] initWithEncoded:Bundle(@[ a ], @{@"a" : @"source"})
                                           error:&error] == nil,
        @"Unknown dimension rejected before publication");
  NSLog(@"PASS: shader validation, conditional planning and slot reuse");
}

static void TestGPU(void) {
  RequireMetalDevice();
  NSString *redBundle =
      Bundle(@[ Pass(@"a", @"HOOKED") ], @{@"a" : Shader(@"return float4(1,0,0,1);")});
  NSString *redConfig = Configuration(@"shaderBundle", redBundle, 2, 2);
  NSError *error = nil;
  FVPMetalVideoEffect *effect = [[FVPMetalVideoEffect alloc] initWithConfiguration:redConfig
                                                                             error:&error];
  Check(effect != nil, error.localizedDescription);
  CVPixelBufferRef blue = Input(0, 0, 255), red = Input(255, 0, 0);
  CVPixelBufferRef held = Render(effect, blue, redConfig);
  Pixels(held, 255, 0, 0);  // Both sampler and sizes were optimized away.
  id compiled = [[effect valueForKey:@"programs"] objectForKey:@"a"];
  CVPixelBufferRef output = Render(effect, blue, Configuration(@"none", nil, 2, 2));
  Pixels(output, 0, 0, 255);
  CVPixelBufferRelease(output);
  Check([[effect valueForKey:@"targets"] count] == 0, @"Off frees intermediates");
  output = Render(effect, blue, Configuration(@"shaderBundle", redBundle, 4, 4));
  Check(CVPixelBufferGetWidth(output) == 4, @"Re-enable resizes output");
  Check([[effect valueForKey:@"programs"] objectForKey:@"a"] == compiled,
        @"Re-enable reuses compiled programs");
  Pixels(output, 255, 0, 0);
  CVPixelBufferRelease(output);
  NSString *sizes =
      Bundle(@[ Pass(@"a", @"HOOKED") ], @{@"a" : Shader(@"return float4(sizes[0] / 2.0, 0, 1);")});
  output = Render(effect, blue, Configuration(@"shaderBundle", sizes, 2, 2));
  Pixels(output, 255, 255, 0);
  CVPixelBufferRelease(output);  // Unused sampler is harmless.
  Pixels(held, 255, 0, 0);
  CVPixelBufferRelease(held);  // Flutter's retained output wasn't overwritten.
  NSString *discard =
      Shader(@"if (input.sample(s, in.uv).b > 0.5) discard_fragment(); return float4(1,0,0,1);");
  NSString *discardBundle = Bundle(@[ Pass(@"a", @"HOOKED") ], @{@"a" : discard});
  NSString *discardConfig = Configuration(@"shaderBundle", discardBundle, 2, 2);
  output = Render(effect, red, discardConfig);
  Pixels(output, 255, 0, 0);
  CVPixelBufferRelease(output);
  output = Render(effect, blue, discardConfig);
  Pixels(output, 0, 0, 0);
  CVPixelBufferRelease(output);
  NSString *reuse = Bundle(@[ Pass(@"a", @"UNUSED"), Pass(@"b", @"HOOKED") ],
                           @{@"a" : Shader(@"return float4(1,0,0,1);"), @"b" : discard});
  output = Render(effect, blue, Configuration(@"shaderBundle", reuse, 2, 2));
  Pixels(output, 0, 0, 0);
  CVPixelBufferRelease(output);
  Check([[effect valueForKey:@"targets"] count] == 1, @"Discard test used a recycled target");
  [effect dispose];
  Check(![effect setConfiguration:redConfig error:&error], @"Disposed pipeline rejects updates");
  CVPixelBufferRelease(red);
  CVPixelBufferRelease(blue);
  NSLog(@"PASS: Metal uniforms, discard, pool ownership, lifecycle and resize");
}

int main(void) {
  @autoreleasepool {
    TestPlans();
    TestGPU();
  }
  return 0;
}
