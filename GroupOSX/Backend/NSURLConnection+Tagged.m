//
//  NSURLConnection+Tagged.m
//  GroupOSX
//
//  Created by Donny Reynolds on 12/29/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import "NSURLConnection+Tagged.h"

@implementation NSURLConnection (Tagged)

static char DNAssociatedKey;

- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate startImmediately:(BOOL)startImmediately tag:(NSString*)tag_arg
{
    self = [[NSURLConnection alloc] initWithRequest:request delegate:delegate startImmediately:startImmediately];
    if (self) {
        self.tag = tag_arg;
    }
    return self;
}

- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate tag:(NSString *)tag_arg
{
    self = [[NSURLConnection alloc] initWithRequest:request delegate:delegate];
    if (self) {
        self.tag = tag_arg;
    }
    return self;
}

+ (NSURLConnection*)connectionWithRequest:(NSURLRequest *)request delegate:(id)delegate tag:(NSString *)tag_arg
{
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:delegate];
    connection.tag = tag_arg;
    return connection;
}

//Use objc_setAssociatedObject and objc_getAssociatedObject to add category property
- (void)setTag:(NSString *)tag
{
    objc_setAssociatedObject(self, &DNAssociatedKey, tag, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString*)tag
{
    return objc_getAssociatedObject(self, &DNAssociatedKey);
}

@end
