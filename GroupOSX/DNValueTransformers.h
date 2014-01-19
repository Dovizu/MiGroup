//
//  DNValueTransformers.h
//  GroupOSX
//
//  Created by Donny Reynolds on 1/12/14.
//  Copyright (c) 2014 Dovizu Network. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DNLastMessagePreviewTransformer : NSValueTransformer
+ (Class)transformedValueClass;
+ (BOOL)allowsReverseTransformation;
- (id)transformedValue:(id)value;
@end