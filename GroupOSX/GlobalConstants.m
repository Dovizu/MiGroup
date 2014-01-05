//
//  GlobalConstants.m
//  GroupOSX
//
//  Created by Donny Reynolds on 12/26/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import "GlobalConstants.h"

//Authentication Constants
NSString * const DNOAuth2ClientID = @"ZKKrd820vbBu0wHiizLuq9XcKLTGueKr3FFTudjsL9kpYT0N";
NSString * const DNOAuth2AuthorizationURL = @"https://api.groupme.com/oauth/authorize";
NSString * const DNOAuth2TokenURL = @"gosx://token/";
NSString * const DNOAuth2RedirectURL = @"gosx://token/";
NSString * const DNOAuth2TokenArgumentKey = @"access_token";
NSString * const DNRESTAPIBaseAddress = @"https://api.groupme.com/v3";

//RESTful constants
NSString * const HTTPMethod = @"HTTPMethod";
NSString * const partialURL = @"partialURL";
NSString * const connectionTag = @"tag";
NSString * const URLTokenParamKey = @"token";
NSString * const JSONRequestContentTypeValue = @"application/json";
NSString * const JSONRequestContentTypeKey = @"Content-Type";
NSString * const JSONRequestContentLengthKey = @"Content-Length";

NSString * const JSONObjectEmojiPlaceholderString = @"\\Ufffd";
NSString * const JSONObjectNotifierTypeGroupRelated = @"JSONObjectNotifierTypeGroupRelated";

//Generic extraction keys for NSNotification's userInfo
NSString * const kGetTypeKey = @"type";
NSString * const kGetContentKey = @"message";

//Authentication use
NSString * const noteUserInfoReceivedReadyForSockets = @"com.dovizu.grouposx.user.information.changed";

//Triggers that caused polling methods to be called
    //aritificial triggers
NSString * const noteFirstTimeLogon = @"com.dovizu.grouposx.noteFirstTimeLogon";
NSString * const noteForceRequestGroupData = @"com.dovizu.grouposx.forceRequestGroupData";
    //organic triggers, sent from Faye socket
NSString * const noteGroupMemberAdded = @"kJSONObjectNotifierTypeGroupMemberAdded";
NSString * const noteGroupMemberRemoved = @"kJSONObjectNotifierTypeGroupMemberRemoved";
NSString * const noteGroupAvatarChanged = @"kJSONObjectNotifierTypeGroupAvatarChanged";
NSString * const noteUserOwnMessageReceived = @"kJSONObjectNotifierTypeMessageReceived";
NSString * const noteMemberMessageReceived = @"kJSONObjectNotifierTypeMemberMessageReceived";

//Updates sent by Server, used in Main Window Controller
NSString * const finalGroupIndexResultsArrived = @"com.dovizu.grouposx.finalGroupIndexResultsArrived";

//Error domain names
NSString * const DNErrorDomain = @"com.dovizu.grouposx.ErrorDomain";
NSInteger const eNoNetworkConnectivityGeneral = 000;
NSString * const eNoNetworkConnectivityGeneralDesc = @"Unable to connect to GroupMe server. Please check your Internet connection.";
NSInteger const eLogOutPurgingFailure = 001;
NSString * const eLogOutPurgingFailureDesc = @"Unable to clear application data and log out.";

//User Defaults
NSString * const DNUserDefaultsUserToken = @"UserToken";
NSString * const DNUserDefaultsUserInfo = @"UserInfo";
