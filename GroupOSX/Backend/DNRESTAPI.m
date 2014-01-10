//
//  DNRESTAPIInterface.m
//  GroupOSX
//
//  Created by Donny Reynolds on 1/8/14.
//  Copyright (c) 2014 Dovizu Network. All rights reserved.
//

#import "DNRESTAPI.h"

#define report_request_error DebugLog(@"%s: %@",__PRETTY_FUNCTION__, error)
#define user_token (_userToken ? _userToken : [NSNull null])
NSString * const DNRESTAPIBaseAddress = @"https://api.groupme.com/v3";

@implementation DNRESTAPI
{
    AFHTTPRequestOperationManager *_HTTPRequestManager;
    AFNetworkReachabilityManager *_reachabilityManager;
    NSString *_userToken;
}

#pragma mark - Initialiazation and State Control
- (id)init
{
    self = [super init];
    if (self) {
        _HTTPRequestManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:DNRESTAPIBaseAddress]];
        NSMutableSet *acceptableTypes = [NSMutableSet setWithSet:_HTTPRequestManager.responseSerializer.acceptableContentTypes];
        [acceptableTypes addObject:@"text/html"];
        _HTTPRequestManager.responseSerializer.acceptableContentTypes = [NSSet setWithSet:acceptableTypes];
        _reachabilityManager = [_HTTPRequestManager reachabilityManager];
    }
    return self;
}

- (BOOL)isReachable
{
    return [_reachabilityManager isReachable];
}

- (void)setReachabilityStatusChangeBlock:(void(^)(AFNetworkReachabilityStatus status))block
{
    NSAssert(block, @"block param cannot be nil");
    [_reachabilityManager setReachabilityStatusChangeBlock:block];
}

- (void)setUserToken:(NSString*)token
{
    NSAssert(token, @"token param cannot be nil");
    _userToken = token;
}

#pragma mark - HTTP Requests Methods

//Users - me
//Response should be a dictionary
- (void)UsersGetInformationAndCompleteBlock:(void(^)(NSDictionary* userDict))completeBlock
{
    NSAssert(completeBlock, @"completion block cannot be nil");
    
    [_HTTPRequestManager GET:@"users/me"
                  parameters:@{@"token":user_token}
                     success:^(AFHTTPRequestOperation *operation, id responseObject){
                         completeBlock((NSDictionary*)responseObject[@"response"]);
                     }
                     failure:^(AFHTTPRequestOperation *operation, NSError *error){
                         report_request_error;
                         completeBlock(nil);
                     }];
}

//Groups - Index
//Response should be an array of dictionaries
- (void)GroupsIndexPage:(NSInteger)nthPage
                   with:(NSInteger)groups
perPageAndCompleteBlock:(void(^)(NSArray* groupArray))completeBlock
{
    NSAssert(nthPage, @"nthPage param cannot be nil");
    NSAssert(groups, @"groups param cannot be nil");
    NSAssert(completeBlock, @"completion block cannot be nil");
    
    [_HTTPRequestManager GET:@"groups"
                  parameters:@{@"token":user_token,
                               @"page":NSNumber(nthPage),
                               @"per_page":NSNumber(groups)}
                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                         completeBlock((NSArray*)responseObject[@"response"]);
                     }
                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                         report_request_error;
                         completeBlock(nil);
                     }];
}

//Groups - Former
//Response should be an array of dictionaries
- (void)GroupsFormerAndCompleteBlock:(void(^)(NSArray* formerGroupArray))completeBlock
{
    NSAssert(completeBlock, @"completion block cannot be nil");
    
    [_HTTPRequestManager GET:@"groups/former"
                  parameters:@{@"token":user_token}
                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                         completeBlock((NSArray*)responseObject[@"response"]);
                     }
                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                         report_request_error;
                         completeBlock(nil);
                     }];
}

//Groups - Show
//Response should be a dictionary
- (void)GroupsShow:(NSString*)groupID
  andCompleteBlock:(void(^)(NSDictionary* groupDict))completeBlock
{
    NSAssert(groupID, @"groupID param cannot be nil");
    NSAssert(completeBlock, @"completion block cannot be nil");
    
    [_HTTPRequestManager GET:concatStrings(@"groups/%@", groupID)
                  parameters:@{@"token":user_token,
                               @"id":groupID}
                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                         completeBlock((NSDictionary*)responseObject[@"response"]);
                     }
                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                         report_request_error;
                         completeBlock(nil);
                     }];
}

//Groups - Create
//Response should be a dictionary
- (void)GroupsCreateName:(NSString*)name
             description:(NSString*)description
                   image:(id)image
                   share:(BOOL)allowShare
        andCompleteBlock:(void(^)(NSDictionary* createdGroupDict))completeBlock
{
    NSAssert(name, @"name param cannot be nil");
    NSAssert(completeBlock, @"completion block cannot be nil");
    
    void (^createGroup)(NSString*) = ^void(NSString* imageURL){
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        [params setObject:name          forKey:@"name"];
        [params setObject:user_token    forKey:@"token"];
        if (description)    {[params setObject:description  forKey:@"description"];}
        if (imageURL)       {[params setObject:imageURL     forKey:@"image_url"];}
        if (allowShare)     {[params setObject:@"true"      forKey:@"share"];}
        [_HTTPRequestManager POST:@"groups"
                       parameters:params
                          success:^(AFHTTPRequestOperation *operation, id responseObject) {
                              completeBlock((NSDictionary*)responseObject[@"response"]);
                          }
                          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                              report_request_error;
                              completeBlock(nil);
                          }];
        
    };
    if (image) {
        [self helpAsyncUploadImageToGroupMe:image usingBlock:^(NSString *imageURL) {
            createGroup(imageURL);
        }];
    }else{
        createGroup(nil);
    }
}

//Groups - Update
//Response should be a dictionary
- (void)GroupsUpdate:(NSString*)groupID
            withName:(NSString*)name
         description:(NSString*)description
               image:(id)image
             orShare:(BOOL)allowShare
    andCompleteBlock:(void(^)(NSDictionary* updatedGroupDict))completeBlock
{
    NSAssert(groupID, @"groupID param cannot be nil");
    NSAssert(completeBlock, @"completion block cannot be nil");
    
    void (^updateGroup)(NSString*) = ^void(NSString* imageURL){
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        [params setObject:user_token forKey:@"token"];
        if (name)           {[params setObject:name forKey:@"name"];}
        if (description)    {[params setObject:description forKey:@"description"];}
        if (allowShare)     {[params setObject:@"true" forKey:@"share"];}else{[params setObject:@"false" forKey:@"share"];}
        if (imageURL)       {[params setObject:imageURL forKey:@"image"];}
        //"baseURL/groups/group_id/update"
        [_HTTPRequestManager POST:concatStrings(@"groups/%@/update", groupID)
                       parameters:params
                          success:^(AFHTTPRequestOperation *operation, id responseObject) {
                              completeBlock((NSDictionary*)responseObject[@"response"]);
                          }
                          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                              report_request_error;
                              completeBlock(nil);
                          }];
    };
    if (image) {
        [self helpAsyncUploadImageToGroupMe:image usingBlock:^(NSString *imageURL) {
            updateGroup(imageURL);
        }];
    }else{
        updateGroup(nil);
    }
}

//Groups - Destroy
//Response should be a status
- (void)GroupsDestroy:(NSString*)groupID andCompleteBlock:(void(^)(NSString* deleted_group_id))completeBlock
{
    NSAssert(groupID, @"groupID param cannot be nil");
    NSAssert(completeBlock, @"completion block cannot be nil");
    
    [_HTTPRequestManager POST:concatStrings(@"groups/%@/destroy", groupID)
                   parameters:@{@"token": user_token}
                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                          completeBlock(groupID);
                      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                          //Do not expect a response but does check statusCode
                          if ([[operation response] statusCode] / 100 == 2) {
                              completeBlock(groupID);
                              completeBlock(nil);
                          }else{
                              report_request_error;
                          }
                      }];
}

//Members - Add
//Response should be a dictionary
- (void)MembersAdd:(NSArray*)members toGroup:(NSString*)groupID andCompleteBlock:(void(^)(NSArray* addedMembers))completeBlock
{
    NSAssert((members), @"members param cannot be nil");
    NSAssert([members count], @"members param cannot be empty array");
    NSAssert([members[0] isKindOfClass:[NSDictionary class]], @"members param does not contain dictionaries");
    NSAssert(groupID, @"groupID param cannot be nil");
    NSAssert(completeBlock, @"completion block cannot be nil");
    
    [members enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger __unused idx, BOOL __unused *stop) {
        NSDictionary *member = (NSDictionary*)obj;
        NSAssert(member[@"nickname"], @"One or more users don't have a valid nickname");
    }];
    
    NSDictionary *userInfo = @{@"members": members,
                               @"token": user_token};
    [_HTTPRequestManager POST:concatStrings(@"groups/%@/members/add", groupID)
                   parameters:userInfo
                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                          [self MembersResults:((NSDictionary*)responseObject)[@"response"][@"results_id"]
                                       inGroup:groupID
                              andCompleteBlock:completeBlock
                                       attempt:1];
                      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                          report_request_error;
                      }];
}

//Members - Remove
//Response should be the removed member's membership ID
- (void)MembersRemoveUser:(NSString*)membershipID
                fromGroup:(NSString*)groupID
         andCompleteBlock:(void(^)(NSString* removedMembershipID))completeBlock
{
    NSAssert(membershipID, @"membershipID param cannot be nil");
    NSAssert(groupID, @"groupID param cannot be nil");
    NSAssert(completeBlock, @"completion block cannot be nil");
    
    NSDictionary *params = @{@"token": user_token};
    [_HTTPRequestManager POST:concatStrings(@"groups/%@/members/%@/remove", groupID, membershipID)
                   parameters:params
                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                          completeBlock(membershipID);
                      }
                      failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                          report_request_error;
                          completeBlock(nil);
                      }];
}

//Members - Results
//Response should be an array
- (void)MembersResults:(NSString*)resultsID
               inGroup:(NSString*)groupID
      andCompleteBlock:(void(^)(NSArray* addedMembers))completeBlock
               attempt:(NSInteger)nthAttempt
{
    NSAssert(resultsID, @"resultsID param cannot be nil");
    NSAssert(completeBlock, @"completeBlock cannot be nil");
    NSAssert(nthAttempt, @"nthAttempt cannot be nil or 0");
    if (nthAttempt > 10) {
        DebugLog(@"Error fetching results for newly added members");
        completeBlock(nil);
        return;
    }
    
    NSDictionary *params = @{@"token": user_token,
                             @"results_id": resultsID};
    [_HTTPRequestManager GET:concatStrings(@"groups/%@/members/results/%@", groupID, resultsID)
                  parameters:params
                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                         completeBlock(((NSDictionary*)responseObject)[@"response"][@"members"]);
                     }
                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                         report_request_error;
                         dispatch_queue_t queue = dispatch_queue_create("com.dovizu.grouposx.resultsFetching", DISPATCH_QUEUE_CONCURRENT);
                         dispatch_async(queue, ^{
                             NSLog(@"%@", [NSThread currentThread]);
                             usleep(1000000); //wait for 1 second and try again
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 [self MembersResults:resultsID
                                              inGroup:groupID
                                     andCompleteBlock:completeBlock
                                              attempt:nthAttempt+1];
                             });
                         });
                     }];
}

//Messages - Index Before
//Response should be a dictionary
- (void)MessagesIndex20BeforeID:(NSString*)beforeID inGroup:(NSString*)groupID andCompleteBlock:(void(^)(NSArray* messages))completeBlock
{
    NSAssert(beforeID, @"beforeID param cannot be nil");
    NSAssert(groupID, @"groupID param cannot be nil");
    NSAssert(completeBlock, @"completion block cannot be nil");
    
    NSDictionary *params = @{@"token":    user_token,
                             @"before_id": beforeID};
    [_HTTPRequestManager GET:concatStrings(@"groups/%@/messages", groupID)
                  parameters:params
                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                         completeBlock(((NSDictionary*)responseObject[@"response"])[@"messages"]);
                     }
                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                         report_request_error;
                         completeBlock(nil);
                     }];
}

//Messages - Index Since
//Response should be a dictionary
- (void)MessagesIndexMostRecent20SinceID:(NSString*)sinceID inGroup:(NSString*)groupID andCompleteBlock:(void(^)(NSArray* messages))completeBlock
{
    NSAssert(sinceID, @"sinceID cannot be nil");
    NSAssert(groupID, @"groupID param cannot be nil");
    NSAssert(completeBlock, @"completion block cannot be nil");
    
    NSDictionary *params = @{@"token":    user_token,
                             @"since_id": sinceID};
    [_HTTPRequestManager GET:concatStrings(@"groups/%@/messages", groupID)
                  parameters:params
                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                         if (completeBlock) {
                             completeBlock(((NSDictionary*)responseObject[@"response"])[@"messages"]);
                         }
                     }
                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                         report_request_error;
                         completeBlock(nil);
                     }];
}

//Messages - Create
//Response should be a dictionary
- (void)MessagesCreateInGroup:(NSString*)groupID
                         text:(NSString*)text
                  attachments:(NSArray*)arrayOfAttach
             andCompleteBlock:(void(^)(NSDictionary* sentMessage))completeBlock
{
    NSAssert(groupID, @"groupID param cannot be nil");
    NSAssert(text, @"text param cannot be nil");
    NSAssert(completeBlock, @"completion block cannot be nil");
    
    
    arrayOfAttach = nil; //Not releasing this feature yet
    if (arrayOfAttach){
        NSMutableArray *convertedAttachments = [[NSMutableArray alloc] initWithCapacity:[arrayOfAttach count]];
        
        //The block that processes an attachment
        void (^processAttachment)(NSDictionary*) = ^void(NSDictionary* attachment){
            if ([attachment[@"type"]  isEqual: @"image"]) {
                //do something about the image, check its validity
            }else if ([attachment[@"type"] isEqualToString:@"location"]){
                //do something about location, check its validity
            }else if ([attachment[@"type"] isEqualToString:@"split"]){
                //do something about the split, check its validity
            }else if ([attachment[@"type"] isEqualToString:@"emoji"]){
                //do something about this emoji, check its validity
            }
        };
        
        [arrayOfAttach enumerateObjectsWithOptions:NSEnumerationConcurrent
                                        usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                            processAttachment((NSDictionary*)obj);
                                        }];
        arrayOfAttach = convertedAttachments;
    }
    NSDictionary *params = @{@"source_guid": @"source_guid_here",
                             @"text": text,
                             @"token": user_token};
    [_HTTPRequestManager POST:concatStrings(@"groups/%@/messages", groupID)
                   parameters:params
                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                          completeBlock((NSDictionary*)responseObject[@"message"]);
                      }
                      failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                          report_request_error;
                          completeBlock(nil);
                      }];
}

#pragma mark - Helper Methods

//Image Service
//Response should be a string of URL, nil if upload failed
- (void)helpAsyncUploadImageToGroupMe:(id)image usingBlock:(void(^)(NSString* imageURL))completeBlock
{
    NSAssert(image, @"Image cannot be nil");
    NSString *imageURL = nil;
    //upload image
    completeBlock(imageURL);
}

@end
