//
//  DNAppDelegate.h
//  GroupOSX
//
//  Created by Donny Reynolds on 12/24/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "GlobalConstants.h"

@class DNServerInterface, DNLoginSheetController, DNMainWindowController;

@interface DNAppDelegate : NSObject <NSApplicationDelegate>

@property IBOutlet NSWindow *window;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property DNServerInterface *server;
@property DNLoginSheetController *loginSheetController;
@property DNMainWindowController<NSWindowDelegate> *mainWindowController;


- (IBAction)saveAction:(id)sender;
- (void)purgeStores;

@end
