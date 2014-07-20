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

#pragma mark methods called by DNMainController
- (void)sendNewMessage:(NSString*)text toGroup:(Group*)group withAttachments:(NSArray*)attachments;
- (void)signIn;
- (void)logOut;
- (BOOL)isUser:(NSString*)userID;

- (void)firstTimeLogonSetup;

- (void)addNewMembers:(NSArray*)members
              toGroup:(NSString*)groupID;

- (void)removeMember:(NSString*)membershipID
           fromGroup:(NSString*)groupID;

- (void)changeGroupAvatar:(id)image forGroup: (NSString*)groupID;

- (void)changeGroupName:(NSString*)name forGroup: (NSString*)groupID;

- (void)createGroupNamed:(NSString*)name
             description:(NSString*)description
                   image:(id)image
                andShare:(BOOL)allowShare;

- (void)deleteGroup:(NSString*)groupID;

- (void)fetchAllGroups;

- (void)fetchFormerGroups;

- (NSImage*)getImageFromMessage:(NSString*) messageID;

#pragma mark methods called by DNServerInterface

- (void)didFetchAllGroups:(NSArray*)groups;

- (void)didFetchFormerGroups:(NSArray*)groups;

- (void)didReceiveMessages:(NSArray*)messages forGroup: (NSString*)groupID;

- (void)didUpdateMembers: (NSArray*)members forGroup: (NSString*)groupID;

- (void)didRemoveMember:(NSString*)membershipID fromGroup: (NSString*)groupID;

- (void)didUpdateGroup:(NSDictionary*) group;

- (void) didFetchInformationForGroup:(NSDictionary*)group;

- (void)didCreateGroup:(NSDictionary*)createdGroup;

- (void)didDeleteGroup:(NSString*)groupID;

- (NSString*)getLastMessageIDForGroupID:(NSString*) groupID;

@end
