// AFAmazonS3RequestSerializer.m
//
// Copyright (c) 2014 Mattt Thompson (http://mattt.me/)
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

#import "AFAmazonS3RequestSerializer.h"
#import "AFAmazonS3Manager.h"

#import <CommonCrypto/CommonHMAC.h>

NSString * const AFAmazonS3USStandardRegion = @"s3.amazonaws.com";
NSString * const AFAmazonS3USWest1Region = @"s3-us-west-1.amazonaws.com";
NSString * const AFAmazonS3USWest2Region = @"s3-us-west-2.amazonaws.com";
NSString * const AFAmazonS3EUWest1Region = @"s3-eu-west-1.amazonaws.com";
NSString * const AFAmazonS3APSoutheast1Region = @"s3-ap-southeast-1.amazonaws.com";
NSString * const AFAmazonS3APSoutheast2Region = @"s3-ap-southeast-2.amazonaws.com";
NSString * const AFAmazonS3APNortheast2Region = @"s3-ap-northeast-1.amazonaws.com";
NSString * const AFAmazonS3SAEast1Region = @"s3-sa-east-1.amazonaws.com";

static NSData * AFHMACSHA1EncodedDataFromStringWithKey(NSString *string, NSString *key) {
    NSData *data = [string dataUsingEncoding:NSASCIIStringEncoding];
    CCHmacContext context;
    const char *keyCString = [key cStringUsingEncoding:NSASCIIStringEncoding];

    CCHmacInit(&context, kCCHmacAlgSHA1, keyCString, strlen(keyCString));
    CCHmacUpdate(&context, [data bytes], [data length]);

    unsigned char digestRaw[CC_SHA1_DIGEST_LENGTH];
    NSUInteger digestLength = CC_SHA1_DIGEST_LENGTH;

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

static NSString * AFBase64EncodedStringFromData(NSData *data) {
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

@interface AFAmazonS3RequestSerializer ()
@property (readwrite, nonatomic, copy) NSString *accessKey;
@property (readwrite, nonatomic, copy) NSString *secret;
@end

@implementation AFAmazonS3RequestSerializer

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.region = AFAmazonS3USStandardRegion;
    self.useSSL = YES;

    return self;
}

- (void)setAccessKeyID:(NSString *)accessKey
                secret:(NSString *)secret
{
    NSParameterAssert(accessKey);
    NSParameterAssert(secret);

    self.accessKey = accessKey;
    self.secret = secret;
}

- (void)setRegion:(NSString *)region {
    NSParameterAssert(region);
    _region = region;
}

- (NSURL *)endpointURL {
    NSString *URLString = nil;
    NSString *scheme = self.useSSL ? @"https" : @"http";
    if (self.bucket) {
        URLString = [NSString stringWithFormat:@"%@://%@.%@", scheme, self.bucket, self.region];
    } else {
        URLString = [NSString stringWithFormat:@"%@://%@", scheme, self.region];
    }

    return [NSURL URLWithString:URLString];
}

#pragma mark -

- (NSURLRequest *)requestBySettingAuthorizationHeadersForRequest:(NSURLRequest *)request
                                                           error:(NSError * __autoreleasing *)error
{
    NSMutableURLRequest *mutableRequest = [request mutableCopy];

    if (self.accessKey && self.secret) {
		NSMutableDictionary *mutableAMZHeaderFields = [NSMutableDictionary dictionary];
		[[request allHTTPHeaderFields] enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, __unused BOOL *stop) {
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

        [mutableRequest setValue:[NSString stringWithFormat:@"AWS %@:%@", self.accessKey, signature] forHTTPHeaderField:@"Authorization"];
        [mutableRequest setValue:(date) ? date : @"" forHTTPHeaderField:@"Date"];
    } else {
        if (error) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: NSLocalizedStringFromTable(@"Access Key and Secret Required", @"AFAmazonS3Manager", nil)};
            *error = [[NSError alloc] initWithDomain:AFAmazonS3ManagerErrorDomain code:NSURLErrorUserAuthenticationRequired userInfo:userInfo];
        }
    }

    return mutableRequest;
}

#pragma mark - AFHTTPRequestSerializer

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                 URLString:(NSString *)URLString
                                parameters:(NSDictionary *)parameters
                                     error:(NSError *__autoreleasing *)error
{
    return [[self requestBySettingAuthorizationHeadersForRequest:[super requestWithMethod:method URLString:URLString parameters:parameters error:error] error:error] mutableCopy];
}

- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                              URLString:(NSString *)URLString
                                             parameters:(NSDictionary *)parameters
                              constructingBodyWithBlock:(void (^)(id<AFMultipartFormData>))block
                                                  error:(NSError *__autoreleasing *)error
{
    return [[self requestBySettingAuthorizationHeadersForRequest:[super multipartFormRequestWithMethod:method URLString:URLString parameters:parameters constructingBodyWithBlock:block error:error] error:error] mutableCopy];
}

@end
