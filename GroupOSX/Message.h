//
//  Message.h
//  GroupOSX
//
//  Created by Donny Reynolds on 1/19/14.
//  Copyright (c) 2014 Dovizu Network. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Attachment, Group, Image;

@interface Message : NSManagedObject

@property (nonatomic, retain) NSDate * created_at;
@property (nonatomic, retain) NSString * message_id;
@property (nonatomic, retain) NSNumber * system;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSString * sender_user_id;
@property (nonatomic, retain) NSString * sender_name;
@property (nonatomic, retain) NSSet *attachments;
@property (nonatomic, retain) Group *target_group;
@property (nonatomic, retain) Image *sender_avatar;
@end

@interface Message (CoreDataGeneratedAccessors)

- (void)addAttachmentsObject:(Attachment *)value;
- (void)removeAttachmentsObject:(Attachment *)value;
- (void)addAttachments:(NSSet *)values;
- (void)removeAttachments:(NSSet *)values;

@end
