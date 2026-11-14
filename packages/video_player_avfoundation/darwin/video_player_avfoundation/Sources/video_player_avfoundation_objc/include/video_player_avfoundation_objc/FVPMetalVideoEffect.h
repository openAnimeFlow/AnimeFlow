// Copyright 2026 The AnimeFlow Authors. All rights reserved.
// Use of this source code is governed by the BSD license in the LICENSE file.

#import <CoreVideo/CoreVideo.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
// GPU work is serialized off the Flutter raster thread. At most one pending input is retained.
@interface FVPMetalVideoEffect : NSObject
@property(nonatomic, copy, nullable) void (^onFrameAvailable)(void);
@property(nonatomic, copy, nullable) void (^onError)(NSString *message);
- (nullable instancetype)initWithConfiguration:(NSString *)configuration error:(NSError **)error;
- (BOOL)setConfiguration:(NSString *)configuration error:(NSError **)error;
// Enqueues a changed input/configuration and returns the last completed output (or the source
// during startup). The caller owns the returned reference; Flutter may retain it across frames.
- (CVPixelBufferRef)copyPixelBuffer:(CVPixelBufferRef)source CF_RETURNS_RETAINED;
- (void)dispose;
@end
NS_ASSUME_NONNULL_END
