/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 Copyright (c) 2012, Janrain, Inc.

 All rights reserved.

 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:

 * Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation and/or
   other materials provided with the distribution.
 * Neither the name of the Janrain, Inc. nor the names of its
   contributors may be used to endorse or promote products derived from this
   software without specific prior written permission.


 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 File:   JRCaptureInterface.m
 Author: Lilli Szafranski - lilli@janrain.com, lillialexis@gmail.com
 Date:   Thursday, January 26, 2012
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */


#ifdef DEBUG
#define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define DLog(...)
#endif

#define ALog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
static NSString *const cSignInUser = @"signinUser";
static NSString *const cCreateUser = @"createUser";
static NSString *const cGetUser = @"getUser";
static NSString *const cGetObject = @"getObject";
static NSString *const cUpdateObject = @"updateObject";
static NSString *const cReplaceObject = @"replaceObject";
static NSString *const cReplaceArray = @"replaceArray";
static NSString *const cTagAction = @"action";

#import "JRCaptureApidInterface.h"
#import "JRCaptureData.h"
#import "JSONKit.h"
#import "JRCaptureError.h"
#import "JRCaptureUser.h"
#import "JRCaptureUser+Extras.h"
#import "JRCapture.h"


@implementation JRCaptureApidInterface
static JRCaptureApidInterface *singleton = nil;

/* Here for testing against Carl's local instance */
#ifdef TESTING_CARL_LOCAL
static NSString *appIdArg = @"&application_id=qx3ss262yufnmpb3ck93jr3zfs"
#endif

- (JRCaptureApidInterface *)init
{
    if ((self = [super init])) { }

    return self;
}

+ (id)captureInterfaceInstance
{
    if (singleton == nil) {
        singleton = [((JRCaptureApidInterface *)[super allocWithZone:NULL]) init];
    }

    return singleton;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [[self captureInterfaceInstance] retain];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
{
    return NSUIntegerMax;
}

- (oneway void)release { }

- (id)autorelease
{
    return self;
}

typedef enum CaptureInterfaceStatEnum
{
    StatOk,
    StatFail,
} CaptureInterfaceStat;

- (void)finishCreateCaptureUserWithStat:(CaptureInterfaceStat)stat andResult:(NSObject *)result
                            forDelegate:(id <JRCaptureInterfaceDelegate>)delegate withContext:(NSObject *)context
{
    DLog(@"");

    if (stat == StatOk)
    {
        if ([delegate respondsToSelector:@selector(createCaptureUserDidSucceedWithResult:context:)])
            [delegate createCaptureUserDidSucceedWithResult:result context:context];
    }
    else
    {
        if ([delegate respondsToSelector:@selector(createCaptureUserDidFailWithResult:context:)])
            [delegate createCaptureUserDidFailWithResult:result context:context];
    }
}

- (void)startCreateCaptureUser:(NSDictionary *)captureUser withToken:(NSString *)token
                   forDelegate:(id <JRCaptureInterfaceDelegate>)delegate withContext:(NSObject *)context
{
    DLog(@"");

    NSString      *attributes = [[captureUser JSONString] stringByAddingUrlPercentEscapes];
    NSMutableData *body       = [NSMutableData data];

    [body appendData:[[NSString stringWithFormat:@"type_name=%@", [JRCaptureData entityTypeName]] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"&attributes=%@", attributes] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"&creation_token=%@", token] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"&include_record=true" dataUsingEncoding:NSUTF8StringEncoding]];

#ifdef TESTING_CARL_LOCAL
    if (appIdArg)
        [body appendData:[appIdArg dataUsingEncoding:NSUTF8StringEncoding]];
#endif

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:
                                     [NSURL URLWithString:
                                      [NSString stringWithFormat:@"%@/entity.create", [JRCaptureData captureApidBaseUrl]]]];

    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:body];

    NSDictionary *tag = [NSDictionary dictionaryWithObjectsAndKeys:
                                              cCreateUser, cTagAction,
                                        delegate, @"delegate",
                                        context, @"context", nil];

    DLog(@"%@ type_name=%@ attributes=%@ creation_token=%@", [[request URL] absoluteString], [JRCaptureData entityTypeName], attributes, token);

    if (![JRConnectionManager createConnectionFromRequest:request forDelegate:self withTag:tag])
        [self finishCreateCaptureUserWithStat:StatFail
                                    andResult:[NSDictionary dictionaryWithObjectsAndKeys:
                                                            @"error", @"stat",
                                                            @"url_connection", @"error",
                                                            [NSString stringWithFormat:@"Could not create a connection to %@", [[request URL] absoluteString]], @"error_description",
                                                            [NSNumber numberWithInteger:JRCaptureLocalApidErrorUrlConnection], @"code", nil]
                                       forDelegate:delegate
                                       withContext:context];

}

- (void)finishSignInFailureWithResult:(NSDictionary *)result forDelegate:(id <JRCaptureInterfaceDelegate>)delegate
                          withContext:(NSObject *)context
{
    if ([delegate respondsToSelector:@selector(signinCaptureUserDidFailWithResult:context:)])
        [delegate signinCaptureUserDidFailWithResult:result context:context];
}

- (void)finishSignInSuccessWithResult:(NSString *)result forDelegate:(id <JRCaptureInterfaceDelegate>)delegate
                          withContext:(NSObject *)context
{
    if ([delegate respondsToSelector:@selector(signinCaptureUserDidSucceedWithResult:context:)])
        [delegate signinCaptureUserDidSucceedWithResult:result context:context];
}


- (void)startSigninCaptureUserWithCredentials:(NSDictionary *)credentials ofType:(NSString *)signInType
                             forDelegate:(id <JRCaptureInterfaceDelegate>)delegate withContext:(NSObject *)context
{
    DLog(@"");

    NSMutableData *body = [NSMutableData data];
    NSString *signInName = [credentials objectForKey:signInType];
    NSString *password   = [credentials objectForKey:@"password"];

    [body appendData:[[NSString stringWithFormat:@"%@=%@", signInType, signInName] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"&password=%@", password] dataUsingEncoding:NSUTF8StringEncoding]];
    //[body appendData:[[NSString stringWithFormat:@"&type_name=%@", [JRCaptureData entityTypeName]] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"&client_id=%@", [JRCaptureData clientId]] dataUsingEncoding:NSUTF8StringEncoding]];


#ifdef TESTING_CARL_LOCAL
    if (appIdArg)
        [body appendData:[appIdArg dataUsingEncoding:NSUTF8StringEncoding]];
#endif

    NSString *const signInEndpoint = [NSString stringWithFormat:@"%@/oauth/mobile_signin_username_password",
                                               [JRCaptureData captureUIBaseUrl]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:signInEndpoint]];

    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:body];

    NSDictionary *tag = [NSDictionary dictionaryWithObjectsAndKeys:
                                                 cSignInUser, cTagAction,
                                                 delegate, @"delegate",
                                                 context, @"context", nil];

    DLog(@"%@ %@=%@", [[request URL] absoluteString], signInType, signInName);
    //DLog(@"body: %@", [[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] autorelease]);

    if (![JRConnectionManager createConnectionFromRequest:request forDelegate:self withTag:tag])
        [self finishSignInFailureWithResult:[NSDictionary dictionaryWithObjectsAndKeys:
                                                    @"error", @"stat",
                                                    @"url_connection", @"error",
                                                    [NSString stringWithFormat:@"Could not create a connection to %@", [[request URL] absoluteString]], @"error_description",
                                                    [NSNumber numberWithInteger:JRCaptureLocalApidErrorUrlConnection], @"code", nil]
                                  forDelegate:delegate
                                  withContext:context];
}

- (void)finishGetCaptureUserWithStat:(CaptureInterfaceStat)stat andResult:(NSObject *)result
                         forDelegate:(id <JRCaptureInterfaceDelegate>)delegate withContext:(NSObject *)context
{
    DLog(@"");

    if (stat == StatOk)
    {
        if ([delegate respondsToSelector:@selector(getCaptureUserDidSucceedWithResult:context:)])
            [delegate getCaptureUserDidSucceedWithResult:result context:context];
    }
    else
    {
        if ([delegate respondsToSelector:@selector(getCaptureUserDidFailWithResult:context:)])
            [delegate getCaptureUserDidFailWithResult:result context:context];
    }
}

- (void)startGetCaptureUserWithToken:(NSString *)token
                         forDelegate:(id <JRCaptureInterfaceDelegate>)delegate withContext:(NSObject *)context
{
    DLog(@"");

    NSMutableData *body = [NSMutableData data];

    [body appendData:[[NSString stringWithFormat:@"type_name=%@", [JRCaptureData entityTypeName]] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"&access_token=%@", token] dataUsingEncoding:NSUTF8StringEncoding]];

#ifdef TESTING_CARL_LOCAL
    if (appIdArg)
        [body appendData:[appIdArg dataUsingEncoding:NSUTF8StringEncoding]];
#endif

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:
                                     [NSURL URLWithString:
                                      [NSString stringWithFormat:@"%@/entity", [JRCaptureData captureApidBaseUrl]]]];

    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:body];

    NSDictionary *newTag = [NSDictionary dictionaryWithObjectsAndKeys:
                                                 cGetUser, cTagAction,
                                        delegate, @"delegate",
                                        context, @"context", nil];

    DLog(@"%@ type_name=%@ access_token=%@", [[request URL] absoluteString], [JRCaptureData entityTypeName], token);

    if (![JRConnectionManager createConnectionFromRequest:request forDelegate:self withTag:newTag])
        [self finishGetCaptureUserWithStat:StatFail
                                 andResult:[NSDictionary dictionaryWithObjectsAndKeys:
                                                    @"error", @"stat",
                                                    @"url_connection", @"error",
                                                    [NSString stringWithFormat:@"Could not create a connection to %@", [[request URL] absoluteString]], @"error_description",
                                                    [NSNumber numberWithInteger:JRCaptureLocalApidErrorUrlConnection], @"code", nil]
                               forDelegate:delegate
                               withContext:context];
}

- (void)finishGetObjectWithStat:(CaptureInterfaceStat)stat andResult:(NSObject *)result
                    forDelegate:(id <JRCaptureInterfaceDelegate>)delegate withContext:(NSObject *)context
{
    DLog(@"");

    if (stat == StatOk)
    {
        if ([delegate respondsToSelector:@selector(getCaptureObjectDidSucceedWithResult:context:)])
            [delegate getCaptureObjectDidSucceedWithResult:result context:context];
    }
    else
    {
        if ([delegate respondsToSelector:@selector(getCaptureObjectDidFailWithResult:context:)])
            [delegate getCaptureObjectDidFailWithResult:result context:context];
    }
}

- (void)startGetCaptureObjectAtPath:(NSString *)entityPath withToken:(NSString *)token
                        forDelegate:(id <JRCaptureInterfaceDelegate>)delegate withContext:(NSObject *)context
{
    DLog(@"");

    NSMutableData *body = [NSMutableData data];
    [body appendData:[[NSString stringWithFormat:@"&access_token=%@", token] dataUsingEncoding:NSUTF8StringEncoding]];

    if (!entityPath || [entityPath isEqualToString:@""]) ;
    else
        [body appendData:[[NSString stringWithFormat:@"&attribute_name=%@", entityPath] dataUsingEncoding:NSUTF8StringEncoding]];

#ifdef TESTING_CARL_LOCAL
    if (appIdArg)
        [body appendData:[appIdArg dataUsingEncoding:NSUTF8StringEncoding]];
#endif

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:
                                     [NSURL URLWithString:
                                      [NSString stringWithFormat:@"%@/entity", [JRCaptureData captureApidBaseUrl]]]];

    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:body];

    NSDictionary *tag = [NSDictionary dictionaryWithObjectsAndKeys:
                                              cGetObject, cTagAction,
                                        delegate, @"delegate",
                                        context, @"context", nil];

    DLog(@"%@ access_token=%@ attribute_name=%@", [[request URL] absoluteString], token, entityPath);

    if (![JRConnectionManager createConnectionFromRequest:request forDelegate:self withTag:tag])
        [self finishGetObjectWithStat:StatFail
                            andResult:[NSDictionary dictionaryWithObjectsAndKeys:
                                               @"error", @"stat",
                                               @"url_connection", @"error",
                                               [NSString stringWithFormat:@"Could not create a connection to %@", [[request URL] absoluteString]], @"error_description",
                                               [NSNumber numberWithInteger:JRCaptureLocalApidErrorUrlConnection], @"code", nil]
                          forDelegate:delegate
                          withContext:context];

}

- (void)finishUpdateObjectWithStat:(CaptureInterfaceStat)stat andResult:(NSObject *)result
                       forDelegate:(id <JRCaptureInterfaceDelegate>)delegate withContext:(NSObject *)context
{
    DLog(@"");

    if (stat == StatOk)
    {
        if ([delegate respondsToSelector:@selector(updateCaptureObjectDidSucceedWithResult:context:)])
            [delegate updateCaptureObjectDidSucceedWithResult:result context:context];
    }
    else
    {
        if ([delegate respondsToSelector:@selector(updateCaptureObjectDidFailWithResult:context:)])
            [delegate updateCaptureObjectDidFailWithResult:result context:context];
    }
}

- (void)startUpdateObject:(NSDictionary *)captureObject atPath:(NSString *)entityPath
                withToken:(NSString *)token forDelegate:(id <JRCaptureInterfaceDelegate>)delegate
              withContext:(NSObject *)context
{
    DLog(@"");

    NSString      *attributes = [[captureObject JSONString] stringByAddingUrlPercentEscapes];
    NSMutableData *body       = [NSMutableData data];

    [body appendData:[[NSString stringWithFormat:@"&attributes=%@", attributes] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"&access_token=%@", token] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"&include_record=true" dataUsingEncoding:NSUTF8StringEncoding]];

    if (!entityPath || [entityPath isEqualToString:@""]) ;
    else
        [body appendData:[[NSString stringWithFormat:@"&attribute_name=%@", entityPath] dataUsingEncoding:NSUTF8StringEncoding]];

#ifdef TESTING_CARL_LOCAL
    if (appIdArg)
        [body appendData:[appIdArg dataUsingEncoding:NSUTF8StringEncoding]];
#endif

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:
                                     [NSURL URLWithString:
                                      [NSString stringWithFormat:@"%@/entity.update", [JRCaptureData captureApidBaseUrl]]]];

    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:body];

    NSDictionary *tag = [NSDictionary dictionaryWithObjectsAndKeys:
                                              cUpdateObject, cTagAction,
                                        delegate, @"delegate",
                                        context, @"context", nil];

    DLog(@"%@ attributes=%@ access_token=%@ attribute_name=%@", [[request URL] absoluteString], attributes, token, entityPath);

    if (![JRConnectionManager createConnectionFromRequest:request forDelegate:self withTag:tag])
        [self finishUpdateObjectWithStat:StatFail
                               andResult:[NSDictionary dictionaryWithObjectsAndKeys:
                                                  @"error", @"stat",
                                                  @"url_connection", @"error",
                                                  [NSString stringWithFormat:@"Could not create a connection to %@", [[request URL] absoluteString]], @"error_description",
                                                  [NSNumber numberWithInteger:JRCaptureLocalApidErrorUrlConnection], @"code", nil]
                             forDelegate:delegate
                             withContext:context];

}

- (void)finishReplaceObjectWithStat:(CaptureInterfaceStat)stat andResult:(NSObject *)result
                        forDelegate:(id <JRCaptureInterfaceDelegate>)delegate withContext:(NSObject *)context
{
    DLog(@"");
    if (stat == StatOk)
    {
        if ([delegate respondsToSelector:@selector(replaceCaptureObjectDidSucceedWithResult:context:)])
            [delegate replaceCaptureObjectDidSucceedWithResult:result context:context];
    }
    else
    {
        if ([delegate respondsToSelector:@selector(replaceCaptureObjectDidFailWithResult:context:)])
            [delegate replaceCaptureObjectDidFailWithResult:result context:context];
    }
}

- (void)startReplaceObject:(NSDictionary *)captureObject atPath:(NSString *)entityPath
                 withToken:(NSString *)token forDelegate:(id <JRCaptureInterfaceDelegate>)delegate withContext:(NSObject *)context
{
    DLog(@"");

    NSString      *attributes = [[captureObject JSONString] stringByAddingUrlPercentEscapes];
    NSMutableData *body       = [NSMutableData data];

    [body appendData:[[NSString stringWithFormat:@"&attributes=%@", attributes] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"&access_token=%@", token] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"&include_record=true" dataUsingEncoding:NSUTF8StringEncoding]];

    if (!entityPath || [entityPath isEqualToString:@""]) ;
    else
        [body appendData:[[NSString stringWithFormat:@"&attribute_name=%@", entityPath] dataUsingEncoding:NSUTF8StringEncoding]];

#ifdef TESTING_CARL_LOCAL
    if (appIdArg)
        [body appendData:[appIdArg dataUsingEncoding:NSUTF8StringEncoding]];
#endif

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:
                                     [NSURL URLWithString:
                                      [NSString stringWithFormat:@"%@/entity.replace", [JRCaptureData captureApidBaseUrl]]]];

    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:body];

    NSDictionary *tag = [NSDictionary dictionaryWithObjectsAndKeys:
                                              cReplaceObject, cTagAction,
                                        delegate, @"delegate",
                                        context, @"context", nil];

    DLog(@"%@ attributes=%@ access_token=%@ attribute_name=%@", [[request URL] absoluteString], attributes, token, entityPath);

    if (![JRConnectionManager createConnectionFromRequest:request forDelegate:self withTag:tag])
        [self finishReplaceObjectWithStat:StatFail
                                andResult:[NSDictionary dictionaryWithObjectsAndKeys:
                                                   @"error", @"stat",
                                                   @"url_connection", @"error",
                                                   [NSString stringWithFormat:@"Could not create a connection to %@", [[request URL] absoluteString]], @"error_description",
                                                   [NSNumber numberWithInteger:JRCaptureLocalApidErrorUrlConnection], @"code", nil]
                              forDelegate:delegate
                              withContext:context];

}

- (void)finishReplaceArrayWithStat:(CaptureInterfaceStat)stat andResult:(NSObject *)result
                       forDelegate:(id <JRCaptureInterfaceDelegate>)delegate withContext:(NSObject *)context
{
    DLog(@"");
    if (stat == StatOk)
    {
        if ([delegate respondsToSelector:@selector(replaceCaptureArrayDidSucceedWithResult:context:)])
            [delegate replaceCaptureArrayDidSucceedWithResult:result context:context];
    }
    else
    {
        if ([delegate respondsToSelector:@selector(replaceCaptureArrayDidFailWithResult:context:)])
            [delegate replaceCaptureArrayDidFailWithResult:result context:context];
    }
}

- (void)startReplaceArray:(NSArray *)captureArray atPath:(NSString *)entityPath
                withToken:(NSString *)token forDelegate:(id <JRCaptureInterfaceDelegate>)delegate withContext:(NSObject *)context
{
    DLog(@"");

    NSString      *attributes = [[captureArray JSONString] stringByAddingUrlPercentEscapes];
    NSMutableData *body       = [NSMutableData data];

    [body appendData:[[NSString stringWithFormat:@"&attributes=%@", attributes] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"&access_token=%@", token] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"&include_record=true" dataUsingEncoding:NSUTF8StringEncoding]];

    if (!entityPath || [entityPath isEqualToString:@""]) ;
    else
        [body appendData:[[NSString stringWithFormat:@"&attribute_name=%@", entityPath] dataUsingEncoding:NSUTF8StringEncoding]];

#ifdef TESTING_CARL_LOCAL
    if (appIdArg)
        [body appendData:[appIdArg dataUsingEncoding:NSUTF8StringEncoding]];
#endif

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:
                                     [NSURL URLWithString:
                                      [NSString stringWithFormat:@"%@/entity.replace", [JRCaptureData captureApidBaseUrl]]]];

    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:body];

    NSDictionary *tag = [NSDictionary dictionaryWithObjectsAndKeys:
                                              cReplaceArray, cTagAction,
                                        delegate, @"delegate",
                                        context, @"context", nil];

    DLog(@"%@ attributes=%@ access_token=%@ attribute_name=%@", [[request URL] absoluteString], attributes, token, entityPath);

    if (![JRConnectionManager createConnectionFromRequest:request forDelegate:self withTag:tag]) /* tag vs context for workaround */
        [self finishReplaceArrayWithStat:StatFail
                               andResult:[NSDictionary dictionaryWithObjectsAndKeys:
                                                  @"error", @"stat",
                                                  @"url_connection", @"error",
                                                  [NSString stringWithFormat:@"Could not create a connection to %@", [[request URL] absoluteString]], @"error_description",
                                                  [NSNumber numberWithInteger:JRCaptureLocalApidErrorUrlConnection], @"code", nil]
                             forDelegate:delegate
                             withContext:context];

}

+ (void)signinCaptureUserWithCredentials:(NSDictionary *)credentials ofType:(NSString *)signInType
                             forDelegate:(id <JRCaptureInterfaceDelegate>)delegate withContext:(NSObject *)context
{
    [[JRCaptureApidInterface captureInterfaceInstance]
            startSigninCaptureUserWithCredentials:credentials ofType:signInType forDelegate:delegate
                                      withContext:context];

}

+ (void)getCaptureUserWithToken:(NSString *)token
                    forDelegate:(id <JRCaptureInterfaceDelegate>)delegate withContext:(NSObject *)context
{
    [[JRCaptureApidInterface captureInterfaceInstance]
            startGetCaptureUserWithToken:token forDelegate:delegate withContext:context];
}

+ (void)createCaptureUser:(NSDictionary *)captureUser withToken:(NSString *)token
              forDelegate:(id <JRCaptureInterfaceDelegate>)delegate withContext:(NSObject *)context
{
    [[JRCaptureApidInterface captureInterfaceInstance]
            startCreateCaptureUser:captureUser withToken:token forDelegate:delegate withContext:context];
}

+ (void)getCaptureObjectAtPath:(NSString *)entityPath withToken:(NSString *)token
                   forDelegate:(id <JRCaptureInterfaceDelegate>)delegate withContext:(NSObject *)context
{
    [[JRCaptureApidInterface captureInterfaceInstance]
            startGetCaptureObjectAtPath:entityPath withToken:token forDelegate:delegate withContext:context];
}

+ (void)updateCaptureObject:(NSDictionary *)captureObject atPath:(NSString *)entityPath withToken:(NSString *)token
                forDelegate:(id <JRCaptureInterfaceDelegate>)delegate withContext:(NSObject *)context
{
    DLog(@"");
    [[JRCaptureApidInterface captureInterfaceInstance]
            startUpdateObject:captureObject atPath:entityPath withToken:token forDelegate:delegate withContext:context];
}

+ (void)replaceCaptureObject:(NSDictionary *)captureObject atPath:(NSString *)entityPath withToken:(NSString *)token
                 forDelegate:(id <JRCaptureInterfaceDelegate>)delegate withContext:(NSObject *)context
{
    [[JRCaptureApidInterface captureInterfaceInstance]
            startReplaceObject:captureObject atPath:entityPath withToken:token forDelegate:delegate withContext:context];
}

+ (void)replaceCaptureArray:(NSArray *)captureArray atPath:(NSString *)entityPath withToken:(NSString *)token
                forDelegate:(id <JRCaptureInterfaceDelegate>)delegate withContext:(NSObject *)context
{
    [[JRCaptureApidInterface captureInterfaceInstance]
            startReplaceArray:captureArray atPath:entityPath withToken:token forDelegate:delegate withContext:context];
}

- (void)connectionDidFinishLoadingWithPayload:(NSString*)payload request:(NSURLRequest*)request andTag:(id)userData
{
    DLog(@"%@", payload);

    NSDictionary *tag       = (NSDictionary *) userData;
    NSString     *action    = [tag objectForKey:cTagAction];
    NSObject     *context   = [tag objectForKey:@"context"];

    NSDictionary *response    = [payload objectFromJSONString];
    CaptureInterfaceStat stat = [[response objectForKey:@"stat"] isEqualToString:@"ok"] ? StatOk : StatFail;

    id<JRCaptureInterfaceDelegate> delegate = [tag objectForKey:@"delegate"];

    if ([action isEqualToString:cCreateUser])
    {
        [self finishCreateCaptureUserWithStat:stat andResult:payload forDelegate:delegate withContext:context];
    }
    else if ([action isEqualToString:cSignInUser])
    {
        [self finishSignInUserWithPayload:payload context:context response:response stat:stat delegate:delegate];
    }
    else if ([action isEqualToString:cGetUser])
    {
        [self finishGetCaptureUserWithStat:stat andResult:payload forDelegate:delegate withContext:context];
    }
    else if ([action isEqualToString:cGetObject])
    {
        [self finishGetObjectWithStat:stat andResult:payload forDelegate:delegate withContext:context];
    }
    else if ([action isEqualToString:cUpdateObject])
    {
        [self finishUpdateObjectWithStat:stat andResult:payload forDelegate:delegate withContext:context];
    }
    else if ([action isEqualToString:cReplaceObject])
    {
        [self finishReplaceObjectWithStat:stat andResult:payload forDelegate:delegate withContext:context];
    }
    else if ([action isEqualToString:cReplaceArray])
    {
        [self finishReplaceArrayWithStat:stat andResult:payload forDelegate:delegate withContext:context];
    }
}

- (void)finishSignInUserWithPayload:(NSString *)payload context:(NSObject *)context response:(NSDictionary *)response
                               stat:(CaptureInterfaceStat)stat delegate:(id <JRCaptureInterfaceDelegate>)delegate
{
    if ([delegate conformsToProtocol:@protocol(JRCaptureInterfaceDelegate)])
    {
        if (stat == StatOk)
            [self finishSignInSuccessWithResult:payload forDelegate:delegate withContext:context];
        else
            [self finishSignInFailureWithResult:response forDelegate:delegate withContext:context];
    }
    else if ([delegate conformsToProtocol:@protocol(JRCaptureSigninDelegate)])
    {
        id <JRCaptureSigninDelegate> d_ = (id) delegate;
        BOOL respondsToFail = [d_ respondsToSelector:@selector(captureAuthenticationDidFailWithError:)];
        if (stat == StatOk)
        {
            FinishSignInError err = [JRCaptureApidInterface finishSignInWithPayload:response forDelegate:d_];

            if ((err == cJRInvalidResponse || err == cJRInvalidCaptureUser) &&
                    respondsToFail)
            {
                NSString *errorDesc = [NSString stringWithFormat:
                        @"The Capture Mobile Endpoint URL did not have the expected data: %@", [payload description]];
                NSNumber *code = [NSNumber numberWithInt:JRCaptureWrappedEngageErrorInvalidEndpointPayload];
                NSDictionary *errDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                                              @"error", @"stat",
                                                              @"invalid_endpoint_response", @"error",
                                                              errorDesc, @"error_description",
                                                              code, @"code", nil];
                [d_ captureAuthenticationDidFailWithError:[JRCaptureError errorFromResult:errDict]];
            }
        }
        else if (respondsToFail)
        {
            NSString *const message = [response objectForKey:@"error"];
            NSNumber *code;
            if ([message isEqual:@"bad username/password combo"])
                code = [NSNumber numberWithInt:JRCaptureErrorGenericBadPassword];
            else
                code = [NSNumber numberWithInt:JRCaptureErrorGeneric];

            NSDictionary *errDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                                          @"error", @"stat",
                                                          message, @"error",
                                                          message, @"error_description",
                                                          code, @"code", nil];

            [d_ captureAuthenticationDidFailWithError:[JRCaptureError errorFromResult:errDict]];
        }
    }
}

- (void)connectionDidFinishLoadingWithFullResponse:(NSURLResponse*)fullResponse unencodedPayload:(NSData*)payload
                                           request:(NSURLRequest*)request andTag:(id)userData { }

- (void)connectionDidFailWithError:(NSError*)error request:(NSURLRequest*)request andTag:(id)userData
{
    DLog(@"");

    NSDictionary *tag       = (NSDictionary*) userData;
    NSString     *action    = [tag objectForKey:cTagAction];
    NSObject     *context   = [tag objectForKey:@"context"];
    id<JRCaptureInterfaceDelegate> delegate = [tag objectForKey:@"delegate"];

    NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"error", @"stat",
                                    [error localizedDescription], @"error",
                                    [error localizedFailureReason], @"error_description",
                                    [NSNumber numberWithInteger:JRCaptureLocalApidErrorConnectionDidFail], @"code",
                                    nil];

    if ([action isEqualToString:cCreateUser])
    {
        [self finishCreateCaptureUserWithStat:StatFail andResult:result forDelegate:delegate withContext:context];
    }
    else if ([action isEqualToString:cSignInUser])
    {
        [self finishSignInFailureWithResult:result forDelegate:delegate withContext:context];
    }
    else if ([action isEqualToString:cGetUser])
    {
        [self finishGetCaptureUserWithStat:StatFail andResult:result forDelegate:delegate withContext:context];
    }
    else if ([action isEqualToString:cGetObject])
    {
        [self finishGetObjectWithStat:StatFail andResult:result forDelegate:delegate withContext:context];
    }
    else if ([action isEqualToString:cUpdateObject])
    {
        [self finishUpdateObjectWithStat:StatFail andResult:result forDelegate:delegate withContext:context];
    }
    else if ([action isEqualToString:cReplaceObject])
    {
        [self finishReplaceObjectWithStat:StatFail andResult:result forDelegate:delegate withContext:context];
    }
    else if ([action isEqualToString:cReplaceArray])
    {
        [self finishReplaceArrayWithStat:StatFail andResult:result forDelegate:delegate withContext:context];
    }
}

+ (FinishSignInError)finishSignInWithPayload:(NSDictionary *)payloadDict
                                 forDelegate:(id<JRCaptureSigninDelegate>)delegate
{
    NSString *accessToken   = [payloadDict objectForKey:@"access_token"];
    NSString *creationToken = [payloadDict objectForKey:@"creation_token"];
    BOOL      isNew         = [(NSNumber*)[payloadDict objectForKey:@"is_new"] boolValue];
    BOOL      notYetCreated = creationToken ? YES: NO;

    NSDictionary *captureProfile = [payloadDict objectForKey:@"capture_user"];

    if (!captureProfile || !(accessToken || creationToken)) return cJRInvalidResponse;

    JRCaptureUser *captureUser = [JRCaptureUser captureUserObjectFromDictionary:captureProfile];

    if (!captureUser) return cJRInvalidCaptureUser;

    NSString *uuid = [captureUser performSelector:NSSelectorFromString(@"uuid")];

    if (accessToken)
        [JRCaptureData setAccessToken:accessToken forUser:uuid];
    else if (creationToken)
        [JRCaptureData setCreationToken:creationToken];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    JRCaptureRecordStatus recordStatus;

    if (notYetCreated)
        recordStatus = JRCaptureRecordMissingRequiredFields;
    else if (isNew)
        recordStatus = JRCaptureRecordNewlyCreated;
    else
        recordStatus = JRCaptureRecordExists;

    if ([delegate respondsToSelector:@selector(captureAuthenticationDidSucceedForUser:status:)])
        [delegate captureAuthenticationDidSucceedForUser:captureUser status:recordStatus];

    return cJRNoError;
}

- (void)connectionWasStoppedWithTag:(id)userData { }
@end
