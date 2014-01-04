//
//  Member.h
//  GroupOSX
//
//  Created by Donny Reynolds on 1/3/14.
//  Copyright (c) 2014 Dovizu Network. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Group, Message;

@interface Member : NSManagedObject

@property (nonatomic, retain) NSNumber * app_installed;
@property (nonatomic, retain) NSNumber * autokicked;
@property (nonatomic, retain) NSString * guid;
@property (nonatomic, retain) NSString * user_instrinsic_id;
@property (nonatomic, retain) NSString * image_url;
@property (nonatomic, retain) NSNumber * muted;
@property (nonatomic, retain) NSString * nickname;
@property (nonatomic, retain) NSString * user_id;
@property (nonatomic, retain) NSSet *created_groups;
@property (nonatomic, retain) NSSet *favorited_messages;
@property (nonatomic, retain) NSSet *groups;
@property (nonatomic, retain) NSSet *messages;
@end

@interface Member (CoreDataGeneratedAccessors)

- (void)addCreated_groupsObject:(Group *)value;
- (void)removeCreated_groupsObject:(Group *)value;
- (void)addCreated_groups:(NSSet *)values;
- (void)removeCreated_groups:(NSSet *)values;

- (void)addFavorited_messagesObject:(Message *)value;
- (void)removeFavorited_messagesObject:(Message *)value;
- (void)addFavorited_messages:(NSSet *)values;
- (void)removeFavorited_messages:(NSSet *)values;

- (void)addGroupsObject:(Group *)value;
- (void)removeGroupsObject:(Group *)value;
- (void)addGroups:(NSSet *)values;
- (void)removeGroups:(NSSet *)values;

- (void)addMessagesObject:(Message *)value;
- (void)removeMessagesObject:(Message *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

@end
