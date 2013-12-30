//
//  DNServerInterface.h
//  GroupOSX
//
//  Created by Donny Reynolds on 12/25/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

//Basic stuff
#import <Foundation/Foundation.h>
#include "GlobalConstants.h"
#import <AFNetworking.h>
#import "NSURL+NXOAuth2.h"

//App headers
#import "DNSocketDelegate.h"
@class DNLoginSheetController;

@interface DNServerInterface : NSObject

@property DNLoginSheetController *loginSheetController;

- (id)init;
- (BOOL)isLoggedIn;
- (void)authenticate;
- (void)didReceiveURL:(NSString*)urlString;
@end
