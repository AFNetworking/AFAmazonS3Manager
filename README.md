# AFAmazonS3Client

`AFAmazonS3Client` is an `AFHTTPClient` subclass for interacting with the [Amazon S3 API](http://aws.amazon.com/s3/).

As the S3 API returns XML responses, you may find it useful to include [AFKissXMLRequestOperation](https://github.com/AFNetworking/AFKissXMLRequestOperation) (just remember to do `-registerHTTPOperationClass:`)

**Caution:** This code is still in its early stages of development, so exercise caution when incorporating this into production code.

## Example Usage

```objective-c
AFAmazonS3Client *s3Client = [[AFAmazonS3Client alloc] initWithAccessKeyID:@"..." secret:@"..."];
    s3Client.bucket = @"my-bucket-name";
    [s3Client postObjectWithFile:@"/path/to/file" destinationPath:@"https://s3.amazonaws.com/example" parameters:nil progress:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        NSLog(@"%f%% Uploaded", (totalBytesWritten / (totalBytesExpectedToWrite * 1.0f) * 100));
    } success:^(id responseObject) {
        NSLog(@"Upload Complete");
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error);
    }];
```

## Contact

Mattt Thompson

- http://github.com/mattt
- http://twitter.com/mattt
- m@mattt.me

## License

AFAmazonS3Client is available under the MIT license. See the LICENSE file for more info.
