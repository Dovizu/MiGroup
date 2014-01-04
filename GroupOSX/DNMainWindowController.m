//
//  DNMainWindowController.m
//  GroupOSX
//
//  Created by Donny Reynolds on 12/26/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import "DNMainWindowController.h"
#import "DNServerInterface.h"
#import "DNAppDelegate.h"

@interface DNMainWindowController ()

@property IBOutlet NSSplitView *splitView;
@property IBOutlet NSView *listView;
@property IBOutlet NSView *chatView;

@property IBOutlet NSView *listViewTop;
@property IBOutlet NSView *listViewMiddle;
@property IBOutlet NSView *listViewBottom;

@property IBOutlet NSSearchField *searchField;
@property IBOutlet NSButton *ListViewBottomNewButton;

@property IBOutlet NSView *groupInfo;

@end


@implementation DNMainWindowController

#pragma mark - Initialization
- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        [self establishObserversForMessages];
    }
    return self;
}

- (void)awakeFromNib
{
    
}

#pragma mark - Data management

- (void)establishObserversForMessages
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    //Group changes
    [center addObserver:self selector:@selector(groupInfoChanged:) name:kJSONObjectNotifierTypeGroupMemberAdded object:nil];
    [center addObserver:self selector:@selector(groupInfoChanged:) name:kJSONObjectNotifierTypeGroupMemberRemoved object:nil];
    [center addObserver:self selector:@selector(groupInfoChanged:) name:kJSONObjectNotifierTypeGroupAvatarChanged object:nil];

    //Messages
    [center addObserver:self selector:@selector(messageReceived:) name:kJSONObjectNotifierTypeMessageReceived object:nil];
    
}

- (void)messageReceived:(NSNotification*)note
{
    __unused NSString *type = note.name;
    NSDictionary *details = note.userInfo[kGetMessageKey];
    NSString *sender = details[@"name"];
    if (![self.server isUser:sender]) {
        DebugLogCD(@"%@ sent a message: %@", sender, details[@"text"]);
    }
#ifdef DEBUG_CORE_DATA
    else{
        DebugLogCD(@"Received a message from myself");
    }
#endif
}

- (void)groupInfoChanged:(NSNotification*)note
{
    NSString *type = note.name;
    NSDictionary *details = note.userInfo[kGetMessageKey];
    
    DebugLogCD(@"Type: %@ received, details:\n%@", type, details);
}

#pragma mark - GUI Actions
- (IBAction)logout:(id)sender
{
    [self.server teardown];
    [self.appDelegate purgeStores];
}


@end
