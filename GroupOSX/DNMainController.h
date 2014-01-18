//
//  DNMainController.h
//  GroupOSX
//
//  Created by Donny Reynolds on 1/12/14.
//  Copyright (c) 2014 Dovizu Network. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class DNAppDelegate, DNDataManager;

@interface DNMainController : NSWindowController <NSWindowDelegate, NSSplitViewDelegate, NSTableViewDelegate>

@property DNAppDelegate *appDelegate;
@property DNDataManager *dataManager;
@property NSManagedObjectContext *managedObjectContext;
@end
