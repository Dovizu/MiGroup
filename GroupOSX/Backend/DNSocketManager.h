//
//  DNSocketManager.h
//  GroupOSX
//
//  Created by Donny Reynolds on 12/31/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FayeClient.h>
@class DNServerInterface;

@interface DNSocketManager : NSObject <FayeClientDelegate>

- (void)establishMessageSocketWithUserID:(NSString*)userID;

@property DNServerInterface *server;

@end
