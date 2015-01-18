//  AFAmazonS3ResponseSerializer.m
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

#import "AFAmazonS3ResponseSerializer.h"

@implementation AFAmazonS3ResponseSerializer

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError * __autoreleasing *)error
{
    if ([self validateResponse:(NSHTTPURLResponse *)response data:data error:error]) {
        return [AFAmazonS3ResponseObject responseObject:(NSHTTPURLResponse *)response];
    }
    
    return nil;
}

@end

#pragma mark -

@interface AFAmazonS3ResponseObject ()
@property (readwrite, nonatomic, strong) NSHTTPURLResponse *originalResponse;
@end

#pragma mark -

@implementation AFAmazonS3ResponseObject

+ (instancetype)responseObject:(NSHTTPURLResponse *)response {
    AFAmazonS3ResponseObject *responseObject = [[AFAmazonS3ResponseObject alloc] init];
    responseObject.originalResponse = response;

    return responseObject;
}

#pragma mark -

- (NSURL *)URL {
    return self.originalResponse.URL;
}

- (NSString *)ETag {
    NSString *ETag = self.originalResponse.allHeaderFields[@"ETag"];

    if ([ETag length] == 0) {
        return nil;
    }

    return [ETag stringByReplacingOccurrencesOfString:@"\"" withString:@""];
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, URL: %@, ETAG: %@, originalResponse: %@>", NSStringFromClass([self class]), self, [self.URL absoluteString], self.ETag, self.originalResponse];
}

@end
