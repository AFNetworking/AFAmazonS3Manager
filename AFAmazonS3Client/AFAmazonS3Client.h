//
// AFAmazonS3Client.h
//
// Copyright (c) 2012 Mattt Thompson (http://mattt.me/)
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

#import "AFHTTPClient.h"

/**

 */
@interface AFAmazonS3Client : AFHTTPClient

/**

 */
@property (nonatomic, retain) NSURL *baseURL;

/**

 */
@property (nonatomic, copy) NSString *bucket;

/**

 */
- (id)initWithAccessKeyID:(NSString *)accessKey
                   secret:(NSString *)secret;

/**

 */
- (void)enqueueS3RequestOperationWithMethod:(NSString *)method
                                       path:(NSString *)path
                                 parameters:(NSDictionary *)parameters
                                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

///-------------------------
/// @name Service Operations
///-------------------------

/**
 Returns a list of all buckets owned by the authenticated request sender.
 */
- (void)getServiceWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                      failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;


///------------------------
/// @name Bucket Operations
///------------------------

/**
 Lists information about the objects in a bucket for a user that has read access to the bucket.
 */
- (void)getBucket:(NSString *)bucket
          success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
          failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

- (void)getBucketWithPrefix:(NSString *)prefix
                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

- (void)getBucketWithPrefix:(NSString *)prefix
                  delimiter:(NSString *)delimiter
                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**
 Creates a new bucket belonging to the account of the authenticated request sender. Optionally, you can specify a EU (Ireland) or US-West (N. California) location constraint.
 */
- (void)putBucket:(NSString *)bucket
       parameters:(NSDictionary *)parameters
          success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
          failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**
 Deletes the specified bucket. All objects in the bucket must be deleted before the bucket itself can be deleted.
 */
- (void)deleteBucket:(NSString *)bucket
             success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
             failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

///----------------------------------------------
/// @name Object Operations
///----------------------------------------------

/**
 Retrieves information about an object for a user with read access without fetching the object.
 */
- (void)headObjectWithPath:(NSString *)path
                   success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                   failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**
 Gets an object for a user that has read access to the object.
 */
- (void)getObjectWithPath:(NSString *)path
                 progress:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress
                  success:(void (^)(AFHTTPRequestOperation *operation, id responseObject, NSData *responseData))success
                  failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**
 Gets an object for a user that has read access to the object.
 */
- (void)getObjectWithPath:(NSString *)path
             outputStream:(NSOutputStream *)outputStream
                 progress:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress
                  success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                  failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**
 Adds an object to a bucket using forms.
 */
- (void)postObjectWithFile:(NSString *)path
           destinationPath:(NSString *)destinationPath
                parameters:(NSDictionary *)parameters
                  progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                   success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                   failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**
 Adds an object to a bucket for a user that has write access to the bucket. A success response indicates the object was successfully stored; if the object already exists, it will be overwritten.
 */
- (void)putObjectWithFile:(NSString *)path
          destinationPath:(NSString *)destinationPath
               parameters:(NSDictionary *)parameters
                 progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                  success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                  failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

- (void)uploadDataAtPath:(NSString *)filePath
         destinationPath:(NSString *)destinationPath
              parameters:(NSDictionary *)parameters
                progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                 success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                 failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;


/**
 Deletes the specified object. Once deleted, there is no method to restore or undelete an object.
 */
- (void)deleteObjectWithPath:(NSString *)path
                     success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                     failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**
 Helper fuctions for creating the signature for S3 Requests
 */
+ (NSString *)stringByURLEncodingForS3Path:(NSString *)key;
+ (NSDateFormatter*)S3ResponseDateFormatter;
+ (NSDateFormatter*)S3RequestDateFormatter;
+ (NSString *)base64forData:(NSData *)theData;
+ (NSData *)HMACSHA1withKey:(NSString *)key forString:(NSString *)string;
+ (NSString *)mimeTypeForFileAtPath:(NSString *)path;


@end

///----------------
/// @name Constants
///----------------

/**

 */
extern NSString * const kAFAmazonS3BaseURLString;
