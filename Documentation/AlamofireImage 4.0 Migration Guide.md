# AlamofireImage 4.0 Migration Guide

AlamofireImage 4.0 is the latest major release of AlamofireImage, an image component library for Alamofire supporting iOS, tvOS, macOS and watchOS written in Swift. As a major release, following Semantic Versioning conventions, 4.0 introduces several API-breaking changes that one should be aware of.

This guide is provided in order to ease the transition of existing applications using AlamofireImage 3.x to the latest APIs.

## Requirements

- iOS 10.0+ / macOS 10.12+ / tvOS 10.0+ / watchOS 3.0+
- Xcode 10.2+
- Swift 5+

## Benefits of Upgrading

The benefits of upgrading can be summarized as follows:

- **Alamofire 5 Compatibility**
- **Swift API Extensions:** includes more Swifty API conventions for extensions on `UIImage`, `UIImageView`, and `UIButton`.
- **Better Control Over Image Scale and Inflation:** added new API for controlling image scale and inflation through the `ImageResponseSerializer` per image download.

---

## Breaking API Changes

AlamofireImage 4 has **NO BREAKING CHANGES** with the exception of a few small refactored types from Alamofire 5. The following sections break down the changes.

### Prefixed APIs

New `UIImage`, `UIImageView`, and `UIButton` extension APIs have been added to replace the `af_` convention with the more Swifty `af.` alternative. As such, here are a few simple examples.

**UIImage**

```swift
let size = CGSize(width: 100.0, height: 100.0)

// AlamofireImage 3
let scaledImage = image.af_imageScaled(to: size)

// AlamofireImage 4
let scaledImage = image.af.imageScaled(to: size)
```

**UIImageView**

```swift
let imageView = UIImageView(frame: frame)
let url = URL(string: "https://httpbin.org/image/png")!

// AlamofireImage 3
imageView.af_setImage(withURL: url)

// AlamofireImage 4
imageView.af.setImage(withURL: url)
```

**UIButton**

```swift
let button = UIButton(frame: frame)
let url = URL(string: "https://httpbin.org/image/png")!

// AlamofireImage 3
button.af_setImage(for: .normal, url: url)

// AlamofireImage 4
button.af.setImage(for: .normal, url: url)
```

### ImageDownloader

The `ImageDownloader`'s `sessionManager` property has been refactored to align with AF5. 

```swift
let button = UIButton(frame: frame)
let url = URL(string: "https://httpbin.org/image/png")!

// AlamofireImage 3
public class ImageDownloader {
    public let sessionManager: SessionManager
    ...
}

// AlamofireImage 4
public class ImageDownloader {
    public let session: Session
    ...
}
```

## Behavioral Changes

### Image Download Cancellation

Cancelling an image download used to allow the image download to continue in the background if it had already started.
Due to this being misleading to the user, and also have threading implications with some new AF5 functionality, cancelling an image download now cancels the image download even if it has already started.

### Custom Cache Keys

AFI 4 now fully supports custom cache keys when downloading images through the `ImageDownloader`, `UIImageView`, and `UIButton`. All you need to do to use it is to provide any custom identifier as the cache key when requesting the download. It will then use that custom cache key as the unique identifier for the cache storage. Just make sure to use the same cache key the next time you request the image, or you'll end up redownloading it.

### Custom Image Scale and Inflation Preferences Per Image Download

In AFI4, you can now set a custom `ImageResponseSerializer` for each image download whether you're using `ImageDownloader`, `UIImageView` or `UIButton`.
This can be really handy when you have a certain `UIImageView` that you need to disable image inflation for because the user could provide a massive image.
We still recommend using an alternative method to displaying giant images to avoid your app getting terminated due to being out-of-memory.
