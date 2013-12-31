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

@implementation DNBackEndTest

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    server = [[DNServerInterface alloc] init];
    [server setTokenTo:@"b8f461104fdc0131750036749a13f9f7"];
    
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


@end
