// ImageDownloader.h
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

public class ImageDownloader {
    
    public typealias ImageDownloadSuccessHandler = (NSURLRequest?, NSHTTPURLResponse?, UIImage) -> Void
    public typealias ImageDownloadFailureHandler = (NSURLRequest?, NSHTTPURLResponse?, NSError?) -> Void
    
    public enum DownloadPrioritization {
        case FIFO, LIFO
    }
    
    // MARK: - Properties

    public let imageCache: ImageCache
    public private(set) var credential: NSURLCredential?
    
    private let sessionManager: Alamofire.Manager
    
    private var queuedRequests: [Request]
    private let synchronizationQueue: dispatch_queue_t
    private let responseQueue: dispatch_queue_t
    private let downloadPrioritization: DownloadPrioritization
    
    private var activeRequestCount: Int
    private let maximumActiveDownloads: Int
    
    // MARK: - Initialization Methods
    
    public class var defaultInstance: ImageDownloader {
        struct Singleton {
            static let instance = ImageDownloader(configuration: ImageDownloader.defaultURLSessionConfiguration())
        }
        
        return Singleton.instance
    }
    
    public class func defaultURLSessionConfiguration() -> NSURLSessionConfiguration {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        
        configuration.HTTPAdditionalHeaders = Manager.defaultHTTPHeaders()
        configuration.HTTPShouldSetCookies = true // true by default
        configuration.HTTPShouldUsePipelining = true // risky change...
//        configuration.HTTPMaximumConnectionsPerHost = 4 on iOS or 6 on OSX
        
        configuration.requestCachePolicy = .UseProtocolCachePolicy // Let server decide (should handle `willCache`)
        configuration.allowsCellularAccess = true
        configuration.timeoutIntervalForRequest = 30 // default is 60
        
        configuration.URLCache = ImageDownloader.defaultURLCache()
        
        return configuration
    }
    
    public class func defaultURLCache() -> NSURLCache {
        let URLCache = NSURLCache(
            memoryCapacity: 50 * 1024 * 1024, // 50 MB
            diskCapacity: 100 * 1024 * 1024, // 100 MB
            diskPath: "com.alamofire.imagedownloader"
        )
        
        return URLCache
    }
    
    public init(
        configuration: NSURLSessionConfiguration? = nil,
        downloadPrioritization: DownloadPrioritization = .FIFO,
        maximumActiveDownloads: Int = 4,
        imageCache: ImageCache = AutoPurgingImageCache())
    {
        self.sessionManager = Alamofire.Manager(configuration: configuration)
        self.sessionManager.startRequestsImmediately = false
        
        self.downloadPrioritization = downloadPrioritization
        self.maximumActiveDownloads = maximumActiveDownloads
        self.imageCache = imageCache
        
        self.queuedRequests = []
        self.activeRequestCount = 0
        
        self.synchronizationQueue = {
            let name = String(format: "com.alamofire.imagedownloader.synchronizationqueue-%08%08", arc4random(), arc4random())
            return dispatch_queue_create(name, DISPATCH_QUEUE_SERIAL)
        }()

        self.responseQueue = {
            let name = String(format: "com.alamofire.imagedownloader.responsequeue-%08%08", arc4random(), arc4random())
            return dispatch_queue_create(name, DISPATCH_QUEUE_CONCURRENT)
        }()
    }
    
    // MARK: - Authentication Methods
    
    public func addAuthentication(#username: String, password: String) {
        let credential = NSURLCredential(user: username, password: password, persistence: NSURLCredentialPersistence.ForSession)
        addAuthentication(usingCredential: credential)
    }
    
    public func addAuthentication(usingCredential credential: NSURLCredential) {
        self.credential = credential
    }
    
    // MARK: - Download Methods
    
    public func downloadImage(
        #URLRequest: URLRequestConvertible,
        success: ImageDownloadSuccessHandler?,
        failure: ImageDownloadFailureHandler?)
        -> Request?
    {
        return downloadImage(URLRequest: URLRequest, filter: nil, success: success, failure: failure)
    }
    
    public func downloadImage(
        #URLRequest: URLRequestConvertible,
        filter: ImageFilter?,
        success: ImageDownloadSuccessHandler?,
        failure: ImageDownloadFailureHandler?)
        -> Request?
    {
        // Attempt to load the image from the image cache if the cache policy allows it
        switch URLRequest.URLRequest.cachePolicy {
        case .ReturnCacheDataElseLoad, .ReturnCacheDataDontLoad:
            if let image = self.imageCache.cachedImageForRequest(URLRequest.URLRequest, withIdentifier: filter?.identifier) {
                dispatch_async(dispatch_get_main_queue()) {
                    success?(URLRequest.URLRequest, nil, image)
                    return
                }
                
                return nil
            }
        default:
            break
        }
        
        let request = self.sessionManager.request(URLRequest)
        
        if let credential = self.credential {
            request.authenticate(usingCredential: credential)
        }
        
        request.validate()
        request.response(
            queue: self.responseQueue,
            serializer: Request.imageResponseSerializer(),
            completionHandler: { [weak self] request, response, image, error in
                if let strongSelf = self {
                    var image = image as? UIImage
                    
                    if image != nil && error == nil {
                        if let filter = filter {
                            image = filter.filter(image!)
                        }
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            success?(request, response, image!)
                            return
                        }
                        
                        strongSelf.imageCache.cacheImage(image!, forRequest: request, withIdentifier: filter?.identifier)
                    } else {
                        dispatch_async(dispatch_get_main_queue()) {
                            failure?(request, response, error)
                            return
                        }
                    }
                    
                    strongSelf.safelyDecrementActiveRequestCount()
                    strongSelf.safelyStartNextRequestIfNecessary()
                }
            }
        )
        
        safelyStartRequestIfPossible(request)
        
        return request
    }
    
    // MARK: - Private - Thread-Safe Request Methods
    
    private func safelyStartRequestIfPossible(request: Request) {
        dispatch_sync(self.synchronizationQueue) {
            if self.isActiveRequestCountBelowMaximumLimit() {
                self.startRequest(request)
            } else {
                self.enqueueRequest(request)
            }
        }
    }
    
    private func safelyStartNextRequestIfNecessary() {
        dispatch_sync(self.synchronizationQueue) {
            if !self.isActiveRequestCountBelowMaximumLimit() {
                return
            }
            
            while (!self.queuedRequests.isEmpty) {
                if let request = self.dequeueRequest() {
                    if request.task.state == .Suspended {
                        self.startRequest(request)
                        break
                    }
                }
            }
        }
    }
    
    private func safelyDecrementActiveRequestCount() {
        dispatch_sync(self.synchronizationQueue) {
            if self.activeRequestCount > 0 {
                self.activeRequestCount -= 1
            }
        }
    }
    
    // MARK: - Private - Non Thread-Safe Request Methods
    
    private func startRequest(request: Request) {
        request.resume()
        ++self.activeRequestCount
    }
    
    private func enqueueRequest(request: Request) {
        switch self.downloadPrioritization {
        case .FIFO:
            self.queuedRequests.append(request)
        case .LIFO:
            self.queuedRequests.insert(request, atIndex: 0)
        }
    }
    
    private func dequeueRequest() -> Request? {
        var request: Request?
        
        if !self.queuedRequests.isEmpty {
            request = self.queuedRequests.removeAtIndex(0)
        }
        
        return request
    }
    
    private func isActiveRequestCountBelowMaximumLimit() -> Bool {
        return self.activeRequestCount < self.maximumActiveDownloads
    }
}
