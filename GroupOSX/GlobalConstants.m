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

//


//Authentication use
NSString * const noteUserInfoReceivedReadyForSockets = @"com.dovizu.grouposx.user.information.changed";

//Generic extraction keys for NSNotification's userInfo
NSString * const kGetTypeKey = @"type";
NSString * const kGetContentKey = @"message";

//Messages posted by DNServerInterface
NSString * const noteMessage = @"com.dovizu.grouposx.noteMessage";
NSString * const noteMemberNameChange = @"com.dovizu.grouposx.noteMemberNameChange";
NSString * const noteGroupAvatarChange = @"com.dovizu.grouposx.noteGroupAvatarChange";
NSString * const noteGroupNameChange = @"com.dovizu.grouposx.noteGroupNameChange";
NSString * const noteMembersRemove = @"com.dovizu.grouposx.noteMembersRemove";
NSString * const noteMembersAdd = @"com.dovizu.grouposx.noteMembersAdd";
NSString * const noteAllGroupsFetch = @"com.dovizu.grouposx.forceRequestGroupData";

//Database attribute names
NSString * const k_name_group = @"name";
NSString * const k_name_member = @"nickname";
NSString * const k_group_id = @"id";
NSString * const k_type = @"type";
NSString * const k_members = @"members";
NSString * const k_image = @"image_url";
NSString * const k_email = @"email";
NSString * const k_phone_number = @"phone_number";
NSString * const k_user_id = @"user_id";
NSString * const k_membership_id = @"id";
NSString * const k_new_name = @"new_name";
NSString * const k_message = @"messages";
NSString * const k_messages = @"messages";
NSString * const k_muted = @"muted";
NSString * const k_message_id = @"id";
NSString * const k_target_group = @"group_id";
NSString * const k_text = @"text";
NSString * const k_creator_group = @"creator_user_id";
NSString * const k_creator_message = @"user_id";
NSString * const k_created_at = @"created_at";
NSString * const k_updated_at = @"updated_at";
NSString * const k_attachments = @"attachments";
NSString * const k_url = @"url";
//Triggers that caused polling methods to be called
//organic triggers
NSString * const finalGroupMemberAdded = @"kJSONObjectNotifierTypeGroupMemberAdded";
NSString * const finalGroupMemberRemoved = @"kJSONObjectNotifierTypeGroupMemberRemoved";
NSString * const finalGroupAvatarChanged = @"kJSONObjectNotifierTypeGroupAvatarChanged";
NSString * const finalUserOwnMessageReceived = @"kJSONObjectNotifierTypeMessageReceived";
NSString * const finalMemberMessageReceived = @"kJSONObjectNotifierTypeMemberMessageReceived";

//deterministic triggers
NSString * const noteFirstTimeLogon = @"com.dovizu.grouposx.noteFirstTimeLogon";

NSString * const finalGroupSpecificResultArrived = @"com.dovizu.grouposx.finalSpecificGroupResultArrived";

//Error domain names
NSString * const DNErrorDomain = @"com.dovizu.grouposx.ErrorDomain";
NSInteger const eNoNetworkConnectivityGeneral = 000;
NSString * const eNoNetworkConnectivityGeneralDesc = @"Unable to connect to GroupMe server. Please check your Internet connection.";
NSInteger const eLogOutPurgingFailure = 001;
NSString * const eLogOutPurgingFailureDesc = @"Unable to clear application data and log out.";

//User Defaults
NSString * const DNUserDefaultsUserToken = @"UserToken";
NSString * const DNUserDefaultsUserInfo = @"UserInfo";
