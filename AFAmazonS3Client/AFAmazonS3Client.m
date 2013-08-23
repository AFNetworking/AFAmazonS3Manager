//
// AFAmazonS3Client.m
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

#import <CommonCrypto/CommonHMAC.h>

#import "AFAmazonS3Client.h"
#import "AFXMLRequestOperation.h"

NSString * const kAFAmazonS3BaseURLString = @"http://s3.amazonaws.com";
NSString * const kAFAmazonS3BucketBaseURLFormatString = @"http://%@.s3.amazonaws.com";

static NSData * AFHMACSHA1EncodedDataFromStringWithKey(NSString *string, NSString *key) {
    NSData *data = [string dataUsingEncoding:NSASCIIStringEncoding];
    CCHmacContext context;
    const char *keyCString = [key cStringUsingEncoding:NSASCIIStringEncoding];
    
    CCHmacInit(&context, kCCHmacAlgSHA1, keyCString, strlen(keyCString));
    CCHmacUpdate(&context, [data bytes], [data length]);
    
    unsigned char digestRaw[CC_SHA1_DIGEST_LENGTH];
    NSInteger digestLength = CC_SHA1_DIGEST_LENGTH;
    
    CCHmacFinal(&context, digestRaw);
    
    return [NSData dataWithBytes:digestRaw length:digestLength];
}

static NSString * AFRFC822FormatStringFromDate(NSDate *date) {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    [dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss z"];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    
    return [dateFormatter stringFromDate:date];
}

NSString * AFBase64EncodedStringFromData(NSData *data) {
    NSUInteger length = [data length];
    NSMutableData *mutableData = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    
    uint8_t *input = (uint8_t *)[data bytes];
    uint8_t *output = (uint8_t *)[mutableData mutableBytes];
    
    for (NSUInteger i = 0; i < length; i += 3) {
        NSUInteger value = 0;
        for (NSUInteger j = i; j < (i + 3); j++) {
            value <<= 8;
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        static uint8_t const kAFBase64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        
        NSUInteger idx = (i / 3) * 4;
        output[idx + 0] = kAFBase64EncodingTable[(value >> 18) & 0x3F];
        output[idx + 1] = kAFBase64EncodingTable[(value >> 12) & 0x3F];
        output[idx + 2] = (i + 1) < length ? kAFBase64EncodingTable[(value >> 6)  & 0x3F] : '=';
        output[idx + 3] = (i + 2) < length ? kAFBase64EncodingTable[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:mutableData encoding:NSASCIIStringEncoding];
}

#pragma mark -

@interface AFAmazonS3Client ()
@property (readwrite, nonatomic, copy) NSString *accessKey;
@property (readwrite, nonatomic, copy) NSString *secret;

- (void)setObjectWithMethod:(NSString *)method
                       file:(NSString *)filePath
            destinationPath:(NSString *)destinationPath
                 parameters:(NSDictionary *)parameters
                   progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progressBlock
                    success:(void (^)(id responseObject))success
                    failure:(void (^)(NSError *error))failure;
@end

@implementation AFAmazonS3Client
@synthesize baseURL = _s3_baseURL;
@synthesize bucket = _bucket;
@synthesize accessKey = _accessKey;
@synthesize secret = _secret;

- (id)initWithAccessKeyID:(NSString *)accessKey
                   secret:(NSString *)secret
{
    self = [self initWithBaseURL:[NSURL URLWithString:kAFAmazonS3BaseURLString]];
    if (!self) {
        return nil;
    }
	
    self.accessKey = accessKey;
    self.secret = secret;
	
    return self;
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
	
    [self registerHTTPOperationClass:[AFXMLRequestOperation class]];
	
    return self;
}

- (NSURL *)baseURL {
    if (_s3_baseURL && self.bucket) {
        return [NSURL URLWithString:[NSString stringWithFormat:kAFAmazonS3BucketBaseURLFormatString, self.bucket]];
    }
	
    return _s3_baseURL;
}

- (void)setBucket:(NSString *)bucket {
    [self willChangeValueForKey:@"baseURL"];
    [self willChangeValueForKey:@"bucket"];
    _bucket = bucket;
    [self didChangeValueForKey:@"bucket"];
    [self didChangeValueForKey:@"baseURL"];
}

- (NSDictionary *)authorizationHeadersForRequest:(NSMutableURLRequest *)request {
    if (self.accessKey && self.secret) {
        // Long header values that are subject to "folding" should split into new lines according to AWS's documentation.
		NSMutableDictionary *mutableAMZHeaderFields = [NSMutableDictionary dictionary];
		[[request allHTTPHeaderFields] enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
			key = [key lowercaseString];
			if ([key hasPrefix:@"x-amz"]) {
				if ([mutableAMZHeaderFields objectForKey:key]) {
					value = [[mutableAMZHeaderFields objectForKey:key] stringByAppendingFormat:@",%@", value];
				}
				[mutableAMZHeaderFields setObject:value forKey:key];
			}
		}];

		NSMutableString *mutableCanonicalizedAMZHeaderString = [NSMutableString string];
		for (NSString *key in [[mutableAMZHeaderFields allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
            id value = [mutableAMZHeaderFields objectForKey:key];
			[mutableCanonicalizedAMZHeaderString appendFormat:@"%@:%@\n", key, value];
		}

        NSString *canonicalizedResource = [NSString stringWithFormat:@"/%@%@", self.bucket, request.URL.path];
    	NSString *method = [request HTTPMethod];
		NSString *contentMD5 = [request valueForHTTPHeaderField:@"Content-MD5"];
		NSString *contentType = [request valueForHTTPHeaderField:@"Content-Type"];
		NSString *date = AFRFC822FormatStringFromDate([NSDate date]);

		NSMutableString *mutableString = [NSMutableString string];
		[mutableString appendFormat:@"%@\n", (method) ? method : @""];
		[mutableString appendFormat:@"%@\n", (contentMD5) ? contentMD5 : @""];
		[mutableString appendFormat:@"%@\n", (contentType) ? contentType : @""];
		[mutableString appendFormat:@"%@\n", (date) ? date : @""];
		[mutableString appendFormat:@"%@", mutableCanonicalizedAMZHeaderString];
		[mutableString appendFormat:@"%@", canonicalizedResource];

        NSData *hmac = AFHMACSHA1EncodedDataFromStringWithKey(mutableString, self.secret);
        NSString *signature = AFBase64EncodedStringFromData(hmac);

        return @{@"Authorization": [NSString stringWithFormat:@"AWS %@:%@", self.accessKey, signature],
                 @"Date": date
                };
    }

    return nil;
}

#pragma mark -

- (void)enqueueS3RequestOperationWithMethod:(NSString *)method
                                       path:(NSString *)path
                                 parameters:(NSDictionary *)parameters
                                    success:(void (^)(id responseObject))success
                                    failure:(void (^)(NSError *error))failure
{
    NSURLRequest *request = [self requestWithMethod:method path:path parameters:parameters];
    
    AFHTTPRequestOperation *requestOperation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
	
    [self enqueueHTTPRequestOperation:requestOperation];
}


#pragma mark Service Operations

- (void)getServiceWithSuccess:(void (^)(id responseObject))success
                      failure:(void (^)(NSError *error))failure
{
    [self enqueueS3RequestOperationWithMethod:@"GET" path:@"/" parameters:nil success:success failure:failure];
}

#pragma mark Bucket Operations

- (void)getBucket:(NSString *)bucket
          success:(void (^)(id responseObject))success
          failure:(void (^)(NSError *error))failure
{
    [self enqueueS3RequestOperationWithMethod:@"GET" path:bucket parameters:nil success:success failure:failure];
}

- (void)putBucket:(NSString *)bucket
       parameters:(NSDictionary *)parameters
          success:(void (^)(id responseObject))success
          failure:(void (^)(NSError *error))failure
{
    [self enqueueS3RequestOperationWithMethod:@"PUT" path:bucket parameters:parameters success:success failure:failure];
	
}

- (void)deleteBucket:(NSString *)bucket
             success:(void (^)(id responseObject))success
             failure:(void (^)(NSError *error))failure
{
    [self enqueueS3RequestOperationWithMethod:@"DELETE" path:bucket parameters:nil success:success failure:failure];
}

#pragma mark Object Operations

- (void)headObjectWithPath:(NSString *)path
                   success:(void (^)(id responseObject))success
                   failure:(void (^)(NSError *error))failure
{
    [self enqueueS3RequestOperationWithMethod:@"HEAD" path:path parameters:nil success:success failure:failure];
}

- (void)getObjectWithPath:(NSString *)path
                 progress:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress
                  success:(void (^)(id responseObject, NSData *responseData))success
                  failure:(void (^)(NSError *error))failure
{
    NSURLRequest *request = [self requestWithMethod:@"GET" path:path parameters:nil];
    
    AFHTTPRequestOperation *requestOperation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(responseObject, operation.responseData);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
	
    [requestOperation setDownloadProgressBlock:progress];
	
    [self enqueueHTTPRequestOperation:requestOperation];
}

- (void)getObjectWithPath:(NSString *)path
             outputStream:(NSOutputStream *)outputStream
                 progress:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress
                  success:(void (^)(id responseObject))success
                  failure:(void (^)(NSError *error))failure
{
    NSURLRequest *request = [self requestWithMethod:@"GET" path:path parameters:nil];
    
    AFHTTPRequestOperation *requestOperation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
	
    [requestOperation setDownloadProgressBlock:progress];
    [requestOperation setOutputStream:outputStream];
	
    [self enqueueHTTPRequestOperation:requestOperation];
}

- (void)postObjectWithFile:(NSString *)path
           destinationPath:(NSString *)destinationPath
                parameters:(NSDictionary *)parameters
                  progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                   success:(void (^)(id responseObject))success
                   failure:(void (^)(NSError *error))failure
{
    [self setObjectWithMethod:@"POST" file:path destinationPath:destinationPath parameters:parameters progress:progress success:success failure:failure];
}

- (void)putObjectWithFile:(NSString *)path
          destinationPath:(NSString *)destinationPath
               parameters:(NSDictionary *)parameters
                 progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                  success:(void (^)(id responseObject))success
                  failure:(void (^)(NSError *error))failure
{
    [self setObjectWithMethod:@"PUT" file:path destinationPath:destinationPath parameters:parameters progress:progress success:success failure:failure];
}

- (void)deleteObjectWithPath:(NSString *)path
                     success:(void (^)(id responseObject))success
                     failure:(void (^)(NSError *error))failure
{
    [self enqueueS3RequestOperationWithMethod:@"DELETE" path:path parameters:nil success:success failure:failure];
}

- (void)setObjectWithMethod:(NSString *)method
                       file:(NSString *)filePath
            destinationPath:(NSString *)destinationPath
                 parameters:(NSDictionary *)parameters
                   progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                    success:(void (^)(id responseObject))success
                    failure:(void (^)(NSError *error))failure
{
    NSMutableURLRequest *fileRequest = [NSMutableURLRequest requestWithURL:[NSURL fileURLWithPath:filePath]];
    [fileRequest setCachePolicy:NSURLCacheStorageNotAllowed];
	
    NSURLResponse *response = nil;
    NSError *fileError = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:fileRequest returningResponse:&response error:&fileError];
	
    if (data && response) {
        NSMutableURLRequest *request = [self multipartFormRequestWithMethod:method path:destinationPath parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            [formData appendPartWithFormData:[[filePath lastPathComponent] dataUsingEncoding:NSUTF8StringEncoding] name:@"key"];
            [formData appendPartWithFileData:data name:@"file" fileName:[filePath lastPathComponent] mimeType:[response MIMEType]];
        }];
		
        AFHTTPRequestOperation *requestOperation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if (success) {
                success(responseObject);
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (failure) {
                failure(error);
            }
        }];
		
        [requestOperation setUploadProgressBlock:progress];
		
        [self enqueueHTTPRequestOperation:requestOperation];
    }
}

#pragma mark - AFHTTPClient

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters
{
	NSMutableURLRequest *request = [super requestWithMethod:method path:path parameters:parameters];

    [[self authorizationHeadersForRequest:request] enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL *stop) {
        [request setValue:value forHTTPHeaderField:field];
    }];

    return request;
}

@end
