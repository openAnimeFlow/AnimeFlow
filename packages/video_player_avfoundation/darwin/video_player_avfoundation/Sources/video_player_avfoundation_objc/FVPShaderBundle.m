// Copyright 2026 The AnimeFlow Authors. All rights reserved.
// Use of this source code is governed by the BSD license in the LICENSE file.

#import "./include/video_player_avfoundation_objc/FVPShaderBundle.h"
#include <math.h>

@implementation FVPShaderNode
@end
@implementation FVPShaderStep
@end
@implementation FVPShaderPlan
@end

NSError *FVPShaderError(NSString *message) {
  return [NSError errorWithDomain:@"video_shader"
                             code:1
                         userInfo:@{NSLocalizedDescriptionKey : message}];
}

static id Invalid(NSError **error, NSString *message) {
  if (error) *error = FVPShaderError(message);
  return nil;
}

static NSArray<NSString *> *Tokens(NSString *expression) {
  return [[expression
      componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]
      filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
}

static BOOL IsOperator(NSString *token) {
  return token.length == 1 && [@"+-*/><" containsString:token];
}

static BOOL Number(NSString *token, float *value) {
  NSScanner *scanner = [NSScanner scannerWithString:token];
  scanner.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
  return [scanner scanFloat:value] && scanner.isAtEnd && isfinite(*value);
}

static BOOL IsSize(NSString *token) { return [token hasSuffix:@".w"] || [token hasSuffix:@".h"]; }

static BOOL ValidExpression(id expression, NSSet<NSString *> *known) {
  if (![expression isKindOfClass:NSString.class]) return NO;
  NSInteger depth = 0;
  for (NSString *token in Tokens(expression)) {
    if (IsOperator(token)) {
      if (depth < 2) return NO;
      depth--;
    } else {
      if (IsSize(token)) {
        if (![known containsObject:[token substringToIndex:token.length - 2]]) return NO;
      } else {
        float value;
        if (!Number(token, &value)) return NO;
      }
      depth++;
    }
  }
  return depth == 1;
}

// Float math and positive lroundf match Android/MPV dimensions and conditions.
static float Evaluate(NSString *expression, NSDictionary<NSString *, FVPShaderNode *> *saved) {
  NSMutableArray<NSNumber *> *stack = [NSMutableArray array];
  for (NSString *token in Tokens(expression)) {
    float value;
    if (IsOperator(token)) {
      if (stack.count < 2) return NAN;
      float b = stack.lastObject.floatValue;
      [stack removeLastObject];
      float a = stack.lastObject.floatValue;
      [stack removeLastObject];
      switch ([token characterAtIndex:0]) {
        case '+':
          value = a + b;
          break;
        case '-':
          value = a - b;
          break;
        case '*':
          value = a * b;
          break;
        case '/':
          value = a / b;
          break;
        case '>':
          value = a > b;
          break;
        case '<':
          value = a < b;
          break;
        default:
          return NAN;
      }
    } else if (IsSize(token)) {
      FVPShaderNode *node = saved[[token substringToIndex:token.length - 2]];
      if (!node) return NAN;
      value = [token hasSuffix:@".w"] ? node.width : node.height;
    } else if (!Number(token, &value)) {
      return NAN;
    }
    if (!isfinite(value)) return NAN;
    [stack addObject:@(value)];
  }
  return stack.count == 1 ? stack[0].floatValue : NAN;
}

static FVPShaderNode *Node(NSInteger width, NSInteger height) {
  FVPShaderNode *node = [[FVPShaderNode alloc] init];
  node.width = width;
  node.height = height;
  node.slot = -1;
  return node;
}

@implementation FVPShaderBundle
- (instancetype)initWithEncoded:(NSString *)encoded error:(NSError **)error {
  self = [super init];
  if (!self) return nil;
  id json = [NSJSONSerialization JSONObjectWithData:[encoded dataUsingEncoding:NSUTF8StringEncoding]
                                            options:0
                                              error:error];
  if (![json isKindOfClass:NSDictionary.class] || ![json[@"version"] isEqual:@1] ||
      ![json[@"passes"] isKindOfClass:NSArray.class] || [json[@"passes"] count] == 0 ||
      ![json[@"shaders"] isKindOfClass:NSDictionary.class]) {
    if (error)
      *error = FVPShaderError(@"Expected a version 1 shader bundle with passes and sources");
    return nil;
  }
  NSMutableSet *known = [NSMutableSet setWithArray:@[ @"NATIVE", @"MAIN", @"OUTPUT" ]];
  NSRegularExpression *identifier =
      [NSRegularExpression regularExpressionWithPattern:@"^[A-Za-z_][A-Za-z0-9_]*$"
                                                options:0
                                                  error:nil];
  BOOL prekernel = NO;
  for (id pass in json[@"passes"]) {
    if (![pass isKindOfClass:NSDictionary.class])
      return Invalid(error, @"Invalid shader pass, binding, source or expression");
    NSString *hook = pass[@"hook"], *save = pass[@"save"], *asset = pass[@"asset"];
    if (![@[ @"MAIN", @"PREKERNEL" ] containsObject:hook ?: @""] ||
        (prekernel && [hook isEqual:@"MAIN"]))
      return Invalid(error, @"Invalid shader pass, binding, source or expression");
    prekernel |= [hook isEqual:@"PREKERNEL"];
    [known addObject:@"HOOKED"];
    [known addObject:hook];
    if (![save isKindOfClass:NSString.class] ||
        [identifier numberOfMatchesInString:save options:0
                                      range:NSMakeRange(0, save.length)] != 1 ||
        [@[ @"NATIVE", @"OUTPUT" ] containsObject:save] || ![asset isKindOfClass:NSString.class])
      return Invalid(error, @"Invalid shader pass, binding, source or expression");
    id source = json[@"shaders"][asset];
    if (![source isKindOfClass:NSString.class] ||
        [source stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]
                .length == 0 ||
        ![pass[@"bindings"] isKindOfClass:NSArray.class] || [pass[@"bindings"] count] > 16)
      return Invalid(error, @"Invalid shader pass, binding, source or expression");
    NSMutableSet *bindings = [NSMutableSet set];
    for (id binding in pass[@"bindings"]) {
      if (![binding isKindOfClass:NSDictionary.class])
        return Invalid(error, @"Invalid shader pass, binding, source or expression");
      id name = binding[@"name"];
      if (![name isKindOfClass:NSString.class] || ![known containsObject:name] ||
          [name isEqual:@"OUTPUT"] || [bindings containsObject:name] ||
          CFGetTypeID((__bridge CFTypeRef)(binding[@"sampler"] ?: NSNull.null)) !=
              CFBooleanGetTypeID() ||
          CFGetTypeID((__bridge CFTypeRef)(binding[@"dimensions"] ?: NSNull.null)) !=
              CFBooleanGetTypeID())
        return Invalid(error, @"Invalid shader pass, binding, source or expression");
      [bindings addObject:name];
    }
    if (!ValidExpression(pass[@"width"], known) || !ValidExpression(pass[@"height"], known) ||
        !ValidExpression(pass[@"when"], known))
      return Invalid(error, @"Invalid shader pass, binding, source or expression");
    [known addObject:save];
  }
  _encoded = [encoded copy];
  _passes = json[@"passes"];
  _shaders = json[@"shaders"];
  return self;
}

- (FVPShaderPlan *)planForWidth:(NSInteger)width
                         height:(NSInteger)height
                    outputWidth:(NSInteger)outputWidth
                   outputHeight:(NSInteger)outputHeight
                          error:(NSError **)error {
  if (MIN(MIN(width, height), MIN(outputWidth, outputHeight)) <= 0) {
    if (error) *error = FVPShaderError(@"Video and output dimensions must be positive");
    return nil;
  }
  FVPShaderNode *original = Node(width, height);
  NSMutableDictionary *saved =
      [@{@"NATIVE" : original, @"MAIN" : original, @"OUTPUT" : Node(outputWidth, outputHeight)}
          mutableCopy];
  NSMutableArray<FVPShaderStep *> *steps = [NSMutableArray array];
  for (NSDictionary *pass in self.passes) {
    saved[@"HOOKED"] = saved[@"MAIN"];
    saved[pass[@"hook"]] = saved[@"MAIN"];
    float condition = Evaluate(pass[@"when"], saved);
    if (!isfinite(condition))
      return Invalid(error, @"Missing conditional shader input or invalid dimensions/expression");
    if (condition == 0) continue;
    NSMutableArray *inputs = [NSMutableArray array];
    for (NSDictionary *binding in pass[@"bindings"]) {
      FVPShaderNode *input = saved[binding[@"name"]];
      if (!input)
        return Invalid(error, @"Missing conditional shader input or invalid dimensions/expression");
      input.uses++;
      [inputs addObject:input];
    }
    float w = Evaluate(pass[@"width"], saved), h = Evaluate(pass[@"height"], saved);
    if (!isfinite(w) || !isfinite(h) || w < .5f || h < .5f || w > INT_MAX / 2.f ||
        h > INT_MAX / 2.f)
      return Invalid(error, @"Missing conditional shader input or invalid dimensions/expression");
    FVPShaderStep *step = [[FVPShaderStep alloc] init];
    step.pass = pass;
    step.inputs = inputs;
    step.output = Node(lroundf(w), lroundf(h));
    [steps addObject:step];
    NSString *save = pass[@"save"];
    saved[[@[ @"HOOKED", @"PREKERNEL" ] containsObject:save] ? @"MAIN" : save] = step.output;
  }
  FVPShaderPlan *plan = [[FVPShaderPlan alloc] init];
  plan.result = saved[@"MAIN"];
  plan.result.uses++;
  NSMutableArray<FVPShaderNode *> *slots = [NSMutableArray array];
  NSMutableArray<NSNumber *> *free = [NSMutableArray array];
  for (FVPShaderStep *step in steps) {
    for (NSNumber *index in [free copy]) {
      FVPShaderNode *slot = slots[index.unsignedIntegerValue];
      if (slot.width == step.output.width && slot.height == step.output.height) {
        step.output.slot = index.integerValue;
        [free removeObject:index];
        break;
      }
    }
    if (step.output.slot < 0) {
      step.output.slot = slots.count;
      [slots addObject:step.output];
    }
    for (FVPShaderNode *input in step.inputs) {
      if (--input.uses == 0 && input != original) [free addObject:@(input.slot)];
    }
    if (step.output.uses == 0) [free addObject:@(step.output.slot)];
  }
  plan.steps = steps;
  plan.slots = slots;
  return plan;
}
@end
