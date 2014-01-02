//
//  DNLoginSheetController.h
//  GroupOSX
//
//  Created by Donny Reynolds on 12/26/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
@class DNMainWindowController, DNServerInterface;

@interface DNLoginSheetController : NSWindowController

@property DNMainWindowController *mainWindowController;
@property DNServerInterface *server;

- (id)init;
- (void)promptForLoginWithPreparedURL:(NSURL *)url;
- (void)closeLoginSheet;

@end
