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

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.server = [[DNServerInterface alloc] init];
    self.mainWindowController = (DNMainWindowController*) [self.window delegate];
    self.loginSheetController = [[DNLoginSheetController alloc] init]; //custom init with xib
    
    //set up login sheet controller
    self.loginSheetController.server = self.server;
    self.loginSheetController.mainWindowController = self.mainWindowController;
    
    //set up mainWindowController
    self.mainWindowController.appDelegate = self;
    self.mainWindowController.server = self.server;
    self.mainWindowController.managedObjectContext = self.managedObjectContext;
    
    //set up server
    self.server.loginSheetController = self.loginSheetController;
    self.server.mainWindowController = self.mainWindowController;

    //set up URI Scheme
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
                                                       andSelector:@selector(handleAppleEvent:withReplyEvent:)
                                                     forEventClass:kInternetEventClass
                                                        andEventID:kAEGetURL];
#ifdef DEBUG_CORE_DATA
    [self prepopulateOnFirstRun];
#endif
    
    [self.server setup];
}

#ifdef DEBUG_CORE_DATA
- (void)prepopulateOnFirstRun
{
    if (![[NSUserDefaults standardUserDefaults] valueForKey:@"DN_DEBUG_FirstRun1"]) {
        NSManagedObject *group1 = [[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:@"Group" inManagedObjectContext:self.managedObjectContext] insertIntoManagedObjectContext:self.managedObjectContext];
        [group1 setValue:@"DA Team" forKey:@"name"];
        [group1 setValue:@"This is the description of the group, later to be replaced with last message" forKey:@"desc"];
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:NO] forKey:@"DN_DEBUG_FirstRUn"];
        
        NSManagedObject *group2 = [[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:@"Group" inManagedObjectContext:self.managedObjectContext] insertIntoManagedObjectContext:self.managedObjectContext];
        [group2 setValue:@"Good Old Friends" forKey:@"name"];
        [group2 setValue:@"Good old friends will last forever" forKey:@"desc"];
//        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:NO] forKey:@"DN_DEBUG_FirstRUn"];
        //Don't save
    }
}
#endif

- (void)purgeStores
{
    DebugLogCD(@"Purging all stores");
    NSPersistentStoreCoordinator *psc = [self persistentStoreCoordinator];
    NSArray *stores = [psc persistentStores];
    NSError *error = nil;
    [self.managedObjectContext save:&error]; //don't really care if error or not
    
    //To-Do: although very rare, recover from database failure? Suggest user manual removal as last resort?
    for (NSPersistentStore *store in stores) {
        [psc removePersistentStore:store error:&error];
        if (error) {
            [[NSApplication sharedApplication] presentError:[[NSError alloc] initWithDomain:DNErrorDomain
                                                                                       code:eLogOutPurgingFailure
                                                                                   userInfo:@{NSLocalizedDescriptionKey:eLogOutPurgingFailureDesc}]];
            //To-Do: although very rare, recover from database failure?
        }
        [[NSFileManager defaultManager] removeItemAtPath:store.URL.path error:&error];
        if (error) {
            [[NSApplication sharedApplication] presentError:[[NSError alloc] initWithDomain:DNErrorDomain
                                                                                       code:eLogOutPurgingFailure
                                                                                   userInfo:@{NSLocalizedDescriptionKey:eLogOutPurgingFailureDesc}]];
        }
    }
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

#pragma mark - Core Data Methods

// Returns the directory the application uses to store the Core Data store file. This code uses a directory named "GroupOSX" in the user's Application Support directory.
- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"DN.GroupOSX"];
}

// Creates if necessary and returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"GroupOSX" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    } else {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:DNErrorDomain code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"GroupOSX.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _persistentStoreCoordinator = coordinator;
    
    return _persistentStoreCoordinator;
}

// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:DNErrorDomain code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    
    return _managedObjectContext;
}

// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self managedObjectContext] undoManager];
}

// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
- (IBAction)saveAction:(id)sender
{
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // Save changes in the application's managed object context before the application terminates.
    
    if (!_managedObjectContext) {
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        
        // Customize this code block to include application-specific recovery steps.
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }
        
        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];
        
        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }
    
    return NSTerminateNow;
}



@end
