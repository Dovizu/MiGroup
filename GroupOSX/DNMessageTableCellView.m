//
//  DNMessageTableViewCell.m
//  GroupOSX
//
//  Created by Donny Reynolds on 1/17/14.
//  Copyright (c) 2014 Dovizu Network. All rights reserved.
//

#import "DNMessageTableCellView.h"

@implementation DNMessageTableCellView
{
    BOOL _didSetupConstraints;
    IBOutlet NSTextField *senderField;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)awakeFromNib
{
}

- (void)updateConstraints
{
    [super updateConstraints];
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
    // Drawing code here.
}

@end
