// AFAmazonS3RequestSerializerTest.h
//
// Copyright (c) 2011–2015 AFNetworking (http://afnetworking.com/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <UIKit/UIKit.h>

#import <XCTest/XCTest.h>
#import <Expecta/Expecta.h>
#import <OCMock/OCMock.h>

#import "AFAmazonS3RequestSerializer.h"

@interface AFAmazonS3RequestSerializerTest : XCTestCase

@property (nonatomic) AFAmazonS3RequestSerializer *requestSerializer;

@end

@implementation AFAmazonS3RequestSerializerTest

- (void)setUp {
    [super setUp];
    self.requestSerializer = [AFAmazonS3RequestSerializer serializer];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testInitialization {
    XCTAssert(self.requestSerializer.cachePolicy == NSURLRequestReloadIgnoringCacheData);
    XCTAssert([self.requestSerializer.region isEqualToString:AFAmazonS3USStandardRegion]);
    XCTAssert(self.requestSerializer.useSSL);
}

- (void)testErrorIsSetIfAccessKeyAndSecretAreNotSet {
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://s3-eu-west-1.amazonaws.com/example/example"]];
    NSError *error;
    [self.requestSerializer requestBySettingAuthorizationHeadersForRequest:request error:&error];
    
    XCTAssert(error != nil);
    XCTAssert([error.domain isEqualToString:@"com.alamofire.networking.s3.error"]);
    XCTAssert(error.code == NSURLErrorUserAuthenticationRequired);
}

- (void)testEnsureAccessKeyThrowsExceptionIfNil {
    expect(^{
        [self.requestSerializer setAccessKeyID:nil secret:@"secret"];
    }).to.raiseAny();
}

- (void)testEnsureSecretThrowsExceptionIfNil {
    expect(^{
        [self.requestSerializer setAccessKeyID:@"access_key" secret:nil];
    }).to.raiseAny();
}

- (void)testEnsureRegionThrowsExceptionIfNil {
    expect(^{
        [self.requestSerializer setRegion:nil];
    }).to.raiseAny();
}

- (void)testHTTPEndpointCreation {
    NSURL *url = [self.requestSerializer endpointURL];
    XCTAssert([url.absoluteString isEqualToString:@"https://s3.amazonaws.com"]);
}

- (void)testHTTPSEndpointCreation {
    self.requestSerializer.useSSL = NO;
    NSURL *url = [self.requestSerializer endpointURL];
    XCTAssert([url.absoluteString isEqualToString:@"http://s3.amazonaws.com"]);
}

- (void)testHeadersAreSetInReturnedRequest {
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://s3-eu-west-1.amazonaws.com/example/example"]];
    NSError *error;
    [self.requestSerializer setAccessKeyID:@"access_key" secret:@"secret"];
    
    NSURLRequest *returnedRequest = [self.requestSerializer requestBySettingAuthorizationHeadersForRequest:request error:&error];
    
    XCTAssert(error == nil);
    XCTAssert(returnedRequest.allHTTPHeaderFields != nil);
    XCTAssert(returnedRequest.allHTTPHeaderFields[@"Authorization"] != nil);
    XCTAssert(returnedRequest.allHTTPHeaderFields[@"Date"] != nil);
}

- (void)testPreSignedRequestWithRequestRequiresRequest {
    expect(^{
        [self.requestSerializer preSignedRequestWithRequest:nil expiration:[NSDate date] error:nil];
    }).to.raiseAny();
}

- (void)testPreSignedRequestWithRequestRequiresGetRequest {
    expect(^{
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://s3-eu-west-1.amazonaws.com/example/example"]];
        request.HTTPMethod = @"PUT";
        [self.requestSerializer preSignedRequestWithRequest:request expiration:[NSDate date] error:nil];
    }).to.raiseAny();
}

- (void)testErrorReturnedFromPreSignedRequestWithRequestIfSecretMissing {
    NSError *error;
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://s3-eu-west-1.amazonaws.com/example/example"]];
    request.HTTPMethod = @"GET";
    
    [self.requestSerializer preSignedRequestWithRequest:request expiration:[NSDate date] error:&error];
    
    XCTAssert(error != nil);
    XCTAssert([error.domain isEqualToString:@"com.alamofire.networking.s3.error"]);
    XCTAssert(error.code == NSURLErrorUserAuthenticationRequired);
}

- (void)testErrorReturnedAsNilFromPreSignedRequestWithRequest {
    NSError *error;
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://s3-eu-west-1.amazonaws.com/example/example"]];
    request.HTTPMethod = @"GET";
    [self.requestSerializer setAccessKeyID:@"access_key" secret:@"secret"];
    
    id partial = [OCMockObject partialMockForObject:self.requestSerializer];
    [[[partial expect] andForwardToRealObject] requestBySerializingRequest:[OCMArg any] withParameters:[OCMArg checkWithBlock:^(id value) {
        BOOL validParameters = [value[@"AWSAccessKeyId"] isEqualToString:@"access_key"] && value[@"Expires"] != nil && value[@"Signature"] != nil;
        return validParameters;
    }] error:[OCMArg anyObjectRef]];
    
    [self.requestSerializer preSignedRequestWithRequest:request expiration:[NSDate date] error:&error];
    
    XCTAssert(error == nil);
    OCMVerifyAll(partial);
}

- (void)testRequestWithMethodAddsSecurityTokenHeader {
    NSError *error;
    [self.requestSerializer setAccessKeyID:@"access_key" secret:@"secret"];
    self.requestSerializer.sessionToken = @"session_token";
    
    NSURLRequest *returnedRequest = [self.requestSerializer requestWithMethod:@"GET" URLString:@"http://s3-eu-west-1.amazonaws.com/example/example" parameters:@{} error:&error];
    
    XCTAssert(error == nil);
    XCTAssert(returnedRequest.allHTTPHeaderFields[@"x-amz-security-token"] != nil);
}

- (void)testMultipartRequestWithMetodAddsSecurityTokenHeader {
    NSError *error;
    [self.requestSerializer setAccessKeyID:@"access_key" secret:@"secret"];
    self.requestSerializer.sessionToken = @"session_token";
    
    NSURLRequest *returnedRequest = [self.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:@"http://s3-eu-west-1.amazonaws.com/example/example" parameters:@{} constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        
    } error:&error];

    XCTAssert(error == nil);
    XCTAssert(returnedRequest.allHTTPHeaderFields[@"x-amz-security-token"] != nil);
}

@end
