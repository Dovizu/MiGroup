//
//  NSURLConnection+Tagged.h
//  GroupOSX
//
//  Created by Donny Reynolds on 12/29/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface NSURLConnection (Tagged)

@property NSString *tag;

//Augment original methods with tags
- (id)initWithRequest:(NSURLRequest*)request delegate:(id)delegate startImmediately:(BOOL)startImmediately tag:(NSString*)tag_arg;
- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate tag:(NSString*)tag_arg;
+ (NSURLConnection*)connectionWithRequest:(NSURLRequest *)request delegate:(id)delegate tag:(NSString*)tag_arg;

@end
