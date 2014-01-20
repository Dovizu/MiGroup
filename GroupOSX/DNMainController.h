//
//  DNMainController.h
//  GroupOSX
//
//  Created by Donny Reynolds on 1/12/14.
//  Copyright (c) 2014 Dovizu Network. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class DNAppDelegate, DNDataManager, Message, Group, DNLoginSheetController, DNServerInterface;

@interface DNMainController : NSWindowController <NSWindowDelegate, NSSplitViewDelegate, NSTableViewDelegate, NSUserNotificationCenterDelegate, NSControlTextEditingDelegate>

@property DNDataManager *dataManager;
@property NSManagedObjectContext *managedObjectContext;
@property DNLoginSheetController *loginSheetController;

#pragma mark - Models Helper Methods
- (void)notifyUserOfGroupMessage:(Message*)message fromGroup:(Group*)targetGroup;
- (void)promptForLoginWithPreparedURL:(NSURL *)url;
- (void)closeLoginSheet;
- (void)logOutWithURL:(NSURL*)url;
@end
