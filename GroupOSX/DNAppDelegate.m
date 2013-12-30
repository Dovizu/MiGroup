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
    
    //set up login sheet controller
    self.loginSheetController.server = self.server;
    self.loginSheetController.mainWindowController = self.mainWindowController;
    
    //set up mainWindowController
    self.mainWindowController.server = self.server;
    
    //set up server
    self.server.loginSheetController = self.loginSheetController;


    //set up URI Scheme
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
                                                       andSelector:@selector(handleAppleEvent:withReplyEvent:)
                                                     forEventClass:kInternetEventClass
                                                        andEventID:kAEGetURL];
    [self.mainWindowController start];
}

//This function should only be used for handling authentication URL redirect's, for now
- (void)handleAppleEvent:(NSAppleEventDescriptor *)event
          withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    NSString *urlString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    DebugLog(@"Apple event received: %@", urlString);
    [self.server didReceiveURL:[NSURL URLWithString:urlString]];
}

- (void)awakeFromNib
{
}

@end
