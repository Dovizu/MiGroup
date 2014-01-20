//
//  DNAppDelegate.m
//  GroupOSX
//
//  Created by Donny Reynolds on 12/24/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import <Foundation/NSFileManager.h>
#import "DNAppDelegate.h"
#import "DNServerInterface.h"
#import "DNLoginSheetController.h"
#import "DNDataManager.h"
#import "DNMainController.h"

@implementation DNAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [MagicalRecord setupAutoMigratingCoreDataStack];
    _managedObjectContext = [NSManagedObjectContext MR_defaultContext];
    
    _server = [[DNServerInterface alloc] init];
    _mainWindowController = (DNMainController*) [self.window delegate];
    _loginSheetController = [[DNLoginSheetController alloc] initWithWindowNibName:@"LoginSheet"];
    _dataManager = [[DNDataManager alloc] init];
    
    //Setup managed object context
    _dataManager.managedObjectContext = _managedObjectContext;
    _mainWindowController.managedObjectContext = _managedObjectContext;
    //set up data manager
    _dataManager.server = _server;
    _dataManager.mainController = _mainWindowController;
    //set up mainWindowController
    _mainWindowController.dataManager = _dataManager;
    //set up login sheet controller
    
    _loginSheetController.mainController = _mainWindowController;
    _mainWindowController.loginSheetController = _loginSheetController;
    
    //set up server
    _server.mainWindowController = _mainWindowController;

    //set up URI Scheme
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
                                                       andSelector:@selector(handleAppleEvent:withReplyEvent:)
                                                     forEventClass:kInternetEventClass
                                                        andEventID:kAEGetURL];
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:_mainWindowController];
    [self.server setup];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//This function should only be used for handling authentication URL redirect's, for now
- (void)handleAppleEvent:(NSAppleEventDescriptor *)event
          withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    NSString *urlString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    DebugLog(@"Apple event received: %@", urlString);
    [self.server didReceiveURL:[NSURL URLWithString:urlString]];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    [MagicalRecord cleanUp];
    return NSTerminateNow;
}

@end
