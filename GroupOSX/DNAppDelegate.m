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
#import "DNMainWindowController.h"

@implementation DNAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [MagicalRecord setupAutoMigratingCoreDataStack];
    _managedObjectContext = [NSManagedObjectContext MR_defaultContext];
    
    self.server = [[DNServerInterface alloc] init];
    self.mainWindowController = (DNMainWindowController*) [self.window delegate];
    self.loginSheetController = [[DNLoginSheetController alloc] init]; //custom init with xib
    
    //set up login sheet controller
    self.loginSheetController.server = self.server;
    self.loginSheetController.mainWindowController = self.mainWindowController;
    
    //set up mainWindowController
    self.mainWindowController.appDelegate = self;
    self.mainWindowController.server = self.server;
    self.mainWindowController.managedObjectContext = _managedObjectContext;
    
    //set up server
    self.server.loginSheetController = self.loginSheetController;
    self.server.mainWindowController = self.mainWindowController;

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
