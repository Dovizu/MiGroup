//
//  DNSocketManager.m
//  GroupOSX
//
//  Created by Donny Reynolds on 12/31/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import "DNSocketManager.h"
#import "DNServerInterface.h"

@implementation DNSocketManager
{
    FayeClient *faye;
}
- (void)establishMessageSocketWithUserID:(NSString*)userID
{
    faye = [[FayeClient alloc] initWithURLString:@"https://push.groupme.com/faye"
                                         channel:[NSString stringWithFormat:@"/user/%@",userID]];
    faye.delegate = self;
    NSDictionary *ext = @{@"access_token":[self.server getUserToken],
                          @"timestamp":[[NSDate date] description]};
    [faye connectToServerWithExt:ext];
}

- (void)connectedToServer {
    DebugLog(@"Push server connected");
}

- (void)disconnectedFromServer {
    DebugLog(@"Push server disconnected");
}

- (void)messageReceived:(NSDictionary *)messageDict channel:(NSString *)channel
{
    DebugLog(@"%@", messageDict);
}

- (void)connectionFailed
{
    DebugLog(@"Push server connection failed");
}
- (void)didSubscribeToChannel:(NSString *)channel
{
    
}
- (void)didUnsubscribeFromChannel:(NSString *)channel
{
    
}
- (void)subscriptionFailedWithError:(NSString *)error
{
    
}
- (void)fayeClientError:(NSError *)error
{
    
}

- (void)fayeClientWillSendMessage:(NSDictionary *)messageDict withCallback:(FayeClientMessageHandler)callback
{
    callback(messageDict);
}

@end
