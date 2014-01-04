//
//  Message.h
//  GroupOSX
//
//  Created by Donny Reynolds on 1/3/14.
//  Copyright (c) 2014 Dovizu Network. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Attachment, Group, Member;

@interface Message : NSManagedObject

@property (nonatomic, retain) NSDate * created_at;
@property (nonatomic, retain) NSString * message_id;
@property (nonatomic, retain) NSString * source_guid;
@property (nonatomic, retain) NSNumber * system;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSSet *attachments;
@property (nonatomic, retain) Member *creator;
@property (nonatomic, retain) NSOrderedSet *favoritor;
@property (nonatomic, retain) Group *target_group;
@end

@interface Message (CoreDataGeneratedAccessors)

- (void)addAttachmentsObject:(Attachment *)value;
- (void)removeAttachmentsObject:(Attachment *)value;
- (void)addAttachments:(NSSet *)values;
- (void)removeAttachments:(NSSet *)values;

- (void)insertObject:(Member *)value inFavoritorAtIndex:(NSUInteger)idx;
- (void)removeObjectFromFavoritorAtIndex:(NSUInteger)idx;
- (void)insertFavoritor:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeFavoritorAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInFavoritorAtIndex:(NSUInteger)idx withObject:(Member *)value;
- (void)replaceFavoritorAtIndexes:(NSIndexSet *)indexes withFavoritor:(NSArray *)values;
- (void)addFavoritorObject:(Member *)value;
- (void)removeFavoritorObject:(Member *)value;
- (void)addFavoritor:(NSOrderedSet *)values;
- (void)removeFavoritor:(NSOrderedSet *)values;
@end
