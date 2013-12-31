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

@class DNSocketManager;
@class DNLoginSheetController;

#ifdef DEBUG
@class DNAsynchronousUnitTesting;
#endif

@interface DNServerInterface : NSObject

@property DNLoginSheetController *loginSheetController;

- (id)init;
- (BOOL)isLoggedIn;
- (BOOL)isConnected;
- (NSString*)getUserToken;
- (void)authenticate;
- (void)didReceiveURL:(NSString*)urlString;

//RESTful API
- (void)UsersGetInformationAndCompleteBlock:(void(^)(NSDictionary* userInfo))completeBlock;
- (void)GroupsIndexPage:(NSInteger)nthPage with:(NSInteger)pagesPerPage andCompleteBlock:(void(^)(NSDictionary* groupsIndexData))completeBlock;
- (void)GroupsFormerAndCompleteBlock:(void(^)(NSDictionary* groupsFormerData))completeBlock;
- (void)GroupsShow:(NSString*)groupID andCompleteBlock:(void(^)(NSDictionary* groupsShowData))completeBlock;
@end
