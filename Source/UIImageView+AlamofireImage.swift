// UIImageView+AlamofireImage.swift
//
// Copyright (c) 2015 Alamofire Software Foundation (http://alamofire.org/)
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

        private var duration: NSTimeInterval {
            switch self {
            case None:                          return 0.0
            case CrossDissolve(let duration):   return duration
            case CurlDown(let duration):        return duration
            case CurlUp(let duration):          return duration
            case FlipFromBottom(let duration):  return duration
            case FlipFromLeft(let duration):    return duration
            case FlipFromRight(let duration):   return duration
            case FlipFromTop(let duration):     return duration
            case Custom(let duration, _, _, _): return duration
            }
        }

        private var animationOptions: UIViewAnimationOptions {
            switch self {
            case None:                                  return .TransitionNone
            case CrossDissolve:                         return .TransitionCrossDissolve
            case CurlDown:                              return .TransitionCurlDown
            case CurlUp:                                return .TransitionCurlUp
            case FlipFromBottom:                        return .TransitionFlipFromBottom
            case FlipFromLeft:                          return .TransitionFlipFromLeft
            case FlipFromRight:                         return .TransitionFlipFromRight
            case FlipFromTop:                           return .TransitionFlipFromTop
            case Custom(_, let animationOptions, _, _): return animationOptions
            }
        }

        private var animations: ((UIImageView, Image) -> Void) {
            switch self {
            case Custom(_, _, let animations, _):
                return animations
            default:
                return { $0.image = $1 }
            }
        }

        private var completion: (Bool -> Void)? {
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
        static var SharedImageDownloaderKey = "af_UIImageView.SharedImageDownloader"
        static var ActiveRequestKey = "af_UIImageView.ActiveRequest"
    }

    // MARK: - Properties

    /// The image downloader used to download all images. By default, this is the default `ImageDownloader` instance 
    /// backed with an `AutoPurgingImageCache` which automatically evicts images from the cache when the memory capacity 
    /// is reached or memory warning notifications occur.
    public class var af_sharedImageDownloader: ImageDownloader {
        get {
            if let downloader = objc_getAssociatedObject(self, &AssociatedKeys.SharedImageDownloaderKey) as? ImageDownloader {
                return downloader
            } else {
                return ImageDownloader.defaultInstance
            }
        }
        set(downloader) {
            objc_setAssociatedObject(self, &AssociatedKeys.SharedImageDownloaderKey, downloader, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    var af_activeRequest: Request? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.ActiveRequestKey) as? Request
        }
        set(request) {
            objc_setAssociatedObject(self, &AssociatedKeys.ActiveRequestKey, request, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // MARK: - Image Download Methods

    /**
        Asynchronously downloads an image from the specified URL and sets it once the request is finished.

        If the image is cached locally, the image is set immediately. Otherwise the specified placehoder image will be 
        set immediately, and then the remote image will be set once the image request is finished.

        - parameter URL:              The URL used for the image request.
        - parameter placeholderImage: The image to be set initially until the image request finished. If `nil`, the 
                                      image view will not change its image until the image request finishes. `nil` by 
                                      default.
    */
    public func af_setImageWithURL(URL: NSURL, placeholderImage: UIImage? = nil) {
        af_setImageWithURLRequest(
            URLRequestWithURL(URL),
            placeholderImage: placeholderImage,
            filter: nil,
            imageTransition: .None,
            completion: nil
        )
    }

    /**
        Asynchronously downloads an image from the specified URL, applies the specified image filter to the downloaded 
        image and sets it once finished.

        If the image is cached locally, the image is set immediately. Otherwise the specified placehoder image will be
        set immediately, and then the remote image will be set once the image request is finished.

        - parameter URL:              The URL used for the image request.
        - parameter placeholderImage: The image to be set initially until the image request finished. If `nil`, the
                                      image view will not change its image until the image request finishes. `nil` by 
                                      default.
        - parameter filter:           The image filter applied to the image after the image request is finished.
    */
    public func af_setImageWithURL(URL: NSURL, placeholderImage: UIImage? = nil, filter: ImageFilter) {
        af_setImageWithURLRequest(
            URLRequestWithURL(URL),
            placeholderImage: placeholderImage,
            filter: filter,
            imageTransition: .None,
            completion: nil
        )
    }

    /**
        Asynchronously downloads an image from the specified URL and sets it once the request is finished while 
        executing the image transition.

        If the image is cached locally, the image is set immediately. Otherwise the specified placehoder image will be
        set immediately, and then the remote image will be set once the image request is finished.

        - parameter URL:              The URL used for the image request.
        - parameter placeholderImage: The image to be set initially until the image request finished. If `nil`, the
                                      image view will not change its image until the image request finishes. `nil` by
                                      default.
        - parameter imageTransition:  The image transition animation applied to the image when set.
    */
    public func af_setImageWithURL(URL: NSURL, placeholderImage: UIImage? = nil, imageTransition: ImageTransition) {
        af_setImageWithURLRequest(
            URLRequestWithURL(URL),
            placeholderImage: placeholderImage,
            filter: nil,
            imageTransition: imageTransition,
            completion: nil
        )
    }

    /**
        Asynchronously downloads an image from the specified URL, applies the specified image filter to the downloaded
        image and sets it once finished while executing the image transition.

        If the image is cached locally, the image is set immediately. Otherwise the specified placehoder image will be
        set immediately, and then the remote image will be set once the image request is finished.

        - parameter URL:              The URL used for the image request.
        - parameter placeholderImage: The image to be set initially until the image request finished. If `nil`, the
                                      image view will not change its image until the image request finishes.
        - parameter filter:           The image filter applied to the image after the image request is finished.
        - parameter imageTransition:  The image transition animation applied to the image when set.
    */
    public func af_setImageWithURL(
        URL: NSURL,
        placeholderImage: UIImage?,
        filter: ImageFilter?,
        imageTransition: ImageTransition)
    {
        af_setImageWithURLRequest(
            URLRequestWithURL(URL),
            placeholderImage: placeholderImage,
            filter: filter,
            imageTransition: imageTransition,
            completion: nil
        )
    }

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

        - parameter URL:              The URL used for the image request.
        - parameter placeholderImage: The image to be set initially until the image request finished. If `nil`, the
                                      image view will not change its image until the image request finishes.
        - parameter filter:           The image filter applied to the image after the image request is finished.
        - parameter imageTransition:  The image transition animation applied to the image when set.
        - parameter completion:       A closure to be executed when the image request finishes. The closure has no
                                      return value and takes three arguments: the original request, the response from
                                      the server and the result containing either the image or the error that occurred.
                                      If the image was returned from the image cache, the response will be `nil`.
    */
    public func af_setImageWithURL(
        URL: NSURL,
        placeholderImage: UIImage?,
        filter: ImageFilter?,
        imageTransition: ImageTransition,
        completion: ((NSURLRequest?, NSHTTPURLResponse?, Result<UIImage>) -> Void)?)
    {
        af_setImageWithURLRequest(
            URLRequestWithURL(URL),
            placeholderImage: placeholderImage,
            filter: filter,
            imageTransition: imageTransition,
            completion: completion
        )
    }

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

        - parameter URLRequest:       The URL request.
        - parameter placeholderImage: The image to be set initially until the image request finished. If `nil`, the
                                      image view will not change its image until the image request finishes.
        - parameter filter:           The image filter applied to the image after the image request is finished.
        - parameter imageTransition:  The image transition animation applied to the image when set.
        - parameter completion:       A closure to be executed when the image request finishes. The closure has no 
                                      return value and takes three arguments: the original request, the response from 
                                      the server and the result containing either the image or the error that occurred.
                                      If the image was returned from the image cache, the response will be `nil`.
    */
    public func af_setImageWithURLRequest(
        URLRequest: URLRequestConvertible,
        placeholderImage: UIImage?,
        filter: ImageFilter?,
        imageTransition: ImageTransition,
        completion: ((NSURLRequest?, NSHTTPURLResponse?, Result<UIImage>) -> Void)?)
    {
        guard !isURLRequestURLEqualToActiveRequestURL(URLRequest) else { return }

        af_cancelImageRequest()

        let imageDownloader = UIImageView.af_sharedImageDownloader
        let imageCache = imageDownloader.imageCache

        // Use the image from the image cache if it exists
        if let image = imageCache?.imageForRequest(URLRequest.URLRequest, withAdditionalIdentifier: filter?.identifier) {
            completion?(URLRequest.URLRequest, nil, .Success(image))
            self.image = image
            return
        }

        // Set the placeholder since we're going to have to download
        if let placeholderImage = placeholderImage {
            self.image = placeholderImage
        }

        // Download the image, then run the image transition or completion handler
        let request = UIImageView.af_sharedImageDownloader.downloadImage(
            URLRequest: URLRequest,
            filter: filter,
            completion: { [weak self] request, response, result in
                guard let strongSelf = self else { return }
                guard strongSelf.isURLRequestURLEqualToActiveRequestURL(request) else { return }

                strongSelf.af_activeRequest = nil

                if let image = result.value {
                    completion?(request, response, result)

                    UIView.transitionWithView(
                        strongSelf,
                        duration: imageTransition.duration,
                        options: imageTransition.animationOptions,
                        animations: {
                            imageTransition.animations(strongSelf, image)
                        },
                        completion: imageTransition.completion
                    )
                } else {
                    completion?(request, response, result)
                }
            }
        )

        af_activeRequest = request
    }

    // MARK: - Image Download Cancellation Methods

    /**
        Cancels the active download request, if one exists.
    */
    public func af_cancelImageRequest() {
        af_activeRequest?.cancel()
    }

    // MARK: - Private - URL Request Helper Methods

    private func URLRequestWithURL(URL: NSURL) -> NSURLRequest {
        let mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.addValue("image/*", forHTTPHeaderField: "Accept")

        return mutableURLRequest
    }

    private func isURLRequestURLEqualToActiveRequestURL(URLRequest: URLRequestConvertible?) -> Bool {
        if let
            currentRequest = af_activeRequest?.task.originalRequest
            where currentRequest.URLString == URLRequest?.URLRequest.URLString
        {
            return true
        }

        return false
    }
}
