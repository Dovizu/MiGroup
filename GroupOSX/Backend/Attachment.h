//
//  Attachment.h
//  GroupOSX
//
//  Created by Donny Reynolds on 1/3/14.
//  Copyright (c) 2014 Dovizu Network. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Message;

@interface Attachment : NSManagedObject

@property (nonatomic, retain) id charmap;
@property (nonatomic, retain) NSString * latitude;
@property (nonatomic, retain) NSString * longitude;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * placeholder;
@property (nonatomic, retain) NSString * token;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) Message *message;

@end
