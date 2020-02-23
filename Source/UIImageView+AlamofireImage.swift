//
//  UIImageView+AlamofireImage.swift
//
//  Copyright (c) 2015 Alamofire Software Foundation (http://alamofire.org/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Alamofire
import Foundation

#if os(iOS) || os(tvOS)

import UIKit

public typealias AnimationOptions = UIView.AnimationOptions

extension UIImageView {
    /// Used to wrap all `UIView` animation transition options alongside a duration.
    public enum ImageTransition {
        case noTransition
        case crossDissolve(TimeInterval)
        case curlDown(TimeInterval)
        case curlUp(TimeInterval)
        case flipFromBottom(TimeInterval)
        case flipFromLeft(TimeInterval)
        case flipFromRight(TimeInterval)
        case flipFromTop(TimeInterval)
        case custom(duration: TimeInterval,
                    animationOptions: AnimationOptions,
                    animations: (UIImageView, Image) -> Void,
                    completion: ((Bool) -> Void)?)

        /// The duration of the image transition in seconds.
        public var duration: TimeInterval {
            switch self {
            case .noTransition:
                return 0.0
            case let .crossDissolve(duration):
                return duration
            case let .curlDown(duration):
                return duration
            case let .curlUp(duration):
                return duration
            case let .flipFromBottom(duration):
                return duration
            case let .flipFromLeft(duration):
                return duration
            case let .flipFromRight(duration):
                return duration
            case let .flipFromTop(duration):
                return duration
            case let .custom(duration, _, _, _):
                return duration
            }
        }

        /// The animation options of the image transition.
        public var animationOptions: AnimationOptions {
            switch self {
            case .noTransition:
                return []
            case .crossDissolve:
                return .transitionCrossDissolve
            case .curlDown:
                return .transitionCurlDown
            case .curlUp:
                return .transitionCurlUp
            case .flipFromBottom:
                return .transitionFlipFromBottom
            case .flipFromLeft:
                return .transitionFlipFromLeft
            case .flipFromRight:
                return .transitionFlipFromRight
            case .flipFromTop:
                return .transitionFlipFromTop
            case let .custom(_, animationOptions, _, _):
                return animationOptions
            }
        }

        /// The animation options of the image transition.
        public var animations: (UIImageView, Image) -> Void {
            switch self {
            case let .custom(_, _, animations, _):
                return animations
            default:
                return { $0.image = $1 }
            }
        }

        /// The completion closure associated with the image transition.
        public var completion: ((Bool) -> Void)? {
            switch self {
            case let .custom(_, _, _, completion):
                return completion
            default:
                return nil
            }
        }
    }
}

// MARK: -

extension UIImageView: AlamofireExtended {}
extension AlamofireExtension where ExtendedType: UIImageView {
    // MARK: - Properties

    /// The instance image downloader used to download all images. If this property is `nil`, the `UIImageView` will
    /// fallback on the `sharedImageDownloader` for all downloads. The most common use case for needing to use a custom
    /// instance image downloader is when images are behind different basic auth credentials.
    public var imageDownloader: ImageDownloader? {
        get {
            return objc_getAssociatedObject(type, &AssociatedKeys.imageDownloader) as? ImageDownloader
        }
        nonmutating set(downloader) {
            objc_setAssociatedObject(type, &AssociatedKeys.imageDownloader, downloader, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// The shared image downloader used to download all images. By default, this is the default `ImageDownloader`
    /// instance backed with an `AutoPurgingImageCache` which automatically evicts images from the cache when the memory
    /// capacity is reached or memory warning notifications occur. The shared image downloader is only used if the
    /// `imageDownloader` is `nil`.
    public static var sharedImageDownloader: ImageDownloader {
        get {
            if let downloader = objc_getAssociatedObject(UIImageView.self, &AssociatedKeys.sharedImageDownloader) as? ImageDownloader {
                return downloader
            } else {
                return ImageDownloader.default
            }
        }
        set {
            objc_setAssociatedObject(UIImageView.self, &AssociatedKeys.sharedImageDownloader, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    var activeRequestReceipt: RequestReceipt? {
        get {
            return objc_getAssociatedObject(type, &AssociatedKeys.activeRequestReceipt) as? RequestReceipt
        }
        nonmutating set {
            objc_setAssociatedObject(type, &AssociatedKeys.activeRequestReceipt, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // MARK: - Image Download

    /// Asynchronously downloads an image from the specified URL, applies the specified image filter to the downloaded
    /// image and sets it once finished while executing the image transition.
    ///
    /// If the image is cached locally, the image is set immediately. Otherwise the specified placeholder image will be
    /// set immediately, and then the remote image will be set once the image request is finished.
    ///
    /// The `completion` closure is called after the image download and filtering are complete, but before the start of
    /// the image transition. Please note it is no longer the responsibility of the `completion` closure to set the
    /// image. It will be set automatically. If you require a second notification after the image transition completes,
    /// use a `.Custom` image transition with a `completion` closure. The `.Custom` `completion` closure is called when
    /// the image transition is finished.
    ///
    /// - parameter url:                        The URL used for the image request.
    /// - parameter cacheKey:                   An optional key used to identify the image in the cache. Defaults
    ///                                         to `nil`.
    /// - parameter placeholderImage:           The image to be set initially until the image request finished. If
    ///                                         `nil`, the image view will not change its image until the image
    ///                                         request finishes. Defaults to `nil`.
    /// - parameter serializer:                 Image response serializer used to convert the image data to `UIImage`.
    ///                                         Defaults to `nil` which will fall back to the
    ///                                         instance `imageResponseSerializer` set on the `ImageDownloader`.
    /// - parameter filter:                     The image filter applied to the image after the image request is
    ///                                         finished. Defaults to `nil`.
    /// - parameter progress:                   The closure to be executed periodically during the lifecycle of the
    ///                                         request. Defaults to `nil`.
    /// - parameter progressQueue:              The dispatch queue to call the progress closure on. Defaults to the
    ///                                         main queue.
    /// - parameter imageTransition:            The image transition animation applied to the image when set.
    ///                                         Defaults to `.None`.
    /// - parameter runImageTransitionIfCached: Whether to run the image transition if the image is cached. Defaults
    ///                                         to `false`.
    /// - parameter completion:                 A closure to be executed when the image request finishes. The closure
    ///                                         has no return value and takes three arguments: the original request,
    ///                                         the response from the server and the result containing either the
    ///                                         image or the error that occurred. If the image was returned from the
    ///                                         image cache, the response will be `nil`. Defaults to `nil`.
    public func setImage(withURL url: URL,
                         cacheKey: String? = nil,
                         placeholderImage: UIImage? = nil,
                         serializer: ImageResponseSerializer? = nil,
                         filter: ImageFilter? = nil,
                         progress: ImageDownloader.ProgressHandler? = nil,
                         progressQueue: DispatchQueue = DispatchQueue.main,
                         imageTransition: UIImageView.ImageTransition = .noTransition,
                         runImageTransitionIfCached: Bool = false,
                         completion: ((AFIDataResponse<UIImage>) -> Void)? = nil) {
        setImage(withURLRequest: urlRequest(with: url),
                 cacheKey: cacheKey,
                 placeholderImage: placeholderImage,
                 serializer: serializer,
                 filter: filter,
                 progress: progress,
                 progressQueue: progressQueue,
                 imageTransition: imageTransition,
                 runImageTransitionIfCached: runImageTransitionIfCached,
                 completion: completion)
    }

    /// Asynchronously downloads an image from the specified URL Request, applies the specified image filter to the downloaded
    /// image and sets it once finished while executing the image transition.
    ///
    /// If the image is cached locally, the image is set immediately. Otherwise the specified placeholder image will be
    /// set immediately, and then the remote image will be set once the image request is finished.
    ///
    /// The `completion` closure is called after the image download and filtering are complete, but before the start of
    /// the image transition. Please note it is no longer the responsibility of the `completion` closure to set the
    /// image. It will be set automatically. If you require a second notification after the image transition completes,
    /// use a `.Custom` image transition with a `completion` closure. The `.Custom` `completion` closure is called when
    /// the image transition is finished.
    ///
    /// - parameter urlRequest:                 The URL request.
    /// - parameter cacheKey:                   An optional key used to identify the image in the cache. Defaults
    ///                                         to `nil`.
    /// - parameter placeholderImage:           The image to be set initially until the image request finished. If
    ///                                         `nil`, the image view will not change its image until the image
    ///                                         request finishes. Defaults to `nil`.
    /// - parameter serializer:                 Image response serializer used to convert the image data to `UIImage`.
    ///                                         Defaults to `nil` which will fall back to the
    ///                                         instance `imageResponseSerializer` set on the `ImageDownloader`.
    /// - parameter filter:                     The image filter applied to the image after the image request is
    ///                                         finished. Defaults to `nil`.
    /// - parameter progress:                   The closure to be executed periodically during the lifecycle of the
    ///                                         request. Defaults to `nil`.
    /// - parameter progressQueue:              The dispatch queue to call the progress closure on. Defaults to the
    ///                                         main queue.
    /// - parameter imageTransition:            The image transition animation applied to the image when set.
    ///                                         Defaults to `.None`.
    /// - parameter runImageTransitionIfCached: Whether to run the image transition if the image is cached. Defaults
    ///                                         to `false`.
    /// - parameter completion:                 A closure to be executed when the image request finishes. The closure
    ///                                         has no return value and takes three arguments: the original request,
    ///                                         the response from the server and the result containing either the
    ///                                         image or the error that occurred. If the image was returned from the
    ///                                         image cache, the response will be `nil`. Defaults to `nil`.
    public func setImage(withURLRequest urlRequest: URLRequestConvertible,
                         cacheKey: String? = nil,
                         placeholderImage: UIImage? = nil,
                         serializer: ImageResponseSerializer? = nil,
                         filter: ImageFilter? = nil,
                         progress: ImageDownloader.ProgressHandler? = nil,
                         progressQueue: DispatchQueue = DispatchQueue.main,
                         imageTransition: UIImageView.ImageTransition = .noTransition,
                         runImageTransitionIfCached: Bool = false,
                         completion: ((AFIDataResponse<UIImage>) -> Void)? = nil) {
        guard !isURLRequestURLEqualToActiveRequestURL(urlRequest) else {
            let response = AFIDataResponse<UIImage>(request: nil,
                                                    response: nil,
                                                    data: nil,
                                                    metrics: nil,
                                                    serializationDuration: 0.0,
                                                    result: .failure(AFIError.requestCancelled))

            completion?(response)

            return
        }

        cancelImageRequest()

        let imageDownloader = self.imageDownloader ?? UIImageView.af.sharedImageDownloader
        let imageCache = imageDownloader.imageCache

        // Use the image from the image cache if it exists
        if let request = urlRequest.urlRequest {
            let cachedImage: Image?

            if let cacheKey = cacheKey {
                cachedImage = imageCache?.image(withIdentifier: cacheKey)
            } else {
                cachedImage = imageCache?.image(for: request, withIdentifier: filter?.identifier)
            }

            if let image = cachedImage {
                let response = AFIDataResponse<UIImage>(request: request,
                                                        response: nil,
                                                        data: nil,
                                                        metrics: nil,
                                                        serializationDuration: 0.0,
                                                        result: .success(image))

                if runImageTransitionIfCached {
                    // It's important to display the placeholder image again otherwise you have some odd disparity
                    // between the request loading from the cache and those that download. It's important to keep
                    // the same behavior between both, otherwise the user can actually see the difference.
                    if let placeholderImage = placeholderImage { type.image = placeholderImage }

                    // Need to let the runloop cycle for the placeholder image to take affect
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1)) {
                        // Added this additional check to ensure another request didn't get in during the delay
                        guard self.activeRequestReceipt == nil else { return }

                        self.run(imageTransition, with: image)
                        completion?(response)
                    }
                } else {
                    type.image = image
                    completion?(response)
                }

                return
            }
        }

        // Set the placeholder since we're going to have to download
        if let placeholderImage = placeholderImage { type.image = placeholderImage }

        // Generate a unique download id to check whether the active request has changed while downloading
        let downloadID = UUID().uuidString

        // Weakify the image view to allow it to go out-of-memory while download is running if deallocated
        weak var imageView = type

        // Download the image, then run the image transition or completion handler
        let requestReceipt = imageDownloader.download(urlRequest,
                                                      cacheKey: cacheKey,
                                                      receiptID: downloadID,
                                                      serializer: serializer,
                                                      filter: filter,
                                                      progress: progress,
                                                      progressQueue: progressQueue,
                                                      completion: { response in
                                                          guard
                                                              let strongSelf = imageView?.af,
                                                              strongSelf.isURLRequestURLEqualToActiveRequestURL(response.request) &&
                                                              strongSelf.activeRequestReceipt?.receiptID == downloadID
                                                          else {
                                                              completion?(response)
                                                              return
                                                          }

                                                          if case let .success(image) = response.result {
                                                              strongSelf.run(imageTransition, with: image)
                                                          }

                                                          strongSelf.activeRequestReceipt = nil

                                                          completion?(response)
            })

        activeRequestReceipt = requestReceipt
    }

    // MARK: - Image Download Cancellation

    /// Cancels the active download request, if one exists.
    public func cancelImageRequest() {
        guard let activeRequestReceipt = activeRequestReceipt else { return }

        let imageDownloader = self.imageDownloader ?? UIImageView.af.sharedImageDownloader
        imageDownloader.cancelRequest(with: activeRequestReceipt)

        self.activeRequestReceipt = nil
    }

    // MARK: - Image Transition

    /// Runs the image transition on the image view with the specified image.
    ///
    /// - parameter imageTransition: The image transition to ran on the image view.
    /// - parameter image:           The image to use for the image transition.
    public func run(_ imageTransition: UIImageView.ImageTransition, with image: Image) {
        let imageView = type

        UIView.transition(with: type,
                          duration: imageTransition.duration,
                          options: imageTransition.animationOptions,
                          animations: { imageTransition.animations(imageView, image) },
                          completion: imageTransition.completion)
    }

    // MARK: - Private - URL Request Helper Methods

    private func urlRequest(with url: URL) -> URLRequest {
        var urlRequest = URLRequest(url: url)

        for mimeType in ImageResponseSerializer.acceptableImageContentTypes {
            urlRequest.addValue(mimeType, forHTTPHeaderField: "Accept")
        }

        return urlRequest
    }

    private func isURLRequestURLEqualToActiveRequestURL(_ urlRequest: URLRequestConvertible?) -> Bool {
        if
            let currentRequestURL = activeRequestReceipt?.request.task?.originalRequest?.url,
            let requestURL = urlRequest?.urlRequest?.url,
            currentRequestURL == requestURL {
            return true
        }

        return false
    }
}

// MARK: - Deprecated

extension UIImageView {
    @available(*, deprecated, message: "Replaced by `imageView.af.imageDownloader`")
    public var af_imageDownloader: ImageDownloader? {
        get { return af.imageDownloader }
        set { af.imageDownloader = newValue }
    }

    @available(*, deprecated, message: "Replaced by `imageView.af.sharedImageDownloader`")
    public class var af_sharedImageDownloader: ImageDownloader {
        get { return af.sharedImageDownloader }
        set { af.sharedImageDownloader = newValue }
    }

    @available(*, deprecated, message: "Replaced by `imageView.af.setImage(withURL: ...)`")
    public func af_setImage(withURL url: URL,
                            cacheKey: String? = nil,
                            placeholderImage: UIImage? = nil,
                            serializer: ImageResponseSerializer? = nil,
                            filter: ImageFilter? = nil,
                            progress: ImageDownloader.ProgressHandler? = nil,
                            progressQueue: DispatchQueue = DispatchQueue.main,
                            imageTransition: ImageTransition = .noTransition,
                            runImageTransitionIfCached: Bool = false,
                            completion: ((AFIDataResponse<UIImage>) -> Void)? = nil) {
        af.setImage(withURL: url,
                    cacheKey: cacheKey,
                    placeholderImage: placeholderImage,
                    serializer: serializer,
                    filter: filter,
                    progress: progress,
                    progressQueue: progressQueue,
                    imageTransition: imageTransition,
                    runImageTransitionIfCached: runImageTransitionIfCached,
                    completion: completion)
    }

    @available(*, deprecated, message: "Replaced by `imageView.af.setImage(withURLRequest: ...)`")
    public func af_setImage(withURLRequest urlRequest: URLRequestConvertible,
                            cacheKey: String? = nil,
                            placeholderImage: UIImage? = nil,
                            serializer: ImageResponseSerializer? = nil,
                            filter: ImageFilter? = nil,
                            progress: ImageDownloader.ProgressHandler? = nil,
                            progressQueue: DispatchQueue = DispatchQueue.main,
                            imageTransition: ImageTransition = .noTransition,
                            runImageTransitionIfCached: Bool = false,
                            completion: ((AFIDataResponse<UIImage>) -> Void)? = nil) {
        af.setImage(withURLRequest: urlRequest,
                    cacheKey: cacheKey,
                    placeholderImage: placeholderImage,
                    serializer: serializer,
                    filter: filter,
                    progress: progress,
                    progressQueue: progressQueue,
                    imageTransition: imageTransition,
                    runImageTransitionIfCached: runImageTransitionIfCached,
                    completion: completion)
    }

    @available(*, deprecated, message: "Replaced by `imageView.af.cancelImageRequest()`")
    public func af_cancelImageRequest() {
        af.cancelImageRequest()
    }

    @available(*, deprecated, message: "Replaced by `imageView.af.run(_:with:)`")
    public func run(_ imageTransition: ImageTransition, with image: Image) {
        af.run(imageTransition, with: image)
    }
}

// MARK: -

private struct AssociatedKeys {
    static var imageDownloader = "UIImageView.af.imageDownloader"
    static var sharedImageDownloader = "UIImageView.af.sharedImageDownloader"
    static var activeRequestReceipt = "UIImageView.af.activeRequestReceipt"
}

#endif
