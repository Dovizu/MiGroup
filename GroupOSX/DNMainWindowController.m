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
        [self establishObserversForNotifications];
    }
    return self;
}

- (void)awakeFromNib
{
    
}

#pragma mark - Message Routing

- (void)establishObserversForNotifications
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    //First time logon
    [center addObserver:self selector:@selector(firstTimeLogonSetup:) name:noteFirstTimeLogon object:nil];
    [center addObserver:self selector:@selector(didReceiveMessage:) name:noteNewMessage object:nil];
    [center addObserver:self selector:@selector(didChangeMemberName:) name:noteMemberNameChange object:nil];
    [center addObserver:self selector:@selector(didChangeGroupAvatar:) name:noteGroupAvatarChange object:nil];
    [center addObserver:self selector:@selector(didChangeGroupName:) name:noteGroupNameChange object:nil];
    [center addObserver:self selector:@selector(didUpdateGroup:) name:noteGroupUpdate object:nil];
    [center addObserver:self selector:@selector(didRemoveGroup:) name:noteGroupRemove object:nil];
    [center addObserver:self selector:@selector(didFetchGroupInfo:) name:noteGroupInfoFetch object:nil];
    [center addObserver:self selector:@selector(didCreateGroup:) name:noteGroupCreate object:nil];
    [center addObserver:self selector:@selector(didRemoveMember:) name:noteMemberRemove object:nil];
    [center addObserver:self selector:@selector(didAddMember:) name:noteMembersAdd object:nil];
    [center addObserver:self selector:@selector(didFetchAllGroups:) name:noteGroupsAllFetch object:nil];
    [center addObserver:self selector:@selector(didFetchFormerGroups:) name:noteGroupsFormerFetch object:nil];
    [center addObserver:self selector:@selector(didFetchMessagesBefore:) name:noteMessagesBeforeFetch object:nil];
    [center addObserver:self selector:@selector(didFetchMessagesSince:) name:noteMessagesSinceFetch object:nil];
}

- (void)firstTimeLogonSetup:(NSNotification*)note
{
    [_server fetchAllGroups];
}

- (void)didReceiveMessage:(NSNotification*)note
{
    
}
- (void)didChangeMemberName:(NSNotification*)note
{
    
}
- (void)didChangeGroupAvatar:(NSNotification*)note
{
    
}
- (void)didChangeGroupName:(NSNotification*)note
{
    
}
- (void)didUpdateGroup:(NSNotification*)note
{
    
}
- (void)didRemoveGroup:(NSNotification*)note
{
    
}
- (void)didFetchGroupInfo:(NSNotification*)note
{
    
}
- (void)didCreateGroup:(NSNotification*)note
{
    
}
- (void)didRemoveMember:(NSNotification*)note
{
    
}
- (void)didAddMember:(NSNotification*)note
{
    
}
- (void)didFetchAllGroups:(NSNotification*)note
{
    
}
- (void)didFetchFormerGroups:(NSNotification*)note
{
    
}
- (void)didFetchMessagesBefore:(NSNotification*)note
{
    
}
- (void)didFetchMessagesSince:(NSNotification*)note
{
    
}

#pragma mark - GUI Actions
- (IBAction)logout:(id)sender
{
    [self.server teardown];
    [self.appDelegate purgeStores];
}


@end
