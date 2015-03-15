// UIImageView+AlamofireImage.swift
//
// Copyright (c) 2014–2015 Alamofire (http://alamofire.org)
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

public extension UIImageView {
    
    // MARK: - Image Transition Enum
    
    public enum ImageTransition {
        case None
        case CrossDissolve(NSTimeInterval)
        case CurlDown(NSTimeInterval)
        case CurlUp(NSTimeInterval)
        case FlipFromBottom(NSTimeInterval)
        case FlipFromLeft(NSTimeInterval)
        case FlipFromRight(NSTimeInterval)
        case FlipFromTop(NSTimeInterval)
        
        var duration: NSTimeInterval {
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
            }
        }
        
        var animationOptions: UIViewAnimationOptions {
            switch self {
            case None:
                return UIViewAnimationOptions.TransitionNone
            case CrossDissolve:
                return UIViewAnimationOptions.TransitionCrossDissolve
            case CurlDown:
                return UIViewAnimationOptions.TransitionCurlDown
            case CurlUp:
                return UIViewAnimationOptions.TransitionCurlUp
            case FlipFromBottom:
                return UIViewAnimationOptions.TransitionFlipFromBottom
            case FlipFromLeft:
                return UIViewAnimationOptions.TransitionFlipFromLeft
            case FlipFromRight:
                return UIViewAnimationOptions.TransitionFlipFromRight
            case FlipFromTop:
                return UIViewAnimationOptions.TransitionFlipFromTop
            }
        }
    }
    
    // MARK: - Properties
    
    public class var sharedImageDownloader: ImageDownloader {
        get {
            if let downloader = objc_getAssociatedObject(self, &sharedImageDownloaderKey) as? ImageDownloader {
                return downloader
            } else {
                return ImageDownloader.defaultInstance
            }
        }
        set(downloader) {
            objc_setAssociatedObject(self, &sharedImageDownloaderKey, downloader, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
        }
    }
    
    private var activeRequest: Request? {
        get {
            return objc_getAssociatedObject(self, &activeRequestKey) as? Request
        }
        set(request) {
            objc_setAssociatedObject(self, &activeRequestKey, request, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
        }
    }
    
    // MARK: - Image Download Methods
    
    public func setImage(#URL: NSURL) {
        setImage(URL: URL, placeholderImage: nil)
    }
    
    public func setImage(#URL: NSURL, placeholderImage: UIImage?) {
        setImage(URL: URL, placeholderImage: placeholderImage, imageTransition: ImageTransition.None)
    }
    
    public func setImage(#URL: NSURL, placeholderImage: UIImage?, imageTransition: ImageTransition) {
        let mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.addValue("image/*", forHTTPHeaderField: "Accept")
        
        let URLRequest = mutableURLRequest.copy() as NSURLRequest
        
        setImage(
            URLRequest: URLRequest,
            placeholderImage: placeholderImage,
            imageTransition: imageTransition,
            success: nil,
            failure: nil
        )
    }
    
    public func setImage(
        #URLRequest: NSURLRequest,
        placeholderImage: UIImage?,
        imageTransition: ImageTransition,
        success: ((NSURLRequest?, NSHTTPURLResponse?, UIImage?) -> Void)?,
        failure: ((NSURLRequest?, NSHTTPURLResponse?, NSError?) -> Void)?)
    {
        cancelImageRequest()
        
        let imageDownloader = UIImageView.sharedImageDownloader
        let imageCache = imageDownloader.imageCache
        
        // Use the image from the image cache if it exists
        if let image = imageCache.cachedImageForRequest(URLRequest, withFilterName: nil) {
            if let success = success {
                success(URLRequest, nil, image)
            } else {
                self.image = image
            }
            
            return
        }
        
        // Set the placeholder since we're going to have to download
        if let placeholderImage = placeholderImage {
            self.image = placeholderImage
        }
        
        // Download the image, then run the image transition, success closure or failure closure
        let request = UIImageView.sharedImageDownloader.downloadImage(
            URLRequest: URLRequest,
            success: { [weak self] request, response, image in
                if let strongSelf = self {
                    if let success = success {
                        success(request, response, image)
                    } else {
                        switch imageTransition {
                        case .None:
                            strongSelf.image = image
                        default:
                            UIView.transitionWithView(
                                strongSelf,
                                duration: imageTransition.duration,
                                options: imageTransition.animationOptions,
                                animations: {
                                    strongSelf.image = image
                                },
                                completion: nil
                            )
                        }
                    }
                }
            },
            failure: { [weak self] request, response, error in
                if let strongSelf = self {
                    failure?(request, response, error)
                    strongSelf.activeRequest = nil
                }
            }
        )
        
        self.activeRequest = request
    }
    
    // MARK: - Image Download Cancellation Methods
    
    public func cancelImageRequest() {
        self.activeRequest?.cancel()
    }
}

private var sharedImageDownloaderKey = "UIImageView.SharedImageDownloader"
private var activeRequestKey = "UIImageView.ActiveRequest"
