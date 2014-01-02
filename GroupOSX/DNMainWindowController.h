//
//  DNMainWindowController.h
//  GroupOSX
//
//  Created by Donny Reynolds on 12/26/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DNServerInterface;

@interface DNMainWindowController : NSWindowController <NSWindowDelegate, NSSplitViewDelegate>

@property DNServerInterface *server;


- (void)start;

@end
