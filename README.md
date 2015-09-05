[![Build Status](https://travis-ci.org/Alamofire/AlamofireImage.svg)](https://travis-ci.org/Alamofire/AlamofireImage)
[![Cocoapods Compatible](https://img.shields.io/cocoapods/v/AlamofireImage.svg)](https://img.shields.io/cocoapods/v/AlamofireImage.svg)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/cocoapods/p/AlamofireImage.svg?style=flat)](http://cocoadocs.org/docsets/AlamofireImage)
[![Twitter](https://img.shields.io/badge/twitter-@AlamofireSF-blue.svg?style=flat)](http://twitter.com/AlamofireSF)

AlamofireImage is an Alamofire extension library for images written in Swift.

## Features

- [x] Image Response Serializers
- [x] UIImage Inflation / Scaling / Rounding / CoreImage Extensions
- [x] UIImageView Async Remote Downloads with Placeholders
- [x] UIImageView Filters and Transitions
- [x] In-Memory Auto-Purging Image Cache
- [x] Single and Multi-Pass Image Filters
- [x] Prioritized Queue Order Image Downloading
- [x] Authentication with NSURLCredential
- [x] Comprehensive Test Coverage
- [x] [Complete Documentation](http://cocoadocs.org/docsets/AlamofireImage)

## Requirements

- iOS 8.0+ / Mac OS X 10.9+ / watchOS 2
- Xcode 7.0 beta 6+

## Communication

- If you **need help**, use [Stack Overflow](http://stackoverflow.com/questions/tagged/alamofire). (Tag 'alamofire')
- If you'd like to **ask a general question**, use [Stack Overflow](http://stackoverflow.com/questions/tagged/alamofire).
- If you **found a bug**, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request.

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects.

CocoaPods 0.38.2 is required to build AlamofireImage. It adds support for Xcode 7, Swift 2.0 and embedded frameworks. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate AlamofireImage into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

pod 'AlamofireImage', '~> 1.0'
```

Then, run the following command:

```bash
$ pod install
```

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that automates the process of adding frameworks to your Cocoa application.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate AlamofireImage into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "Alamofire/AlamofireImage" ~> 1.0
```

---

## Usage

TODO

---

## Advanced Usage

TODO

---

## Credits

Alamofire is owned and maintained by the [Alamofire Software Foundation](http://alamofire.org). You can follow them on Twitter at [@AlamofireSF](https://twitter.com/AlamofireSF) for project updates and releases.

### Security Disclosure

If you believe you have identified a security vulnerability with AlamofireImage, you should report it as soon as possible via email to security@alamofire.org. Please do not post it to a public issue tracker.

## License

AlamofireImage is released under the MIT license. See LICENSE for details.
