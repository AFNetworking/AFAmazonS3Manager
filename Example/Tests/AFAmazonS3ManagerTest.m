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

@interface AFAmazonS3Manager ()

- (AFHTTPRequestOperation *)setObjectWithMethod:(NSString *)method
                                           file:(NSString *)filePath
                                destinationPath:(NSString *)destinationPath
                                     parameters:(NSDictionary *)parameters
                                       progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                                        success:(void (^)(id responseObject))success
                                        failure:(void (^)(NSError *error))failure;

@end

@interface NSURLConnection ()

+ (NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error;

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
    
    __block BOOL successCallbackInvoked = FALSE;
    
    id partialOperationQueue = [OCMockObject partialMockForObject:self.manager.operationQueue];
    id partialManager = [OCMockObject partialMockForObject:self.manager];
    
    [[[partialOperationQueue expect] andForwardToRealObject] addOperation:[OCMArg checkWithBlock:^BOOL(id obj) {
        return [obj isKindOfClass:[AFHTTPRequestOperation class]];
    }]];
    
    [[[[partialManager expect] andForwardToRealObject] andDo:^(NSInvocation *invocation) {
        void (^successBlock)(AFHTTPRequestOperation *operation, id responseObject) = nil;
        [invocation getArgument:&successBlock atIndex:3];
        successBlock(nil, nil);
    }] HTTPRequestOperationWithRequest:OCMOCK_ANY success:OCMOCK_ANY failure:OCMOCK_ANY];
    
    NSOperation *operation = [self.manager getServiceWithSuccess:^(id responseObject) {
        successCallbackInvoked = TRUE;
    } failure:^(NSError *error) {
        
    }];
    
    [operation start];

    OCMVerifyAll(partialOperationQueue);
    OCMVerifyAll(partialManager);
    
    expect(successCallbackInvoked).will.beTruthy();
}

- (void)testGetServiceFailure {
    
    __block BOOL failureCallbackInvoked = FALSE;
    
    id partialOperationQueue = [OCMockObject partialMockForObject:self.manager.operationQueue];
    id partialManager = [OCMockObject partialMockForObject:self.manager];
    
    [[[partialOperationQueue expect] andForwardToRealObject] addOperation:[OCMArg checkWithBlock:^BOOL(id obj) {
        return [obj isKindOfClass:[AFHTTPRequestOperation class]];
    }]];
    
    [[[[partialManager expect] andForwardToRealObject] andDo:^(NSInvocation *invocation) {
        void (^failureBlock)(AFHTTPRequestOperation *operation, NSError *error) = nil;
        [invocation getArgument:&failureBlock atIndex:4];
        failureBlock(nil, [[NSError alloc] initWithDomain:@"Domain" code:123 userInfo:@{}]);
    }] HTTPRequestOperationWithRequest:OCMOCK_ANY success:OCMOCK_ANY failure:OCMOCK_ANY];
    
    NSOperation *operation = [self.manager getServiceWithSuccess:^(id responseObject) {
        
    } failure:^(NSError *error) {
        failureCallbackInvoked = TRUE;
    }];
    
    [operation start];
    
    OCMVerifyAll(partialOperationQueue);
    OCMVerifyAll(partialManager);
    
    expect(failureCallbackInvoked).will.beTruthy();
}

- (void)testGetBucketAssertionFailure {
    expect(^{
        [self.manager getBucket:nil success:^(id responseObject) {
            
        } failure:^(NSError *error) {
            
        }];
    }).to.raiseAny();
}

- (void)testGetBucketEnqueued {
    NSString *bucket = @"bucket";
    id partialManager = [OCMockObject partialMockForObject:self.manager];
    [[[partialManager expect] andForwardToRealObject] enqueueS3RequestOperationWithMethod:@"GET" path:bucket parameters:nil success:OCMOCK_ANY failure:OCMOCK_ANY];
    
    NSOperation *operation = [self.manager getBucket:bucket success:^(id responseObject) {
        
    } failure:^(NSError *error) {
        
    }];
    
    [operation start];
    
    OCMVerifyAll(partialManager);
}

- (void)testPutBucketAssertionFailure {
    expect(^{
        [self.manager putBucket:nil parameters:nil success:^(id responseObject) {
            
        } failure:^(NSError *error) {
            
        }];
    }).to.raiseAny();
}

- (void)testPutBucketEnqueued {
    NSString *bucket = @"bucket";
    id partialManager = [OCMockObject partialMockForObject:self.manager];
    [[[partialManager expect] andForwardToRealObject] enqueueS3RequestOperationWithMethod:@"PUT" path:bucket parameters:nil success:OCMOCK_ANY failure:OCMOCK_ANY];
    
    NSOperation *operation = [self.manager putBucket:bucket parameters:nil success:^(id responseObject) {
        
    } failure:^(NSError *error) {
        
    }];
    
    [operation start];
    
    OCMVerifyAll(partialManager);
}

- (void)testDeleteBucketAssertionFailure {
    expect(^{
        [self.manager deleteBucket:nil success:^(id responseObject) {
            
        } failure:^(NSError *error) {
            
        }];
    }).to.raiseAny();
}

- (void)testDeleteBucketEnqueued {
    NSString *bucket = @"bucket";
    id partialManager = [OCMockObject partialMockForObject:self.manager];
    [[[partialManager expect] andForwardToRealObject] enqueueS3RequestOperationWithMethod:@"DELETE" path:bucket parameters:nil success:OCMOCK_ANY failure:OCMOCK_ANY];
    
    NSOperation *operation = [self.manager deleteBucket:bucket success:^(id responseObject) {
        
    } failure:^(NSError *error) {
        
    }];
    
    [operation start];
    
    OCMVerifyAll(partialManager);
}

- (void)testHeadObjectAssertionFailure {
    expect(^{
        [self.manager headObjectWithPath:nil success:^(NSHTTPURLResponse *response) {
        
        } failure:^(NSError *error) {
            
        }];
    }).to.raiseAny();
}

- (void)testHeadObjectSuccess {
    __block BOOL successCallbackInvoked = FALSE;
    NSString *path = @"bucket/path";
    id partialManager = [OCMockObject partialMockForObject:self.manager];
    id partialSerializer = [OCMockObject partialMockForObject:self.manager.requestSerializer];
    
    [[[[partialManager expect] andForwardToRealObject] andDo:^(NSInvocation *invocation) {
        void (^successBlock)(AFHTTPRequestOperation *operation, id responseObject) = nil;
        [invocation getArgument:&successBlock atIndex:3];
        successBlock(nil, nil);
    }] HTTPRequestOperationWithRequest:OCMOCK_ANY success:OCMOCK_ANY failure:OCMOCK_ANY];
    
    [[[partialSerializer expect] andForwardToRealObject] requestWithMethod:@"HEAD" URLString:OCMOCK_ANY parameters:nil error:nil];
    
    NSOperation *operation = [self.manager headObjectWithPath:path success:^(NSHTTPURLResponse *response) {
        successCallbackInvoked = TRUE;
    } failure:^(NSError *error) {
        
    }];
    
    [operation start];

    OCMVerifyAll(partialManager);
    OCMVerifyAll(partialSerializer);
    expect(successCallbackInvoked).will.beTruthy();
}

- (void)testHeadObjectFailure {
    __block BOOL failureCallbackInvoked = FALSE;
    NSString *path = @"bucket/path";
    id partialManager = [OCMockObject partialMockForObject:self.manager];
    id partialSerializer = [OCMockObject partialMockForObject:self.manager.requestSerializer];
    
    [[[[partialManager expect] andForwardToRealObject] andDo:^(NSInvocation *invocation) {
        void (^failureBlock)(AFHTTPRequestOperation *operation, NSError *error) = nil;
        [invocation getArgument:&failureBlock atIndex:4];
        failureBlock(nil, [[NSError alloc] initWithDomain:@"Domain" code:123 userInfo:@{}]);
    }] HTTPRequestOperationWithRequest:OCMOCK_ANY success:OCMOCK_ANY failure:OCMOCK_ANY];
    
    [[[partialSerializer expect] andForwardToRealObject] requestWithMethod:@"HEAD" URLString:OCMOCK_ANY parameters:nil error:nil];
    
    NSOperation *operation = [self.manager headObjectWithPath:path success:^(NSHTTPURLResponse *response) {
        
    } failure:^(NSError *error) {
        failureCallbackInvoked = TRUE;
    }];
    
    [operation start];
    
    OCMVerifyAll(partialManager);
    OCMVerifyAll(partialSerializer);
    expect(failureCallbackInvoked).will.beTruthy();
}

- (void)testGetObjectWithPathAssertionFailure {
    expect(^{
        [self.manager getObjectWithPath:nil outputStream:nil progress:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        } success:^(id responseObject) {
        } failure:^(NSError *error) {
        }];
    }).to.raiseAny();
}

- (void)testGetObjectWithPathSuccess {
    __block BOOL successCallbackInvoked = FALSE;
    NSString *path = @"bucket/path";
    
    id partialManager = [OCMockObject partialMockForObject:self.manager];
    id partialSerializer = [OCMockObject partialMockForObject:self.manager.requestSerializer];
    
    [[[[partialManager expect] andForwardToRealObject] andDo:^(NSInvocation *invocation) {
        void (^successBlock)(AFHTTPRequestOperation *operation, id responseObject) = nil;
        [invocation getArgument:&successBlock atIndex:3];
        successBlock(nil, nil);
    }] HTTPRequestOperationWithRequest:OCMOCK_ANY success:OCMOCK_ANY failure:OCMOCK_ANY];
    
    [[[partialSerializer expect] andForwardToRealObject] requestWithMethod:@"GET" URLString:OCMOCK_ANY parameters:nil error:nil];
    
    NSOperation *operation = [self.manager getObjectWithPath:path progress:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        
    } success:^(id responseObject, NSData *responseData) {
        successCallbackInvoked = YES;
    } failure:^(NSError *error) {
        
    }];
    
    [operation start];
    
    OCMVerifyAll(partialManager);
    OCMVerifyAll(partialSerializer);
    expect(successCallbackInvoked).will.beTruthy();
}

- (void)testGetObjectWithPathFailure {
    __block BOOL failureCallbackInvoked = FALSE;
    NSString *path = @"bucket/path";
    id partialManager = [OCMockObject partialMockForObject:self.manager];
    id partialSerializer = [OCMockObject partialMockForObject:self.manager.requestSerializer];
    
    [[[[partialManager expect] andForwardToRealObject] andDo:^(NSInvocation *invocation) {
        void (^failureBlock)(AFHTTPRequestOperation *operation, NSError *error) = nil;
        [invocation getArgument:&failureBlock atIndex:4];
        failureBlock(nil, [[NSError alloc] initWithDomain:@"Domain" code:123 userInfo:@{}]);
    }] HTTPRequestOperationWithRequest:OCMOCK_ANY success:OCMOCK_ANY failure:OCMOCK_ANY];
    
    [[[partialSerializer expect] andForwardToRealObject] requestWithMethod:@"GET" URLString:OCMOCK_ANY parameters:nil error:nil];
    
    NSOperation *operation = [self.manager getObjectWithPath:path progress:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        
    } success:^(id responseObject, NSData *responseData) {
       
    } failure:^(NSError *error) {
        failureCallbackInvoked = YES;
    }];
    
    [operation start];
    
    OCMVerifyAll(partialManager);
    OCMVerifyAll(partialSerializer);
    expect(failureCallbackInvoked).will.beTruthy();
}

- (void)testGetObjectWithPathAndOutputStreamSuccess {
    __block BOOL successCallbackInvoked = FALSE;
    NSString *path = @"bucket/path";
    
    id partialManager = [OCMockObject partialMockForObject:self.manager];
    id partialSerializer = [OCMockObject partialMockForObject:self.manager.requestSerializer];
    
    [[[[partialManager expect] andForwardToRealObject] andDo:^(NSInvocation *invocation) {
        void (^successBlock)(AFHTTPRequestOperation *operation, id responseObject) = nil;
        [invocation getArgument:&successBlock atIndex:3];
        successBlock(nil, nil);
    }] HTTPRequestOperationWithRequest:OCMOCK_ANY success:OCMOCK_ANY failure:OCMOCK_ANY];
    
    [[[partialSerializer expect] andForwardToRealObject] requestWithMethod:@"GET" URLString:OCMOCK_ANY parameters:nil error:nil];
    
    NSOperation *operation = [self.manager getObjectWithPath:path outputStream:nil progress:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
    } success:^(id responseObject) {
        successCallbackInvoked = YES;
    } failure:^(NSError *error) {
    }];
    
    [operation start];
    
    OCMVerifyAll(partialManager);
    OCMVerifyAll(partialSerializer);
    expect(successCallbackInvoked).will.beTruthy();
}

- (void)testGetObjectWithPathAndOutputStreamFailure {
    __block BOOL failureCallbackInvoked = FALSE;
    NSString *path = @"bucket/path";
    id partialManager = [OCMockObject partialMockForObject:self.manager];
    id partialSerializer = [OCMockObject partialMockForObject:self.manager.requestSerializer];
    
    [[[[partialManager expect] andForwardToRealObject] andDo:^(NSInvocation *invocation) {
        void (^failureBlock)(AFHTTPRequestOperation *operation, NSError *error) = nil;
        [invocation getArgument:&failureBlock atIndex:4];
        failureBlock(nil, [[NSError alloc] initWithDomain:@"Domain" code:123 userInfo:@{}]);
    }] HTTPRequestOperationWithRequest:OCMOCK_ANY success:OCMOCK_ANY failure:OCMOCK_ANY];
    
    [[[partialSerializer expect] andForwardToRealObject] requestWithMethod:@"GET" URLString:OCMOCK_ANY parameters:nil error:nil];
    
    NSOperation *operation = [self.manager getObjectWithPath:path outputStream:nil progress:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
    } success:^(id responseObject) {
        
    } failure:^(NSError *error) {
        failureCallbackInvoked = YES;
    }];
    
    [operation start];
    
    OCMVerifyAll(partialManager);
    OCMVerifyAll(partialSerializer);
    expect(failureCallbackInvoked).will.beTruthy();
}

- (void)testPostObjectWithFile {
    NSString *path = @"path";
    id partialManager = [OCMockObject partialMockForObject:self.manager];
    
    [[partialManager expect] setObjectWithMethod:@"POST" file:OCMOCK_ANY destinationPath:OCMOCK_ANY parameters:OCMOCK_ANY progress:OCMOCK_ANY success:OCMOCK_ANY failure:OCMOCK_ANY];
    
    [self.manager postObjectWithFile:path destinationPath:path parameters:@{} progress:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        
    } success:^(id responseObject) {
        
    } failure:^(NSError *error) {
        
    }];
    
    OCMVerifyAll(partialManager);
}

- (void)testPutObjectWithFile {
    NSString *path = @"path";
    id partialManager = [OCMockObject partialMockForObject:self.manager];
    
    [[partialManager expect] setObjectWithMethod:@"PUT" file:OCMOCK_ANY destinationPath:OCMOCK_ANY parameters:OCMOCK_ANY progress:OCMOCK_ANY success:OCMOCK_ANY failure:OCMOCK_ANY];
    
    [self.manager putObjectWithFile:path destinationPath:path parameters:@{} progress:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        
    } success:^(id responseObject) {
        
    } failure:^(NSError *error) {
        
    }];
    
    OCMVerifyAll(partialManager);
}

- (void)testSetObjectWithMethodMissingMethod {
    expect(^{
        [self.manager setObjectWithMethod:nil file:@"file" destinationPath:@"desitinationPath" parameters:nil progress:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        } success:^(id responseObject) {
            
        } failure:^(NSError *error) {
            
        }];
    }).to.raiseAny();
}

- (void)testSetObjectWithMethodMissingFile {
    expect(^{
        [self.manager setObjectWithMethod:@"GET" file:nil destinationPath:@"desitinationPath" parameters:nil progress:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        } success:^(id responseObject) {
            
        } failure:^(NSError *error) {
            
        }];
    }).to.raiseAny();
}

- (void)testSetObjectWithMethodMissingDestination {
    expect(^{
        [self.manager setObjectWithMethod:@"GET" file:@"file" destinationPath:nil parameters:nil progress:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        } success:^(id responseObject) {
            
        } failure:^(NSError *error) {
            
        }];
    }).to.raiseAny();
}

- (void)testSetObjectWithMethodFailureDueToNilData {
    __block BOOL failureCallbackInvoked = FALSE;
    NSString *file = @"file";
    NSString *method = @"POST";
    NSString *destinationPath = @"destinationPath";
  
    id urlConnectionMock = OCMClassMock([NSURLConnection class]);
    
    [[urlConnectionMock expect] sendSynchronousRequest:OCMOCK_ANY returningResponse:[OCMArg anyObjectRef] error:[OCMArg anyObjectRef]];
    
    [self.manager setObjectWithMethod:method file:file destinationPath:destinationPath parameters:nil progress:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
    } success:^(id responseObject) {

    } failure:^(NSError *error) {
        failureCallbackInvoked = YES;
    }];
    
    OCMVerifyAll(urlConnectionMock);
    expect(failureCallbackInvoked).will.beTruthy();
}

@end
