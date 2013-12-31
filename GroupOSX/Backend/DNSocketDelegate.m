//
//  DNSocketDelegate.m
//  GroupOSX
//
//  Created by Donny Reynolds on 12/25/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import "DNSocketDelegate.h"

@implementation DNSocketDelegate

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    DebugLog(@"[%@] received \"%@\"", webSocket, message);
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    DebugLog(@"[%@] Connected", webSocket);
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    DebugLog(@"[%@] Failed With Error %@", webSocket, error);
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    DebugLog(@"[%@] closed", webSocket);
}

- (void)establishSockets
{
    //Close current connections if they are any
    if (messageSocket) {
        [messageSocket close];
        DebugLog(@"[%@] closed.", messageSocket);
    }
    
    //Get requests made
    NSURLRequest *messageSubscriptionRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"blah"]];
    messageSocket = [[SRWebSocket alloc] initWithURLRequest:messageSubscriptionRequest];
    [messageSocket setDelegate:self];    
    
}

@end
