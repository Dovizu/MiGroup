//
//  DNValueTransformers.m
//  GroupOSX
//
//  Created by Donny Reynolds on 1/12/14.
//  Copyright (c) 2014 Dovizu Network. All rights reserved.
//

#import "DNValueTransformers.h"
#import "Message.h"
#import "Member.h"

@implementation DNLastMessagePreviewTransformer

+ (Class)transformedValueClass
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    Message *lastMessage = value;
    if (value == nil) return nil;
    
    NSString *formattedPreview = [NSString stringWithFormat:@"%@: %@", lastMessage.creator.name, lastMessage.text];
    if (!formattedPreview) {
        [NSException raise: NSInternalInconsistencyException
                    format: @"Error generating last message (%@) preview.",
         [value class]];
    }
    return formattedPreview;
}

@end

@implementation DNSingleMessageTransformer

+ (Class)transformedValueClass
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    Message *message = (Message*)value;
    NSString *text = message.text;
    NSString *sender = message.creator.name;
    NSString *messageDisplay = [NSString stringWithFormat:@"%@\n%@", sender, text];
    return messageDisplay;
}

@end