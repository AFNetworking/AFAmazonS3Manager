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

- (NSURLSessionDataTask *)enqueueS3DataTaskWithMethod:(NSString *)method
                                                 path:(NSString *)path
                                           parameters:(NSDictionary *)parameters
                                              success:(void (^)(NSURLSessionDataTask *, id))success
                                              failure:(void (^)(NSURLSessionDataTask *, NSError *))failure;
{
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method URLString:[[self.baseURL URLByAppendingPathComponent:path] absoluteString] parameters:parameters error:nil];
    
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [self dataTaskWithRequest:request completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
        if (error) {
            if (failure) {
                failure(dataTask, error);
            }
        } else {
            if (success) {
                success(dataTask, responseObject);
            }
        }
    }];
    [dataTask resume];
    
    return dataTask;
}


#pragma mark Service Operations

- (NSURLSessionDataTask *)getServiceWithSuccess:(void (^)(NSURLSessionDataTask *, id))success
                                        failure:(void (^)(NSURLSessionDataTask *, NSError *))failure
{
    return [self enqueueS3DataTaskWithMethod:@"GET" path:@"/" parameters:nil success:success failure:failure];
}

#pragma mark Bucket Operations

- (NSURLSessionDataTask *)getBucket:(NSString *)bucket
                            success:(void (^)(NSURLSessionDataTask *, id))success
                            failure:(void (^)(NSURLSessionDataTask *, NSError *))failure
{
    NSParameterAssert(bucket);

    return [self enqueueS3DataTaskWithMethod:@"GET" path:bucket parameters:nil success:success failure:failure];
}

- (NSURLSessionDataTask *)putBucket:(NSString *)bucket
                           parameters:(NSDictionary *)parameters
                            success:(void (^)(NSURLSessionDataTask *, id))success
                            failure:(void (^)(NSURLSessionDataTask *, NSError *))failure
{
    NSParameterAssert(bucket);
    
    return [self enqueueS3DataTaskWithMethod:@"PUT" path:bucket parameters:parameters success:success failure:failure];
}

- (NSURLSessionDataTask *)deleteBucket:(NSString *)bucket
                               success:(void (^)(NSURLSessionDataTask *, id))success
                               failure:(void (^)(NSURLSessionDataTask *, NSError *))failure
{
    NSParameterAssert(bucket);
    
    return [self enqueueS3DataTaskWithMethod:@"DELETE" path:bucket parameters:nil success:success failure:failure];
}

#pragma mark Object Operations

- (NSURLSessionDataTask *)headObjectWithPath:(NSString *)path
                                     success:(void (^)(NSURLSessionDataTask *, id))success
                                     failure:(void (^)(NSURLSessionDataTask *, NSError *))failure
{
    NSParameterAssert(path);

    path = AFPathByEscapingSpacesWithPlusSigns(path);

    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"HEAD" URLString:[[self.baseURL URLByAppendingPathComponent:path] absoluteString] parameters:nil error:nil];

    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [self dataTaskWithRequest:request completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
        if (error) {
            if (failure) {
                failure(dataTask, error);
            }
        } else {
            if (success) {
                success(dataTask, responseObject);
            }
        }
    }];
    
    [dataTask resume];
    
    return dataTask;
}

- (NSURLSessionDataTask *)getObjectWithPath:(NSString *)path
                                   progress:(nullable void (^)(NSProgress *downloadProgress))downloadProgressBlock
                                destination:(nullable NSURL * _Nullable (^)(NSURL * _Nullable targetPath, NSURLResponse * _Nullable response))destination
                                    success:(void (^_Nullable)(NSURLResponse * _Nullable response, NSURL * _Nullable filePath))success
                                    failure:(void (^_Nullable)(NSURLResponse * _Nullable response, NSError * _Nullable error))failure
{
    NSParameterAssert(path);

    path = AFPathByEscapingSpacesWithPlusSigns(path);

    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"GET" URLString:[[self.baseURL URLByAppendingPathComponent:path] absoluteString] parameters:nil error:nil];
    
    __block NSURLSessionDataTask *dataTask = nil;
    
    dataTask = [self downloadTaskWithRequest:request progress:downloadProgressBlock destination:destination
                                                 completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                                                     if (error) {
                                                         if (failure) {
                                                             failure(response, error);
                                                         }
                                                     } else {
                                                         if (success) {
                                                             success(response, filePath);
                                                         }
                                                     }
                                                 }];
    [dataTask resume];

    
    return dataTask;
}

- (NSURLSessionDataTask *)postObjectWithFile:(NSString *)path
                             destinationPath:(NSString *)destinationPath
                                  parameters:(NSDictionary *)parameters
                                    progress:(void (^)(NSProgress * uploadProgress))uploadProgressBlock
                                     success:(void (^)(NSURLResponse *response, id responseObject))success
                                     failure:(void (^)(NSURLResponse *response, NSError *error))failure
{
    return [self setObjectWithMethod:@"POST" file:path destinationPath:destinationPath parameters:parameters progress:uploadProgressBlock success:success failure:failure];
}

- (NSURLSessionDataTask *)putObjectWithFile:(NSString *)path
                            destinationPath:(NSString *)destinationPath
                                 parameters:(NSDictionary *)parameters
                                   progress:(nullable void (^)(NSProgress *uploadProgress))uploadProgressBlock
                                    success:(void (^)(NSURLResponse *response, id responseObject))success
                                    failure:(void (^)(NSURLResponse *response, NSError * error))failure
{
    return [self setObjectWithMethod:@"PUT" file:path destinationPath:destinationPath parameters:parameters progress:uploadProgressBlock success:success failure:failure];
}

- (NSURLSessionDataTask *)setObjectWithMethod:(NSString *)method
                                           file:(NSString *)filePath
                                destinationPath:(NSString *)destinationPath
                                     parameters:(NSDictionary *)parameters
                                     progress:(void (^)(NSProgress *downloadProgress))uploadProgressBlock
                                      success:(void (^)(NSURLResponse *, id))success
                                      failure:(void (^)(NSURLResponse *, NSError *))failure
{
    NSParameterAssert(method);
    NSParameterAssert(filePath);
    NSParameterAssert(destinationPath);
    
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];

    NSMutableURLRequest *fileRequest = [NSMutableURLRequest requestWithURL:fileURL];
    fileRequest.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;

    NSURLResponse *response = nil;
    NSError *fileError = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:fileRequest returningResponse:&response error:&fileError];

    if (fileError || !response || !data) {
        if (failure) {
            failure(response, fileError);
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
                failure(response, requestError);
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
    __block NSURLSessionDataTask *dataTask = nil;


    dataTask = [self uploadTaskWithRequest:request fromFile:fileURL progress:uploadProgressBlock completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            if (failure) {
                failure(response, error);
            }
        } else {
            if (success) {
                success(response, filePath);
            }
        }
    }];
    
    [dataTask resume];
    
    return dataTask;
}

- (NSURLSessionDataTask *)deleteObjectWithPath:(NSString *)path
                                       success:(void (^)(NSURLSessionDataTask * task, id responseObject))success
                                       failure:(void (^)(NSURLSessionDataTask * task, NSError * error))failure
{
    NSParameterAssert(path);

    path = AFPathByEscapingSpacesWithPlusSigns(path);

    return [self enqueueS3DataTaskWithMethod:@"DELETE" path:path parameters:nil success:success failure:failure];
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
