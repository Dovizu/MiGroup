//
//  DNDataManager.h
//  GroupOSX
//
//  Created by Donny Reynolds on 12/26/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Group.h"
#import "Attachment.h"
#import "Message.h"
#import "Member.h"
#import "Image.h"

#import <AFNetworking.h>

@class DNServerInterface;
@class DNAppDelegate;
@class DNMainController;

@interface DNDataManager : NSObject

@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property DNServerInterface *server;
@property DNMainController *mainController;

- (void)sendNewMessage:(NSString*)text toGroup:(Group*)group withAttachments:(NSArray*)attachments;
- (void)signIn;
- (void)logOut;
- (BOOL)isUser:(NSString*)userID;

@end
