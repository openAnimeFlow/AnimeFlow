// Native shader test helpers; synthetic sources and buffers only.
#pragma once
#import <Metal/Metal.h>
#import "FVPMetalVideoEffect.h"
#import "FVPShaderBundle.h"

static inline void Check(BOOL condition, NSString *message) {
  if (!condition) {
    NSLog(@"FAIL: %@", message);
    exit(1);
  }
}

static inline NSString *JSON(id object) {
  return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:object
                                                                        options:0
                                                                          error:nil]
                               encoding:NSUTF8StringEncoding];
}

static inline NSMutableDictionary *Pass(NSString *asset, NSString *save) {
  return [@{
    @"asset" : asset,
    @"hook" : @"MAIN",
    @"save" : save,
    @"width" : @"HOOKED.w",
    @"height" : @"HOOKED.h",
    @"when" : @"1",
    @"bindings" : @[
      @{@"name" : @"MAIN",
        @"sampler" : @YES,
        @"dimensions" : @YES}
    ]
  } mutableCopy];
}

static inline NSString *Shader(NSString *body) {
  return [@"#include <metal_stdlib>\nusing namespace metal;\n"
           "struct VideoVertex { float4 position [[position]]; float2 uv; };\n"
           "fragment float4 videoFragment(VideoVertex in [[stage_in]], constant float2 *sizes "
           "[[buffer(0)]],\n"
           "texture2d<float> input [[texture(0)]]) {\n"
           "constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear);\n"
      stringByAppendingFormat:@"%@\n}\n", body];
}

static inline NSString *Bundle(NSArray *passes, NSDictionary *shaders) {
  return JSON(@{@"version" : @1, @"passes" : passes, @"shaders" : shaders});
}

static inline NSString *Configuration(NSString *effect, NSString *bundle, NSInteger width,
                                      NSInteger height) {
  return JSON(@{
    @"effect" : effect,
    @"shaderBundle" : bundle ?: (id)NSNull.null,
    @"outputWidth" : width ? @(width) : (id)NSNull.null,
    @"outputHeight" : height ? @(height) : (id)NSNull.null
  });
}

static inline FVPShaderBundle *Parse(NSString *encoded) {
  NSError *error = nil;
  FVPShaderBundle *bundle = [[FVPShaderBundle alloc] initWithEncoded:encoded error:&error];
  Check(bundle != nil, error.localizedDescription);
  return bundle;
}

static inline CVPixelBufferRef Input(uint8_t red, uint8_t green, uint8_t blue) {
  CVPixelBufferRef buffer = NULL;
  NSDictionary *attributes = @{
    (id)kCVPixelBufferIOSurfacePropertiesKey : @{},
    (id)kCVPixelBufferMetalCompatibilityKey : @YES
  };
  Check(CVPixelBufferCreate(NULL, 2, 2, kCVPixelFormatType_32BGRA,
                            (__bridge CFDictionaryRef)attributes, &buffer) == kCVReturnSuccess,
        @"Input allocation");
  CVPixelBufferLockBaseAddress(buffer, 0);
  for (int y = 0; y < 2; y++) {
    uint8_t *row = CVPixelBufferGetBaseAddress(buffer) + y * CVPixelBufferGetBytesPerRow(buffer);
    for (int x = 0; x < 2; x++) {
      row[x * 4] = blue;
      row[x * 4 + 1] = green;
      row[x * 4 + 2] = red;
      row[x * 4 + 3] = 255;
    }
  }
  CVPixelBufferUnlockBaseAddress(buffer, 0);
  return buffer;
}

static inline void Pixels(CVPixelBufferRef buffer, int red, int green, int blue) {
  CVPixelBufferLockBaseAddress(buffer, kCVPixelBufferLock_ReadOnly);
  for (size_t y = 0; y < CVPixelBufferGetHeight(buffer); y++) {
    uint8_t *row = CVPixelBufferGetBaseAddress(buffer) + y * CVPixelBufferGetBytesPerRow(buffer);
    for (size_t x = 0; x < CVPixelBufferGetWidth(buffer); x++) {
      Check(abs(row[x * 4] - blue) <= 1 && abs(row[x * 4 + 1] - green) <= 1 &&
                abs(row[x * 4 + 2] - red) <= 1 && row[x * 4 + 3] == 255,
            @"Rendered pixel mismatch");
    }
  }
  CVPixelBufferUnlockBaseAddress(buffer, kCVPixelBufferLock_ReadOnly);
}

static inline CVPixelBufferRef Render(FVPMetalVideoEffect *effect, CVPixelBufferRef input,
                                      NSString *configuration) {
  NSError *error = nil;
  Check([effect setConfiguration:configuration error:&error], error.localizedDescription);
  __block BOOL done = NO;
  effect.onFrameAvailable = ^{
    done = YES;
  };
  effect.onError = ^(NSString *message) {
    Check(NO, message);
  };
  CVPixelBufferRelease([effect copyPixelBuffer:input]);
  NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:60];
  while (!done && deadline.timeIntervalSinceNow > 0) {
    [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.005]];
  }
  Check(done, @"GPU processing completed");
  return [effect copyPixelBuffer:input];
}

static inline void RequireMetalDevice(void) {
  id<MTLDevice> device = MTLCreateSystemDefaultDevice();
  Check(device != nil,
        @"A Metal GPU is required; use a GPU-enabled macOS runner. GPU tests cannot be skipped.");
  NSLog(@"Testing Metal GPU: %@", device.name);
}
