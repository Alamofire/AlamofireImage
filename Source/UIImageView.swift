// UIImageView.swift
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

import Foundation
import UIKit
import Alamofire

// MARK: ImageCache

@objc public protocol ImageCache : NSObjectProtocol {
    func cachedImageForRequest(request: NSURLRequest) -> UIImage?
    func cacheImage(image: UIImage, forRequest request: NSURLRequest)
    func removeAllCachedImages()
}

// MARK: -

public class ImageViewCache : NSCache, ImageCache {
    
    // MARK: Lifecycle Methods
    
    override init() {
        super.init()
        
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidReceiveMemoryWarningNotification,
            object: nil,
            queue: NSOperationQueue.mainQueue(),
            usingBlock: { [weak self] notification in
                if let strongSelf = self {
                    strongSelf.removeAllObjects()
                }
            }
        )
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: Cache Methods
    
    public func cachedImageForRequest(request: NSURLRequest) -> UIImage? {
        switch request.cachePolicy {
        case .ReloadIgnoringLocalCacheData, .ReloadIgnoringLocalAndRemoteCacheData:
            return nil
        default:
            let key = ImageViewCache.imageCacheKeyFromURLRequest(request)
            return objectForKey(key) as? UIImage
        }
    }
    
    public func cacheImage(image: UIImage, forRequest request: NSURLRequest) {
        let key = ImageViewCache.imageCacheKeyFromURLRequest(request)
        setObject(image, forKey: key)
    }
    
    public func removeAllCachedImages() {
        removeAllObjects()
    }
    
    // MARK: Private - Helper Methods
    
    private class func imageCacheKeyFromURLRequest(request: NSURLRequest) -> String {
        return request.URL.absoluteString!
    }
}

// MARK: -

public extension UIImageView {
    
    // MARK: Image Transition Enum
    
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
    
    // MARK: Private - Properties
    
    private var activeTask: NSURLSessionTask? {
        get {
            let userDefinedTask: AnyObject! = objc_getAssociatedObject(self, &activeTaskKey)
            return userDefinedTask as? NSURLSessionTask
        }
        set(newTask) {
            objc_setAssociatedObject(self, &activeTaskKey, newTask, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
        }
    }
    
    // MARK: Image Cache Methods
    
    public class func sharedImageCache() -> ImageCache {
        let userDefinedCache: AnyObject! = objc_getAssociatedObject(self, &sharedImageCacheKey)
        
        if let userDefinedCache = userDefinedCache as? ImageCache {
            return userDefinedCache
        } else {
            struct Static { static let imageCache = ImageViewCache() }
            return Static.imageCache
        }
    }
    
    public class func setSharedImageCache(imageCache: ImageCache) {
        objc_setAssociatedObject(self, &sharedImageCacheKey, imageCache, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
    }
    
    // MARK: Remote Image Methods
    
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
        
        if let image = UIImageView.sharedImageCache().cachedImageForRequest(URLRequest) {
            if let success = success {
                success(URLRequest, nil, image)
            } else {
                self.image = image
            }
        } else {
            if let placeholderImage = placeholderImage {
                self.image = placeholderImage
            }
            
            let request = Alamofire.request(URLRequest)
            request.validate()
            request.responseImage { [weak self] request, response, image, error in
                if let strongSelf = self {
                    if error == nil && image is UIImage {
                        let image = image! as UIImage
                        
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
                        
                        UIImageView.sharedImageCache().cacheImage(image, forRequest: request)
                    } else {
                        failure?(request, response, error)
                    }
                    
                    strongSelf.activeTask = nil
                }
            }
            
            self.activeTask = request.task
        }
    }
    
    public func cancelImageRequest() {
        self.activeTask?.cancel()
    }
}

private var sharedImageCacheKey = "UIImageView.SharedImageCache"
private var activeTaskKey = "UIImageView.ActiveTask"
