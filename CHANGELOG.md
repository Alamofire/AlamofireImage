# Change Log
All notable changes to this project will be documented in this file.
`AlamofireImage` adheres to [Semantic Versioning](http://semver.org/).

#### 3.x Releases
- `3.3.x` Releases - [3.3.0](#330) | [3.3.1](#331)
- `3.2.x` Releases - [3.2.0](#320)
- `3.1.x` Releases - [3.1.0](#310)
- `3.0.x` Releases - [3.0.0](#300)

#### 2.x Releases
- `2.5.x` Releases - [2.5.0](#250)
- `2.4.x` Releases - [2.4.0](#240) | [2.4.1](#241)
- `2.3.x` Releases - [2.3.0](#230) | [2.3.1](#231)
- `2.2.x` Releases - [2.2.0](#220)
- `2.1.x` Releases - [2.1.0](#210) | [2.1.1](#211)
- `2.0.x` Releases - [2.0.0](#200)
- `2.0.0` Betas - [2.0.0-beta.1](#200-beta1) | [2.0.0-beta.2](#200-beta2)

#### 1.x Releases
- `1.1.x` Releases - [1.1.0](#110) | [1.1.1](#111) | [1.1.2](#112)
- `1.0.x` Releases - [1.0.0](#100)
- `1.0.0` Betas - [1.0.0-beta.1](#100-beta1)

---

## [3.3.1](https://github.com/Alamofire/AlamofireImage/releases/tag/3.3.1)
Released on 2018-03-31. All issues associated with this milestone can be found using this
[filter](https://github.com/Alamofire/AlamofireImage/milestone/24?closed=1).

#### Added
- Jazzy docs and configuration.
  - Added by [Jon Shier](https://github.com/jshier) in Pull Request [#309](https://github.com/Alamofire/AlamofireImage/pull/309).
- Ruby environment settings that match Alamofire's.
  - Added by [Jon Shier](https://github.com/jshier) in Pull Request [#309](https://github.com/Alamofire/AlamofireImage/pull/309).

#### Updated
- Project configuration and files for Xcode 9.3 and Swift 4.1.
  - Updated by [Jon Shier](https://github.com/jshier) in Pull Request [#309](https://github.com/Alamofire/AlamofireImage/pull/309).
- Copyrights to 2018 for all files.
  - Updated by [Jon Shier](https://github.com/jshier) in Pull Request [#309](https://github.com/Alamofire/AlamofireImage/pull/309).
- TravisCI configuration for Xcode 9.3.
  - Updated by [Jon Shier](https://github.com/jshier) in Pull Request [#309](https://github.com/Alamofire/AlamofireImage/pull/309).

#### Fixed
- Gravatar API usage in example code.
  - Fixed by [Felipe Plets](https://github.com/felipeplets) in Pull Request [#298](https://github.com/Alamofire/AlamofireImage/pull/298).

## [3.3.0](https://github.com/Alamofire/AlamofireImage/releases/tag/3.3.0)
Released on 2017-09-06. All issues associated with this milestone can be found using this
[filter](https://github.com/Alamofire/AlamofireImage/milestone/21?closed=1).

#### Added
- Gitter badge to the README to direct users to the group.
  - Added by [Christian Noon](https://github.com/cnoon).
- Optional `queue` parameter to `responseImage` function.
  - Added by [Timur Galimov](https://github.com/timaktimak) in Pull Request
  [#227](https://github.com/Alamofire/AlamofireImage/pull/227).
- Asserts to scaling functions as well as production fallbacks.
  - Added by [Christian Noon](https://github.com/cnoon) in regards to Issue
  [#226](https://github.com/Alamofire/AlamofireImage/issues/226).
- GitHub templates for issues and pull requests.
  - Added by [Jon Shier](https://github.com/jshier).

#### Updated
- Alamofire submodule and dependency to `~> 4.5`.
  - Updated by [Christian Noon](https://github.com/cnoon).
- The project and codebase to support Swift 3 / 4 simultaneously.
  - Updated by [Jon Shier](https://github.com/jshier) in Pull Requests
  [#269](https://github.com/Alamofire/AlamofireImage/pull/269) and
  [#283](https://github.com/Alamofire/AlamofireImage/pull/283).
- The README to use the current version throughout the installation section.
  - Updated by [Kim de Vos](https://github.com/kimdv) in Pull Request
  [#274](https://github.com/Alamofire/AlamofireImage/pull/274).
- Image response serializers code sample in the README to `import Alamofire`.
  - Updated by [Brian Schermerhorn](https://github.com/elderbas) in Pull Request
  [#276](https://github.com/Alamofire/AlamofireImage/pull/276).

#### Fixed
- The Swift Package Manager (SPM) integration by excluding `Tests` folder.
  - Fixed by [Jon Shier](https://github.com/jshier) in Pull Request
  [#252](https://github.com/Alamofire/AlamofireImage/pull/252).
- Issue in the embedded framework section of the README where `bash` specifier was incorrect.
  - Fixed by [Chris Schepman](https://github.com/cschep) in Pull Request
  [#253](https://github.com/Alamofire/AlamofireImage/pull/253).
- Various typos throughout the project using `misspell`.
  - Fixed by [Wolfgang Lutz](https://github.com/Lutzifer) in Pull Request
  [#259](https://github.com/Alamofire/AlamofireImage/pull/259).

---

## [3.2.0](https://github.com/Alamofire/AlamofireImage/releases/tag/3.2.0)
Released on 2016-11-20. All issues associated with this milestone can be found using this
[filter](https://github.com/Alamofire/AlamofireImage/milestone/20?closed=1).

#### Added
- A new `imageResponseSerializer` property to the `ImageDownloader`.
  - Added by [Tapani Saarinen](https://github.com/tapz) in Pull Request.
  [#208](https://github.com/Alamofire/AlamofireImage/pull/208).
- New embedded framework installation instructions to the README.
  - Added by [Eric Horstmanshof](https://github.com/Erulezz) in Pull Request.
  [#213](https://github.com/Alamofire/AlamofireImage/pull/213).
- A new iOS 8.1 target to the Travis CI device matrix.
  - Added by [Christian Noon](https://github.com/cnoon).

#### Updated
- The `AutoPurgingImageCache` APIs to an `open` ACL where applicable.
  - Updated by [Christian Noon](https://github.com/cnoon).
- The `ImageDownloader` and `RequestReceipt` APIs to an `open` ACL where applicable.
  - Updated by [Christian Noon](https://github.com/cnoon).
- The Xcode project to Xcode 8.1 and made all suggested project updates.
  - Updated by [Christian Noon](https://github.com/cnoon).
- `UIButton` and `UIImageView` completion closures to be called after image is set.
  - Updated by [Christian Noon](https://github.com/cnoon) in regards to Issue
  [#209](https://github.com/Alamofire/AlamofireImage/issues/209).
- The deployment targets to iOS 8.0 and macOS 10.10 to match core Alamofire project.
  - Updated by [Christian Noon](https://github.com/cnoon) in regards to Issue.
  [#216](https://github.com/Alamofire/AlamofireImage/issues/216).
- The Cartfile and pulled in Alamofire 4.2.0 submodule.
  - Updated by [Christian Noon](https://github.com/cnoon).

#### Removed
- CoreImage filters on iOS 8.x due to runtime mapping issue with `CIContext`.
  - Removed by [Christian Noon](https://github.com/cnoon).

---

## [3.1.0](https://github.com/Alamofire/AlamofireImage/releases/tag/3.1.0)
Released on 2016-10-01. All issues associated with this milestone can be found using this
[filter](https://github.com/Alamofire/AlamofireImage/milestone/19?closed=1).

#### Added
- New `.swift-version` file to repo and reactivated pod lib lint in Travis file.
  - Added by [Christian Noon](https://github.com/cnoon).
- The `OS_ACTIVITY_MODE` environment variable to disable excessive logging.
  - Added by [Christian Noon](https://github.com/cnoon).
- The new `CoreImageFilter` protocol and updated `BlurFilter` to conform to it.
  - Added by [Florian Morello](https://github.com/arsonik) in Pull Request
  [#101](https://github.com/Alamofire/AlamofireImage/pull/101).
- The ability to the `AutoPurgingImageCache` to remove all images matching a URL request.
  - Added by [Christian Noon](https://github.com/cnoon) in regards to Issue
  [#105](https://github.com/Alamofire/AlamofireImage/issues/105).
- `ImageFilter` support to the `UIButton` extension.
  - Added by [gshahbazian](https://github.com/gshahbazian) in Pull Request
  [#129](https://github.com/Alamofire/AlamofireImage/pull/129).
- MJPEG support to `DataRequest` extension for streaming images.
  - Added by [Robbie Trencheny](https://github.com/robbiet480) in Pull Request
  [#185](https://github.com/Alamofire/AlamofireImage/pull/185).
- Stream image test for `DataRequest` extension and updated docstrings.
  - Added by [Christian Noon](https://github.com/cnoon).

#### Updated
- The Alamofire submodule to the 4.0.1 release.
  - Updated by [Christian Noon](https://github.com/cnoon).
- All cases of OSX to macOS throughout the project.
  - Updated by [Justin Jia](https://github.com/JustinJiaDev) in Pull Request
  [#181](https://github.com/Alamofire/AlamofireImage/issues/181).
- Project settings by removing duplicate settings for individual targets.
  - Updated by [Christian Noon](https://github.com/cnoon).
- Project and podspec so all files are compiled on all platforms.
  - Updated by [Christian Noon](https://github.com/cnoon).

#### Fixed
- A typo in `placeholderImage` parameter in several UIButton APIs.
  - Fixed by [Christian Noon](https://github.com/cnoon) in regard to Issue
  [#180](https://github.com/Alamofire/AlamofireImage/issues/180).
- A `CIGuassianBlur` typo in one of the README code samples.
  - Fixed by [Christian Noon](https://github.com/cnoon) in regard to Issue
  [#189](https://github.com/Alamofire/AlamofireImage/issues/189).

#### Upgrade Notes
This release contains a non-backwards compatible change that fixes a typo in the `UIButton` extension where `placeholderImage` was misspelled in two APIs. Rather than push a MAJOR version release for a typo that people are generally getting incorrect, we decided to break semver here and fix the typo for everyone. Please note that we always try to follow semver as strictly as possible. However, this seemed like the best option given that users would continue to struggle with the typo throughout the lifespan of the 3.x releases.

---

## [3.0.0](https://github.com/Alamofire/AlamofireImage/releases/tag/3.0.0)
Released on 2016-09-11. All issues associated with this milestone can be found using this
[filter](https://github.com/Alamofire/AlamofireImage/milestone/18?closed=1).

#### Added
- An AFI 3.0 Migration Guide and updated the README to match new APIs.
  - Updated by [Jon Shier](https://github.com/jshier) in Pull Request
  [#176](https://github.com/Alamofire/AlamofireImage/pull/176).

#### Updated
- All source, test and example logic as well as project settings to compile against
  the Xcode 8 beta releases.
  - Updated by [Kevin Harwood](https://github.com/kcharwood),
    [Mathias Nagler](https://github.com/mathiasnagler),
    [Jon Shier](https://github.com/jshier) and 
    [Christian Noon](https://github.com/cnoon).
- Deployment targets to iOS 9.0, macOS 10.11, tvOS 9.0 and watchOS 2.0.
  - Updated by [Christian Noon](https://github.com/cnoon).
- All instances of `com.alamofire` with `org.alamofire` throughout project.
  - Updated by [Christian Noon](https://github.com/cnoon).
- Copyright headers to match Alamofire formatting.
  - Updated by [Christian Noon](https://github.com/cnoon).
- Updated the travis yaml file for Xcode 8.
  - Updated by [Christian Noon](https://github.com/cnoon) in Pull Request
  [#154](https://github.com/Alamofire/AlamofireImage/pull/154).
- All source, test and example APIs to match Swift 3 design guidelines.
  - Updated by [Christian Noon](https://github.com/cnoon) in Pull Request
  [#154](https://github.com/Alamofire/AlamofireImage/pull/154).
- All docstrings to use new Swift 3 syntax.
  - Updated by [Christian Noon](https://github.com/cnoon) in Pull Request
  [#154](https://github.com/Alamofire/AlamofireImage/pull/154).
- All `AssociatedKey` names to be lowercased to match Swift 3 guidelines.
  - Updated by [Christian Noon](https://github.com/cnoon) in Pull Request
  [#154](https://github.com/Alamofire/AlamofireImage/pull/154).
- The podspec for the 3.0.0 release and bumped deployment targets.
  - Updated by [Christian Noon](https://github.com/cnoon).
- Code signing to now automatic with an empty team.
  - Updated by [Christian Noon](https://github.com/cnoon).
- Number of large image test iterations to 200 to attempt to stabilize travis.
  - Updated by [Christian Noon](https://github.com/cnoon).

#### Removed
- `DispatchWorkItemFlags` implementation with async flags.
  - Removed by [Christian Noon](https://github.com/cnoon) in Pull Request
  [#154](https://github.com/Alamofire/AlamofireImage/pull/154).
- `ReleaseTest` configuration by enabling testability in travis yaml file.
  - Removed by [Christian Noon](https://github.com/cnoon).
- An `NSURL` extension from the test suite that wasn’t used.
  - Removed by [Christian Noon](https://github.com/cnoon).

#### Fixed
- Issue where `removeImage` API on the image cache would not remove the image.
  - Fixed by [Christian Noon](https://github.com/cnoon) in Pull Request
  [#154](https://github.com/Alamofire/AlamofireImage/pull/154) in regards to Issue
  [#152](https://github.com/Alamofire/AlamofireImage/issues/152).
- Compilation errors due to `AFError` refactors in Alamofire.
  - Fixed by [Christian Noon](https://github.com/cnoon).

---

## [2.5.0](https://github.com/Alamofire/AlamofireImage/releases/tag/2.5.0)
Released on 2016-09-08. All issues associated with this milestone can be found using this
[filter](https://github.com/Alamofire/AlamofireImage/milestone/15?closed=1).

#### Added
- Cleanup Whitespace aggregate target and scheme and removed all excess whitespace.
  - Added by [Christian Noon](https://github.com/cnoon).

#### Updated
- The source, test and example code along with project settings to support Swift 2.2
  and Swift 2.3 simultaneously.
  - Updated by [Christian Noon](https://github.com/cnoon).
- Updated the travis yaml file for Swift 2.3 and the new OS target versions.
  - Updated by [Christian Noon](https://github.com/cnoon).
- Updated the Cartfile and Alamofire submodule to the 3.5.0 release.
  - Updated by [Christian Noon](https://github.com/cnoon).
- Updated Xcode project settings based on Xcode 8 GM recommendations.
  - Updated by [Christian Noon](https://github.com/cnoon).
- Code coverage generation is now disabled on framework targets to improve stability.
  - Updated by [Christian Noon](https://github.com/cnoon).

#### Fixed
- Issue where image download cancellation error was thrown in incorrect domain.
  - Fixed by [Christian Noon](https://github.com/cnoon) in regards to Issue
  [#128](https://github.com/Alamofire/AlamofireImage/issues/128).
- Image download cancellation and restart race condition.
  - Fixed by [Christian Noon](https://github.com/cnoon) in regards to Issue
  [#121](https://github.com/Alamofire/AlamofireImage/issues/121).

---

## [2.4.1](https://github.com/Alamofire/AlamofireImage/releases/tag/2.4.1)
Released on 2016-07-18. All issues associated with this milestone can be found using this
[filter](https://github.com/Alamofire/AlamofireImage/milestone/16?closed=1).

#### Updated
- The dependency requirement in the README to Alamofire 3.3+.
  - Updated by [Christian Noon](https://github.com/cnoon).
- The Alamofire submodule to the 3.4.1 release.
  - Updated by [Christian Noon](https://github.com/cnoon).
- The Travis CI yaml file to use the `xcode7.3` build.
  - Updated by [Christian Noon](https://github.com/cnoon).

#### Fixed
- Issue where queue names were not using hex formatters properly.
  - Fixed by [消失的旅人](https://github.com/xsdlr) in Pull Request
  [#119](https://github.com/Alamofire/AlamofireImage/pull/119).
- Deprecation warning from `errorWithCode` usage by switching to explicit `NSError`
  creation logic.
  - Fixed by [Christian Noon](https://github.com/cnoon).

## [2.4.0](https://github.com/Alamofire/AlamofireImage/releases/tag/2.4.0)
Released on 2016-03-23. All issues associated with this milestone can be found using this
[filter](https://github.com/Alamofire/AlamofireImage/issues?utf8=✓&q=milestone%3A2.4.0).

#### Added
- The `image/x-ms-bmp` as an acceptable Content-Type.
  - Added by [Guilherme Torres Castro](https://github.com/guitcastro) in Pull Request
  [#88](https://github.com/Alamofire/AlamofireImage/pull/88).
- The ability to track download progress in the `ImageDownloader` as well as
  the `UIButton` and `UIImageView` extensions.
  - Added by [Anthony Miller](https://github.com/AnthonyMDev) in Pull Request
  [#91](https://github.com/Alamofire/AlamofireImage/pull/91).
- The `UIButton` extension and tests to the tvOS targets.
  - Added by [Christian Noon](https://github.com/cnoon) in regards to Issue
  [#94](https://github.com/Alamofire/AlamofireImage/issues/94).

#### Updated
- The Alamofire submodule to the 3.3.0 release along with the Cartfile
  and Podspec dependencies.
  - Updated by [Christian Noon](https://github.com/cnoon).
- All source code, tests and example logic to use Swift 2.2 conventions.
  - Updated by [Christian Noon](https://github.com/cnoon).
- The required version of Xcode to 7.3 in the README.
  - Updated by [Christian Noon](https://github.com/cnoon).
- The `AutoPurgingImageCache` to purge cache during memory warnings on tvOS.
  - Updated by [Christian Noon](https://github.com/cnoon).
- Several `Request` and `ImageDownloader` tests on tvOS that were previously disabled.
  - Updated by [Christian Noon](https://github.com/cnoon).

---

## [2.3.1](https://github.com/Alamofire/AlamofireImage/releases/tag/2.3.1)
Released on 2016-02-07. All issues associated with this milestone can be found using this
[filter](https://github.com/Alamofire/AlamofireImage/issues?utf8=✓&q=milestone%3A2.3.1).

#### Added
- Default value to `completion` parameter in `downloadImage` API in `ImageDownloader.
  - Added by [Christian Noon](https://github.com/cnoon).

#### Updated
- The Alamofire submodule to the 3.2.0 release.
  - Updated by [Christian Noon](https://github.com/cnoon).

#### Removed
- Superfluous APIs on `ImageDownloader`, `UIButton` and `UIImageView` extensions and replaced
  with default parameter values.
  - Removed by [Anthony Miller](https://github.com/AnthonyMDev) in Pull Request
  [#81](https://github.com/Alamofire/AlamofireImage/pull/81).

#### Fixed
- Issue in `UIImage` extension where CoreImage filters were using the incorrect output frame.
  - Fixed by [Felipe](https://github.com/fsaint) in Pull Request
  [#78](https://github.com/Alamofire/AlamofireImage/pull/78).
- All blur filter tests across all devices and OS's.
  - Fixed by [Christian Noon](https://github.com/cnoon).
- Issue where image response serializer was not thread-safe by switching over to 
  thread-safe UIImage initializer.
  - Fixed by [Christian Noon](https://github.com/cnoon) in regards to Issue
  [#75](https://github.com/Alamofire/AlamofireImage/pull/75).
- Build warnings in Xcode 7.3 beta 2 for Swift 2.2.
  - Fixed by [James Barrow](https://github.com/Baza207) in regards to Issue
  [#77](https://github.com/Alamofire/AlamofireImage/pull/77).

## [2.3.0](https://github.com/Alamofire/AlamofireImage/releases/tag/2.3.0)
Released on 2016-01-17. All issues associated with this milestone can be found using this
[filter](https://github.com/Alamofire/AlamofireImage/issues?utf8=✓&q=milestone%3A2.3.0).

#### Added
- Alpha properties to `UIImage` extension along with unit tests.
  - Added by [Christian Noon](https://github.com/cnoon).
- Condition to `UIImageView` test to verify active request receipt is reset.
  - Added by [Jorge Mario Orjuela Gutierrez](https://github.com/jorjuela33) in Pull Request
  [#62](https://github.com/Alamofire/AlamofireImage/pull/62).
- `UIButton` extension supporting remote image downloads.
  - Added by [Jorge Mario Orjuela Gutierrez](https://github.com/jorjuela33) in Pull Request
  [#63](https://github.com/Alamofire/AlamofireImage/pull/63).
- Tests verifying `Accept` header is set properly for button image downloads.
  - Added by [Christian Noon](https://github.com/cnoon).
- `UIButton` extension tests around cancelling and restarting image downloads.
  - Added by [Christian Noon](https://github.com/cnoon).
- iOS 9.2 devices to the travis yaml device matrix.
  - Added by [Christian Noon](https://github.com/cnoon).
- `Carthage/Build` ignore flag to the `.gitignore` file to match Alamofire.
  - Added by [Lars Anderson](https://github.com/larsacus) in Pull Request
  [#71](https://github.com/Alamofire/AlamofireImage/pull/71).
- `Package.swift` file to support Swift Package Manager (SPM).
  - Added by [Christian Noon](https://github.com/cnoon).

#### Updated
- `UIImage` scaling now uses `af_isOpaque` property where applicable.
  - Updated by [Christian Noon](https://github.com/cnoon) in regards to Issue
  [#65](https://github.com/Alamofire/AlamofireImage/issues/65).
- Refactored `UIButton` extension and tests to more closely follow coding standards.
  - Updated by [Christian Noon](https://github.com/cnoon).
- Simplified `UIImageView` tests replacing KVO by overriding the image property.
  - Updated by [Christian Noon](https://github.com/cnoon).
- Excluded the `UIButton` extension from osx and watchOS targets in podspec.
  - Updated by [Christian Noon](https://github.com/cnoon).
- Copyright headers to include 2016! 🎉🎉🎉
  - Updated by [Christian Noon](https://github.com/cnoon).
- The default parameters in `AutoPurgingImageCache` initializer with correct MB values.
  - Updated by [Christian Noon](https://github.com/cnoon).
- Several `UIImageView` APIs to public ACL to allow for better reuse.
  - Updated by [Christian Noon](https://github.com/cnoon).
- Alamofire submodule to 3.1.5 release.
  - Updated by [Christian Noon](https://github.com/cnoon).

---

## [2.2.0](https://github.com/Alamofire/AlamofireImage/releases/tag/2.2.0)
Released on 2015-12-16. All issues associated with this milestone can be found using this
[filter](https://github.com/Alamofire/AlamofireImage/issues?utf8=✓&q=milestone%3A2.2.0).

#### Added
- Ability for `ImageDownloader` to enqueue multiple image downloads at once.
  - Added by [Jeff Kelley](https://github.com/SlaunchaMan) in Pull Request
  [#51](https://github.com/Alamofire/AlamofireImage/pull/51).
- Tests to verify image view can cancel and restart the same request.
  - Added by [Christian Noon](https://github.com/cnoon) in regards to Issue
  [#55](https://github.com/Alamofire/AlamofireImage/pull/55).
- Precondition to `ImageCache` ensuring memory capacity is GTE preferred usage after purge.
  - Added by [Christian Noon](https://github.com/cnoon) in regards to Issue
  [#56](https://github.com/Alamofire/AlamofireImage/pull/56).
- Ability for image transitions to run when image is cached if specified.
  - Added by [Jarrod Robins](https://github.com/jarrodrobins) in Pull Request
  [#50](https://github.com/Alamofire/AlamofireImage/pull/50).
- Test to verify Accept header is set correctly on `UIImageView` extension.
  - Added by [Christian Noon](https://github.com/cnoon) in regards to Issue
  [#60](https://github.com/Alamofire/AlamofireImage/pull/60).
- Added `ReleaseTest` configuration to allow running tests against optimized build.
  - Added by [Christian Noon](https://github.com/cnoon).

#### Updated
- Project to disable testability on release and to only build tests on when testing.
  - Updated by [Christian Noon](https://github.com/cnoon).
- The Travis-CI configuration to Xcode 7.2, iOS 9.2, tvOS 9.1 and watchOS 2.1.
  - Updated by [Christian Noon](https://github.com/cnoon).

#### Fixed
- Issue where image was not downloaded when cancelled and restarted.
  - Fixed by [Christian Noon](https://github.com/cnoon) in regards to Issue
  [#55](https://github.com/Alamofire/AlamofireImage/pull/55).
- Issue where `af_setImageWithURL` was not using acceptable content types.
  - Fixed by [Branden Russell](https://github.com/brandenr) in Pull Request
  [#61](https://github.com/Alamofire/AlamofireImage/pull/61).

---

## [2.1.1](https://github.com/Alamofire/AlamofireImage/releases/tag/2.1.1)
Released on 2015-11-22. All issues associated with this milestone can be found using this
[filter](https://github.com/Alamofire/AlamofireImage/issues?utf8=✓&q=milestone%3A2.1.1).

#### Added
- Note to the README about storing a strong ref to image downloaders.
  - Added by [Muhammad Ishaq](https://github.com/ishaq) in Pull Request
  [#45](https://github.com/Alamofire/AlamofireImage/pull/45).
- Custom `Info.plist` for tvOS setting the `UIRequiredDeviceCapabilities` to `arm64`.
  - Added by [Christian Noon](https://github.com/cnoon).

#### Updated
- The `sessionManager` ACL in the `ImageDownloader` to allow access to the underlying
  session and configuration.
  - Updated by [Christian Noon](https://github.com/cnoon).
- The Alamofire submodule to the Alamofire 3.1.3 release.
  - Updated by [Christian Noon](https://github.com/cnoon).

## [2.1.0](https://github.com/Alamofire/AlamofireImage/releases/tag/2.1.0)
Released on 2015-10-24. All issues associated with this milestone can be found using this
[filter](https://github.com/Alamofire/AlamofireImage/issues?utf8=✓&q=milestone%3A2.1.0).

#### Added
- New tvOS framework and test targets to the project.
  - Added by [Christian Noon](https://github.com/cnoon).
- The tvOS deployment target to the podspec.
  - Added by [Christian Noon](https://github.com/cnoon).
- The `BITCODE_GENERATION_MODE` user defined setting to tvOS framework target.
  - Added by [Christian Noon](https://github.com/cnoon).

#### Updated
- The README to include tvOS and bumped the required version of Xcode.
  - Updated by [Christian Noon](https://github.com/cnoon).
- The default tvOS and watchOS deployment targets in the Xcode project.
  - Updated by [Christian Noon](https://github.com/cnoon).
- The Cartfile and Alamofire submodule to the 3.1.0 release.
  - Updated by [Christian Noon](https://github.com/cnoon).
- The Travis-CI yaml file to run watchOS and tvOS builds and tests on xcode7.1 osx_image.
  - Updated by [Christian Noon](https://github.com/cnoon).

#### Fixed
- Several typos in the `AutoPurgingImageCache` section of the README.
  - Fixed by [Nate Cook](https://github.com/natecook1000) in Pull Request
  [#39](https://github.com/Alamofire/AlamofireImage/pull/39).

---

## [2.0.0](https://github.com/Alamofire/AlamofireImage/releases/tag/2.0.0)
Released on 2015-10-17. All issues associated with this milestone can be found using this
[filter](https://github.com/Alamofire/AlamofireImage/issues?utf8=✓&q=milestone%3A2.0.0).

#### Updated
- The cocoapods and carthage instructions in the README.
  - Updated by [Christian Noon](https://github.com/cnoon).

---

## [2.0.0-beta.2](https://github.com/Alamofire/AlamofireImage/releases/tag/2.0.0-beta.2)
Released on 2015-10-14. All issues associated with this milestone can be found using this
[filter](https://github.com/Alamofire/AlamofireImage/issues?utf8=✓&q=milestone%3A2.0.0-beta.2).

#### Added
- Ability to use a custom `ImageDownloader` per `UIImageView` instance.
  - Added by [Christian Noon](https://github.com/cnoon) in Pull Request
  [#31](https://github.com/Alamofire/AlamofireImage/pull/31).
- New `ImageDownloader` initializer accepting a custom `Manager` instance using dependency injection.
  - Added by [Christian Noon](https://github.com/cnoon) in Pull Request
  [#32](https://github.com/Alamofire/AlamofireImage/pull/32).
- Ability to add additional acceptable image content types for `Request` validation.
  - Added by [Christian Noon](https://github.com/cnoon) in Pull Request
  [#33](https://github.com/Alamofire/AlamofireImage/pull/33) to address Issues
  [#28](https://github.com/Alamofire/AlamofireImage/issues/28) and
  [#29](https://github.com/Alamofire/AlamofireImage/issues/29).

#### Fixed
- Cancelled request completion closures are now called on the main queue.
  - Fixed by [Christian Noon](https://github.com/cnoon).

## [2.0.0-beta.1](https://github.com/Alamofire/AlamofireImage/releases/tag/2.0.0-beta.1)
Released on 2015-09-27. All issues associated with this milestone can be found using this
[filter](https://github.com/Alamofire/AlamofireImage/issues?utf8=✓&q=milestone%3A2.0.0-beta.1).

#### Added
- The AlamofireImage 2.0 Migration Guide and also added to the README.
  - Added by [Christian Noon](https://github.com/cnoon).
- A new `RequestReceipt` struct to the `ImageDownloader` to improve cancellation reasoning.
  - Added by [Kevin Harwood](https://github.com/kcharwood).
- Cancellation tests to the `ImageDownloader` to validate new cancellation behavior.
  - Added by [Christian Noon](https://github.com/cnoon).
- Section to the README documenting the `RequestReceipt` usage.
  - Added by [Christian Noon](https://github.com/cnoon).

#### Updated
- Cartfile to pick up latest changes from the `master` branch of Alamofire 3.0.
  - Updated by [Christian Noon](https://github.com/cnoon).
- All source logic to use the Alamofire 3.0 APIs.
  - Updated by [Christian Noon](https://github.com/cnoon).
- All tests to compile and run against the Alamofire 3.0 APIs.
  - Updated by [Christian Noon](https://github.com/cnoon).  
- All the sample code examples in the README to use all the new APIs.
  - Updated by [Christian Noon](https://github.com/cnoon).    

---

## [1.1.2](https://github.com/Alamofire/AlamofireImage/releases/tag/1.1.2)
Released on 2015-09-26. All issues associated with this milestone can be found using this 
[filter](https://github.com/Alamofire/AlamofireImage/issues?utf8=✓&q=milestone%3A1.1.2).

#### Added
- Tests verifying response image serializers support file URLs.
  - Added by [Alexander Edge](https://github.com/alexanderedge) in regards to Pull Request
  [#19](https://github.com/Alamofire/AlamofireImage/pull/19).
- Tests verifying cached image is set on `UIImageView` if completion closure is set.
  - Added by [Kevin Harwood](https://github.com/kcharwood) in Pull Request
  [#20](https://github.com/Alamofire/AlamofireImage/pull/20).

#### Updated
- The `Request` extension to validate file URLs making test mocking easier.
  - Updated by [Alexander Edge](https://github.com/alexanderedge) in Pull Request
  [#19](https://github.com/Alamofire/AlamofireImage/pull/19).

#### Fixed
- Issue where cached image was not set on a `UIImageView` if completion closure was set.
  - Fixed by [Kevin Harwood](https://github.com/kcharwood) in Pull Request
  [#20](https://github.com/Alamofire/AlamofireImage/pull/20).

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
