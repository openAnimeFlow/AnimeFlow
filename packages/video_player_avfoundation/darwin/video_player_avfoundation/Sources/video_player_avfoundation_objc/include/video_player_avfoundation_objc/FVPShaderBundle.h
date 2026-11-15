// Copyright 2026 The AnimeFlow Authors. All rights reserved.
// Use of this source code is governed by the BSD license in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Version 1 graph semantics shared with the Android implementation. No GPU dependencies.
@interface FVPShaderNode : NSObject
@property(nonatomic) NSInteger width;
@property(nonatomic) NSInteger height;
@property(nonatomic) NSInteger slot;
@property(nonatomic) NSInteger uses;
@end

@interface FVPShaderStep : NSObject
@property(nonatomic, copy) NSDictionary *pass;
@property(nonatomic, copy) NSArray<FVPShaderNode *> *inputs;
@property(nonatomic, strong) FVPShaderNode *output;
@end

@interface FVPShaderPlan : NSObject
@property(nonatomic, copy) NSArray<FVPShaderStep *> *steps;
@property(nonatomic, copy) NSArray<FVPShaderNode *> *slots;
@property(nonatomic, strong) FVPShaderNode *result;
@end

@interface FVPShaderBundle : NSObject
@property(nonatomic, readonly, copy) NSString *encoded;
@property(nonatomic, readonly, copy) NSArray<NSDictionary *> *passes;
@property(nonatomic, readonly, copy) NSDictionary<NSString *, NSString *> *shaders;
- (nullable instancetype)initWithEncoded:(NSString *)encoded error:(NSError **)error;
- (nullable FVPShaderPlan *)planForWidth:(NSInteger)width
                                  height:(NSInteger)height
                             outputWidth:(NSInteger)outputWidth
                            outputHeight:(NSInteger)outputHeight
                                   error:(NSError **)error;
@end

FOUNDATION_EXPORT NSError *FVPShaderError(NSString *message);
NS_ASSUME_NONNULL_END
