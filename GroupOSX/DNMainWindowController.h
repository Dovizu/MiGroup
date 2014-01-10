//
//  DNMainWindowController.h
//  GroupOSX
//
//  Created by Donny Reynolds on 12/26/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Group.h"
#import "Name.h"
#import "Attachment.h"
#import "Message.h"
#import "Member.h"

@class DNServerInterface;
@class DNAppDelegate;

@interface DNMainWindowController : NSWindowController <NSWindowDelegate, NSSplitViewDelegate>

@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property DNServerInterface *server;
@property DNAppDelegate *appDelegate;

@end
