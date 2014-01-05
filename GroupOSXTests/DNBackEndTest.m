//
//  DNBackEndTest.m
//  GroupOSX
//
//  Created by Donny Reynolds on 12/25/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "DNServerInterface.h"

@interface DNBackEndTest : XCTestCase
{
    DNServerInterface* server;
}
@end

@interface DNServerInterface (Test)
- (void)convertRawDictionary:(NSDictionary*)oldDict usingBlock:(void(^)(NSDictionary* newDict))block;
- (void)GroupsShow:(NSString*)groupID andCompleteBlock:(void(^)(NSDictionary* groupsShowData))completeBlock;
@end

@implementation DNBackEndTest

- (void)setUp
{
    [super setUp];
    server = [[DNServerInterface alloc] init];
    
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}



- (void)testConvertRawDictionary
{
    //test converting dates
    NSDictionary *dict = @{@"created_at": @"1388914990"};
    [server convertRawDictionary:dict usingBlock:^(NSDictionary *newDict) {
        NSLog(@"%@", newDict[@"created_at"]);
    }];
    
    //test images
    dict = @{@"type":@"image", @"url": @"http://i.groupme.com/116e96f0a4da0130f4466ab9833e124e"};
    [server convertRawDictionary:dict usingBlock:^(NSDictionary *newDict) {
        NSLog(@"%@", newDict[@"image"]);
    }];
}

@end
