//
//  DNAsynchronousUnitTesting.m
//  GroupOSX
//
//  Created by Donny Reynolds on 12/30/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import "DNAsynchronousUnitTesting.h"
#import "DNServerInterface.h"

@interface DNServerInterface (Testing)

- (void)establishMessageSocket;
- (void)UsersGetInformationAndCompleteBlock:(void(^)(NSDictionary* userInfo))completeBlock;
- (void)GroupsIndexPage:(NSInteger)nthPage
                   with:(NSInteger)groups
perPageAndCompleteBlock:(void(^)(NSArray* groupArray))completeBlock;
- (void)GroupsFormerAndCompleteBlock:(void(^)(NSArray* groupsFormerData))completeBlock;
- (void)GroupsShow:(NSString*)groupID andCompleteBlock:(void(^)(NSDictionary* groupsShowData))completeBlock;
- (void)GroupsCreateName:(NSString*)name
             description:(NSString*)description
                   image:(id)image
                   share:(BOOL)allowShare
        andCompleteBlock:(void(^)(NSDictionary* createdGroupDict))completeBlock;
- (void)GroupsUpdate:(NSString*)groupID
            withName:(NSString*)name
         description:(NSString*)description
               image:(id)image
             orShare:(BOOL)allowShare
    andCompleteBlock:(void(^)(NSDictionary* createdGroupDict))completeBlock;
- (void)GroupsDestroy:(NSString*)groupID andCompleteBlock:(void(^)(id responseBody))completeBlock;
- (void)MembersAdd:(NSArray*)members toGroup:(NSString*)groupID andCompleteBlock:(void(^)())completeBlock;
- (void)MembersRemoveUser:(NSString*)userID
                fromGroup:(NSString*)groupID
         andCompleteBlock:(void(^)())completeBlock;
@end

@implementation DNAsynchronousUnitTesting
+ (void)testAllAsynchronousUnits:(DNServerInterface*)server
{
    DebugLog(@"=========Asynchronous Units Testing============");
    
//    //UsersGetInformation
//    [server UsersGetInformationAndCompleteBlock:^(NSDictionary *userInfo) {
//        if (userInfo) {
//            DebugLog(@"UsersGetInformation: %d entries", (int)[userInfo count]);
//        }else{
//            DebugLog(@"UsersGetInformation failed");
//        }
//    }];
//    
    //Groups Index
//    [server GroupsIndexPage:1 with:10 perPageAndCompleteBlock:^(NSArray *groupsIndexData) {
//        if (groupsIndexData) {
//            DebugLog(@"%@", groupsIndexData);
//        }else{
//            DebugLog(@"GroupsIndexFailed");
//        }
//    }];
//
//    //Groups Former
//    [server GroupsFormerAndCompleteBlock:^(NSArray *groupsFormerData) {
//        if (groupsFormerData) {
//            DebugLog(@"GroupsFormer: %u entries", (int)[groupsFormerData count]);
//        }else{
//            DebugLog(@"GroupsFormer failed");
//        }
//    }];
//    
//    [server GroupsShow:@"6622360" andCompleteBlock:^(NSDictionary *groupsShowData) {
//        NSLog(@"%@", groupsShowData);
//    }];
//    [server GroupsShow:@"6736514" andCompleteBlock:^(NSDictionary *groupsShowData) {
//        NSLog(@"%@", groupsShowData);
//    }];
////
//    [server GroupsCreateName:@"XCTest test group" description:@"blah" image:nil share:NO andCompleteBlock:^(NSDictionary *createdGroupDict) {
//        DebugLog(@"Group Created:\n%@", createdGroupDict);
//    }];
//    [server GroupsUpdate:@"6746608" withName:@"XCTest name change" description:@"description change" image:nil orShare:YES andCompleteBlock:^(NSDictionary *updatedGroupDict) {
//        DebugLog(@"Group Updated:\n%@", updatedGroupDict);
//    }];
//    
//    [server GroupsDestroy:@"6746948" andCompleteBlock:^(id responseBody) {
//        DebugLog(@"%@", responseBody);
//    }];
    
//    NSArray *membersToAdd = @[
//                              @{@"nickname": @"Kha",
//                                @"phone_number":@"+1 9255664491"},
//                              @{@"nickname":@"Omer",
//                                @"phone_number":@"+1 2097519635"}];
//    [server MembersAdd:membersToAdd toGroup:@"6736514" andCompleteBlock:^() {
//    }];
    
    [server MembersRemoveUser:@"11201736" fromGroup:@"6736514" andCompleteBlock:^() {
    }];
    
}

+ (void)testAllSockets:(DNServerInterface*)server
{
    [server establishMessageSocket];
}

@end
