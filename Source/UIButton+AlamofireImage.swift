//
//  UIButton+AlamofireImage.swift
//
//  Copyright (c) 2015-2018 Alamofire Software Foundation (http://alamofire.org/)
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

public typealias ControlState = UIControl.State

extension UIButton {

    // MARK: - Private - AssociatedKeys

    private struct AssociatedKey {
        static var imageDownloader = "af_UIButton.ImageDownloader"
        static var sharedImageDownloader = "af_UIButton.SharedImageDownloader"
        static var imageReceipts = "af_UIButton.ImageReceipts"
        static var backgroundImageReceipts = "af_UIButton.BackgroundImageReceipts"
    }

    // MARK: - Properties

    /// The instance image downloader used to download all images. If this property is `nil`, the `UIButton` will
    /// fallback on the `af_sharedImageDownloader` for all downloads. The most common use case for needing to use a
    /// custom instance image downloader is when images are behind different basic auth credentials.
    public var af_imageDownloader: ImageDownloader? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKey.imageDownloader) as? ImageDownloader
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKey.imageDownloader, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// The shared image downloader used to download all images. By default, this is the default `ImageDownloader`
    /// instance backed with an `AutoPurgingImageCache` which automatically evicts images from the cache when the memory
    /// capacity is reached or memory warning notifications occur. The shared image downloader is only used if the
    /// `af_imageDownloader` is `nil`.
    public class var af_sharedImageDownloader: ImageDownloader {
        get {
            guard let
                downloader = objc_getAssociatedObject(self, &AssociatedKey.sharedImageDownloader) as? ImageDownloader
            else {
                return ImageDownloader.default
            }

            return downloader
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKey.sharedImageDownloader, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    private var imageRequestReceipts: [UInt: RequestReceipt] {
        get {
            guard let
                receipts = objc_getAssociatedObject(self, &AssociatedKey.imageReceipts) as? [UInt: RequestReceipt]
            else {
                return [:]
            }

            return receipts
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKey.imageReceipts, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    private var backgroundImageRequestReceipts: [UInt: RequestReceipt] {
        get {
            guard let
                receipts = objc_getAssociatedObject(self, &AssociatedKey.backgroundImageReceipts) as? [UInt: RequestReceipt]
            else {
                return [:]
            }

            return receipts
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKey.backgroundImageReceipts, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // MARK: - Image Downloads

    /// Asynchronously downloads an image from the specified URL and sets it once the request is finished.
    ///
    /// If the image is cached locally, the image is set immediately. Otherwise the specified placeholder image will be
    /// set immediately, and then the remote image will be set once the image request is finished.
    ///
    /// - parameter state:            The control state of the button to set the image on.
    /// - parameter url:              The URL used for your image request.
    /// - parameter placeholderImage: The image to be set initially until the image request finished. If `nil`, the
    ///                               image will not change its image until the image request finishes. Defaults
    ///                               to `nil`.
    /// - parameter filter:           The image filter applied to the image after the image request is finished.
    ///                               Defaults to `nil`.
    /// - parameter progress:         The closure to be executed periodically during the lifecycle of the request.
    ///                               Defaults to `nil`.
    /// - parameter progressQueue:    The dispatch queue to call the progress closure on. Defaults to the main queue.
    /// - parameter completion:       A closure to be executed when the image request finishes. The closure takes a
    ///                               single response value containing either the image or the error that occurred. If
    ///                               the image was returned from the image cache, the response will be `nil`. Defaults
    ///                               to `nil`.
    public func af_setImage(
        for state: ControlState,
        url: URL,
        placeholderImage: UIImage? = nil,
        filter: ImageFilter? = nil,
        progress: ImageDownloader.ProgressHandler? = nil,
        progressQueue: DispatchQueue = DispatchQueue.main,
        completion: ((DataResponse<UIImage>) -> Void)? = nil)
    {
        af_setImage(
            for: state,
            urlRequest: urlRequest(with: url),
            placeholderImage: placeholderImage,
            filter: filter,
            progress: progress,
            progressQueue: progressQueue,
            completion: completion
        )
    }

    /// Asynchronously downloads an image from the specified URL request and sets it once the request is finished.
    ///
    /// If the image is cached locally, the image is set immediately. Otherwise the specified placeholder image will be
    /// set immediately, and then the remote image will be set once the image request is finished.
    ///
    /// - parameter state:            The control state of the button to set the image on.
    /// - parameter urlRequest:       The URL request.
    /// - parameter placeholderImage: The image to be set initially until the image request finished. If `nil`, the
    ///                               image will not change its image until the image request finishes. Defaults
    ///                               to `nil`.
    /// - parameter filter:           The image filter applied to the image after the image request is finished.
    ///                               Defaults to `nil`.
    /// - parameter progress:         The closure to be executed periodically during the lifecycle of the request.
    ///                               Defaults to `nil`.
    /// - parameter progressQueue:    The dispatch queue to call the progress closure on. Defaults to the main queue.
    /// - parameter completion:       A closure to be executed when the image request finishes. The closure takes a
    ///                               single response value containing either the image or the error that occurred. If
    ///                               the image was returned from the image cache, the response will be `nil`. Defaults
    ///                               to `nil`.
    public func af_setImage(
        for state: ControlState,
        urlRequest: URLRequestConvertible,
        placeholderImage: UIImage? = nil,
        filter: ImageFilter? = nil,
        progress: ImageDownloader.ProgressHandler? = nil,
        progressQueue: DispatchQueue = DispatchQueue.main,
        completion: ((DataResponse<UIImage>) -> Void)? = nil)
    {
        guard !isImageURLRequest(urlRequest, equalToActiveRequestURLForState: state) else {
            let response = DataResponse<UIImage>(
                request: nil,
                response: nil,
                data: nil,
                metrics: nil,
                serializationDuration: 0.0,
                result: .failure(AFIError.requestCancelled)
            )

            completion?(response)

            return
        }

        af_cancelImageRequest(for: state)

        let imageDownloader = af_imageDownloader ?? UIButton.af_sharedImageDownloader
        let imageCache = imageDownloader.imageCache

        // Use the image from the image cache if it exists
        if
            let request = urlRequest.urlRequest,
            let image = imageCache?.image(for: request, withIdentifier: filter?.identifier)
        {
            let response = DataResponse<UIImage>(
                request: urlRequest.urlRequest,
                response: nil,
                data: nil,
                metrics: nil,
                serializationDuration: 0.0,
                result: .success(image)
            )

            setImage(image, for: state)
            completion?(response)

            return
        }

        // Set the placeholder since we're going to have to download
        if let placeholderImage = placeholderImage { setImage(placeholderImage, for: state)  }

        // Generate a unique download id to check whether the active request has changed while downloading
        let downloadID = UUID().uuidString

        // Download the image, then set the image for the control state
        let requestReceipt = imageDownloader.download(
            urlRequest,
            receiptID: downloadID,
            filter: filter,
            progress: progress,
            progressQueue: progressQueue,
            completion: { [weak self] response in
                guard
                    let strongSelf = self,
                    strongSelf.isImageURLRequest(response.request, equalToActiveRequestURLForState: state) &&
                    strongSelf.imageRequestReceipt(for: state)?.receiptID == downloadID
                else {
                    completion?(response)
                    return
                }

                if case .success(let image) = response.result {
                    strongSelf.setImage(image, for: state)
                }

                strongSelf.setImageRequestReceipt(nil, for: state)

                completion?(response)
            }
        )

        setImageRequestReceipt(requestReceipt, for: state)
    }

    /// Cancels the active download request for the image, if one exists.
    public func af_cancelImageRequest(for state: ControlState) {
        guard let receipt = imageRequestReceipt(for: state) else { return }

        let imageDownloader = af_imageDownloader ?? UIButton.af_sharedImageDownloader
        imageDownloader.cancelRequest(with: receipt)

        setImageRequestReceipt(nil, for: state)
    }

    // MARK: - Background Image Downloads

    /// Asynchronously downloads an image from the specified URL and sets it once the request is finished.
    ///
    /// If the image is cached locally, the image is set immediately. Otherwise the specified placeholder image will be
    /// set immediately, and then the remote image will be set once the image request is finished.
    ///
    /// - parameter state:            The control state of the button to set the image on.
    /// - parameter url:              The URL used for the image request.
    /// - parameter placeholderImage: The image to be set initially until the image request finished. If `nil`, the
    ///                               background image will not change its image until the image request finishes.
    ///                               Defaults to `nil`.
    /// - parameter filter:           The image filter applied to the image after the image request is finished.
    ///                               Defaults to `nil`.
    /// - parameter progress:         The closure to be executed periodically during the lifecycle of the request.
    ///                               Defaults to `nil`.
    /// - parameter progressQueue:    The dispatch queue to call the progress closure on. Defaults to the main queue.
    /// - parameter completion:       A closure to be executed when the image request finishes. The closure takes a
    ///                               single response value containing either the image or the error that occurred. If
    ///                               the image was returned from the image cache, the response will be `nil`. Defaults
    ///                               to `nil`.
    public func af_setBackgroundImage(
        for state: ControlState,
        url: URL,
        placeholderImage: UIImage? = nil,
        filter: ImageFilter? = nil,
        progress: ImageDownloader.ProgressHandler? = nil,
        progressQueue: DispatchQueue = DispatchQueue.main,
        completion: ((DataResponse<UIImage>) -> Void)? = nil)
    {
        af_setBackgroundImage(
            for: state,
            urlRequest: urlRequest(with: url),
            placeholderImage: placeholderImage,
            filter: filter,
            progress: progress,
            progressQueue: progressQueue,
            completion: completion
        )
    }

    /// Asynchronously downloads an image from the specified URL request and sets it once the request is finished.
    ///
    /// If the image is cached locally, the image is set immediately. Otherwise the specified placeholder image will be
    /// set immediately, and then the remote image will be set once the image request is finished.
    ///
    /// - parameter state:            The control state of the button to set the image on.
    /// - parameter urlRequest:       The URL request.
    /// - parameter placeholderImage: The image to be set initially until the image request finished. If `nil`, the
    ///                               background image will not change its image until the image request finishes.
    ///                               Defaults to `nil`.
    /// - parameter filter:           The image filter applied to the image after the image request is finished.
    ///                               Defaults to `nil`.
    /// - parameter progress:         The closure to be executed periodically during the lifecycle of the request.
    ///                               Defaults to `nil`.
    /// - parameter progressQueue:    The dispatch queue to call the progress closure on. Defaults to the main queue.
    /// - parameter completion:       A closure to be executed when the image request finishes. The closure takes a
    ///                               single response value containing either the image or the error that occurred. If
    ///                               the image was returned from the image cache, the response will be `nil`. Defaults
    ///                               to `nil`.
    public func af_setBackgroundImage(
        for state: ControlState,
        urlRequest: URLRequestConvertible,
        placeholderImage: UIImage? = nil,
        filter: ImageFilter? = nil,
        progress: ImageDownloader.ProgressHandler? = nil,
        progressQueue: DispatchQueue = DispatchQueue.main,
        completion: ((DataResponse<UIImage>) -> Void)? = nil)
    {
        guard !isImageURLRequest(urlRequest, equalToActiveRequestURLForState: state) else {
            let response = DataResponse<UIImage>(
                request: nil,
                response: nil,
                data: nil,
                metrics: nil,
                serializationDuration: 0.0,
                result: .failure(AFIError.requestCancelled)
            )

            completion?(response)

            return
        }

        af_cancelBackgroundImageRequest(for: state)

        let imageDownloader = af_imageDownloader ?? UIButton.af_sharedImageDownloader
        let imageCache = imageDownloader.imageCache

        // Use the image from the image cache if it exists
        if
            let request = urlRequest.urlRequest,
            let image = imageCache?.image(for: request, withIdentifier: filter?.identifier)
        {
            let response = DataResponse<UIImage>(
                request: urlRequest.urlRequest,
                response: nil,
                data: nil,
                metrics: nil,
                serializationDuration: 0.0,
                result: .success(image)
            )

            setBackgroundImage(image, for: state)
            completion?(response)

            return
        }

        // Set the placeholder since we're going to have to download
        if let placeholderImage = placeholderImage { self.setBackgroundImage(placeholderImage, for: state)  }

        // Generate a unique download id to check whether the active request has changed while downloading
        let downloadID = UUID().uuidString

        // Download the image, then set the image for the control state
        let requestReceipt = imageDownloader.download(
            urlRequest,
            receiptID: downloadID,
            filter: nil,
            progress: progress,
            progressQueue: progressQueue,
            completion: { [weak self] response in
                guard
                    let strongSelf = self,
                    strongSelf.isBackgroundImageURLRequest(response.request, equalToActiveRequestURLForState: state) &&
                    strongSelf.backgroundImageRequestReceipt(for: state)?.receiptID == downloadID
                else {
                    completion?(response)
                    return
                }

                if case .success(let image) = response.result {
                    strongSelf.setBackgroundImage(image, for: state)
                }

                strongSelf.setBackgroundImageRequestReceipt(nil, for: state)

                completion?(response)
            }
        )

        setBackgroundImageRequestReceipt(requestReceipt, for: state)
    }

    /// Cancels the active download request for the background image, if one exists.
    public func af_cancelBackgroundImageRequest(for state: ControlState) {
        guard let receipt = backgroundImageRequestReceipt(for: state) else { return }

        let imageDownloader = af_imageDownloader ?? UIButton.af_sharedImageDownloader
        imageDownloader.cancelRequest(with: receipt)

        setBackgroundImageRequestReceipt(nil, for: state)
    }

    // MARK: - Internal - Image Request Receipts

    func imageRequestReceipt(for state: ControlState) -> RequestReceipt? {
        guard let receipt = imageRequestReceipts[state.rawValue] else { return nil }
        return receipt
    }

    func setImageRequestReceipt(_ receipt: RequestReceipt?, for state: ControlState) {
        var receipts = imageRequestReceipts
        receipts[state.rawValue] = receipt

        imageRequestReceipts = receipts
    }

    // MARK: - Internal - Background Image Request Receipts

    func backgroundImageRequestReceipt(for state: ControlState) -> RequestReceipt? {
        guard let receipt = backgroundImageRequestReceipts[state.rawValue] else { return nil }
        return receipt
    }

    func setBackgroundImageRequestReceipt(_ receipt: RequestReceipt?, for state: ControlState) {
        var receipts = backgroundImageRequestReceipts
        receipts[state.rawValue] = receipt

        backgroundImageRequestReceipts = receipts
    }

    // MARK: - Private - URL Request Helpers

    private func isImageURLRequest(
        _ urlRequest: URLRequestConvertible?,
        equalToActiveRequestURLForState state: ControlState)
        -> Bool
    {
        if
            let currentURL = imageRequestReceipt(for: state)?.request.task?.originalRequest?.url,
            let requestURL = urlRequest?.urlRequest?.url,
            currentURL == requestURL
        {
            return true
        }

        return false
    }

    private func isBackgroundImageURLRequest(
        _ urlRequest: URLRequestConvertible?,
        equalToActiveRequestURLForState state: ControlState)
        -> Bool
    {
        if
            let currentRequestURL = backgroundImageRequestReceipt(for: state)?.request.task?.originalRequest?.url,
            let requestURL = urlRequest?.urlRequest?.url,
            currentRequestURL == requestURL
        {
            return true
        }

        return false
    }

    private func urlRequest(with url: URL) -> URLRequest {
        var urlRequest = URLRequest(url: url)

        for mimeType in ImageResponseSerializer.acceptableImageContentTypes {
            urlRequest.addValue(mimeType, forHTTPHeaderField: "Accept")
        }

        return urlRequest
    }
}

#endif
