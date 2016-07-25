// UIImageView+AlamofireImage.swift
//
// Copyright (c) 2015-2016 Alamofire Software Foundation (http://alamofire.org/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Alamofire
import Foundation
import UIKit

extension UIImageView {

    // MARK: - ImageTransition

    /// Used to wrap all `UIView` animation transition options alongside a duration.
    public enum ImageTransition {
        case None
        case CrossDissolve(NSTimeInterval)
        case CurlDown(NSTimeInterval)
        case CurlUp(NSTimeInterval)
        case FlipFromBottom(NSTimeInterval)
        case FlipFromLeft(NSTimeInterval)
        case FlipFromRight(NSTimeInterval)
        case FlipFromTop(NSTimeInterval)
        case Custom(
            duration: NSTimeInterval,
            animationOptions: UIViewAnimationOptions,
            animations: (UIImageView, Image) -> Void,
            completion: (Bool -> Void)?
        )

        /// The duration of the image transition in seconds.
        public var duration: NSTimeInterval {
            switch self {
            case None:
                return 0.0
            case CrossDissolve(let duration):
                return duration
            case CurlDown(let duration):
                return duration
            case CurlUp(let duration):
                return duration
            case FlipFromBottom(let duration):
                return duration
            case FlipFromLeft(let duration):
                return duration
            case FlipFromRight(let duration):
                return duration
            case FlipFromTop(let duration):
                return duration
            case Custom(let duration, _, _, _):
                return duration
            }
        }

        /// The animation options of the image transition.
        public var animationOptions: UIViewAnimationOptions {
            switch self {
            case None:
                return .TransitionNone
            case CrossDissolve:
                return .TransitionCrossDissolve
            case CurlDown:
                return .TransitionCurlDown
            case CurlUp:
                return .TransitionCurlUp
            case FlipFromBottom:
                return .TransitionFlipFromBottom
            case FlipFromLeft:
                return .TransitionFlipFromLeft
            case FlipFromRight:
                return .TransitionFlipFromRight
            case FlipFromTop:
                return .TransitionFlipFromTop
            case Custom(_, let animationOptions, _, _):
                return animationOptions
            }
        }

        /// The animation options of the image transition.
        public var animations: ((UIImageView, Image) -> Void) {
            switch self {
            case Custom(_, _, let animations, _):
                return animations
            default:
                return { $0.image = $1 }
            }
        }

        /// The completion closure associated with the image transition.
        public var completion: (Bool -> Void)? {
            switch self {
            case Custom(_, _, _, let completion):
                return completion
            default:
                return nil
            }
        }
    }

    // MARK: - Private - AssociatedKeys

    private struct AssociatedKeys {
        static var ImageDownloaderKey = "af_UIImageView.ImageDownloader"
        static var SharedImageDownloaderKey = "af_UIImageView.SharedImageDownloader"
        static var ActiveRequestReceiptKey = "af_UIImageView.ActiveRequestReceipt"
    }

    // MARK: - Associated Properties

    /// The instance image downloader used to download all images. If this property is `nil`, the `UIImageView` will
    /// fallback on the `af_sharedImageDownloader` for all downloads. The most common use case for needing to use a
    /// custom instance image downloader is when images are behind different basic auth credentials.
    public var af_imageDownloader: ImageDownloader? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.ImageDownloaderKey) as? ImageDownloader
        }
        set(downloader) {
            objc_setAssociatedObject(self, &AssociatedKeys.ImageDownloaderKey, downloader, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// The shared image downloader used to download all images. By default, this is the default `ImageDownloader`
    /// instance backed with an `AutoPurgingImageCache` which automatically evicts images from the cache when the memory
    /// capacity is reached or memory warning notifications occur. The shared image downloader is only used if the
    /// `af_imageDownloader` is `nil`.
    public class var af_sharedImageDownloader: ImageDownloader {
        get {
            if let downloader = objc_getAssociatedObject(self, &AssociatedKeys.SharedImageDownloaderKey) as? ImageDownloader {
                return downloader
            } else {
                return ImageDownloader.defaultInstance
            }
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.SharedImageDownloaderKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    var af_activeRequestReceipt: RequestReceipt? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.ActiveRequestReceiptKey) as? RequestReceipt
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.ActiveRequestReceiptKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // MARK: - Image Download

    /**
        Asynchronously downloads an image from the specified URL, applies the specified image filter to the downloaded
        image and sets it once finished while executing the image transition.

        If the image is cached locally, the image is set immediately. Otherwise the specified placehoder image will be
        set immediately, and then the remote image will be set once the image request is finished.

        The `completion` closure is called after the image download and filtering are complete, but before the start of
        the image transition. Please note it is no longer the responsibility of the `completion` closure to set the
        image. It will be set automatically. If you require a second notification after the image transition completes,
        use a `.Custom` image transition with a `completion` closure. The `.Custom` `completion` closure is called when
        the image transition is finished.

        - parameter URL:                        The URL used for the image request.
        - parameter placeholderImage:           The image to be set initially until the image request finished. If
                                                `nil`, the image view will not change its image until the image
                                                request finishes. Defaults to `nil`.
        - parameter filter:                     The image filter applied to the image after the image request is
                                                finished. Defaults to `nil`.
        - parameter progress:                   The closure to be executed periodically during the lifecycle of the
                                                request. Defaults to `nil`.
        - parameter progressQueue:              The dispatch queue to call the progress closure on. Defaults to the
                                                main queue.
        - parameter imageTransition:            The image transition animation applied to the image when set.
                                                Defaults to `.None`.
        - parameter runImageTransitionIfCached: Whether to run the image transition if the image is cached. Defaults
                                                to `false`.
        - parameter completion:                 A closure to be executed when the image request finishes. The closure
                                                has no return value and takes three arguments: the original request,
                                                the response from the server and the result containing either the
                                                image or the error that occurred. If the image was returned from the
                                                image cache, the response will be `nil`. Defaults to `nil`.
    */
    public func af_setImageWithURL(
        URL: NSURL,
        placeholderImage: UIImage? = nil,
        filter: ImageFilter? = nil,
        progress: ImageDownloader.ProgressHandler? = nil,
        progressQueue: dispatch_queue_t = dispatch_get_main_queue(),
        imageTransition: ImageTransition = .None,
        runImageTransitionIfCached: Bool = false,
        completion: (Response<UIImage, NSError> -> Void)? = nil)
    {
        af_setImageWithURLRequest(
            URLRequestWithURL(URL),
            placeholderImage: placeholderImage,
            filter: filter,
            progress: progress,
            progressQueue: progressQueue,
            imageTransition: imageTransition,
            runImageTransitionIfCached: runImageTransitionIfCached,
            completion: completion
        )
    }

    /**
        Asynchronously downloads an image from the specified URL Request, applies the specified image filter to the downloaded
        image and sets it once finished while executing the image transition.

        If the image is cached locally, the image is set immediately. Otherwise the specified placehoder image will be
        set immediately, and then the remote image will be set once the image request is finished.

        The `completion` closure is called after the image download and filtering are complete, but before the start of
        the image transition. Please note it is no longer the responsibility of the `completion` closure to set the
        image. It will be set automatically. If you require a second notification after the image transition completes,
        use a `.Custom` image transition with a `completion` closure. The `.Custom` `completion` closure is called when
        the image transition is finished.

        - parameter URLRequest:                 The URL request.
        - parameter placeholderImage:           The image to be set initially until the image request finished. If
                                                `nil`, the image view will not change its image until the image
                                                request finishes. Defaults to `nil`.
        - parameter filter:                     The image filter applied to the image after the image request is
                                                finished. Defaults to `nil`.
        - parameter progress:                   The closure to be executed periodically during the lifecycle of the
                                                request. Defaults to `nil`.
        - parameter progressQueue:              The dispatch queue to call the progress closure on. Defaults to the
                                                main queue.
        - parameter imageTransition:            The image transition animation applied to the image when set.
                                                Defaults to `.None`.
        - parameter runImageTransitionIfCached: Whether to run the image transition if the image is cached. Defaults
                                                to `false`.
        - parameter completion:                 A closure to be executed when the image request finishes. The closure
                                                has no return value and takes three arguments: the original request,
                                                the response from the server and the result containing either the
                                                image or the error that occurred. If the image was returned from the
                                                image cache, the response will be `nil`. Defaults to `nil`.
    */
    public func af_setImageWithURLRequest(
        URLRequest: URLRequestConvertible,
        placeholderImage: UIImage? = nil,
        filter: ImageFilter? = nil,
        progress: ImageDownloader.ProgressHandler? = nil,
        progressQueue: dispatch_queue_t = dispatch_get_main_queue(),
        imageTransition: ImageTransition = .None,
        runImageTransitionIfCached: Bool = false,
        completion: (Response<UIImage, NSError> -> Void)? = nil)
    {
        guard !isURLRequestURLEqualToActiveRequestURL(URLRequest) else { return }

        af_cancelImageRequest()

        let imageDownloader = af_imageDownloader ?? UIImageView.af_sharedImageDownloader
        let imageCache = imageDownloader.imageCache

        // Use the image from the image cache if it exists
        if let image = imageCache?.imageForRequest(URLRequest.URLRequest, withAdditionalIdentifier: filter?.identifier) {
            let response = Response<UIImage, NSError>(
                request: URLRequest.URLRequest,
                response: nil,
                data: nil,
                result: .Success(image)
            )

            completion?(response)

            if runImageTransitionIfCached {
                let tinyDelay = dispatch_time(DISPATCH_TIME_NOW, Int64(0.001 * Float(NSEC_PER_SEC)))

                // Need to let the runloop cycle for the placeholder image to take affect
                dispatch_after(tinyDelay, dispatch_get_main_queue()) {
                    self.runImageTransition(imageTransition, withImage: image)
                }
            } else {
                self.image = image
            }

            return
        }

        // Set the placeholder since we're going to have to download
        if let placeholderImage = placeholderImage { self.image = placeholderImage }

        // Generate a unique download id to check whether the active request has changed while downloading
        let downloadID = NSUUID().UUIDString

        // Download the image, then run the image transition or completion handler
        let requestReceipt = imageDownloader.downloadImage(
            URLRequest: URLRequest,
            receiptID: downloadID,
            filter: filter,
            progress: progress,
            progressQueue: progressQueue,
            completion: { [weak self] response in
                guard let strongSelf = self else { return }

                completion?(response)

                guard
                    strongSelf.isURLRequestURLEqualToActiveRequestURL(response.request) &&
                    strongSelf.af_activeRequestReceipt?.receiptID == downloadID
                else {
                    return
                }

                if let image = response.result.value {
                    strongSelf.runImageTransition(imageTransition, withImage: image)
                }

                strongSelf.af_activeRequestReceipt = nil
            }
        )

        af_activeRequestReceipt = requestReceipt
    }

    // MARK: - Image Download Cancellation

    /**
        Cancels the active download request, if one exists.
    */
    public func af_cancelImageRequest() {
        guard let activeRequestReceipt = af_activeRequestReceipt else { return }

        let imageDownloader = af_imageDownloader ?? UIImageView.af_sharedImageDownloader
        imageDownloader.cancelRequestForRequestReceipt(activeRequestReceipt)

        af_activeRequestReceipt = nil
    }

    // MARK: - Image Transition

    /**
        Runs the image transition on the image view with the specified image.

        - parameter imageTransition: The image transition to ran on the image view.
        - parameter image:           The image to use for the image transition.
    */
    public func runImageTransition(imageTransition: ImageTransition, withImage image: Image) {
        UIView.transitionWithView(
            self,
            duration: imageTransition.duration,
            options: imageTransition.animationOptions,
            animations: {
                imageTransition.animations(self, image)
            },
            completion: imageTransition.completion
        )
    }

    // MARK: - Private - URL Request Helper Methods

    private func URLRequestWithURL(URL: NSURL) -> NSURLRequest {
        let mutableURLRequest = NSMutableURLRequest(URL: URL)

        for mimeType in Request.acceptableImageContentTypes {
            mutableURLRequest.addValue(mimeType, forHTTPHeaderField: "Accept")
        }

        return mutableURLRequest
    }

    private func isURLRequestURLEqualToActiveRequestURL(URLRequest: URLRequestConvertible?) -> Bool {
        if let
            currentRequest = af_activeRequestReceipt?.request.task.originalRequest
            where currentRequest.URLString == URLRequest?.URLRequest.URLString
        {
            return true
        }

        return false
    }
}
