//
//  DNSocketManagerTest.m
//  GroupOSX
//
//  Created by Donny Reynolds on 12/31/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "DNSocketManager.h"

@interface DNSocketManagerTest : XCTestCase

@end

@implementation DNSocketManagerTest
{
    DNSocketManager *socketManager;
}
- (void)setUp
{
    [super setUp];
    socketManager = [[DNSocketManager alloc] init];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testConnectingToServer
{
    [socketManager establishMessageSocket];
}

@end
