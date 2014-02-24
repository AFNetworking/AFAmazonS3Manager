# AFAmazonS3Client

`AFAmazonS3Client` is an `AFHTTPRequestOperationManager` subclass for interacting with the [Amazon S3 API](http://aws.amazon.com/s3/).

## Example Usage

```objective-c
AFAmazonS3Client *s3Client = [[AFAmazonS3Client alloc] initWithAccessKeyID:@"..." secret:@"..."];
s3Client.region = AFAmazonS3USWest1Region;
s3Client.bucket = @"my-bucket-name";

[s3Client postObjectWithFile:@"/path/to/file"
             destinationPath:@"https://s3.amazonaws.com/example"
                  parameters:nil
                    progress:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
                        NSLog(@"%f%% Uploaded", (totalBytesWritten / (totalBytesExpectedToWrite * 1.0f) * 100));
}
                     success:^(id responseObject) {
                        NSLog(@"Upload Complete");
}
                     failure:^(NSError *error) {
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
