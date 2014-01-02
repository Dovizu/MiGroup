//
//  DNMainWindow.m
//  GroupOSX
//
//  Created by Donny Reynolds on 1/2/14.
//  Copyright (c) 2014 Dovizu Network. All rights reserved.
//

#import "DNMainWindow.h"

@implementation DNMainWindow

- (id)initWithContentRect:(NSRect)contentRect
                styleMask:(NSUInteger)aStyle
                  backing:(NSBackingStoreType)bufferingType
                    defer:(BOOL)flag
{
    NSInteger windowStyle = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask;
    self = [super initWithContentRect:contentRect styleMask:windowStyle backing:NSBackingStoreBuffered defer:NO];
    if (self) {
//        [self setBackgroundColor:[NSColor whiteColor]];
//        [self setAutorecalculatesContentBorderThickness:NO forEdge:NSMaxYEdge];
//        [self setContentBorderThickness:20 forEdge:NSMaxYEdge];
        [self.contentView setBackgroundColor:[NSColor blackColor]];

    }
    return self;
}

- (BOOL)canBecomeKeyWindow {
    
    return YES;
}

@end
