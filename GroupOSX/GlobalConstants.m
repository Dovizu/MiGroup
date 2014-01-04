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

//Network observer names
NSString * const kUserInformationChanged = @"com.dovizu.grouposx.user.information.changed";
NSString * const kJSONObjectNotifierTypeGroupMemberAdded = @"kJSONObjectNotifierTypeGroupMemberAdded";
NSString * const kJSONObjectNotifierTypeGroupMemberRemoved = @"kJSONObjectNotifierTypeGroupMemberRemoved";
NSString * const kJSONObjectNotifierTypeGroupAvatarChanged = @"kJSONObjectNotifierTypeGroupAvatarChanged";
NSString * const kJSONObjectNotifierTypeMessageReceived = @"kJSONObjectNotifierTypeMessageReceived";
NSString * const kGetMessageKey = @"message";

//Error domain names
NSString * const DNErrorDomain = @"com.dovizu.grouposx.ErrorDomain";
NSInteger const eNoNetworkConnectivityGeneral = 000;
NSString * const eNoNetworkConnectivityGeneralDesc = @"Unable to connect to GroupMe server. Please check your Internet connection.";
NSInteger const eLogOutPurgingFailure = 001;
NSString * const eLogOutPurgingFailureDesc = @"Unable to clear application data and log out.";

//User Defaults
NSString * const DNUserDefaultsUserToken = @"UserToken";
NSString * const DNUserDefaultsUserInfo = @"UserInfo";
