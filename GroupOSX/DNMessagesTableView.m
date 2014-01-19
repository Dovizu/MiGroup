//
//  DNMessagesTableView.m
//  GroupOSX
//
//  Created by Donny Reynolds on 1/18/14.
//  Copyright (c) 2014 Dovizu Network. All rights reserved.
//

#import "DNMessagesTableView.h"

@implementation DNMessagesTableView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
    // Drawing code here.
}

- (void)awakeFromNib
{
    //For new messages, scroll to the bottom
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollToBottomOfTable:) name:NSManagedObjectContextObjectsDidChangeNotification object:nil];
}

- (void)reloadData
{
    [super reloadData];
}

- (void)scrollToBottomOfTable:(NSNotification*) note
{
    if ([[note.userInfo allKeys] containsObject:@"inserted"]) {
        [self scrollRowToVisible:[self numberOfRows]-1];
    }
}

@end
