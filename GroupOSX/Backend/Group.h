//
//  Group.h
//  GroupOSX
//
//  Created by Donny Reynolds on 1/19/14.
//  Copyright (c) 2014 Dovizu Network. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Image, Member, Message;

@interface Group : NSManagedObject

@property (nonatomic, retain) NSDate * created_at;
@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSString * group_id;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) id share_url;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSDate * updated_at;
@property (nonatomic, retain) Member *creator;
@property (nonatomic, retain) Message *last_message;
@property (nonatomic, retain) NSSet *members;
@property (nonatomic, retain) NSSet *messages;
@property (nonatomic, retain) Image *image;
@end

@interface Group (CoreDataGeneratedAccessors)

- (void)addMembersObject:(Member *)value;
- (void)removeMembersObject:(Member *)value;
- (void)addMembers:(NSSet *)values;
- (void)removeMembers:(NSSet *)values;

- (void)addMessagesObject:(Message *)value;
- (void)removeMessagesObject:(Message *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

@end
