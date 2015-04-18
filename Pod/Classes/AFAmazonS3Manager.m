// AFAmazonS3Manager.m
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

#import "AFAmazonS3Manager.h"
#import "AFAmazonS3ResponseSerializer.h"

NSString * const AFAmazonS3ManagerErrorDomain = @"com.alamofire.networking.s3.error";

static NSString * AFPathByEscapingSpacesWithPlusSigns(NSString *path) {
    return [path stringByReplacingOccurrencesOfString:@" " withString:@"+"];
}

@interface AFAmazonS3Manager ()
@property (readwrite, nonatomic, strong) NSURL *baseURL;
@end

@implementation AFAmazonS3Manager
@synthesize baseURL = _s3_baseURL;
@dynamic requestSerializer;

- (instancetype)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }

    self.requestSerializer = [AFAmazonS3RequestSerializer serializer];
    self.responseSerializer = [AFAmazonS3ResponseSerializer serializer];

    return self;
}

- (id)initWithAccessKeyID:(NSString *)accessKey
                   secret:(NSString *)secret
{
    self = [self initWithBaseURL:nil];
    if (!self) {
        return nil;
    }

    [self.requestSerializer setAccessKeyID:accessKey secret:secret];

    return self;
}

- (NSURL *)baseURL {
    if (!_s3_baseURL) {
        return self.requestSerializer.endpointURL;
    }

    return _s3_baseURL;
}

#pragma mark -

- (AFHTTPRequestOperation *)enqueueS3RequestOperationWithMethod:(NSString *)method
                                                           path:(NSString *)path
                                                     parameters:(NSDictionary *)parameters
                                                        success:(void (^)(id responseObject))success
                                                        failure:(void (^)(NSError *error))failure
{
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method URLString:[[self.baseURL URLByAppendingPathComponent:path] absoluteString] parameters:parameters error:nil];
    AFHTTPRequestOperation *requestOperation = [self HTTPRequestOperationWithRequest:request success:^(__unused AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(__unused AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];

    [self.operationQueue addOperation:requestOperation];
    
    return requestOperation;
}


#pragma mark Service Operations

- (AFHTTPRequestOperation *)getServiceWithSuccess:(void (^)(id responseObject))success
                                          failure:(void (^)(NSError *error))failure
{
    return [self enqueueS3RequestOperationWithMethod:@"GET" path:@"/" parameters:nil success:success failure:failure];
}

#pragma mark Bucket Operations

- (AFHTTPRequestOperation *)getBucket:(NSString *)bucket
                              success:(void (^)(id responseObject))success
                              failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(bucket);

    return [self enqueueS3RequestOperationWithMethod:@"GET" path:bucket parameters:nil success:success failure:failure];
}

- (AFHTTPRequestOperation *)putBucket:(NSString *)bucket
                           parameters:(NSDictionary *)parameters
                              success:(void (^)(id responseObject))success
                              failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(bucket);
    
    return [self enqueueS3RequestOperationWithMethod:@"PUT" path:bucket parameters:parameters success:success failure:failure];
}

- (AFHTTPRequestOperation *)deleteBucket:(NSString *)bucket
                                 success:(void (^)(id responseObject))success
                                 failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(bucket);
    
    return [self enqueueS3RequestOperationWithMethod:@"DELETE" path:bucket parameters:nil success:success failure:failure];
}

#pragma mark Object Operations

- (AFHTTPRequestOperation *)headObjectWithPath:(NSString *)path
                                       success:(void (^)(NSHTTPURLResponse *response))success
                                       failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(path);

    path = AFPathByEscapingSpacesWithPlusSigns(path);

    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"HEAD" URLString:[[self.baseURL URLByAppendingPathComponent:path] absoluteString] parameters:nil error:nil];
    AFHTTPRequestOperation *requestOperation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, __unused id responseObject) {
        if (success) {
            success(operation.response);
        }
    } failure:^(__unused AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];

    [self.operationQueue addOperation:requestOperation];
    
    return requestOperation;
}

- (AFHTTPRequestOperation *)getObjectWithPath:(NSString *)path
                                     progress:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress
                                      success:(void (^)(id responseObject, NSData *responseData))success
                                      failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(path);

    path = AFPathByEscapingSpacesWithPlusSigns(path);

    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"GET" URLString:[[self.baseURL URLByAppendingPathComponent:path] absoluteString] parameters:nil error:nil];
    AFHTTPRequestOperation *requestOperation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(responseObject, operation.responseData);
        }
    } failure:^(__unused AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];

    [requestOperation setDownloadProgressBlock:progress];

    [self.operationQueue addOperation:requestOperation];
    
    return requestOperation;
}

- (AFHTTPRequestOperation *)getObjectWithPath:(NSString *)path
                                 outputStream:(NSOutputStream *)outputStream
                                     progress:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress
                                      success:(void (^)(id responseObject))success
                                      failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(path);

    path = AFPathByEscapingSpacesWithPlusSigns(path);

    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"GET" URLString:[[self.baseURL URLByAppendingPathComponent:path] absoluteString] parameters:nil error:nil];
    AFHTTPRequestOperation *requestOperation = [self HTTPRequestOperationWithRequest:request success:^(__unused AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(__unused AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];

    requestOperation.outputStream = outputStream;

    [requestOperation setDownloadProgressBlock:progress];

    [self.operationQueue addOperation:requestOperation];
    
    return requestOperation;
}

- (AFHTTPRequestOperation *)postObjectWithFile:(NSString *)path
                               destinationPath:(NSString *)destinationPath
                                    parameters:(NSDictionary *)parameters
                                      progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                                       success:(void (^)(id responseObject))success
                                       failure:(void (^)(NSError *error))failure
{
    return [self setObjectWithMethod:@"POST" file:path destinationPath:destinationPath parameters:parameters progress:progress success:success failure:failure];
}

- (AFHTTPRequestOperation *)putObjectWithFile:(NSString *)path
                              destinationPath:(NSString *)destinationPath
                                   parameters:(NSDictionary *)parameters
                                     progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                                      success:(void (^)(id responseObject))success
                                      failure:(void (^)(NSError *error))failure
{
    return [self setObjectWithMethod:@"PUT" file:path destinationPath:destinationPath parameters:parameters progress:progress success:success failure:failure];
}

- (AFHTTPRequestOperation *)setObjectWithMethod:(NSString *)method
                                           file:(NSString *)filePath
                                destinationPath:(NSString *)destinationPath
                                     parameters:(NSDictionary *)parameters
                                       progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                                        success:(void (^)(id responseObject))success
                                        failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(method);
    NSParameterAssert(filePath);
    NSParameterAssert(destinationPath);

    NSMutableURLRequest *fileRequest = [NSMutableURLRequest requestWithURL:[NSURL fileURLWithPath:filePath]];
    fileRequest.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;

    NSURLResponse *response = nil;
    NSError *fileError = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:fileRequest returningResponse:&response error:&fileError];

    if (fileError || !response || !data) {
        if (failure) {
            failure(fileError);
        }

        return nil;
    }

    destinationPath = AFPathByEscapingSpacesWithPlusSigns(destinationPath);

    NSMutableURLRequest *request = nil;
    if ([method compare:@"POST" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
        NSError *requestError = nil;
        request = [self.requestSerializer multipartFormRequestWithMethod:method URLString:[[self.baseURL URLByAppendingPathComponent:destinationPath] absoluteString] parameters:parameters constructingBodyWithBlock:^(id <AFMultipartFormData> formData) {
            if (![parameters valueForKey:@"key"]) {
                [formData appendPartWithFormData:[[filePath lastPathComponent] dataUsingEncoding:NSUTF8StringEncoding] name:@"key"];
            }

            [formData appendPartWithFileData:data name:@"file" fileName:[filePath lastPathComponent] mimeType:[response MIMEType]];
        } error:&requestError];

        if (requestError || !request) {
            if (failure) {
                failure(requestError);
            }

            return nil;
        }
    } else {
        request = [self.requestSerializer requestWithMethod:method URLString:[[self.baseURL URLByAppendingPathComponent:destinationPath] absoluteString] parameters:nil error:nil];
        
        // S3 expects parameters as headers for PUT requests
        if (parameters != nil) {
            for (id key in parameters) {
                [request setValue:[parameters objectForKey:key] forHTTPHeaderField:key];
            }
        }
        
        request.HTTPBody = data;
    }

    AFHTTPRequestOperation *requestOperation = [self HTTPRequestOperationWithRequest:request success:^(__unused AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(__unused AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];

    [requestOperation setUploadProgressBlock:progress];

    [self.operationQueue addOperation:requestOperation];
    
    return requestOperation;
}

- (AFHTTPRequestOperation *)deleteObjectWithPath:(NSString *)path
                                         success:(void (^)(id responseObject))success
                                         failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(path);

    path = AFPathByEscapingSpacesWithPlusSigns(path);

    return [self enqueueS3RequestOperationWithMethod:@"DELETE" path:path parameters:nil success:success failure:failure];
}

#pragma mark - NSKeyValueObserving

+ (NSSet *)keyPathsForValuesAffectingBaseURL {
    return [NSSet setWithObjects:@"baseURL", @"requestSerializer.bucket", @"requestSerializer.region", @"requestSerializer.useSSL", nil];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    AFAmazonS3Manager *manager = [[[self class] allocWithZone:zone] initWithBaseURL:_s3_baseURL];

    manager.requestSerializer = [self.requestSerializer copyWithZone:zone];
    manager.responseSerializer = [self.responseSerializer copyWithZone:zone];

    return manager;
}

@end
