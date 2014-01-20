//
//  DNLoginSheetController.h
//  GroupOSX
//
//  Created by Donny Reynolds on 1/19/14.
//  Copyright (c) 2014 Dovizu Network. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
@class DNMainController;

@interface DNLoginSheetController : NSWindowController

@property IBOutlet WebView *loginWebView;
@property IBOutlet NSWindow *loginWindow;
@property DNMainController *mainController;

- (void)openSheetWithURL:(NSURL *)url;
- (IBAction)closeLoginSheet:(id)sender;

@end
