// UIButton+AlamofireImage.swift
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

extension UIButton {

    // MARK: - Private - AssociatedKeys

    private struct AssociatedKeys {
        static var ImageDownloaderKey = "af_UIButton.ImageDownloader"
        static var SharedImageDownloaderKey = "af_UIButton.SharedImageDownloader"
        static var ImageReceiptsKey = "af_UIButton.ImageReceipts"
        static var BackgroundImageReceiptsKey = "af_UIButton.BackgroundImageReceipts"
    }

    // MARK: - Properties

    /// The instance image downloader used to download all images. If this property is `nil`, the `UIButton` will
    /// fallback on the `af_sharedImageDownloader` for all downloads. The most common use case for needing to use a
    /// custom instance image downloader is when images are behind different basic auth credentials.
    public var af_imageDownloader: ImageDownloader? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.ImageDownloaderKey) as? ImageDownloader
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.ImageDownloaderKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// The shared image downloader used to download all images. By default, this is the default `ImageDownloader`
    /// instance backed with an `AutoPurgingImageCache` which automatically evicts images from the cache when the memory
    /// capacity is reached or memory warning notifications occur. The shared image downloader is only used if the
    /// `af_imageDownloader` is `nil`.
    public class var af_sharedImageDownloader: ImageDownloader {
        get {
            guard let
                downloader = objc_getAssociatedObject(self, &AssociatedKeys.SharedImageDownloaderKey) as? ImageDownloader
            else {
                return ImageDownloader.defaultInstance
            }

            return downloader
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.SharedImageDownloaderKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    private var imageRequestReceipts: [UInt: RequestReceipt] {
        get {
            guard let
                receipts = objc_getAssociatedObject(self, &AssociatedKeys.ImageReceiptsKey) as? [UInt: RequestReceipt]
            else {
                return [:]
            }

            return receipts
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.ImageReceiptsKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    private var backgroundImageRequestReceipts: [UInt: RequestReceipt] {
        get {
            guard let
                receipts = objc_getAssociatedObject(self, &AssociatedKeys.BackgroundImageReceiptsKey) as? [UInt: RequestReceipt]
            else {
                return [:]
            }

            return receipts
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.BackgroundImageReceiptsKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // MARK: - Image Downloads

    /**
        Asynchronously downloads an image from the specified URL and sets it once the request is finished.

        If the image is cached locally, the image is set immediately. Otherwise the specified placehoder image will be
        set immediately, and then the remote image will be set once the image request is finished.

        - parameter state:            The control state of the button to set the image on.
        - parameter URL:              The URL used for your image request.
        - parameter placeholderImage: The image to be set initially until the image request finished. If `nil`, the
                                      image will not change its image until the image request finishes. Defaults
                                      to `nil`.
        - parameter progress:         The closure to be executed periodically during the lifecycle of the request.
                                      Defaults to `nil`.
        - parameter progressQueue:    The dispatch queue to call the progress closure on. Defaults to the main queue.
        - parameter completion:       A closure to be executed when the image request finishes. The closure takes a 
                                      single response value containing either the image or the error that occurred. If 
                                      the image was returned from the image cache, the response will be `nil`. Defaults 
                                      to `nil`.
    */
    public func af_setImageForState(
        state: UIControlState,
        URL: NSURL,
        placeHolderImage: UIImage? = nil,
        progress: ImageDownloader.ProgressHandler? = nil,
        progressQueue: dispatch_queue_t = dispatch_get_main_queue(),
        completion: (Response<UIImage, NSError> -> Void)? = nil)
    {
        af_setImageForState(state,
            URLRequest: URLRequestWithURL(URL),
            placeholderImage: placeHolderImage,
            progress: progress,
            progressQueue: progressQueue,
            completion: completion
        )
    }

    /**
        Asynchronously downloads an image from the specified URL request and sets it once the request is finished.

        If the image is cached locally, the image is set immediately. Otherwise the specified placehoder image will be
        set immediately, and then the remote image will be set once the image request is finished.

        - parameter state:            The control state of the button to set the image on.
        - parameter URLRequest:       The URL request.
        - parameter placeholderImage: The image to be set initially until the image request finished. If `nil`, the
                                      image will not change its image until the image request finishes. Defaults 
                                      to `nil`.
        - parameter progress:         The closure to be executed periodically during the lifecycle of the request.
                                      Defaults to `nil`.
        - parameter progressQueue:    The dispatch queue to call the progress closure on. Defaults to the main queue.
        - parameter completion:       A closure to be executed when the image request finishes. The closure takes a
                                      single response value containing either the image or the error that occurred. If
                                      the image was returned from the image cache, the response will be `nil`. Defaults
                                      to `nil`.
    */
    public func af_setImageForState(
        state: UIControlState,
        URLRequest: URLRequestConvertible,
        placeholderImage: UIImage? = nil,
        progress: ImageDownloader.ProgressHandler? = nil,
        progressQueue: dispatch_queue_t = dispatch_get_main_queue(),
        completion: (Response<UIImage, NSError> -> Void)? = nil)
    {
        guard !isImageURLRequest(URLRequest, equalToActiveRequestURLForState: state) else { return }

        af_cancelImageRequestForState(state)

        let imageDownloader = af_imageDownloader ?? UIButton.af_sharedImageDownloader
        let imageCache = imageDownloader.imageCache

        // Use the image from the image cache if it exists
        if let image = imageCache?.imageForRequest(URLRequest.URLRequest, withAdditionalIdentifier: nil) {
            let response = Response<UIImage, NSError>(
                request: URLRequest.URLRequest,
                response: nil,
                data: nil,
                result: .Success(image)
            )

            completion?(response)
            setImage(image, forState: state)

            return
        }

        // Set the placeholder since we're going to have to download
        if let placeholderImage = placeholderImage { self.setImage(placeholderImage, forState: state)  }

        // Generate a unique download id to check whether the active request has changed while downloading
        let downloadID = NSUUID().UUIDString

        // Download the image, then set the image for the control state
        let requestReceipt = imageDownloader.downloadImage(
            URLRequest: URLRequest,
            receiptID: downloadID,
            filter: nil,
            progress: progress,
            progressQueue: progressQueue,
            completion: { [weak self] response in
                guard let strongSelf = self else { return }

                completion?(response)

                guard
                    strongSelf.isImageURLRequest(response.request, equalToActiveRequestURLForState: state) &&
                    strongSelf.imageRequestReceiptForState(state)?.receiptID == downloadID
                else {
                    return
                }

                if let image = response.result.value {
                    strongSelf.setImage(image, forState: state)
                }

                strongSelf.setImageRequestReceipt(nil, forState: state)
            }
        )

        setImageRequestReceipt(requestReceipt, forState: state)
    }

    /**
        Cancels the active download request for the image, if one exists.
    */
    public func af_cancelImageRequestForState(state: UIControlState) {
        guard let receipt = imageRequestReceiptForState(state) else { return }

        let imageDownloader = af_imageDownloader ?? UIButton.af_sharedImageDownloader
        imageDownloader.cancelRequestForRequestReceipt(receipt)

        setImageRequestReceipt(nil, forState: state)
    }

    // MARK: - Background Image Downloads

    /**
        Asynchronously downloads an image from the specified URL and sets it once the request is finished.

        If the image is cached locally, the image is set immediately. Otherwise the specified placehoder image will be
        set immediately, and then the remote image will be set once the image request is finished.

        - parameter state:            The control state of the button to set the image on.
        - parameter URL:              The URL used for the image request.
        - parameter placeholderImage: The image to be set initially until the image request finished. If `nil`, the
                                      background image will not change its image until the image request finishes.
                                      Defaults to `nil`.
        - parameter progress:         The closure to be executed periodically during the lifecycle of the request.
                                      Defaults to `nil`.
        - parameter progressQueue:    The dispatch queue to call the progress closure on. Defaults to the main queue.
        - parameter completion:       A closure to be executed when the image request finishes. The closure takes a
                                      single response value containing either the image or the error that occurred. If
                                      the image was returned from the image cache, the response will be `nil`. Defaults
                                      to `nil`.
    */
    public func af_setBackgroundImageForState(
        state: UIControlState,
        URL: NSURL,
        placeHolderImage: UIImage? = nil,
        progress: ImageDownloader.ProgressHandler? = nil,
        progressQueue: dispatch_queue_t = dispatch_get_main_queue(),
        completion: (Response<UIImage, NSError> -> Void)? = nil)
    {
        af_setBackgroundImageForState(state,
            URLRequest: URLRequestWithURL(URL),
            placeholderImage: placeHolderImage,
            completion: completion)
    }

    /**
        Asynchronously downloads an image from the specified URL request and sets it once the request is finished.

        If the image is cached locally, the image is set immediately. Otherwise the specified placehoder image will be
        set immediately, and then the remote image will be set once the image request is finished.

        - parameter state:            The control state of the button to set the image on.
        - parameter URLRequest:       The URL request.
        - parameter placeholderImage: The image to be set initially until the image request finished. If `nil`, the
                                      background image will not change its image until the image request finishes.
                                      Defaults to `nil`.
        - parameter progress:         The closure to be executed periodically during the lifecycle of the request.
                                      Defaults to `nil`.
        - parameter progressQueue:    The dispatch queue to call the progress closure on. Defaults to the main queue.
        - parameter completion:       A closure to be executed when the image request finishes. The closure takes a
                                      single response value containing either the image or the error that occurred. If
                                      the image was returned from the image cache, the response will be `nil`. Defaults
                                      to `nil`.
    */
    public func af_setBackgroundImageForState(
        state: UIControlState,
        URLRequest: URLRequestConvertible,
        placeholderImage: UIImage? = nil,
        progress: ImageDownloader.ProgressHandler? = nil,
        progressQueue: dispatch_queue_t = dispatch_get_main_queue(),
        completion: (Response<UIImage, NSError> -> Void)? = nil)
    {
        guard !isImageURLRequest(URLRequest, equalToActiveRequestURLForState: state) else { return }

        af_cancelBackgroundImageRequestForState(state)

        let imageDownloader = af_imageDownloader ?? UIButton.af_sharedImageDownloader
        let imageCache = imageDownloader.imageCache

        // Use the image from the image cache if it exists
        if let image = imageCache?.imageForRequest(URLRequest.URLRequest, withAdditionalIdentifier: nil) {
            let response = Response<UIImage, NSError>(
                request: URLRequest.URLRequest,
                response: nil,
                data: nil,
                result: .Success(image)
            )

            completion?(response)
            setBackgroundImage(image, forState: state)

            return
        }

        // Set the placeholder since we're going to have to download
        if let placeholderImage = placeholderImage { self.setBackgroundImage(placeholderImage, forState: state)  }

        // Generate a unique download id to check whether the active request has changed while downloading
        let downloadID = NSUUID().UUIDString

        // Download the image, then set the image for the control state
        let requestReceipt = imageDownloader.downloadImage(
            URLRequest: URLRequest,
            receiptID: downloadID,
            progress: progress,
            progressQueue: progressQueue,
            filter: nil,
            completion: { [weak self] response in
                guard let strongSelf = self else { return }

                completion?(response)

                guard
                    strongSelf.isBackgroundImageURLRequest(response.request, equalToActiveRequestURLForState: state) &&
                    strongSelf.backgroundImageRequestReceiptForState(state)?.receiptID == downloadID
                else {
                    return
                }

                if let image = response.result.value {
                    strongSelf.setBackgroundImage(image, forState: state)
                }

                strongSelf.setBackgroundImageRequestReceipt(nil, forState: state)
            }
        )

        setBackgroundImageRequestReceipt(requestReceipt, forState: state)
    }

    /**
        Cancels the active download request for the background image, if one exists.
    */
    public func af_cancelBackgroundImageRequestForState(state: UIControlState) {
        guard let receipt = backgroundImageRequestReceiptForState(state) else { return }

        let imageDownloader = af_imageDownloader ?? UIButton.af_sharedImageDownloader
        imageDownloader.cancelRequestForRequestReceipt(receipt)

        setBackgroundImageRequestReceipt(nil, forState: state)
    }

    // MARK: - Internal - Image Request Receipts

    func imageRequestReceiptForState(state: UIControlState) -> RequestReceipt? {
        guard let receipt = imageRequestReceipts[state.rawValue] else { return nil }
        return receipt
    }

    func setImageRequestReceipt(receipt: RequestReceipt?, forState state: UIControlState) {
        var receipts = imageRequestReceipts
        receipts[state.rawValue] = receipt

        imageRequestReceipts = receipts
    }

    // MARK: - Internal - Background Image Request Receipts

    func backgroundImageRequestReceiptForState(state: UIControlState) -> RequestReceipt? {
        guard let receipt = backgroundImageRequestReceipts[state.rawValue] else { return nil }
        return receipt
    }

    func setBackgroundImageRequestReceipt(receipt: RequestReceipt?, forState state: UIControlState) {
        var receipts = backgroundImageRequestReceipts
        receipts[state.rawValue] = receipt

        backgroundImageRequestReceipts = receipts
    }

    // MARK: - Private - URL Request Helpers

    private func isImageURLRequest(
        URLRequest: URLRequestConvertible?,
        equalToActiveRequestURLForState state: UIControlState)
        -> Bool
    {
        if let
            currentRequest = imageRequestReceiptForState(state)?.request.task.originalRequest
            where currentRequest.URLString == URLRequest?.URLRequest.URLString
        {
            return true
        }

        return false
    }

    private func isBackgroundImageURLRequest(
        URLRequest: URLRequestConvertible?,
        equalToActiveRequestURLForState state: UIControlState)
        -> Bool
    {
        if let
            currentRequest = backgroundImageRequestReceiptForState(state)?.request.task.originalRequest
            where currentRequest.URLString == URLRequest?.URLRequest.URLString
        {
            return true
        }

        return false
    }

    private func URLRequestWithURL(URL: NSURL) -> NSURLRequest {
        let mutableURLRequest = NSMutableURLRequest(URL: URL)

        for mimeType in Request.acceptableImageContentTypes {
            mutableURLRequest.addValue(mimeType, forHTTPHeaderField: "Accept")
        }

        return mutableURLRequest
    }
}
