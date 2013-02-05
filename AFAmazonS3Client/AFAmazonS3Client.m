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

#import "AFAmazonS3Client.h"
#import "AFXMLRequestOperation.h"
#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonDigest.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <XMLDictionary/XMLDictionary.h>

NSString * const kAFAmazonS3BaseURLString = @"https://s3.amazonaws.com";
NSString * const kAFAmazonS3BucketBaseURLFormatString = @"https://%@.s3.amazonaws.com";

#pragma mark -

@interface AFAmazonS3Client ()
@property (readwrite, nonatomic, copy) NSString *accessKey;
@property (readwrite, nonatomic, copy) NSString *secret;

- (void)setObjectWithMethod:(NSString *)method
                       file:(NSString *)filePath
            destinationPath:(NSString *)destinationPath
                 parameters:(NSDictionary *)parameters
                   progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progressBlock
                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
@end

@implementation AFAmazonS3Client
@synthesize baseURL = _s3_baseURL;
@synthesize bucket = _bucket;
@synthesize accessKey = _accessKey;
@synthesize secret = _secret;

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }

    [self registerHTTPOperationClass:[AFXMLRequestOperation class]];
    [self setParameterEncoding:AFFormURLParameterEncoding];
    //	[self setDefaultHeader:@"Accept" value:@"application/xml"];

    return self;
}

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

#pragma mark - Private Methods

- (void)buildHeadersForRequest:(NSMutableURLRequest *)request bucket:(NSString *)bucket key:(NSString *)key method:(NSString *)method contentMD5:(NSString *)contentMD5 contentType:(NSString *)contentType {
    NSString *dateString = [[[self class] S3RequestDateFormatter] stringFromDate:[NSDate date]];
	[request setValue:dateString forHTTPHeaderField:@"Date"];
	
	// Ensure our formatted string doesn't use '(null)' for the empty path
	NSString *canonicalizedResource = [NSString stringWithFormat:@"/%@%@", bucket, [[self class] stringByURLEncodingForS3Path:key]];;
	
	// Add a header for the access policy if one was set, otherwise we won't add one (and S3 will default to private)
	NSMutableDictionary *amzHeaders = [self S3Headers];
	
	NSString *canonicalizedAmzHeaders = @"";
	for (NSString *header in [[amzHeaders allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
		canonicalizedAmzHeaders = [NSString stringWithFormat:@"%@%@:%@\n",canonicalizedAmzHeaders,[header lowercaseString],[amzHeaders objectForKey:header]];
        [request setValue:[amzHeaders objectForKey:header] forHTTPHeaderField:header];
	}
    
	// Put it all together
	NSString *stringToSign = [NSString stringWithFormat:@"%@\n\n%@\n%@\n%@%@", method, contentType, dateString, canonicalizedAmzHeaders, canonicalizedResource];
	NSString *signature = [[self class] base64forData:[[self class] HMACSHA1withKey:self.secret forString:stringToSign]];
	NSString *authorizationString = [NSString stringWithFormat:@"AWS %@:%@", _accessKey, signature];
    [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
    [request setValue:authorizationString forHTTPHeaderField:@"Authorization"];
}

- (void)buildRequestHeadersForBucket:(NSString *)bucket key:(NSString *)key method:(NSString *)method {
	NSString *dateString = [[[self class] S3RequestDateFormatter] stringFromDate:[NSDate date]];
	[self setDefaultHeader:@"Date" value:dateString];
	
	// Ensure our formatted string doesn't use '(null)' for the empty path
	NSString *canonicalizedResource = [NSString stringWithFormat:@"/%@%@", bucket, [[self class] stringByURLEncodingForS3Path:key]];;
	
	// Add a header for the access policy if one was set, otherwise we won't add one (and S3 will default to private)
	NSMutableDictionary *amzHeaders = [self S3Headers];
	
	NSString *canonicalizedAmzHeaders = @"";
	for (NSString *header in [[amzHeaders allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
		canonicalizedAmzHeaders = [NSString stringWithFormat:@"%@%@:%@\n",canonicalizedAmzHeaders,[header lowercaseString],[amzHeaders objectForKey:header]];
		[self setDefaultHeader:header value:[amzHeaders objectForKey:header]];
	}
    
	// Put it all together
	NSString *stringToSign = [NSString stringWithFormat:@"%@\n\n\n%@\n%@%@", method, dateString, canonicalizedAmzHeaders, canonicalizedResource];
	NSString *signature = [[self class] base64forData:[[self class] HMACSHA1withKey:self.secret forString:stringToSign]];
	NSString *authorizationString = [NSString stringWithFormat:@"AWS %@:%@", _accessKey, signature];
	[self setDefaultHeader:@"Authorization" value:authorizationString];
}


- (NSMutableDictionary *)S3Headers {
	NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    //	if (_accessPolicy) {
    [headers setObject:@"public-read" forKey:@"x-amz-acl"];
    //	}
    //	if (_sessionToken) {
    //		[headers setObject:_sessionToken forKey:@"x-amz-security-token"];
    //	}
	return headers;
}

#pragma mark -

- (void)enqueueS3RequestOperationWithMethod:(NSString *)method
                                       path:(NSString *)path
                                 parameters:(NSDictionary *)parameters
                                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    [self buildRequestHeadersForBucket:self.bucket key:path method:method];
    NSURLRequest *request = [self requestWithMethod:method path:path parameters:parameters];
    
    AFHTTPRequestOperation *requestOperation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(operation, responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation, error);
        }
    }];
    
    [self enqueueHTTPRequestOperation:requestOperation];
}

#pragma mark Service Operations

- (void)getServiceWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                      failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    [self enqueueS3RequestOperationWithMethod:@"GET" path:@"/" parameters:nil success:success failure:failure];
}


#pragma mark Bucket Operations

- (void)getBucketWithPrefix:(NSString *)prefix
                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [self getBucketWithPrefix:prefix delimiter:nil success:success failure:failure];
}

- (void)getBucketWithPrefix:(NSString *)prefix
                  delimiter:(NSString *)delimiter
                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (prefix) {
        [params setObject:prefix forKey:@"prefix"];
    }
    if (delimiter) {
        [params setObject:delimiter forKey:@"delimiter"];
    }
    [self enqueueS3RequestOperationWithMethod:@"GET" path:@"/" parameters:params success:success failure:failure];
}

- (void)getBucket:(NSString *)bucket
          success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
          failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    [self enqueueS3RequestOperationWithMethod:@"GET" path:bucket parameters:nil success:success failure:failure];
}

- (void)putBucket:(NSString *)bucket
       parameters:(NSDictionary *)parameters
          success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
          failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    [self enqueueS3RequestOperationWithMethod:@"PUT" path:bucket parameters:parameters success:success failure:failure];
    
}

- (void)deleteBucket:(NSString *)bucket
             success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
             failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    [self enqueueS3RequestOperationWithMethod:@"DELETE" path:bucket parameters:nil success:success failure:failure];
}

#pragma mark Object Operations

- (void)headObjectWithPath:(NSString *)path
                   success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                   failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    [self enqueueS3RequestOperationWithMethod:@"HEAD" path:path parameters:nil success:success failure:failure];
}

- (void)getObjectWithPath:(NSString *)path
                 progress:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress
                  success:(void (^)(AFHTTPRequestOperation *operation, id responseObject, NSData *responseData))success
                  failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSURLRequest *request = [self requestWithMethod:@"GET" path:path parameters:nil];
    AFHTTPRequestOperation *requestOperation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(operation, operation.responseData, responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation, error);
        }
    }];
    
    [requestOperation setDownloadProgressBlock:progress];
    
    [self enqueueHTTPRequestOperation:requestOperation];
}

- (void)getObjectWithPath:(NSString *)path
             outputStream:(NSOutputStream *)outputStream
                 progress:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress
                  success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                  failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSURLRequest *request = [self requestWithMethod:@"GET" path:path parameters:nil];
    AFHTTPRequestOperation *requestOperation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(operation, responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation, error);
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
                   success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                   failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    [self setObjectWithMethod:@"POST" file:path destinationPath:destinationPath parameters:parameters progress:progress success:success failure:failure];
}

- (void)putObjectWithFile:(NSString *)path
          destinationPath:(NSString *)destinationPath
               parameters:(NSDictionary *)parameters
                 progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                  success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                  failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    [self setObjectWithMethod:@"PUT" file:path destinationPath:destinationPath parameters:parameters progress:progress success:success failure:failure];
}

- (void)deleteObjectWithPath:(NSString *)path
                     success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                     failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    [self enqueueS3RequestOperationWithMethod:@"DELETE" path:path parameters:nil success:success failure:failure];
}

- (void)setObjectWithMethod:(NSString *)method
                       file:(NSString *)filePath
            destinationPath:(NSString *)destinationPath
                 parameters:(NSDictionary *)parameters
                   progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSMutableURLRequest *fileRequest = [NSMutableURLRequest requestWithURL:[NSURL fileURLWithPath:filePath]];
    [fileRequest setCachePolicy:NSURLCacheStorageNotAllowed];

    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:fileRequest returningResponse:&response error:&error];
    NSString *MD5 = [[self class] MD5ForData:data];
    NSString *contentType = [[self class] mimeTypeForFileAtPath:filePath];

    if (data && response) {
        NSMutableURLRequest *request = [self multipartFormRequestWithMethod:method path:destinationPath parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            [formData appendPartWithFileData:data name:@"file" fileName:[filePath lastPathComponent] mimeType:[response MIMEType]];
        }];
        [self buildHeadersForRequest:request bucket:self.bucket key:destinationPath method:method contentMD5:MD5 contentType:contentType];
        
        AFHTTPRequestOperation *requestOperation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if (success) {
                success(operation, responseObject);
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (failure) {
                failure(operation, error);
            }
        }];
        
        [requestOperation setUploadProgressBlock:progress];
        
        [self enqueueHTTPRequestOperation:requestOperation];
    }
}

- (void)uploadDataAtPath:(NSString *)filePath
         destinationPath:(NSString *)destinationPath
              parameters:(NSDictionary *)parameters
                progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                 success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                 failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    NSMutableURLRequest *fileRequest = [NSMutableURLRequest requestWithURL:[NSURL fileURLWithPath:filePath]];
    [fileRequest setCachePolicy:NSURLCacheStorageNotAllowed];
    
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:fileRequest returningResponse:&response error:&error];
    NSString *MD5 = [[self class] MD5ForData:data];
    NSString *contentType = [[self class] mimeTypeForFileAtPath:filePath];
    
    if (data && response) {
        NSMutableURLRequest *request = [self requestWithMethod:@"PUT" path:destinationPath data:data];
        [self buildHeadersForRequest:request bucket:self.bucket key:destinationPath method:@"PUT" contentMD5:MD5 contentType:contentType];
        
        AFHTTPRequestOperation *requestOperation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if (success) {
                success(operation, responseObject);
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (failure) {
                failure(operation, error);
            }
        }];

        [requestOperation setUploadProgressBlock:progress];

        [self enqueueHTTPRequestOperation:requestOperation];
    }
}

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                      data:(NSData *)data
{
	NSMutableURLRequest *request = [super requestWithMethod:method path:path parameters:nil];
	[request setHTTPBody:data];
	
	return request;
}

#pragma mark - Helper Methods

+ (NSString *)stringByURLEncodingForS3Path:(NSString *)key {
	if (!key) {
		return @"/";
	}
	NSString *path = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)key, NULL, CFSTR(":#[]@!$ '()*+,;=\"<>%{}|\\^~`"), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));
	if (![[path substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"/"]) {
		path = [@"/" stringByAppendingString:path];
	}
	return path;
}

// Thanks to Tom Andersen for pointing out the threading issues and providing this code!
+ (NSDateFormatter *)S3ResponseDateFormatter {
	// We store our date formatter in the calling thread's dictionary
	// NSDateFormatter is not thread-safe, this approach ensures each formatter is only used on a single thread
	// This formatter can be reused 1000 times in parsing a single response, so it would be expensive to keep creating new date formatters
	NSMutableDictionary *threadDict = [[NSThread currentThread] threadDictionary];
	NSDateFormatter *dateFormatter = [threadDict objectForKey:@"AFS3ResponseDateFormatter"];
	if (dateFormatter == nil) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
		[dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
		[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'.000Z'"];
		[threadDict setObject:dateFormatter forKey:@"ASIS3ResponseDateFormatter"];
	}
	return dateFormatter;
}

+ (NSDateFormatter *)S3RequestDateFormatter {
	NSMutableDictionary *threadDict = [[NSThread currentThread] threadDictionary];
	NSDateFormatter *dateFormatter = [threadDict objectForKey:@"AFS3RequestHeaderDateFormatter"];
	if (dateFormatter == nil) {
		dateFormatter = [[NSDateFormatter alloc] init];
		// Prevent problems with dates generated by other locales (tip from: http://rel.me/t/date/)
		[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
		[dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
		[dateFormatter setDateFormat:@"EEE, d MMM yyyy HH:mm:ss Z"];
		[threadDict setObject:dateFormatter forKey:@"ASIS3RequestHeaderDateFormatter"];
	}
	return dateFormatter;
	
}

// From: http://www.cocoadev.com/index.pl?BaseSixtyFour

+ (NSString *)base64forData:(NSData *)theData {
	const uint8_t* input = (const uint8_t*)[theData bytes];
	NSInteger length = [theData length];
	
	static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
	
	NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
	uint8_t* output = (uint8_t*)data.mutableBytes;
	
	NSInteger i,i2;
	for (i=0; i < length; i += 3) {
		NSInteger value = 0;
		for (i2=0; i2<3; i2++) {
			value <<= 8;
			if (i+i2 < length) {
				value |= (0xFF & input[i+i2]);
			}
		}
		
		NSInteger theIndex = (i / 3) * 4;
		output[theIndex + 0] =                    table[(value >> 18) & 0x3F];
		output[theIndex + 1] =                    table[(value >> 12) & 0x3F];
		output[theIndex + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
		output[theIndex + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
	}
	
	return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
}

// From: http://stackoverflow.com/questions/476455/is-there-a-library-for-iphone-to-work-with-hmac-sha-1-encoding

+ (NSData *)HMACSHA1withKey:(NSString *)key forString:(NSString *)string {
	NSData *clearTextData = [string dataUsingEncoding:NSUTF8StringEncoding];
	NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
	
	uint8_t digest[CC_SHA1_DIGEST_LENGTH] = {0};
	
	CCHmacContext hmacContext;
	CCHmacInit(&hmacContext, kCCHmacAlgSHA1, keyData.bytes, keyData.length);
	CCHmacUpdate(&hmacContext, clearTextData.bytes, clearTextData.length);
	CCHmacFinal(&hmacContext, digest);
	
	return [NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH];
}

+ (NSString *)mimeTypeForFileAtPath:(NSString *)path {
	if (![[[NSFileManager alloc] init] fileExistsAtPath:path]) {
		return nil;
	}
	// Borrowed from http://stackoverflow.com/questions/2439020/wheres-the-iphone-mime-type-database
	CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[path pathExtension], NULL);
	CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType);
	CFRelease(UTI);
	if (!MIMEType) {
		return @"application/octet-stream";
	}
	return (__bridge NSString *)(MIMEType);
}

+ (NSString *)MD5ForData:(NSData *)data {
    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(data.bytes, data.length, md5Buffer);
    
    // Convert unsigned char buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    return output;
}

@end
