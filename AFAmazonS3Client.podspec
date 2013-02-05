Pod::Spec.new do |s|
  s.name         = "AFAmazonS3Client"
  s.version      = "0.1.1"
  s.summary      = "AFNetworking Client for the Amazon S3 API."
  s.homepage     = "https://github.com/eliperkins/AFAmazonS3Client"
  s.license      = 'MIT'
  s.authors       = { "Mattt Thompson" => "m@mattt.me", "Eli Perkins" => "eli@onemightyroar.com" }
  s.source       = { :git => "https://github.com/eliperkins/AFAmazonS3Client.git", 
                     :tag => "0.1.1" }

  s.source_files = 'AFAmazonS3Client'
  s.requires_arc = true

  s.dependency 'AFNetworking', '~> 1.0'
  s.dependency 'XMLDictionary'
end
