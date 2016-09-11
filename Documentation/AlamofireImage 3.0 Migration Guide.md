# AlamofireImage 3.0 Migration Guide

AlamofireImage 2.0 is the latest major release of AlamofireImage, an image component library for Alamofire supporting iOS, tvOS, macOS and watchOS written in Swift. As a major release, following Semantic Versioning conventions, 3.0 introduces several API-breaking changes that one should be aware of.

This guide is provided in order to ease the transition of existing applications using AlamofireImage 2.x to the latest APIs, as well as explain the design and structure of new and changed functionality.

## Requirements

AlamofireImage 3.0 officially supports iOS 9+, tvOS 9+, macOS 10.11+, watchOS 2.0+, Xcode 8 and Swift 3.0.

## Benefits of Upgrading

The benefits of upgrading can be summarized as follows:

- **Alamofire 4 Compatability**
- **Complete Swift 3 Compatibility:** includes the full adoption of the new [API Design Guidelines](https://swift.org/documentation/api-design-guidelines/).
- **New Error System:** uses a new `AFIError` type to adhere to the new pattern proposed in [SE-0112](https://github.com/apple/swift-evolution/blob/master/proposals/0112-nserror-bridging.md).

---

## Breaking API Changes

AlamofireImage 3 has fully adopted the new Swift 3 changes and conventions, including the new [API Design Guidelines](https://swift.org/documentation/api-design-guidelines/). Because of this, almost every API in AlamofireImage has been modified in some way. We can't possibly document every single change, so we're going to attempt to identify the most common APIs and how they have changed to help you through those sometimes less than helpful compiler errors. If you're interested in the underlying Alamofire 4 changes, read the [migration guide](https://github.com/Alamofire/Alamofire/blob/master/Documentation/Alamofire%204.0%20Migration%20Guide.md).

### Making Requests

The underlying Alamofire `request` API has changed, here is an example:

```swift
// AlamofireImage 2
Alamofire.request(.GET, "https://httpbin.org/image/png")
		 .responseImage { response in
		 	if let image = response.result.value {
                 print("image downloaded: \(image)")
            }
		 }
		 
// AlamofireImage 3
Alamofire.request("https://httpbin.org/image/png") // .request now defaults to .get
		 .responseImage { response in
		 	if let image = response.result.value {
                 print("image downloaded: \(image)")
            }
		 }
```