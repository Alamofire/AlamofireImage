# AlamofireImage 3.0 Migration Guide

AlamofireImage 3.0 is the latest major release of AlamofireImage, an image component library for Alamofire supporting iOS, tvOS, macOS and watchOS written in Swift. As a major release, following Semantic Versioning conventions, 3.0 introduces several API-breaking changes that one should be aware of.

This guide is provided in order to ease the transition of existing applications using AlamofireImage 2.x to the latest APIs, as well as explain the design and structure of new and changed functionality.

## Requirements

- iOS 8.0+, macOS 10.10+, tvOS 9.0+, watchOS 2.0+
- Xcode 8.0+
- Swift 3.0+

For those of you that would like to use AlamofireImage with Swift 2.2 or 2.3, please use the latest tagged 2.x release.

## Benefits of Upgrading

The benefits of upgrading can be summarized as follows:

- **Alamofire 4 Compatibility**
- **Complete Swift 3 Compatibility:** includes the full adoption of the new [API Design Guidelines](https://swift.org/documentation/api-design-guidelines/).
- **New Error System:** uses a new `AFIError` type to adhere to the new pattern proposed in [SE-0112](https://github.com/apple/swift-evolution/blob/master/proposals/0112-nserror-bridging.md).

---

## Breaking API Changes

AlamofireImage 3 has fully adopted the new Swift 3 changes and conventions, including the new [API Design Guidelines](https://swift.org/documentation/api-design-guidelines/). Because of this, almost every API in AlamofireImage has been modified in some way. We can't possibly document every single change, so we're going to attempt to identify the most common APIs and how they have changed to help you through those sometimes less than helpful compiler errors. If you're interested in the underlying Alamofire 4 changes, check out the [migration guide](https://github.com/Alamofire/Alamofire/blob/master/Documentation/Alamofire%204.0%20Migration%20Guide.md).

### Requests

```swift
// AlamofireImage 2
Alamofire.request(.GET, "https://httpbin.org/image/png").responseImage { response in
	if let image = response.result.value {
		print("image downloaded: \(image)")
	}
}
		 
// AlamofireImage 3
Alamofire.request("https://httpbin.org/image/png").responseImage { response in
	if let image = response.result.value {
		print("image downloaded: \(image)")
	}
}
```

### UIImage and UIImageView Extensions

The `UIImage` and `UIImageView` extensions have undergone extensive renaming.

#### Loading an Image

```swift
// AlamofireImage 2
imageView.af_setImageWithURL(
	URL, 
	placeholderImage: placeholderImage,
	filter: filter
)

// AlamofireImage 3
imageView.af_setImage(
	withURL: url,
	placeholderImage: placeholderImage,
	filter: filter
)
```

#### Loading an Image with Placeholder, Filter and Transition

```swift 
// AlamofireImage 2
imageView.af_setImageWithURL(
	URL, 
	placeholderImage: placeholderImage,
	filter: filter,
	imageTransition: .CrossDissolve(0.2)
)

// AlamofireImage 3
imageView.af_setImage(
	withURL: url,
	placeholderImage: placeholderImage,
	filter: filter,
	imageTransition: .crossDissolve(0.2)
)
``` 

### Image Cache

#### Getting an Image

```swift
// AlamofireImage 2
let cachedAvatar = imageCache.imageWithIdentifier("avatar")

// AlamofireImage 3
let cachedAvatar = imageCache.image(withIdentifier: "avatar")
```

#### Adding an Image

```swift
// AlamofireImage 2
imageCache.addImage(avatarImage, withIdentifier: "avatar")

// AlamofireImage 3
imageCache.add(avatarImage, withIdentifier: "avatar")

// With an Additional Identifier

// AlamofireImage 2
imageCache.addImage(avatarImage, forRequest: urlRequest, withAdditionalIdentifier: "circle")

// AlamofireImage 3
imageCache.add(avatarImage, for: urlRequest, withIdentifier: "circle")
```

#### Removing an Image

```swift
// AlamofireImage 2
imageCache.removeImageWithIdentifier("avatar")

// AlamofireImage 3
imageCache.removeImage(withIdentifier: "avatar")

// With an Additional Identifier

// AlamofireImage 2
imageCache.removeImageForRequest(urlRequest, withAdditionalIdentifier: "circle")

// AlamofireImage 3
imageCache.removeImage(for: urlRequest, withIdentifier: "circle")
```
