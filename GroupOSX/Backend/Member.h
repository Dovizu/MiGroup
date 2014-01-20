//
//  Member.h
//  GroupOSX
//
//  Created by Donny Reynolds on 1/19/14.
//  Copyright (c) 2014 Dovizu Network. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Group, Image;

@interface Member : NSManagedObject

@property (nonatomic, retain) NSNumber * is_creator;
@property (nonatomic, retain) NSString * membership_id;
@property (nonatomic, retain) NSNumber * muted;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * user_id;
@property (nonatomic, retain) Group *group;
@property (nonatomic, retain) Image *image;

@end
