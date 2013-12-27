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
    NSLog(@"Received \"%@\"", message);
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    NSLog(@"Websocket Connected");
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    NSLog(@":( Websocket Failed With Error %@", error);
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    NSLog(@"WebSocket closed");
}


@end
