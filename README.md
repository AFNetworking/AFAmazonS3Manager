# AFAmazonS3Manager

`AFAmazonS3Manager` is an `AFHTTPRequestOperationManager` subclass for interacting with the [Amazon S3 API](http://aws.amazon.com/s3/).

## Example Usage

```objective-c
AFAmazonS3Manager *s3Manager = [[AFAmazonS3Manager alloc] initWithAccessKeyID:@"..." secret:@"..."];
s3Manager.requestSerializer.region = AFAmazonS3USWest1Region;
s3Manager.requestSerializer.bucket = @"my-bucket-name";

NSString *destinationPath = @"/pathOnS3/to/file.txt";

[s3Manager postObjectWithFile:@"/path/to/file.txt"
              destinationPath:destinationPath
                   parameters:nil
                     progress:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
                        NSLog(@"%f%% Uploaded", (totalBytesWritten / (totalBytesExpectedToWrite * 1.0f) * 100));
}
                      success:^(AFAmazonS3ResponseObject *responseObject) {
                        NSLog(@"Upload Complete: %@", responseObject.URL);
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

AFAmazonS3Manager is available under the MIT license. See the LICENSE file for more info.
