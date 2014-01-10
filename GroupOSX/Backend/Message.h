//
//  Message.h
//  GroupOSX
//
//  Created by Donny Reynolds on 1/9/14.
//  Copyright (c) 2014 Dovizu Network. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Attachment, Group;

@interface Message : NSManagedObject

@property (nonatomic, retain) NSDate * created_at;
@property (nonatomic, retain) NSString * message_id;
@property (nonatomic, retain) NSNumber * system;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSSet *attachments;
@property (nonatomic, retain) NSManagedObject *creator;
@property (nonatomic, retain) NSOrderedSet *favoritors;
@property (nonatomic, retain) Group *target_group;
@end

@interface Message (CoreDataGeneratedAccessors)

- (void)addAttachmentsObject:(Attachment *)value;
- (void)removeAttachmentsObject:(Attachment *)value;
- (void)addAttachments:(NSSet *)values;
- (void)removeAttachments:(NSSet *)values;

- (void)insertObject:(NSManagedObject *)value inFavoritorsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromFavoritorsAtIndex:(NSUInteger)idx;
- (void)insertFavoritors:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeFavoritorsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInFavoritorsAtIndex:(NSUInteger)idx withObject:(NSManagedObject *)value;
- (void)replaceFavoritorsAtIndexes:(NSIndexSet *)indexes withFavoritors:(NSArray *)values;
- (void)addFavoritorsObject:(NSManagedObject *)value;
- (void)removeFavoritorsObject:(NSManagedObject *)value;
- (void)addFavoritors:(NSOrderedSet *)values;
- (void)removeFavoritors:(NSOrderedSet *)values;
@end
