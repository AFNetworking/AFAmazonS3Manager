Pod::Spec.new do |s|
  s.name         = "AFAmazonS3Client"
  s.version      = "1.0.0"
  s.summary      = "AFNetworking Client for the Amazon S3 API."
  s.homepage     = "https://github.com/AFNetworking/AFAmazonS3Client"
  s.social_media_url = "https://twitter.com/AFNetworking"
  s.license      = 'MIT'
  s.author       = { "Mattt Thompson" => "m@mattt.me" }
  s.source       = { :git => "https://github.com/AFNetworking/AFAmazonS3Client.git",
                     :tag => "1.0.0" }

  s.source_files = 'AFAmazonS3Client'
  s.requires_arc = true

  s.dependency 'AFNetworking', '~> 2.0.0'

  s.prefix_header_contents = <<-EOS
#import <Availability.h>

#define _AFNETWORKING_PIN_SSL_CERTIFICATES_

#if __IPHONE_OS_VERSION_MIN_REQUIRED
  #import <SystemConfiguration/SystemConfiguration.h>
  #import <MobileCoreServices/MobileCoreServices.h>
  #import <Security/Security.h>
#else
  #import <SystemConfiguration/SystemConfiguration.h>
  #import <CoreServices/CoreServices.h>
  #import <Security/Security.h>
#endif
EOS

end
