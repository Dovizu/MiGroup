//
//  DNChatLogSingleView.m
//  GroupOSX
//
//  Created by Donny Reynolds on 1/16/14.
//  Copyright (c) 2014 Dovizu Network. All rights reserved.
//

#import "DNChatLogSingleView.h"

@implementation DNChatLogSingleView

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
	
    // Drawing code here
    CGFloat maxX = CGRectGetWidth(self.superview.frame);
    _frame.size.width = maxX;
}

@end
