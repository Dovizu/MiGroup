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
    _loginSheetController = [[DNLoginSheetController alloc] init]; //custom init with xib
    _dataManager = [[DNDataManager alloc] init];
    
    //set up login sheet controller
    _loginSheetController.server = _server;
    _loginSheetController.mainWindowController = _mainWindowController;

    //set up data manager
    _dataManager.managedObjectContext = _managedObjectContext;
    _dataManager.server = _server;
    
    //set up mainWindowController
    _mainWindowController.appDelegate = self;
    _mainWindowController.managedObjectContext = _managedObjectContext;
    _mainWindowController.dataManager = _dataManager;
    
    //set up server
    _server.loginSheetController = _loginSheetController;
    _server.mainWindowController = _mainWindowController;

    //set up URI Scheme
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
                                                       andSelector:@selector(handleAppleEvent:withReplyEvent:)
                                                     forEventClass:kInternetEventClass
                                                        andEventID:kAEGetURL];
    [self.server setup];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)purgeStores
{
//    DebugLogCD(@"Purging all stores");
//    NSPersistentStoreCoordinator *psc = [self persistentStoreCoordinator];
//    NSArray *stores = [psc persistentStores];
//    NSError *error = nil;
//    [self.managedObjectContext save:&error]; //don't really care if error or not
//    
//    //To-Do: although very rare, recover from database failure? Suggest user manual removal as last resort?
//    for (NSPersistentStore *store in stores) {
//        [psc removePersistentStore:store error:&error];
//        if (error) {
//            [[NSApplication sharedApplication] presentError:[[NSError alloc] initWithDomain:DNErrorDomain
//                                                                                       code:eLogOutPurgingFailure
//                                                                                   userInfo:@{NSLocalizedDescriptionKey:eLogOutPurgingFailureDesc}]];
//            //To-Do: although very rare, recover from database failure?
//        }
//        [[NSFileManager defaultManager] removeItemAtPath:store.URL.path error:&error];
//        if (error) {
//            [[NSApplication sharedApplication] presentError:[[NSError alloc] initWithDomain:DNErrorDomain
//                                                                                       code:eLogOutPurgingFailure
//                                                                                   userInfo:@{NSLocalizedDescriptionKey:eLogOutPurgingFailureDesc}]];
//        }
//    }
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
