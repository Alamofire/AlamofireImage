# AlamofireImage

[![Build Status](https://travis-ci.org/Alamofire/AlamofireImage.svg)](https://travis-ci.org/Alamofire/AlamofireImage)
[![Cocoapods Compatible](https://img.shields.io/cocoapods/v/AlamofireImage.svg)](https://img.shields.io/cocoapods/v/AlamofireImage.svg)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/cocoapods/p/AlamofireImage.svg?style=flat)](http://cocoadocs.org/docsets/AlamofireImage)
[![Twitter](https://img.shields.io/badge/twitter-@AlamofireSF-blue.svg?style=flat)](http://twitter.com/AlamofireSF)

AlamofireImage is an image component library for Alamofire.

## Features

- [x] Image Response Serializers
- [x] UIImage Extensions for Inflation / Scaling / Rounding / CoreImage
- [x] Single and Multi-Pass Image Filters
- [x] Auto-Purging In-Memory Image Cache
- [x] Prioritized Queue Order Image Downloading
- [x] Authentication with NSURLCredential
- [x] UIImageView Async Remote Downloads with Placeholders
- [x] UIImageView Filters and Transitions
- [x] Comprehensive Test Coverage
- [x] [Complete Documentation](http://cocoadocs.org/docsets/AlamofireImage)

## Requirements

- iOS 8.0+ / Mac OS X 10.9+ / watchOS 2
- Xcode 7.0+

## Dependencies

- [Alamofire 2.0+](https://github.com/Alamofire/Alamofire)

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

### Image Response Serializers

```swift
import AlamofireImage

Alamofire.request(.GET, "https://httpbin.org/image/png")
         .responseImage { request, response, result in
             print(request)
             print(response)
             debugPrint(result)
             
             if let image = result.value {
                 print("image downloaded: \(image)")
             }
         }
```

The AlamofireImage response image serializers support a wide range of image types including:

- `image/png`
- `image/jpeg`
- `image/tiff`
- `image/gif`
- `image/ico`
- `image/x-icon`
- `image/bmp`
- `image/x-bmp`
- `image/x-xbitmap`
- `image/x-win-bitmap`

> Support for other image types will continue to be added as the library matures. Pull requests welcome!

### UIImage Extensions

There are several `UIImage` extensions designed to make the common image manipulation operations as simple as possible.

#### Inflation

```swift
let URL = NSBundle.mainBundle().URLForResource("unicorn", withExtension: "png")!
let data = NSData(contentsOfURL: URL)!
let image = UIImage(data: data, scale: UIScreen.mainScreen().scale)!

image.af_inflate()
```

> Inflating compressed image formats (such as PNG or JPEG) in a background queue can significantly improve drawing performance on the main thread.

#### Scaling

```swift
let image = UIImage(named: "unicorn")!
let size = CGSize(width: 100.0, height: 100.0)

// Scale image to size disregarding aspect ratio
let scaledImage = image.af_imageScaledToSize(size)

// Scale image to fit within specified size while maintaining aspect ratio
let aspectScaledToFitImage = image.af_imageAspectScaledToFitSize(size)

// Scale image to fill specified size while maintaining aspect ratio
let aspectScaledToFillImage = image.af_imageAspectScaledToFillSize(size)
```

#### Rounded Corners

```swift
let image = UIImage(named: "unicorn")!
let radius: CGFloat = 20.0

let roundedImage = image.af_imageWithRoundedCornerRadius(radius)
let circularImage = image.af_imageRoundedIntoCircle()
```

#### Core Image Filters

```swift
let image = UIImage(named: "unicorn")!

let sepiaImage = image.af_imageWithAppliedCoreImageFilter("CISepiaTone")
let blurredImage = image.af_imageWithAppliedCoreImageFilter(
    "CIGaussianBlur", 
    filterParameters: ["inputRadius": 25]
)
```

### Image Filters

The `ImageFilter` protocol was designed to make it easy to apply a filter operation and cache the result after an image finished downloading. It defines two properties to facilitate this functionality.

```swift
public protocol ImageFilter {
    var filter: Image -> Image { get }
    var identifier: String { get }
}
```

The `filter` closure contains the operation used to create a modified version of the specified image. The `identifier` property is a string used to uniquely identify the filter operation. This is useful when adding filtered versions of an image to a cache. All identifier properties inside AlamofireImage are implemented using protocol extensions.

#### Single Pass

The single pass image filters only perform a single operation on the specified image.

```swift
let image = UIImage(named: "unicorn")!
let imageFilter = RoundedCornersFilter(radius: 10.0)

let roundedImage = imageFilter.filter(image)
```

The current list of single pass image filters includes:

- `ScaledToSizeFilter` - Scales an image to a specified size.
- `AspectScaledToFitSizeFilter` - Scales an image from the center while maintaining the aspect ratio to fit within a specified size.
- `AspectScaledToFillSizeFilter` - Scales an image from the center while maintaining the aspect ratio to fill a specified size. Any pixels that fall outside the specified size are clipped.
- `RoundedCornersFilter` - Rounds the corners of an image to the specified radius.
- `CircleFilter` - Rounds the corners of an image into a circle.
- `BlurFilter` - Blurs an image using a `CIGaussianBlur` filter with the specified blur radius.

> Each image filter is built ontop of the `UIImage` extensions.

#### Multi-Pass

The multi-pass image filters perform multiple operations on the specified image.

```swift
let image = UIImage(named: "avatar")!
let size = CGSize(width: 100.0, height: 100.0)
let imageFilter = AspectScaledToFillSizeCircleFilter(size: size)

let avatarImage = imageFilter.filter(image)
```

The current list of multi-pass image filters includes:

- `ScaledToSizeWithRoundedCornersFilter` - Scales an image to a specified size, then rounds the corners to the specified radius.
- `AspectScaledToFillSizeWithRoundedCornersFilter` - Scales an image from the center while maintaining the aspect ratio to fit within a specified size, then rounds the corners to the specified radius.
- `ScaledToSizeCircleFilter` - Scales an image to a specified size, then rounds the corners into a circle.
- `AspectScaledToFillSizeCircleFilter` - Scales an image from the center while maintaining the aspect ratio to fit within a specified size, then rounds the corners into a circle.

### Image Cache

Image caching can become complicated when it comes to network images. `NSURLCache` is quite powerful and does a great job reasoning through the various cache policies and `Cache-Control` headers. However, it is not equiped to handle caching multiple modified versions of those images. 

For example, let's say you need to download an album of images. Your app needs to display both the thumbnail version as well as the full size version at various times. Due to performance issues, you want to scale down the thumbnails to a reasonable size before rendering them on-screen. You also need to apply a global CoreImage filter to the full size images when displayed. While `NSURLCache` can easily handle storing the original downloaded image, it cannot store these different variants. What you really need is another caching layer designed to handle these different variants.

```swift
let imageCache = AutoPurgingImageCache(
    memoryCapacity: 100 * 1024 * 1024, 
    preferredMemoryUsageAfterPurge: 60 * 1024 * 1024
)
```

The `AutoPurgingImageCache` in AlamofireImage fills the roll of that additional caching layer. It is an in-memory image cache used to store images up to a given memory capacity. When the memory capacity is reached, the image cache is sorted by last access date, then the oldest image is continuously purged until the preferred memory usage after purge is met. Each time an image is accessed through the cache, the internal access date of the image is updated.

#### Add / Remove / Fetch Images

Interacting with the `ImageCache` protocol APIs is very straight-forward.

```swift
let imageCache = AutoPurgingImageCache()
let avatarImage = UIImage(data: data)!

// Add
imageCache.addImage(avatarImage, withIdentifier: "avatar")

// Fetch
let cachedAvatar = imageCache.imageWithIdentifier("avatar")

// Remove
imageCache.removeImageWithIdentifier("avatar")
```

#### URL Requests

The `ImageRequestCache` protocol extends the `ImageCache` protocol by adding support for `NSURLRequest` caching. This allows an `NSURLRequest` and additional identifier to generate the unique identifier for the image in the cache.

```swift
let imageCache = AutoPurgingImageCache()

let URLRequest = NSURLRequest(URL: NSURL(string: "https://httpbin.org/image/png")!)
let avatarImage = UIImage(named: "avatar")!.af_imageRoundedIntoCircle()

// Add
imageCache.addImage(
    avatarImage, 
    forRequest: URLRequest, 
    withAdditionalIdentifier: "circle"
)

// Fetch
let cachedAvatarImage = imageCache.imageForRequest(
    URLRequest, 
    withAdditionalIdentifier: "circle"
)

// Remove
imageCache.removeImageForRequest(
    URLRequest, 
    withAdditionalIdentifier: "circle"
)
```

#### Auto-Purging

Each time an image is fetched from the cache, the cache internally updates the last access date for that image.

```swift
let avatar = imageCache.imageWithIdentifier("avatar")
let circularAvatar = imageCache.imageForRequest(
    URLRequest, 
    withIdentifier: "circle"
)
```

By updating the last access date for each image, the image cache can make more informed decisions about which images to purge when the memory capacity is reached. The `AutoPurgingImageCache` automatically evicts images from the cache in order from oldest last access date to newest until the memory capacity drops below the `preferredMemoryCapacityAfterPurge`.

> It is important to set reasonable default values for the `memoryCapacity` and `preferredMemoryCapacityAfterPurge` when you are initializing your image cache. By default, the `memoryCapacity` equals 100 MB and the `preferredMemoryCapacityAfterPurge` equals 60 MB.

#### Memory Warnings

The `AutoPurgingImageCache` also listens for memory warnings from your application and will purge all images from the cache is a memory warning is observed.

### Image Downloader

The `ImageDownloader` class is responsible for downloading images in parallel on a prioritized queue. It uses an internal Alamofire `Manager` instance to handle all the downloading and response image serialization. By default, the initialization of an `ImageDownloader` uses a default `NSURLSessionConfiguration` with the most common parameter values.

```swift
let imageDownloader = ImageDownloader(
    configuration: ImageDownloader.defaultURLSessionConfiguration(),
    downloadPrioritization: .FIFO,
    maximumActiveDownloads: 4,
    imageCache: AutoPurgingImageCache()
)
```

> If you need to customize the `NSURLSessionConfiguration` type or parameters, then simply provide your own rather than using the default.

#### Downloading an Image

```swift
let downloader = ImageDownloader()
let URLRequest = NSURLRequest(URL: NSURL(string: "https://httpbin.org/image/jpeg")!)

downloader.downloadImage(URLRequest: URLRequest) { request, response, result in
    print(request)
    print(response)
    debugPrint(result)

    if let image = result.value {
        print(image)
    }
}
```

#### Applying an ImageFilter

```swift
let downloader = ImageDownloader()
let URLRequest = NSURLRequest(URL: NSURL(string: "https://httpbin.org/image/jpeg")!)
let filter = AspectScaledToFillSizeCircleFilter(size: CGSize(width: 100.0, height: 100.0))

downloader.downloadImage(URLRequest: URLRequest, filter: filter) { request, response, result in
    print(request)
    print(response)
    debugPrint(result)
    
    if let image = result.value {
        print(image)
    }
}
```

#### Authentication

If your images are behind HTTP Basic Auth, you can append the `user:password:` or the `credential` to the `ImageDownloader` instance. The credentials will be applied to all future download requests.

```swift
let downloader = ImageDownloader()
downloader.addAuthentication(user: "username", password: "password")
```

#### Download Prioritization

The `ImageDownloader` maintains an internal queue of pending download requests. Depending on your situation, you may want incoming downloads to be inserted at the front or the back of the queue. The `DownloadPrioritization` enumeration allows you to specify which behavior you would prefer.

```swift
public enum DownloadPrioritization {
    case FIFO, LIFO
}
```

> The `ImageDownloader` is initialized with a `.FIFO` queue by default.

#### Image Caching

The `ImageDownloader` uses a combination of an `NSURLCache` and `AutoPurgingImageCache` to create a very robust, high performance image caching system.

##### NSURLCache

The `NSURLCache` is used to cache all the original image content downloaded from the server. By default, it is initialized with a memory capacity of 20 MB and a disk capacity of 150 MB. This allows up to 150 MB of original image data to be stored on disk at any given time. While these defaults have been carefully set, it is very important to consider your application's needs and performance requirements and whether these values are right for you.

> If you wish to disable this caching layer, create a custom `NSURLSessionConfiguration` with the `URLCache` property set to `nil` and use that configuration when initializing the `ImageDownloader`.

##### Image Cache

The `ImageCache` is used to cache all the potentially filtered image content after it has been downloaded from the server. This allows multiple variants of the same image to also be cached, rather than having to re-apply the image filters to the original image each time it is required. By default, an `AutoPurgingImageCache` is initialized with a memory capacity of 100 MB and a preferred memory usage after purge limit of 60 MB. This allows up to 100 MB of most recently accessed filtered image content to be stored in-memory at a given time.

##### Setting Ideal Capacity Limits

Determining the ideal the in-memory and on-disk capacity limits of the `NSURLCache` and `AutoPurgingImageCache` requires a bit of forethought. You must carefully consider your application's needs, and tailor the limits accordingly. By default, the combination of caches offers the following storage capacities:

- 150 MB of on-disk storage
- 20 MB of in-memory original image data storage
- 100 MB of in-memory storage of filtered image content
- 60 MB preferred memory capacity after purge of filtered image content

> If you do not use image filters, it is advised to set the memory capacity of the `NSURLCache` to zero to avoid storing the same content in-memory twice.

#### Duplicate Downloads

Sometimes application logic can end up attempting to download an image more than once before the initial download request is complete. Most often, this results in the image being downloaded more than once. AlamofireImage handles this case elegantly by merging the duplicate downloads. The image will only be downloaded once, yet both completion handlers will be called.

##### Image Filter Reuse

In addition to merging duplicate downloads, AlamofireImage can also merge duplicate image filters. If two image filters with the same identifier are attached to the same download, the image filter is only executed once and both completion handlers are called with the same resulting image. This can save large amounts of time and resources for computationally expensive filters such as ones leveraging CoreImage.

### UIImageView Extension

The [UIImage Extensions](#uiimage-extensions), [Image Filters](#image-filters), [Image Cache](#image-cache) and [Image Downloader](#image-downloader) were all designed to be flexible and standalone, yet also to provide the foundation of the `UIImageView` extension. Due to the powerful support of these classes, protocols and extensions, the `UIImageView` APIs are concise, easy to use and contain a large amount of functionality.

#### Setting Image with URL

Setting the image with a URL will asynchronously download the image and set it once the request is finished.

```swift
let imageView = UIImageView(frame: frame)
let URL = NSURL(string: "https://httpbin.org/image/png")!

imageView.af_setImageWithURL(URL)
```

> If the image is cached locally, the image is set immediately.

#### Placeholder Images

By specifying a placeholder image, the image view uses the placeholder image until the remote image is downloaded.

```swift
let imageView = UIImageView(frame: frame)
let URL = NSURL(string: "https://httpbin.org/image/png")!
let placeholderImage = UIImage(named: "placeholder")!

imageView.af_setImageWithURL(URL, placeholderImage: placeholderImage)
```

> If the remote image is cached locally, the placeholder image is never set.

#### Image Filters

If an image filter is specified, it is applied asynchronously after the remote image is downloaded. Once the filter execution is complete, the resulting image is set on the image view.

```swift
let imageView = UIImageView(frame: frame)

let URL = NSURL(string: "https://httpbin.org/image/png")!
let placeholderImage = UIImage(named: "placeholder")!

let filter = AspectScaledToFillSizeWithRoundedCornersFilter(
    size: imageView.frame.size, 
    radius: 20.0
)

imageView.af_setImageWithURL(
    URL, 
    placeholderImage: placeholderImage,
    filter: filter
)
```

> If the remote image with the applied filter is cached locally, the image is set immediately.

#### Image Transitions

By default, there is no image transition animation when setting the image on the image view. If you wish to add a cross dissolve or flip-from-bottom animation, then specify an `ImageTransition` with the preferred duration.

```swift
let imageView = UIImageView(frame: frame)

let URL = NSURL(string: "https://httpbin.org/image/png")!
let placeholderImage = UIImage(named: "placeholder")!

let filter = AspectScaledToFillSizeWithRoundedCornersFilter(
    size: imageView.frame.size, 
    radius: 20.0
)

imageView.af_setImageWithURL(
    URL, 
    placeholderImage: placeholderImage,
    filter: filter,
    imageTransition: .CrossDissolve(0.2)
)
```

> If the remote image is cached locally, the image transition is ignored.

#### Image Downloader

The `UIImageView` extension is powered by the default `ImageDownloader` instance. To customize cache capacities, download priorities, request cache policies, timeout durations, etc., please refer to the [Image Downloader](#image-downloader) documentation.

##### Authentication

If an image requires and authentication credential from the `UIImageView` extension, it can be provided as follows:

```swift
ImageDownloader.defaultInstance.addAuthentication(
    user: "user", 
    password: "password"
)
```

---

## Credits

Alamofire is owned and maintained by the [Alamofire Software Foundation](http://alamofire.org). You can follow them on Twitter at [@AlamofireSF](https://twitter.com/AlamofireSF) for project updates and releases.

### Security Disclosure

If you believe you have identified a security vulnerability with AlamofireImage, you should report it as soon as possible via email to security@alamofire.org. Please do not post it to a public issue tracker.

## License

AlamofireImage is released under the MIT license. See LICENSE for details.
