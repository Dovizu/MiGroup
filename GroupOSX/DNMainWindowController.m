//
//  DNMainWindowController.m
//  GroupOSX
//
//  Created by Donny Reynolds on 12/26/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import "DNMainWindowController.h"

@interface DNMainWindowController ()

@end

#import "DNServerInterface.h"

@implementation DNMainWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        NSLog(@"initWithWindow has been called");
    }
    return self;
}

- (void)awakeFromNib
{
    NSLog(@"DNMainWindowController loaded");
}

- (void)start
{
    if (![self.server loggedIn]) {
        [self.server authenticate];
    }
}

@end
