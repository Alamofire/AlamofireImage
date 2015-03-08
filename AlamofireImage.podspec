Pod::Spec.new do |s|
  s.name = 'AlamofireImage'
  s.version = '0.0.1'
  s.license = 'MIT'
  s.summary = 'Response Image Serializers for Alamofire'
  s.homepage = 'https://github.com/cnoon/AlamofireImage'
  s.social_media_url = 'http://twitter.com/Christian_Noon'
  s.authors = { 'Christian Noon' => 'christian.noon@gmail.com' }
  
  s.source = { :git => 'https://github.com/cnoon/AlamofireImage.git', :branch => 'development' }
  s.source_files = 'Source/*.swift'
  
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  
  s.dependency 'Alamofire', '~> 1.1.4'
end
