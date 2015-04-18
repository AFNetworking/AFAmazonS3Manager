// AFAmaxonS3ResponseSerializerTest.h
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

#import "AFAmazonS3ResponseSerializer.h"

@interface AFAmaxonS3ResponseSerializerTest : XCTestCase

@property (nonatomic) AFAmazonS3ResponseObject *responseObject;

@end

@interface AFAmazonS3ResponseSerializer ()

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError * __autoreleasing *)error;

@end

@implementation AFAmaxonS3ResponseSerializerTest

- (void)setUp {
    [super setUp];
    
    NSURL *url = [NSURL URLWithString:@"http://s3-eu-west-1.amazonaws.com/example/example"];
    NSHTTPURLResponse *urlResponse = [[NSHTTPURLResponse alloc] initWithURL:url MIMEType:@"" expectedContentLength:1024 textEncodingName:@"text/html"];

    self.responseObject = [AFAmazonS3ResponseObject responseObject:urlResponse];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testInitialization {
    XCTAssert(self.responseObject != nil);
}

- (void)testValidationOfResponseObjectsSucceeds {
    NSError *error;
    NSURL *url = [NSURL URLWithString:@"http://s3-eu-west-1.amazonaws.com/example/example"];
    NSHTTPURLResponse *urlResponse = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Etag": @"123\"456789"}];
    AFAmazonS3ResponseSerializer *serializer = [[AFAmazonS3ResponseSerializer alloc] init];
    AFAmazonS3ResponseObject *responseObject = [serializer responseObjectForResponse:urlResponse data:nil error:&error];
    
    XCTAssert(responseObject != nil);
    XCTAssert(error == nil);
}

- (void)testValidationOfResponseObjectsFails {
    NSError *error;
    NSURL *url = [NSURL URLWithString:@"http://s3-eu-west-1.amazonaws.com/example/example"];
    NSHTTPURLResponse *urlResponse = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:500 HTTPVersion:@"1.1" headerFields:@{@"Etag": @"123\"456789"}];
    AFAmazonS3ResponseSerializer *serializer = [[AFAmazonS3ResponseSerializer alloc] init];
    AFAmazonS3ResponseObject *responseObject = [serializer responseObjectForResponse:urlResponse data:nil error:&error];
    
    XCTAssert(responseObject == nil);
    XCTAssert(error != nil);
}

- (void)testURL {
    [self.responseObject.URL.absoluteString isEqualToString:@"http://s3-eu-west-1.amazonaws.com/example/example"];
}

- (void)testETAGAbsent {
    XCTAssert(self.responseObject.ETag == nil);
}

- (void)testETAGPresent {
    NSURL *url = [NSURL URLWithString:@"http://s3-eu-west-1.amazonaws.com/example/example"];
    NSHTTPURLResponse *urlResponse = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Etag": @"123\"456789"}];
    
    AFAmazonS3ResponseObject *responseObject = [AFAmazonS3ResponseObject responseObject:urlResponse];

    XCTAssert(responseObject.ETag != nil);
    XCTAssert([responseObject.ETag isEqualToString:@"123456789"]);
}

@end
