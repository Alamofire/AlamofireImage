// NSImageView+AlamofireImage.swift
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
import AppKit


extension NSImageView {

    // MARK: - Private - AssociatedKeys

    private struct AssociatedKeys {
        static var ImageDownloaderKey = "af_NSImageView.ImageDownloader"
        static var SharedImageDownloaderKey = "af_NSImageView.SharedImageDownloader"
        static var ActiveRequestReceiptKey = "af_NSImageView.ActiveRequestReceipt"
    }

    // MARK: - Associated Properties

    /// The instance image downloader used to download all images. If this property is `nil`, the `NSImageView` will
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
     image and sets it once finished
     If the image is cached locally, the image is set immediately. Otherwise the specified placehoder image will be
     set immediately, and then the remote image will be set once the image request is finished.
     The `completion` closure is called after the image download and filtering are complete.
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
     - parameter completion:                 A closure to be executed when the image request finishes. The closure
     has no return value and takes three arguments: the original request,
     the response from the server and the result containing either the
     image or the error that occurred. If the image was returned from the
     image cache, the response will be `nil`. Defaults to `nil`.
     */
    public func af_setImageWithURL(
        URL: NSURL,
        placeholderImage: NSImage? = nil,
        filter: ImageFilter? = nil,
        progress: ImageDownloader.ProgressHandler? = nil,
        progressQueue: dispatch_queue_t = dispatch_get_main_queue(),
        completion: (Response<NSImage, NSError> -> Void)? = nil)
    {
        af_setImageWithURLRequest(
            URLRequestWithURL(URL),
            placeholderImage: placeholderImage,
            filter: filter,
            progress: progress,
            progressQueue: progressQueue,
            completion: completion
        )
    }

    /**
     Asynchronously downloads an image from the specified URL Request, applies the specified image filter to the downloaded
     image and sets it.
     If the image is cached locally, the image is set immediately. Otherwise the specified placehoder image will be
     set immediately, and then the remote image will be set once the image request is finished.
     The `completion` closure is called after the image download and filtering are complete,
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
     - parameter completion:                 A closure to be executed when the image request finishes. The closure
     has no return value and takes three arguments: the original request,
     the response from the server and the result containing either the
     image or the error that occurred. If the image was returned from the
     image cache, the response will be `nil`. Defaults to `nil`.
     */
    public func af_setImageWithURLRequest(
        URLRequest: URLRequestConvertible,
        placeholderImage: NSImage? = nil,
        filter: ImageFilter? = nil,
        progress: ImageDownloader.ProgressHandler? = nil,
        progressQueue: dispatch_queue_t = dispatch_get_main_queue(),
        completion: (Response<NSImage, NSError> -> Void)? = nil)
    {
        guard !isURLRequestURLEqualToActiveRequestURL(URLRequest) else { return }

        af_cancelImageRequest()

        let imageDownloader = af_imageDownloader ?? NSImageView.af_sharedImageDownloader
        let imageCache = imageDownloader.imageCache

        // Use the image from the image cache if it exists
        if let image = imageCache?.imageForRequest(URLRequest.URLRequest, withAdditionalIdentifier: filter?.identifier) {
            let response = Response<NSImage, NSError>(
                request: URLRequest.URLRequest,
                response: nil,
                data: nil,
                result: .Success(image)
            )

            completion?(response)

            self.image = image

            return
        }

        // Set the placeholder since we're going to have to download
        if let placeholderImage = placeholderImage { self.image = placeholderImage }

        // Generate a unique download id to check whether the active request has changed while downloading
        let downloadID = NSUUID().UUIDString

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
                    strongSelf.image = image
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

        let imageDownloader = af_imageDownloader ?? NSImageView.af_sharedImageDownloader
        imageDownloader.cancelRequestForRequestReceipt(activeRequestReceipt)

        af_activeRequestReceipt = nil
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
