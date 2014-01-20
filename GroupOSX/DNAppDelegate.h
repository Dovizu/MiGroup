//
//  DNAppDelegate.h
//  GroupOSX
//
//  Created by Donny Reynolds on 12/24/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "GlobalConstants.h"

@class DNServerInterface, DNLoginSheetController, DNDataManager, DNMainController;

@interface DNAppDelegate : NSObject <NSApplicationDelegate>

@property IBOutlet NSWindow *window;

@property (readonly, nonatomic) NSManagedObjectContext *managedObjectContext;

@property DNServerInterface *server;
@property DNLoginSheetController *loginSheetController;
@property DNMainController<NSWindowDelegate> *mainWindowController;
@property DNDataManager *dataManager;


@end
