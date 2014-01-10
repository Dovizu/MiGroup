//
//  DNRESTAPIInterface.h
//  GroupOSX
//
//  Created by Donny Reynolds on 1/8/14.
//  Copyright (c) 2014 Dovizu Network. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking.h>

@interface DNRESTAPI : NSObject

#pragma mark - Initialization and State Control
- (id)init;
- (BOOL)isReachable;
- (void)setReachabilityStatusChangeBlock:(void(^)(AFNetworkReachabilityStatus status))block;
- (void)setUserToken:(NSString*)token;

#pragma mark - API
//Users - me
//Response should be a dictionary
- (void)UsersGetInformationAndCompleteBlock:(void(^)(NSDictionary* userDict))completeBlock;
//Groups - Index
//Response should be an array of dictionaries
- (void)GroupsIndexPage:(NSInteger)nthPage
                   with:(NSInteger)groups
perPageAndCompleteBlock:(void(^)(NSArray* groupArray))completeBlock;
//Groups - Former
//Response should be an array of dictionaries
- (void)GroupsFormerAndCompleteBlock:(void(^)(NSArray* formerGroupArray))completeBlock;
//Groups - Show
//Response should be a dictionary
- (void)GroupsShow:(NSString*)groupID
  andCompleteBlock:(void(^)(NSDictionary* groupDict))completeBlock;
//Groups - Create
//Response should be a dictionary
- (void)GroupsCreateName:(NSString*)name
             description:(NSString*)description
                   image:(id)image
                   share:(BOOL)allowShare
        andCompleteBlock:(void(^)(NSDictionary* createdGroupDict))completeBlock;
//Groups - Update
//Response should be a dictionary
- (void)GroupsUpdate:(NSString*)groupID
            withName:(NSString*)name
         description:(NSString*)description
               image:(id)image
             orShare:(BOOL)allowShare
    andCompleteBlock:(void(^)(NSDictionary* updatedGroupDict))completeBlock;
//Groups - Destroy
//Response should be a status
- (void)GroupsDestroy:(NSString*)groupID andCompleteBlock:(void(^)(NSString* deleted_group_id))completeBlock;
//Members - Add
//Response should be a dictionary
- (void)MembersAdd:(NSArray*)members toGroup:(NSString*)groupID andCompleteBlock:(void(^)(NSArray* addedMembers))completeBlock;
//Members - Remove
//Response should be the removed member's membership ID
- (void)MembersRemoveUser:(NSString*)membershipID
                fromGroup:(NSString*)groupID
         andCompleteBlock:(void(^)(NSString* removedMembershipID))completeBlock;
//Messages - Index Before
//Response should be a dictionary
- (void)MessagesIndex20BeforeID:(NSString*)beforeID inGroup:(NSString*)groupID andCompleteBlock:(void(^)(NSArray* messages))completeBlock;
//Messages - Index Since
//Response should be a dictionary
- (void)MessagesIndexMostRecent20SinceID:(NSString*)sinceID inGroup:(NSString*)groupID andCompleteBlock:(void(^)(NSArray* messages))completeBlock;
//Messages - Create
//Response should be a dictionary
- (void)MessagesCreateInGroup:(NSString*)groupID
                         text:(NSString*)text
                  attachments:(NSArray*)arrayOfAttach
             andCompleteBlock:(void(^)(NSDictionary* sentMessage))completeBlock;

@end
