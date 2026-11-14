// Copyright 2026 The AnimeFlow Authors. All rights reserved.
// Use of this source code is governed by the BSD license in the LICENSE file.

#import "./include/video_player_avfoundation_objc/FVPMetalVideoEffect.h"
#import <Metal/Metal.h>
#import <TargetConditionals.h>
#import <simd/simd.h>
#import "./include/video_player_avfoundation_objc/FVPShaderBundle.h"
#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#endif

@interface FVPEffectSettings : NSObject
@property(nonatomic, copy) NSString *effect;
@property(nonatomic) NSInteger width;
@property(nonatomic) NSInteger height;
@property(nonatomic, strong, nullable) FVPShaderBundle *bundle;
@end
@implementation FVPEffectSettings
@end

@interface FVPEffectFrame : NSObject
@property(nonatomic, assign) CVPixelBufferRef buffer;
@property(nonatomic, strong) FVPEffectSettings *settings;
@end
@implementation FVPEffectFrame
- (void)dealloc {
  CVPixelBufferRelease(_buffer);
}
@end

// Coordinates have their origin at the top-left in both CVPixelBuffer and Metal. All passes
// use the same convention, including the depth-to-space shaders; no per-pass Y flip is needed.
static NSString *const VertexSource =
    @"#include <metal_stdlib>\nusing namespace metal;\n"
     "struct Vertex { float4 position [[position]]; float2 uv; };\n"
     "vertex Vertex videoVertex(uint id [[vertex_id]]) {\n"
     "  float2 uv = float2((id << 1) & 2, id & 2);\n"
     "  return {float4(uv.x * 2 - 1, 1 - uv.y * 2, 0, 1), uv};\n}\n"
     "fragment float4 videoCopy(Vertex in [[stage_in]], texture2d<float> image [[texture(0)]],\n"
     "                         constant bool &gray [[buffer(0)]]) {\n"
     "  constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear);\n"
     "  float3 rgb = image.sample(s, in.uv).rgb;\n"
     "  if (gray) rgb = float3(dot(rgb, float3(0.2126, 0.7152, 0.0722)));\n"
     "  return float4(clamp(rgb, 0.0, 1.0), 1.0);\n}\n";

@implementation FVPMetalVideoEffect {
  // Accessed only under @synchronized(self).
  FVPEffectSettings *_settings;
  FVPEffectSettings *_failedSettings;
  FVPEffectFrame *_lastSubmitted;
  FVPEffectFrame *_pending;
  CVPixelBufferRef _output;
  BOOL _running, _disposed, _suspended;
  id<MTLCommandBuffer> _inFlight;
  id _suspendObserver, _resumeObserver;
  // Accessed only on _queue (or in dealloc after its work has finished).
  dispatch_queue_t _queue;
  id<MTLDevice> _device;
  id<MTLCommandQueue> _commands;
  id<MTLFunction> _vertex;
  id<MTLRenderPipelineState> _copy;
  CVMetalTextureCacheRef _cache;
  CVPixelBufferPoolRef _pool;
  NSInteger _poolWidth, _poolHeight;
  FVPShaderBundle *_compiledBundle;
  NSMutableDictionary<NSString *, id<MTLRenderPipelineState>> *_programs;
  FVPShaderPlan *_plan;
  NSArray<id<MTLTexture>> *_targets;
  NSInteger _inputWidth, _inputHeight, _outputWidth, _outputHeight;
}

- (instancetype)initWithConfiguration:(NSString *)configuration error:(NSError **)error {
  self = [super init];
  if (self) {
    _queue = dispatch_queue_create("dev.flutter.video_player.metal", DISPATCH_QUEUE_SERIAL);
    _programs = [NSMutableDictionary dictionary];
    if (![self setConfiguration:configuration error:error]) return nil;
#if TARGET_OS_IOS
    _suspended = UIApplication.sharedApplication.applicationState != UIApplicationStateActive;
    __weak FVPMetalVideoEffect *weakSelf = self;
    _suspendObserver = [NSNotificationCenter.defaultCenter
        addObserverForName:UIApplicationWillResignActiveNotification
                    object:nil
                     queue:NSOperationQueue.mainQueue
                usingBlock:^(NSNotification *note) {
                  [weakSelf setSuspended:YES];
                }];
    _resumeObserver = [NSNotificationCenter.defaultCenter
        addObserverForName:UIApplicationDidBecomeActiveNotification
                    object:nil
                     queue:NSOperationQueue.mainQueue
                usingBlock:^(NSNotification *note) {
                  [weakSelf setSuspended:NO];
                }];
#endif
  }
  return self;
}

- (BOOL)setConfiguration:(NSString *)configuration error:(NSError **)error {
  id json =
      [NSJSONSerialization JSONObjectWithData:[configuration dataUsingEncoding:NSUTF8StringEncoding]
                                      options:0
                                        error:error];
  if (![json isKindOfClass:NSDictionary.class] ||
      ![@[ @"none", @"debugGrayscale", @"shaderBundle" ] containsObject:json[@"effect"] ?: @""]) {
    if (error) *error = FVPShaderError(@"Invalid video effect configuration");
    return NO;
  }
  id width = json[@"outputWidth"], height = json[@"outputHeight"], encoded = json[@"shaderBundle"];
  if (width == NSNull.null) width = nil;
  if (height == NSNull.null) height = nil;
  if (encoded == NSNull.null) encoded = nil;
  BOOL custom = [json[@"effect"] isEqual:@"shaderBundle"];
  if ((width != nil) != (height != nil) ||
      (width && (![width isKindOfClass:NSNumber.class] || ![height isKindOfClass:NSNumber.class] ||
                 [width doubleValue] != [width integerValue] ||
                 [height doubleValue] != [height integerValue] || [width integerValue] <= 0 ||
                 [height integerValue] <= 0 || [width doubleValue] > INT_MAX ||
                 [height doubleValue] > INT_MAX)) ||
      custom != (encoded != nil) || (encoded && ![encoded isKindOfClass:NSString.class])) {
    if (error) *error = FVPShaderError(@"Invalid output dimensions or shader bundle configuration");
    return NO;
  }
  FVPEffectSettings *next = [[FVPEffectSettings alloc] init];
  next.effect = json[@"effect"];
  next.width = [width integerValue];
  next.height = [height integerValue];
  @synchronized(self) {
    if (_disposed) {
      if (error) *error = FVPShaderError(@"Video effect pipeline is disposed");
      return NO;
    }
    if (custom) {
      next.bundle = [_settings.bundle.encoded isEqual:encoded]
                        ? _settings.bundle
                        : [[FVPShaderBundle alloc] initWithEncoded:encoded error:error];
      if (!next.bundle) return NO;
    }
    if ([_settings.effect isEqual:next.effect] && _settings.width == next.width &&
        _settings.height == next.height && _settings.bundle == next.bundle)
      return YES;
    _settings = next;
    _failedSettings = nil;
  }
  return YES;
}

- (CVPixelBufferRef)copyPixelBuffer:(CVPixelBufferRef)source {
  @synchronized(self) {
    if (!_disposed && !_suspended && _settings != _failedSettings &&
        (source != _lastSubmitted.buffer || _settings != _lastSubmitted.settings)) {
      FVPEffectFrame *frame = [[FVPEffectFrame alloc] init];
      frame.buffer = CVPixelBufferRetain(source);
      frame.settings = _settings;
      _pending = frame;  // Replace, rather than queue, obsolete input when the GPU falls behind.
      _lastSubmitted = frame;
      if (!_running) {
        _running = YES;
        dispatch_async(_queue, ^{
          [self drainFrames];
        });
      }
    }
    return CVPixelBufferRetain(_output ?: source);
  }
}

- (void)drainFrames {
  while (YES) {
    @autoreleasepool {
      FVPEffectFrame *frame;
      @synchronized(self) {
        frame = _pending;
        _pending = nil;
        if (!frame || _disposed || _suspended) {
          _running = NO;
          return;
        }
      }
      NSError *error = nil;
      CVPixelBufferRef output = [self renderFrame:frame error:&error];
      @synchronized(self) {
        if (!_disposed && !_suspended && frame.settings == _settings) {
          if (output) {
            CVPixelBufferRelease(_output);
            _output = CVPixelBufferRetain(output);
          }
          FVPEffectSettings *settings = frame.settings;
          dispatch_async(dispatch_get_main_queue(), ^{
            @synchronized(self) {
              if (self->_disposed || self->_suspended || settings != self->_settings) return;
              if (error) {
                if (self.onError) self.onError(error.localizedDescription);
              } else if (self.onFrameAvailable) {
                self.onFrameAvailable();
              }
            }
          });
          // Do not retry a permanently failing bundle on every video frame. A new valid
          // configuration can recover; normal playback continues with the last good output.
          if (error) {
            _pending = nil;
            _failedSettings = frame.settings;
          }
        }
      }
      CVPixelBufferRelease(output);
    }
  }
}

- (id<MTLRenderPipelineState>)pipeline:(id<MTLFunction>)fragment
                                format:(MTLPixelFormat)format
                                 error:(NSError **)error {
  MTLRenderPipelineDescriptor *descriptor = [[MTLRenderPipelineDescriptor alloc] init];
  descriptor.vertexFunction = _vertex;
  descriptor.fragmentFunction = fragment;
  descriptor.colorAttachments[0].pixelFormat = format;
  return [_device newRenderPipelineStateWithDescriptor:descriptor error:error];
}

- (BOOL)prepareDevice:(NSError **)error {
  if (_copy) return YES;
  if (_cache) {
    CFRelease(_cache);
    _cache = NULL;
  }
  _device = MTLCreateSystemDefaultDevice();
  _commands = [_device newCommandQueue];
  if (!_device || !_commands ||
      CVMetalTextureCacheCreate(kCFAllocatorDefault, NULL, _device, NULL, &_cache) !=
          kCVReturnSuccess) {
    if (error) *error = FVPShaderError(@"Metal is unavailable for video effects");
    return NO;
  }
  id<MTLLibrary> library = [_device newLibraryWithSource:VertexSource options:nil error:error];
  if (!library) return NO;
  _vertex = [library newFunctionWithName:@"videoVertex"];
  _copy = [self pipeline:[library newFunctionWithName:@"videoCopy"]
                  format:MTLPixelFormatBGRA8Unorm
                   error:error];
  return _copy != nil;
}

- (BOOL)configurePlan:(FVPEffectFrame *)frame
                width:(NSInteger)width
               height:(NSInteger)height
          outputWidth:(NSInteger)outputWidth
         outputHeight:(NSInteger)outputHeight
                error:(NSError **)error {
  FVPShaderBundle *bundle = frame.settings.bundle;
  if (!bundle) {
    _plan = nil;
    _targets = nil;  // Keep only the most recently compiled bundle across off/grayscale toggles.
    return YES;
  }
  if (![_compiledBundle.encoded isEqual:bundle.encoded]) {
    [_programs removeAllObjects];
    _compiledBundle = bundle;
    _plan = nil;
    _targets = nil;
  }
  if (_plan && _inputWidth == width && _inputHeight == height && _outputWidth == outputWidth &&
      _outputHeight == outputHeight)
    return YES;
  _plan = nil;
  _targets = nil;
  FVPShaderPlan *plan = [bundle planForWidth:width
                                      height:height
                                 outputWidth:outputWidth
                                outputHeight:outputHeight
                                       error:error];
  if (!plan) return NO;
  NSMutableArray *targets = [NSMutableArray array];
  for (FVPShaderNode *slot in plan.slots) {
    // iOS Metal families supported by this plugin allow at least 8192x8192 textures.
    if (slot.width > 8192 || slot.height > 8192) {
      if (error) *error = FVPShaderError(@"Shader intermediate exceeds the supported texture size");
      return NO;
    }
    MTLTextureDescriptor *descriptor =
        [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA16Float
                                                           width:slot.width
                                                          height:slot.height
                                                       mipmapped:NO];
    descriptor.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
    descriptor.storageMode = MTLStorageModePrivate;
    id<MTLTexture> texture = [_device newTextureWithDescriptor:descriptor];
    if (!texture) {
      if (error) *error = FVPShaderError(@"Unable to allocate shader intermediates");
      return NO;
    }
    [targets addObject:texture];
  }
  for (FVPShaderStep *step in plan.steps) {
    NSString *asset = step.pass[@"asset"];
    if (_programs[asset]) continue;
    MTLCompileOptions *options = [[MTLCompileOptions alloc] init];
    options.fastMathEnabled = NO;
    id<MTLLibrary> library = [_device newLibraryWithSource:bundle.shaders[asset]
                                                   options:options
                                                     error:error];
    if (!library) return NO;
    id<MTLFunction> fragment = [library newFunctionWithName:@"videoFragment"];
    if (!fragment) {
      if (error) *error = FVPShaderError(@"Metal shader must export videoFragment");
      return NO;
    }
    id<MTLRenderPipelineState> program = [self pipeline:fragment
                                                 format:MTLPixelFormatRGBA16Float
                                                  error:error];
    if (!program) return NO;
    _programs[asset] = program;
  }
  _plan = plan;
  _targets = targets;
  _inputWidth = width;
  _inputHeight = height;
  _outputWidth = outputWidth;
  _outputHeight = outputHeight;
  return YES;
}

- (CVMetalTextureRef)copyTexture:(CVPixelBufferRef)buffer usage:(MTLTextureUsage)usage {
  CVMetalTextureRef texture = NULL;
  NSDictionary *attributes = @{(id)kCVMetalTextureUsage : @(usage)};
  CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _cache, buffer,
                                            (__bridge CFDictionaryRef)attributes,
                                            MTLPixelFormatBGRA8Unorm, CVPixelBufferGetWidth(buffer),
                                            CVPixelBufferGetHeight(buffer), 0, &texture);
  return texture;
}

- (id<MTLRenderCommandEncoder>)encoderFor:(id<MTLTexture>)target
                                 commands:(id<MTLCommandBuffer>)commands {
  MTLRenderPassDescriptor *pass = [MTLRenderPassDescriptor renderPassDescriptor];
  pass.colorAttachments[0].texture = target;
  pass.colorAttachments[0].loadAction =
      MTLLoadActionClear;  // Discarded fragments never leak old pixels.
  pass.colorAttachments[0].storeAction = MTLStoreActionStore;
  pass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);
  return [commands renderCommandEncoderWithDescriptor:pass];
}

- (CVPixelBufferRef)renderFrame:(FVPEffectFrame *)frame
                          error:(NSError **)error CF_RETURNS_RETAINED {
  NSInteger width = CVPixelBufferGetWidth(frame.buffer),
            height = CVPixelBufferGetHeight(frame.buffer);
  NSInteger outWidth = frame.settings.width ?: width, outHeight = frame.settings.height ?: height;
  if (outWidth > 8192 || outHeight > 8192 || width > 8192 || height > 8192 ||
      CVPixelBufferGetPixelFormatType(frame.buffer) != kCVPixelFormatType_32BGRA) {
    if (error)
      *error = FVPShaderError(@"Video effects require BGRA SDR buffers and dimensions <= 8192");
    return NULL;
  }
  if (![self prepareDevice:error] || ![self configurePlan:frame
                                                    width:width
                                                   height:height
                                              outputWidth:outWidth
                                             outputHeight:outHeight
                                                    error:error])
    return NULL;
  if ([frame.settings.effect isEqual:@"none"] && outWidth == width && outHeight == height) {
    if (_pool) {
      CVPixelBufferPoolRelease(_pool);
      _pool = NULL;
    }
    return CVPixelBufferRetain(frame.buffer);
  }
  if (!_pool || _poolWidth != outWidth || _poolHeight != outHeight) {
    if (_pool) {
      CVPixelBufferPoolRelease(_pool);
      _pool = NULL;
    }
    NSDictionary *attributes = @{
      (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
      (id)kCVPixelBufferWidthKey : @(outWidth),
      (id)kCVPixelBufferHeightKey : @(outHeight),
      (id)kCVPixelBufferIOSurfacePropertiesKey : @{},
      (id)kCVPixelBufferMetalCompatibilityKey : @YES
    };
    CVPixelBufferPoolCreate(kCFAllocatorDefault, NULL, (__bridge CFDictionaryRef)attributes,
                            &_pool);
    _poolWidth = outWidth;
    _poolHeight = outHeight;
  }
  CVPixelBufferRef output = NULL;
  if (!_pool ||
      CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, _pool, &output) != kCVReturnSuccess) {
    if (error) *error = FVPShaderError(@"Unable to allocate effect output buffer");
    return NULL;
  }
  // Preserve color metadata; source geometry attachments must not be applied to resized output.
  for (NSString *key in @[
         (id)kCVImageBufferColorPrimariesKey, (id)kCVImageBufferTransferFunctionKey,
         (id)kCVImageBufferYCbCrMatrixKey
       ]) {
    CFTypeRef value = CVBufferGetAttachment(frame.buffer, (__bridge CFStringRef)key, NULL);
    if (value)
      CVBufferSetAttachment(output, (__bridge CFStringRef)key, value,
                            kCVAttachmentMode_ShouldPropagate);
  }
  CVMetalTextureRef inputView = [self copyTexture:frame.buffer usage:MTLTextureUsageShaderRead];
  CVMetalTextureRef outputView = [self copyTexture:output usage:MTLTextureUsageRenderTarget];
  id<MTLCommandBuffer> commands = [_commands commandBuffer];
  BOOL success = inputView && outputView && commands;
  BOOL cancelled = NO;
  if (success) {
    id<MTLTexture> input = CVMetalTextureGetTexture(inputView);
    for (FVPShaderStep *step in _plan.steps) {
      id<MTLRenderCommandEncoder> encoder = [self encoderFor:_targets[step.output.slot]
                                                    commands:commands];
      if (!encoder) {
        success = NO;
        break;
      }
      [encoder setRenderPipelineState:_programs[step.pass[@"asset"]]];
      // Manifest indices are stable even when the Metal compiler eliminates unused arguments.
      vector_float2 sizes[16] = {0};
      NSArray *bindings = step.pass[@"bindings"];
      for (NSUInteger i = 0; i < step.inputs.count; i++) {
        FVPShaderNode *node = step.inputs[i];
        sizes[i] = (vector_float2){node.width, node.height};
        if ([bindings[i][@"sampler"] boolValue]) {
          [encoder setFragmentTexture:node.slot < 0 ? input : _targets[node.slot] atIndex:i];
        }
      }
      [encoder setFragmentBytes:sizes length:sizeof(sizes) atIndex:0];
      [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
      [encoder endEncoding];
    }
    if (success) {
      id<MTLRenderCommandEncoder> encoder = [self encoderFor:CVMetalTextureGetTexture(outputView)
                                                    commands:commands];
      success = encoder != nil;
      [encoder setRenderPipelineState:_copy];
      id<MTLTexture> result = _plan && _plan.result.slot >= 0 ? _targets[_plan.result.slot] : input;
      [encoder setFragmentTexture:result atIndex:0];
      BOOL gray = [frame.settings.effect isEqual:@"debugGrayscale"];
      [encoder setFragmentBytes:&gray length:sizeof(gray) atIndex:0];
      [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
      [encoder endEncoding];
    }
    if (success) {
      @synchronized(self) {
        cancelled = _disposed || _suspended || frame.settings != _settings;
        if (!cancelled) {
          _inFlight = commands;
          [commands commit];
        }
      }
      // Flutter samples the IOSurface from its own command queue. Complete before publishing;
      // this wait is on our worker queue, never on the Flutter raster or platform thread.
      if (!cancelled) {
        [commands waitUntilCompleted];
        @synchronized(self) {
          _inFlight = nil;
        }
        success = commands.status == MTLCommandBufferStatusCompleted;
        if (!success && error) *error = commands.error;
      }
    }
  }
  if (inputView) CFRelease(inputView);
  if (outputView) CFRelease(outputView);
  CVMetalTextureCacheFlush(_cache, 0);
  if (cancelled) {
    CVPixelBufferRelease(output);
    return NULL;
  }
  if (!success) {
    if (error && !*error) *error = FVPShaderError(@"Metal failed to render the video effect");
    CVPixelBufferRelease(output);
    return NULL;
  }
  return output;
}

- (void)setSuspended:(BOOL)suspended {
  id<MTLCommandBuffer> commands;
  @synchronized(self) {
    if (_disposed) return;
    _suspended = suspended;
    _pending = nil;
    _lastSubmitted = nil;
    commands = _inFlight;
  }
  // iOS must not enter the background with submitted GPU work. Wait only for a
  // submitted frame, not for queued work or shader compilation. New commits are gated above.
  if (suspended)
    [commands waitUntilCompleted];
  else if (self.onFrameAvailable)
    self.onFrameAvailable();
}

- (void)dispose {
  @synchronized(self) {
    if (_disposed) return;
    _disposed = YES;
    _pending = nil;
    _lastSubmitted = nil;
    CVPixelBufferRelease(_output);
    _output = NULL;
    self.onFrameAvailable = nil;
    self.onError = nil;
  }
  if (_suspendObserver) [NSNotificationCenter.defaultCenter removeObserver:_suspendObserver];
  if (_resumeObserver) [NSNotificationCenter.defaultCenter removeObserver:_resumeObserver];
  dispatch_async(_queue, ^{
    self->_plan = nil;
    self->_targets = nil;
    [self->_programs removeAllObjects];
    self->_compiledBundle = nil;
    self->_copy = nil;
    self->_vertex = nil;
    if (self->_pool) {
      CVPixelBufferPoolRelease(self->_pool);
      self->_pool = NULL;
    }
    if (self->_cache) {
      CFRelease(self->_cache);
      self->_cache = NULL;
    }
    self->_commands = nil;
    self->_device = nil;
  });
}

- (void)dealloc {
  if (_suspendObserver) [NSNotificationCenter.defaultCenter removeObserver:_suspendObserver];
  if (_resumeObserver) [NSNotificationCenter.defaultCenter removeObserver:_resumeObserver];
  CVPixelBufferRelease(_output);
  if (_pool) CVPixelBufferPoolRelease(_pool);
  if (_cache) CFRelease(_cache);
}
@end
