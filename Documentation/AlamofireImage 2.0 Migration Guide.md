# AlamofireImage 2.0 Migration Guide

AlamofireImage 2.0 is the latest major release of AlamofireImage, an image component library for Alamofire supporting iOS, Mac OS X and watchOS written in Swift. As a major release, following Semantic Versioning conventions, 2.0 introduces several API-breaking changes that one should be aware of.

This guide is provided in order to ease the transition of existing applications using Alamofire 2.x to the latest APIs, as well as explain the design and structure of new and changed functionality.

## Requirements

AlamofireImage 2.0 officially supports iOS 8+, Mac OS X 10.9+, watchOS 2.0, Xcode 7 and Swift 2.0.

## Reasons for Bumping to 2.0

The [Alamofire Software Foundation](https://github.com/Alamofire/Foundation) (ASF) tries to do everything possible to avoid MAJOR version bumps. We realize the challenges involved with migrating large projects from one MAJOR version to another. The reason for bumping to 2.0 is due to the Alamofire 3.0 changes. We want to keep both libraries in sync, which requires changes to the foundational classes of AlamofireImage. The changes made to Alamofire give us more flexibility moving forward to help avoid the need for MAJOR version bumps to maintain backwards compatibility.

## Benefits of Upgrading

The benefits of upgrading can be summarized as follows:

* Can be used in conjunction with Alamofire 3.0
* Leverages generic `Response` types for all `Request` completion closures.
* Image download request cancellation logic is now much more intelligent thanks to the new `RequestReceipt` struct allowing MUCH better optimization for table and collection view use cases.

---

## Breaking API Changes

AlamofireImage 2.0 contains some breaking API changes to the foundational classes supporting the response serialization system. It is important to understand how these changes affect the common usage patterns.

### Request Extension

The `Request` extension has been modified to support the Alamofire 3.0 `ResponseSerializer` changes. All `responseImage` methods now use a `completionHandler` of type `Response<Image, NSError> -> Void` matching all response serializers located in the Alamofire core library.

```swift
public func responseImage(
    imageScale: CGFloat = Request.imageScale,
    inflateResponseImage: Bool = true,
    completionHandler: Response<Image, NSError> -> Void)
    -> Self
{
    return response(
        responseSerializer: Request.imageResponseSerializer(
            imageScale: imageScale,
            inflateResponseImage: inflateResponseImage
        ),
        completionHandler: completionHandler
    )
}
```

> There are no actual changes in functionality in terms of the `responseImage` serializers.

### Image Downloader 

#### Completion Handler

The `CompletionHandler` typealias in the `ImageDownloader` has been modified to a `Response<Image, NSError>` type to match the Alamofire 3.0 APIs.

```swift
public class ImageDownloader {
	public typealias CompletionHandler = Response<Image, NSError> -> Void
}
```

#### Request Receipts

The `downloadImage` APIs now return a `RequestReceipt?` instead of a `Request?`. The main reason for this change was to allow the `ImageDownloader` to be more intelligent about cancelling active requests. Here are some of the questions we asked ourselves when designing this new system:

Should a download request be cancelled...

* If it is pending in the queue?
    * `YES`
* If it is actively being downloaded?
    * `NO` - The completion handler should be called with a cancellation error while the request is allowed to complete.
* If there are multiple response handlers attached to the same request?
    * `NO` - The completion handler should be called with a cancellation error while the request is allowed to complete since the other callers also depend on the same request.

In order to be able to support the third case, the `ImageDownloader` needed a way to identify multiple response handlers attached to a single `Request`. The `RequestReceipt` solves this problem by associating a `receiptID` with each download request. Each call to `downloadImage` generates a new, unique `receiptID` which can in turn be used to cancel a request.

```swift
public class RequestReceipt {
    public let request: Request
    public let receiptID: String
}
```

The `cancelRequestForRequestReceipt` method on the `ImageDownloader` handles all three cancellation cases internally. By always cancelling requests using the `RequestReceipt` APIs, your download requests will much better optimized for table and collection view use cases.


### UIImageView Extension

The only changes to the `UIImageView` extension in terms of backwards compatibility is the `completion` closure signature that now leverages the new Alamofire 3.0 `Response` type. 

```swift
public func af_setImageWithURLRequest(
    URLRequest: URLRequestConvertible,
    placeholderImage: UIImage?,
    filter: ImageFilter?,
    imageTransition: ImageTransition,
    completion: (Response<UIImage, NSError> -> Void)?)
{
    ...
}
```

Another change worth noting is the `UIImageView` extension now leverages `RequestReceipt` objects for cancelling the active request. This greatly improves overall performance and behavior for image views used in table and collection views.
