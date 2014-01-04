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

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        
    }
    return self;
}

- (IBAction)logout:(id)sender
{
    [self.server teardown];
    [self.appDelegate purgeStores];
}

- (void)awakeFromNib
{
    
}


@end
