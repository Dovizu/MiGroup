//
//  DNAppDelegate.h
//  GroupOSX
//
//  Created by Donny Reynolds on 12/24/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DNServerInterface, DNLoginSheetController, DNMainWindowController;

@interface DNAppDelegate : NSObject <NSApplicationDelegate>

@property IBOutlet NSWindow *window;

@property DNServerInterface *server;
@property DNLoginSheetController *loginSheetController;
@property DNMainWindowController<NSWindowDelegate> *mainWindowController;



@end
