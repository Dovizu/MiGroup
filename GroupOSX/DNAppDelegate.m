//
//  DNAppDelegate.m
//  GroupOSX
//
//  Created by Donny Reynolds on 12/24/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import "DNAppDelegate.h"

#import "DNServerInterface.h"
#import "DNLoginSheetController.h"
#import "DNMainWindowController.h"

@implementation DNAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.server = [[DNServerInterface alloc] init];
    self.mainWindowController = (DNMainWindowController*) [self.window delegate];
    self.loginSheetController = [[DNLoginSheetController alloc] init]; //init with xib
    
    //setup login sheet controller
    self.loginSheetController.server = self.server;
    self.loginSheetController.mainWindowController = self.mainWindowController;
    
    //setup mainWindowController
    self.mainWindowController.server = self.server;
    
    //setup server
    self.server.loginSheetController = self.loginSheetController;
    
    [self.mainWindowController start];
}

- (void)awakeFromNib
{
}

@end
