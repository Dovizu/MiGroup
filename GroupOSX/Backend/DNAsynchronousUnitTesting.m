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

@end

@implementation DNAsynchronousUnitTesting
+ (void)testAllAsynchronousUnits:(DNServerInterface*)server
{
    DebugLog(@"=========Asynchronous Units Testing============");
    
    //UsersGetInformation
    [server UsersGetInformationAndCompleteBlock:^(NSDictionary *userInfo) {
        if (userInfo) {
            DebugLog(@"UsersGetInformation: %d entries", (int)[userInfo count]);
        }else{
            DebugLog(@"UsersGetInformation failed");
        }
    }];
    
    //Groups Index
    [server GroupsIndexPage:1 with:10 andCompleteBlock:^(NSDictionary *groupsIndexData) {
        if (groupsIndexData) {
            DebugLog(@"GroupIndex: %u entries",(int)[groupsIndexData count]);
        }else{
            DebugLog(@"GroupsIndexFailed");
        }
    }];
    
    //Groups Former
    [server GroupsFormerAndCompleteBlock:^(NSDictionary *groupsFormerData) {
        if (groupsFormerData) {
            DebugLog(@"GroupsFormer: %u entries", (int)[groupsFormerData count]);
        }else{
            DebugLog(@"GroupsFormer failed");
        }
    }];
}

+ (void)testAllSockets:(DNServerInterface*)server
{
    [server establishMessageSocket];
}

@end
