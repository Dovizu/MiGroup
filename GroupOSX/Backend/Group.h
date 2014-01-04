//
//  Group.h
//  GroupOSX
//
//  Created by Donny Reynolds on 1/3/14.
//  Copyright (c) 2014 Dovizu Network. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Member, Message;

@interface Group : NSManagedObject

@property (nonatomic, retain) NSDate * created_at;
@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSString * group_id;
@property (nonatomic, retain) id image;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * share_url;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSDate * updated_at;
@property (nonatomic, retain) Member *creator;
@property (nonatomic, retain) NSOrderedSet *members;
@property (nonatomic, retain) NSOrderedSet *messages;
@end

@interface Group (CoreDataGeneratedAccessors)

- (void)insertObject:(Member *)value inMembersAtIndex:(NSUInteger)idx;
- (void)removeObjectFromMembersAtIndex:(NSUInteger)idx;
- (void)insertMembers:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeMembersAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInMembersAtIndex:(NSUInteger)idx withObject:(Member *)value;
- (void)replaceMembersAtIndexes:(NSIndexSet *)indexes withMembers:(NSArray *)values;
- (void)addMembersObject:(Member *)value;
- (void)removeMembersObject:(Member *)value;
- (void)addMembers:(NSOrderedSet *)values;
- (void)removeMembers:(NSOrderedSet *)values;
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
