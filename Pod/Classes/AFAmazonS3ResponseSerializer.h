//  AFAmazonS3ResponseSerializer.h
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

#import "AFURLResponseSerialization.h"

/**
 Returns an `AFAmazonS3ResponseObject` object from the AmazonS3 HTTP response
 */
@interface AFAmazonS3ResponseSerializer : AFHTTPResponseSerializer

@end

#pragma mark -

/**
 Returned as the response object for S3 requests
 */
@interface AFAmazonS3ResponseObject : NSObject

/**
 Creates a new from the HTTP response S3 returns

 @param response AFAmazonS3ResponseObject

 @return Returns an initialized instance of AFAmazonS3ResponseObject
 */
+ (instancetype)responseObject:(NSHTTPURLResponse *)response;

///-------------------------
/// @name Reading Attributes
///-------------------------

/**
 The URL of the file sent to or retrieved from S3
 */
@property (readonly, nonatomic, copy) NSURL *URL;

/**
 Contains the MD5 hash S3 computed for the file in the request
 */
@property (readonly, nonatomic, copy) NSString *ETag;

/**
 The original NSHTTPURLResponse object returned by S3
 */
@property (readonly, nonatomic, strong) NSHTTPURLResponse *originalResponse;

@end
