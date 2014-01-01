//
//  DNAsynchronousUnitTesting.h
//  GroupOSX
//
//  Created by Donny Reynolds on 12/30/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import <Foundation/Foundation.h>
@class DNServerInterface;
@class DNSocketManager;

@interface DNAsynchronousUnitTesting : NSObject
+ (void)testAllAsynchronousUnits:(DNServerInterface*)server;
+ (void)testAllSockets:(DNServerInterface*)server;
@end
