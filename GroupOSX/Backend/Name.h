//
//  Name.h
//  GroupOSX
//
//  Created by Donny Reynolds on 1/9/14.
//  Copyright (c) 2014 Dovizu Network. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Member, Message;

@interface Name : NSManagedObject

@property (nonatomic, retain) NSString * membership_id;
@property (nonatomic, retain) NSNumber * muted;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *favorited_messages;
@property (nonatomic, retain) NSSet *messages;
@property (nonatomic, retain) Member *owner;
@end

@interface Name (CoreDataGeneratedAccessors)

- (void)addFavorited_messagesObject:(Message *)value;
- (void)removeFavorited_messagesObject:(Message *)value;
- (void)addFavorited_messages:(NSSet *)values;
- (void)removeFavorited_messages:(NSSet *)values;

- (void)addMessagesObject:(Message *)value;
- (void)removeMessagesObject:(Message *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

@end
