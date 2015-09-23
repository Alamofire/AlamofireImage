# Change Log
All notable changes to this project will be documented in this file.
`AlamofireImage` adheres to [Semantic Versioning](http://semver.org/).

#### 1.x Releases

- `1.1.x` Releases - [1.1.0](#110) | [1.1.1](#111)
- `1.0.x` Releases - [1.0.0](#100)
- `1.0.0` Betas - [1.0.0-beta.1](#100-beta1)

---

## [1.1.1](https://github.com/Alamofire/AlamofireImage/releases/tag/1.1.1)
Released on 2015-09-22. All issues associated with this milestone can be found using this 
[filter](https://github.com/Alamofire/AlamofireImage/issues?utf8=✓&q=milestone%3A1.1.1).

#### Added
- Tests around the UIImageView extension usage with redirect URLs.
  - Added by [Christian Noon](https://github.com/cnoon) in regards to Issue
  [#15](https://github.com/Alamofire/AlamofireImage/pull/15).
- Tests around the UIImageView extension usage with duplicate image requests.
  - Added by [Christian Noon](https://github.com/cnoon) in regards to Issue
  [#17](https://github.com/Alamofire/AlamofireImage/pull/17).

#### Fixed
- Issue where `UIImageView` extension did not support redirect URLs.
  - Fixed by [Robert Payne](https://github.com/robertjpayne) in Pull Request
  [#16](https://github.com/Alamofire/AlamofireImage/pull/16).
- Issue where duplicate image requests were cancelling the active image download
in the `UIImageView` extension.
  - Fixed by [Christian Noon](https://github.com/cnoon) in regards to Issue
  [#17](https://github.com/Alamofire/AlamofireImage/pull/17).

## [1.1.0](https://github.com/Alamofire/AlamofireImage/releases/tag/1.1.0)
Released on 2015-09-19. All issues associated with this milestone can be found using this 
[filter](https://github.com/Alamofire/AlamofireImage/issues?utf8=✓&q=milestone%3A1.1.0).

#### Added
- Custom image transition to the `UIImageView` extension.
  - Added by [Kevin Harwood](https://github.com/kcharwood) in Pull Request
  [#9](https://github.com/Alamofire/AlamofireImage/pull/9).
- CompositeImageFilter protocol to construct composite image filters.
  - Added by [Damien Rambout](https://github.com/damienrambout) in Pull Request
  [#8](https://github.com/Alamofire/AlamofireImage/pull/8).
- `DynamicImageFilter` and `DynamicCompositeImageFilter` structs to make it easy
to create custom image filters.
  - Added by [Damien Rambout](https://github.com/damienrambout) in Pull Request
  [#14](https://github.com/Alamofire/AlamofireImage/pull/14).

#### Updated
- `ImageDownloader` download image completion closures to be optional.
  - Updated by [Christian Noon](https://github.com/cnoon).
- Completion callback behavior of the `UIImageView` extension methods to be called before
the image transition occurs.
  - Updated by [Kevin Harwood](https://github.com/kcharwood) in Pull Request
  [#9](https://github.com/Alamofire/AlamofireImage/pull/9).
- Rounded corner radius image filter can now be adjusted by the image scale.
  - Updated by [Christian Noon](https://github.com/cnoon) in Pull Request
  [#10](https://github.com/Alamofire/AlamofireImage/pull/10).
- Enabled APPLICATION_EXTENSION_API_ONLY in watchOS framework.
  - Updated by [James Barrow](https://github.com/Baza207) in Pull Request
  [#11](https://github.com/Alamofire/AlamofireImage/pull/11).
- The podspec file to allow all Alamofire 2.x versions.
  - Updated by [Christian Noon](https://github.com/cnoon).

## [1.0.0](https://github.com/Alamofire/AlamofireImage/releases/tag/1.0.0)
Released on 2015-09-09. All issues associated with this milestone can be found using this 
[filter](https://github.com/Alamofire/AlamofireImage/issues?utf8=✓&q=milestone%3A1.0.0).

#### Updated
- Alamofire dependency to `~> 2.0` for CocoaPods and Carthage.
  - Updated by [Christian Noon](https://github.com/cnoon).
- Alamofire submodule to 2.0.0 release commit.
  - Updated by [Christian Noon](https://github.com/cnoon).
- Xcode `APPLICATION_EXTENSION_API_ONLY` to `YES` for iOS and OSX frameworks.
  - Updated by [Matt Delves](https://github.com/mattdelves) in Pull Request
  [#4](https://github.com/Alamofire/AlamofireImage/pull/4).

#### Fixed
- Issue in `ImageDownloader` where the wrong image was being stored in the image cache.
  - Fixed by [Robin Eggenkamp](https://github.com/Edubits) in Pull Request
  [#3](https://github.com/Alamofire/AlamofireImage/pull/3).

---

## [1.0.0-beta.1](https://github.com/Alamofire/AlamofireImage/releases/tag/1.0.0-beta.1)
Released on 2015-09-05.

#### Added
- Initial release of AlamofireImage.
  - Added by [Christian Noon](https://github.com/cnoon).
