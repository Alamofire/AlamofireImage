
// UIButton+AlamofireImage.swift
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
import UIKit

extension UIButton {
    
    // MARK: Private
    
    private struct AssociatedKeys {
        static var BackgroundImageRequestReceiptKey = "af_UIButton.BackgroundImage"
        static var ImageDownloaderKey = "af_UIButton.ImageDownloader"
        static var ImageRequestReceiptKey = "af_UIButton.Image"
        static var SharedImageDownloaderKey = "af_UIButton.SharedImageDownloader"
    }
    
    // MARK: - Properties
    
    /// The instance image downloader used to download all images. If this property is `nil`, the `UIButton` will
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
            }
        
            return ImageDownloader.defaultInstance
        }
        
        set(downloader) {
            objc_setAssociatedObject(self, &AssociatedKeys.SharedImageDownloaderKey, downloader, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // MARK: Image Download methods
    
    /**
        Asynchronously downloads an image from the specified URL and sets it once the request is finished.
    
        If the image is cached locally, the image is set immediately. Otherwise the specified placehoder image will be
        set immediately, and then the remote image will be set once the image request is finished.
    
        - parameter URL:              The URL used for the image request.
        - parameter placeholderImage: The image to be set initially until the image request finished. If `nil`, the
                                      image view will not change its image until the image request finishes. `nil` by
                                      default.
    */
    public func af_setBackgroundImageForState(state: UIControlState, URL: NSURL, placeHolderImage: UIImage? = nil) {
        af_setBackgroundImageForState(state, URLRequest: URLRequestWithURL(URL), placeholderImage: placeHolderImage)
    }
    
    /**
        Asynchronously downloads an image from the specified URL and sets it once the request is finished.
    
        If the image is cached locally, the image is set immediately. Otherwise the specified placehoder image will be
        set immediately, and then the remote image will be set once the image request is finished.
    
        - parameter URLRequest:       The URL request.
        - parameter placeholderImage: The image to be set initially until the image request finished. If `nil`, the
                                      image view will not change its image until the image request finishes. `nil` by
                                      default.
        - parameter completion:       A closure to be executed when the image request finishes. The closure
                                      has no return value and takes three arguments: the original request,
                                      the response from the server and the result containing either the
                                      image or the error that occurred. If the image was returned from the
                                      image cache, the response will be `nil`.
    */
    public func af_setBackgroundImageForState(
        state: UIControlState,
        URLRequest: URLRequestConvertible,
        placeholderImage: UIImage?,
        completion: (Response<UIImage, NSError> -> Void)? = nil)
    {
        guard !isImageURLRequest(URLRequest, equalToActiveRequestURLForState: state) else { return }
        
        af_cancelBackgroundImageRequestForState(state)
        
        let imageDownloader = af_imageDownloader ?? UIButton.af_sharedImageDownloader
        let imageCache = imageDownloader.imageCache
        
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
        
        // Download the image, then set the image with no transition because is not supported yet.
        let requestReceipt = imageDownloader.downloadImage(
            URLRequest: URLRequest,
            completion: { [weak self] response in
                guard let strongSelf = self else { return }
                
                completion?(response)
                
                guard strongSelf.isBackgroundImageURLRequest(response.request, equalToActiveRequestURLForState: state) else { return }
                
                if let image = response.result.value {
                    strongSelf.setBackgroundImage(image, forState: state)
                }
                
                strongSelf.setBackgroundImageRequestReceipt(nil, forState: state)
            }
        )
        
        setBackgroundImageRequestReceipt(requestReceipt, forState: state)
    }

    /**
        Asynchronously downloads an image from the specified URL and sets it once the request is finished.
    
        If the image is cached locally, the image is set immediately. Otherwise the specified placehoder image will be
        set immediately, and then the remote image will be set once the image request is finished.
    
        - parameter URL:              The URL used for the image request.
        - parameter placeholderImage: The image to be set initially until the image request finished. If `nil`, the
                                      image view will not change its image until the image request finishes. `nil` by
                                      default.
    */
    public func af_setImageForState(state: UIControlState, URL: NSURL, placeHolderImage: UIImage? = nil) {
        af_setImageForState(state, URLRequest: URLRequestWithURL(URL), placeholderImage: placeHolderImage)
    }
    
    /**
        Asynchronously downloads an image from the specified URL and sets it once the request is finished.
     
        If the image is cached locally, the image is set immediately. Otherwise the specified placehoder image will be
        set immediately, and then the remote image will be set once the image request is finished.
     
        - parameter URLRequest:       The URL request.
        - parameter placeholderImage: The image to be set initially until the image request finished. If `nil`, the
                                      image view will not change its image until the image request finishes. `nil` by
                                      default.
        - parameter completion:       A closure to be executed when the image request finishes. The closure
                                      has no return value and takes three arguments: the original request,
                                      the response from the server and the result containing either the
                                      image or the error that occurred. If the image was returned from the
                                      image cache, the response will be `nil`.
     */
    public func af_setImageForState(
        state: UIControlState,
        URLRequest: URLRequestConvertible,
        placeholderImage: UIImage?,
        completion: (Response<UIImage, NSError> -> Void)? = nil)
    {
        guard !isImageURLRequest(URLRequest, equalToActiveRequestURLForState: state) else { return }
        
        af_cancelImageRequestForState(state)
        
        let imageDownloader = af_imageDownloader ?? UIButton.af_sharedImageDownloader
        let imageCache = imageDownloader.imageCache
        
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
        
        // Download the image, then set the image with no transition because is not supported yet.
        let requestReceipt = imageDownloader.downloadImage(
            URLRequest: URLRequest,
            completion: { [weak self] response in
                guard let strongSelf = self else { return }
                
                completion?(response)
                
                guard strongSelf.isImageURLRequest(response.request, equalToActiveRequestURLForState: state) else { return }
                
                if let image = response.result.value {
                    strongSelf.setImage(image, forState: state)
                }
                
                strongSelf.setImageRequestReceipt(nil, forState: state)
            }
        )
        
        setImageRequestReceipt(requestReceipt, forState: state)
    }
    
    /**
        Returns the active request receipt for the background image
        
        - parameter state - The `UIControlState`
    */
    public func af_activeBackgroundImageRequestReceiptForState(state: UIControlState) -> RequestReceipt? {
        if let backgroundImagesReceipts = backgroundImageReceiptsForState(state) {
            return backgroundImagesReceipts[state.rawValue]
        }
        
        return nil
    }
    
    /**
        Returns the active request receipt for the image
     
        - parameter state - The `UIControlState`
     */
    public func af_activeImageRequestReceiptForState(state: UIControlState) -> RequestReceipt? {
        if let backgroundImagesReceipts = imageReceiptsForState(state) {
            return backgroundImagesReceipts[state.rawValue]
        }
        
        return nil
    }
    
    /**
        Cancels the active download request for the background image, if one exists.
    */
    public func af_cancelBackgroundImageRequestForState(state: UIControlState) {
        guard let activeRequestReceipt = af_activeBackgroundImageRequestReceiptForState(state) else { return }
        
        let imageDownloader = af_imageDownloader ?? UIButton.af_sharedImageDownloader
        imageDownloader.cancelRequestForRequestReceipt(activeRequestReceipt)
        
        setBackgroundImageRequestReceipt(nil, forState: state)
    }
    
    /**
        Cancels the active download request for the image, if one exists.
    */
    public func af_cancelImageRequestForState(state: UIControlState) {
        guard let activeRequestReceipt = af_activeImageRequestReceiptForState(state) else { return }
        
        let imageDownloader = af_imageDownloader ?? UIButton.af_sharedImageDownloader
        imageDownloader.cancelRequestForRequestReceipt(activeRequestReceipt)
        
        setImageRequestReceipt(nil, forState: state)
    }
    
    // MARK: - Private methods
    
    private func isBackgroundImageURLRequest(
        URLRequest: URLRequestConvertible?,
        equalToActiveRequestURLForState state: UIControlState) -> Bool {
            
        if let
            // Gets the current `RequestReceipt` for the state
            activeRequestReceipt = af_activeBackgroundImageRequestReceiptForState(state),
            currentRequest = activeRequestReceipt.request.task.originalRequest
            where currentRequest.URLString == URLRequest?.URLRequest.URLString
        {
            return true
        }
        
        return false
    }

    
    private func isImageURLRequest(URLRequest: URLRequestConvertible?, equalToActiveRequestURLForState state: UIControlState) -> Bool {
        if let
            // Gets the current `RequestReceipt` for the state
            activeRequestReceipt = af_activeImageRequestReceiptForState(state),
            currentRequest = activeRequestReceipt.request.task.originalRequest
            where currentRequest.URLString == URLRequest?.URLRequest.URLString
        {
            return true
        }
        
        return false
    }
    
    private func backgroundImageReceiptsForState(state: UIControlState) -> [UInt: RequestReceipt]? {
        return objc_getAssociatedObject(self, &AssociatedKeys.BackgroundImageRequestReceiptKey) as? [UInt: RequestReceipt]
    }
    
    private func imageReceiptsForState(state: UIControlState) -> [UInt: RequestReceipt]? {
        return objc_getAssociatedObject(self, &AssociatedKeys.ImageRequestReceiptKey) as? [UInt: RequestReceipt]
    }
    
    private func setBackgroundImageRequestReceipt(requestReceipt: RequestReceipt?, forState state: UIControlState) {
        var backgroundImagesReceipts = backgroundImageReceiptsForState(state) ?? [:]
        backgroundImagesReceipts[state.rawValue] = requestReceipt
        objc_setAssociatedObject(self, &AssociatedKeys.BackgroundImageRequestReceiptKey, backgroundImagesReceipts, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    private func setImageRequestReceipt(requestReceipt: RequestReceipt?, forState state: UIControlState) {
        var imagesReceipts = imageReceiptsForState(state) ?? [:]
        imagesReceipts[state.rawValue] = requestReceipt
        objc_setAssociatedObject(self, &AssociatedKeys.ImageRequestReceiptKey, imagesReceipts, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    private func URLRequestWithURL(URL: NSURL) -> NSURLRequest {
        let mutableURLRequest = NSMutableURLRequest(URL: URL)
        for mimeType in Request.acceptableImageContentTypes {
            mutableURLRequest.addValue(mimeType, forHTTPHeaderField: "Accept")
        }
        
        return mutableURLRequest
    }
    
}