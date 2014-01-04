//
//  DNMainWindowController.h
//  GroupOSX
//
//  Created by Donny Reynolds on 12/26/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DNServerInterface;
@class DNAppDelegate;

@interface DNMainWindowController : NSWindowController <NSWindowDelegate, NSSplitViewDelegate>

@property (nonatomic) NSManagedObjectContext *managedObjectContext;

@property DNServerInterface *server;

@property DNAppDelegate *appDelegate;

@end
