//
//  Group+DNGroup.m
//  GroupOSX
//
//  Created by Donny Reynolds on 1/11/14.
//  Copyright (c) 2014 Dovizu Network. All rights reserved.
//

#import "Group+DNGroup.h"

@implementation Group (DNGroup)

- (void)addMembersObject:(Member *)value; {
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.members];
    [tempSet addObject:value];
    self.members = tempSet;
}

@end
