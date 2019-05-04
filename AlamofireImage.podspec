Pod::Spec.new do |s|
  s.name = 'AlamofireImage'
  s.version = '4.0.0-beta.3'
  s.license = 'MIT'
  s.summary = 'AlamofireImage is an image component library for Alamofire'
  s.homepage = 'https://github.com/Alamofire/AlamofireImage'
  s.social_media_url = 'http://twitter.com/AlamofireSF'
  s.authors = { 'Alamofire Software Foundation' => 'info@alamofire.org' }
  s.documentation_url = 'https://alamofire.github.io/AlamofireImage/'

  s.source = { :git => 'https://github.com/Alamofire/AlamofireImage.git', :tag => s.version }
  s.source_files = 'Source/*.swift'

  s.ios.deployment_target = '10.0'
  s.osx.deployment_target = '10.12'
  s.tvos.deployment_target = '10.0'
  s.watchos.deployment_target = '3.0'

  s.swift_version = '5.0'

  s.dependency 'Alamofire', '~> 5.0.0-beta.6'
end
