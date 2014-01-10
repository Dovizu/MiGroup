//
//  Member.h
//  GroupOSX
//
//  Created by Donny Reynolds on 1/9/14.
//  Copyright (c) 2014 Dovizu Network. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Group;

@interface Member : NSManagedObject

@property (nonatomic, retain) id image;
@property (nonatomic, retain) NSString * user_id;
@property (nonatomic, retain) Group *created_group;
@property (nonatomic, retain) Group *membership_group;
@property (nonatomic, retain) NSSet *names;
@end

@interface Member (CoreDataGeneratedAccessors)

- (void)addNamesObject:(NSManagedObject *)value;
- (void)removeNamesObject:(NSManagedObject *)value;
- (void)addNames:(NSSet *)values;
- (void)removeNames:(NSSet *)values;

@end
