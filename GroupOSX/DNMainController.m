//
//  DNMainController.m
//  GroupOSX
//
//  Created by Donny Reynolds on 1/12/14.
//  Copyright (c) 2014 Dovizu Network. All rights reserved.
//

#import "DNMainController.h"
#import "DNDataManager.h"

@interface DNMainController ()

@end

@implementation DNMainController
{
    IBOutlet NSSplitView *_splitView;
    IBOutlet NSView *_listView;
    IBOutlet NSView *_chatView;
    
    IBOutlet NSView *_listViewTop;
    IBOutlet NSView *_listViewMiddle;
    IBOutlet NSView *_listViewBottom;
    
    IBOutlet NSSearchField *_searchField;
    IBOutlet NSButton *_ListViewBottomNewButton;
    
    IBOutlet NSView *groupInfo;
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

#pragma mark - GUI Actions
- (IBAction)logout:(id)sender
{

}
@end
