//
//  DNServerInterface.h
//  GroupOSX
//
//  Created by Donny Reynolds on 12/25/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking.h>
#import <KSReachability/KSReachability.h>
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

@end


