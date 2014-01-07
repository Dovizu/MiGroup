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

#import "Group.h"

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

#pragma mark - Data Management


#pragma mark - Message Routing

- (void)establishObserversForMessages
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    //First time logon
    [center addObserver:self selector:@selector(firstTimeLogonSetup:) name:noteFirstTimeLogon object:nil];
    //Group changes
    [center addObserver:self selector:@selector(groupInfoChanged:) name:finalGroupIndexAllResultsArrived object:nil];
    //Messages
    [center addObserver:self selector:@selector(messageReceived:) name:finalMemberMessageReceived object:nil];
}

//noteMemberMessageReceived
- (void)messageReceived:(NSNotification*)note
{
    NSDictionary *details = note.userInfo[kGetContentKey];
    DebugLogCD(@"%@ sent a message: %@", sender, details[@"text"]);
}

//finalGroupIndexResultsArrived
- (void)groupInfoChanged:(NSNotification*)note
{

    
}

//first time logon procedure
- (void)firstTimeLogonSetup:(NSNotification*)note
{
}

#pragma mark - GUI Actions
- (IBAction)logout:(id)sender
{
    [self.server teardown];
    [self.appDelegate purgeStores];
}


@end
