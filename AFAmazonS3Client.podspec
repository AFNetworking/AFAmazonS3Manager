Pod::Spec.new do |s|
  s.name         = "AFAmazonS3Client"
  s.version      = "2.0.1"
  s.summary      = "AFNetworking extension for the Amazon S3 API."
  s.homepage     = "https://github.com/AFNetworking/AFAmazonS3Client"
  s.social_media_url = "https://twitter.com/AFNetworking"
  s.license      = 'MIT'
  s.author       = { "Mattt Thompson" => "m@mattt.me" }
  s.source       = { :git => "https://github.com/AFNetworking/AFAmazonS3Client.git",
                     :tag => "2.0.1" }

  s.ios.deployment_target = '6.0'
  s.osx.deployment_target = '10.8'

  s.source_files = 'AFAmazonS3Client'
  s.requires_arc = true

  s.deprecated = true
  s.deprecated_in_favor_of = 'AFAmazonS3Manager'

  s.dependency 'AFNetworking', '~>2.2'
end
