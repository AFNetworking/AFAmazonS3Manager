// AFAmazonS3ManagerTest.m
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

#import "AFAmazonS3Manager.h"

@interface AFAmazonS3ManagerTest : XCTestCase

@property (nonatomic) AFAmazonS3Manager *manager;

@end

@interface AFAmazonS3RequestSerializer ()
@property (readwrite, nonatomic, copy) NSString *accessKey;
@property (readwrite, nonatomic, copy) NSString *secret;
@end

@implementation AFAmazonS3ManagerTest

- (void)setUp {
    [super setUp];
    NSURL *url = [NSURL URLWithString:@"http://s3-eu-west-1.amazonaws.com/example/example/"];
    self.manager = [[AFAmazonS3Manager alloc] initWithBaseURL:url];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testInitialization {
    AFAmazonS3Manager *manager = [[AFAmazonS3Manager alloc] init];
    
    XCTAssert(manager != nil);
    XCTAssert(manager.requestSerializer != nil);
    XCTAssert(manager.responseSerializer != nil);
    XCTAssert(manager.requestSerializer.accessKey == nil);
    XCTAssert(manager.requestSerializer.secret == nil);
    XCTAssert([manager.baseURL.absoluteString isEqualToString:manager.requestSerializer.endpointURL.absoluteString]);
}

- (void)testInitializationWithAccessIdAndSecret {
    NSString *accessKeyID = @"access_key_id";
    NSString *secret = @"secret";
    AFAmazonS3Manager *manager = [[AFAmazonS3Manager alloc] initWithAccessKeyID:accessKeyID secret:secret];
    
    XCTAssert(manager != nil);
    XCTAssert(manager.requestSerializer != nil);
    XCTAssert([manager.requestSerializer.accessKey isEqualToString:accessKeyID]);
    XCTAssert([manager.requestSerializer.secret isEqualToString:secret]);
    XCTAssert(manager.responseSerializer != nil);
    XCTAssert([manager.baseURL.absoluteString isEqualToString:manager.requestSerializer.endpointURL.absoluteString]);
}

- (void)testInitialzationWithBaseURL {
    NSURL *url = [NSURL URLWithString:@"http://s3-eu-west-1.amazonaws.com/example/example/"];
    AFAmazonS3Manager *manager = [[AFAmazonS3Manager alloc] initWithBaseURL:url];
    
    XCTAssert(manager != nil);
    XCTAssert(manager.requestSerializer != nil);
    XCTAssert(manager.requestSerializer.accessKey == nil);
    XCTAssert(manager.requestSerializer.secret == nil);
    XCTAssert([manager.baseURL.absoluteString isEqualToString:url.absoluteString]);
}

- (void)testGetServiceSuccess {
    
    id partialOperationQueue = [OCMockObject partialMockForObject:self.manager.operationQueue];
    id partialManager = [OCMockObject partialMockForObject:self.manager];
    
    [[[partialOperationQueue expect] andForwardToRealObject] addOperation:[OCMArg checkWithBlock:^BOOL(id obj) {
        return [obj isKindOfClass:[AFHTTPRequestOperation class]];
    }]];
    [[[partialManager expect] andForwardToRealObject] HTTPRequestOperationWithRequest:OCMOCK_ANY success:OCMOCK_ANY failure:OCMOCK_ANY];
    
    [self.manager getServiceWithSuccess:^(id responseObject) {
        
    } failure:^(NSError *error) {

    }];

    OCMVerifyAll(partialOperationQueue);
    OCMVerifyAll(partialManager);
}

@end
