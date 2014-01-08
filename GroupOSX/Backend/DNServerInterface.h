//
//  DNServerInterface.h
//  GroupOSX
//
//  Created by Donny Reynolds on 12/25/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking.h>
#import <FayeClient.h>
#import "NSURL+NXOAuth2.h"

@class DNLoginSheetController;
@class DNMainWindowController;

#ifdef DEBUG_BACKEND
@class DNAsynchronousUnitTesting;
#endif

@interface DNServerInterface : NSObject <FayeClientDelegate>

@property DNLoginSheetController *loginSheetController;
@property DNMainWindowController *mainWindowController;

- (id)init;
- (void)setup;
- (void)teardown;
- (void)didReceiveURL:(NSString*)urlString;

#pragma mark - GroupMe Interface
//Messages
- (void)sendNewMessage:(NSString*)message
               toGroup:(NSString*)groupID
       withAttachments:(NSArray*)attachments;
//Upon completion, will send 
- (void)fetch20MessagesBeforeMessageID:(NSString*)beforeID
                               inGroup:(NSString*)groupID;
- (void)fetch20MostRecentMessagesSinceMessageID:(NSString*)sinceID
                                        inGroup:(NSString*)groupID;
//Members
- (void)addNewMembers:(NSArray*)members
              toGroup:(NSString*)groupID;
- (void)removeMember:(NSString*)membershipID
           fromGroup:(NSString*)groupID;
//relies on Message Router for comeback update

//Groups
- (void)fetchAllGroups;
- (void)fetchFormerGroups;
- (void)fetchInformationForGroup:(NSString*)groupID;
- (void)createGroupNamed:(NSString*)name
             description:(NSString*)description
                   image:(id)image
                andShare:(BOOL)allowShare;
- (void)updateGroup:(NSString*)groupID
           withName:(NSString*)name
        description:(NSString*)description
              image:(id)image
           andShare:(BOOL)allowShare;
- (void)deleteGroup:(NSString*)groupID;

@end


