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
@property (nonatomic, retain) id avatar;
@property (nonatomic, retain) NSString * guid;
@property (nonatomic, retain) NSNumber * muted;
@property (nonatomic, retain) NSString * nickname;
@property (nonatomic, retain) NSString * user_id;
@property (nonatomic, retain) NSString * user_instrinsic_id;
@property (nonatomic, retain) NSOrderedSet *created_groups;
@property (nonatomic, retain) NSOrderedSet *favorited_messages;
@property (nonatomic, retain) NSSet *groups;
@property (nonatomic, retain) NSOrderedSet *messages;
@end

@interface Member (CoreDataGeneratedAccessors)

- (void)insertObject:(Group *)value inCreated_groupsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromCreated_groupsAtIndex:(NSUInteger)idx;
- (void)insertCreated_groups:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeCreated_groupsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInCreated_groupsAtIndex:(NSUInteger)idx withObject:(Group *)value;
- (void)replaceCreated_groupsAtIndexes:(NSIndexSet *)indexes withCreated_groups:(NSArray *)values;
- (void)addCreated_groupsObject:(Group *)value;
- (void)removeCreated_groupsObject:(Group *)value;
- (void)addCreated_groups:(NSOrderedSet *)values;
- (void)removeCreated_groups:(NSOrderedSet *)values;
- (void)insertObject:(Message *)value inFavorited_messagesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromFavorited_messagesAtIndex:(NSUInteger)idx;
- (void)insertFavorited_messages:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeFavorited_messagesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInFavorited_messagesAtIndex:(NSUInteger)idx withObject:(Message *)value;
- (void)replaceFavorited_messagesAtIndexes:(NSIndexSet *)indexes withFavorited_messages:(NSArray *)values;
- (void)addFavorited_messagesObject:(Message *)value;
- (void)removeFavorited_messagesObject:(Message *)value;
- (void)addFavorited_messages:(NSOrderedSet *)values;
- (void)removeFavorited_messages:(NSOrderedSet *)values;
- (void)addGroupsObject:(Group *)value;
- (void)removeGroupsObject:(Group *)value;
- (void)addGroups:(NSSet *)values;
- (void)removeGroups:(NSSet *)values;

- (void)insertObject:(Message *)value inMessagesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromMessagesAtIndex:(NSUInteger)idx;
- (void)insertMessages:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeMessagesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInMessagesAtIndex:(NSUInteger)idx withObject:(Message *)value;
- (void)replaceMessagesAtIndexes:(NSIndexSet *)indexes withMessages:(NSArray *)values;
- (void)addMessagesObject:(Message *)value;
- (void)removeMessagesObject:(Message *)value;
- (void)addMessages:(NSOrderedSet *)values;
- (void)removeMessages:(NSOrderedSet *)values;
@end
