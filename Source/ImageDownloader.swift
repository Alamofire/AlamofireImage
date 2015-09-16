// ImageDownloader.swift
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

#if os(iOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import Cocoa
#endif

/// The `ImageDownloader` class is responsible for downloading images in parallel on a prioritized queue. Incoming
/// downloads are added to the front or back of the queue depending on the download prioritization. Each downloaded 
/// image is cached in the underlying `NSURLCache` as well as the in-memory image cache that supports image filters. 
/// By default, any download request with a cached image equivalent in the image cache will automatically be served the
/// cached image representation. Additional advanced features include supporting multiple image filters and completion 
/// handlers for a single request.
public class ImageDownloader {
    /// The completion handler closure used when an image download completes.
    public typealias CompletionHandler = (NSURLRequest?, NSHTTPURLResponse?, Result<Image>) -> Void

    /**
        Defines the order prioritization of incoming download requests being inserted into the queue.

        - FIFO: All incoming downloads are added to the back of the queue.
        - LIFO: All incoming downloads are added to the front of the queue.
    */
    public enum DownloadPrioritization {
        case FIFO, LIFO
    }

    class ResponseHandler {
        let identifier: String
        let request: Request
        var filters: [ImageFilter?]
        var completionHandlers: [CompletionHandler?]

        init(request: Request, filter: ImageFilter?, completion: CompletionHandler?) {
            self.request = request
            self.identifier = ImageDownloader.identifierForURLRequest(request.request!)
            self.filters = [filter]
            self.completionHandlers = [completion]
        }
    }

    // MARK: - Properties

    /// The image cache used to store all downloaded images in.
    public let imageCache: ImageRequestCache?

    /// The credential used for authenticating each download request.
    public private(set) var credential: NSURLCredential?

    var queuedRequests: [Request]
    var activeRequestCount: Int
    let maximumActiveDownloads: Int

    let sessionManager: Alamofire.Manager

    private let synchronizationQueue: dispatch_queue_t
    private let responseQueue: dispatch_queue_t
    private let downloadPrioritization: DownloadPrioritization

    private var responseHandlers: [String: ResponseHandler]

    // MARK: - Initialization

    /// The default instance of `ImageDownloader` initialized with default values.
    public static let defaultInstance = ImageDownloader()

    /**
        Creates a default `NSURLSessionConfiguration` with common usage parameter values.
    
        - returns: The default `NSURLSessionConfiguration` instance.
    */
    public class func defaultURLSessionConfiguration() -> NSURLSessionConfiguration {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()

        configuration.HTTPAdditionalHeaders = Manager.defaultHTTPHeaders
        configuration.HTTPShouldSetCookies = true
        configuration.HTTPShouldUsePipelining = false

        configuration.requestCachePolicy = .UseProtocolCachePolicy
        configuration.allowsCellularAccess = true
        configuration.timeoutIntervalForRequest = 60

        configuration.URLCache = ImageDownloader.defaultURLCache()

        return configuration
    }

    /**
        Creates a default `NSURLCache` with common usage parameter values.

        - returns: The default `NSURLCache` instance.
    */
    public class func defaultURLCache() -> NSURLCache {
        return NSURLCache(
            memoryCapacity: 20 * 1024 * 1024, // 20 MB
            diskCapacity: 150 * 1024 * 1024,  // 150 MB
            diskPath: "com.alamofire.imagedownloader"
        )
    }

    /**
        Initializes the `ImageDownloader` instance with the given configuration, download prioritization, maximum active 
        download count and image cache.

        - parameter configuration:          The `NSURLSessionConfiguration` to use to create the underlying Alamofire 
                                            `Manager` instance.
        - parameter downloadPrioritization: The download prioritization of the download queue. `.FIFO` by default.
        - parameter maximumActiveDownloads: The maximum number of active downloads allowed at any given time.
        - parameter imageCache:             The image cache used to store all downloaded images in.

        - returns: The new `ImageDownloader` instance.
    */
    public init(
        configuration: NSURLSessionConfiguration = ImageDownloader.defaultURLSessionConfiguration(),
        downloadPrioritization: DownloadPrioritization = .FIFO,
        maximumActiveDownloads: Int = 4,
        imageCache: ImageRequestCache? = AutoPurgingImageCache())
    {
        self.sessionManager = Alamofire.Manager(configuration: configuration)
        self.sessionManager.startRequestsImmediately = false

        self.downloadPrioritization = downloadPrioritization
        self.maximumActiveDownloads = maximumActiveDownloads
        self.imageCache = imageCache

        self.queuedRequests = []
        self.responseHandlers = [:]

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

    // MARK: - Authentication

    /**
        Associates an HTTP Basic Auth credential with all future download requests.

        - parameter user:        The user.
        - parameter password:    The password.
        - parameter persistence: The URL credential persistence. `.ForSession` by default.
    */
    public func addAuthentication(
        user user: String,
        password: String,
        persistence: NSURLCredentialPersistence = .ForSession)
    {
        let credential = NSURLCredential(user: user, password: password, persistence: persistence)
        addAuthentication(usingCredential: credential)
    }

    /**
        Associates the specified credential with all future download requests.

        - parameter credential: The credential.
    */
    public func addAuthentication(usingCredential credential: NSURLCredential) {
        dispatch_sync(synchronizationQueue) {
            self.credential = credential
        }
    }

    // MARK: - Download

    /**
        Creates a download request using the internal Alamofire `Manager` instance for the specified URL request.
    
        If the same download request is already in the queue or currently being downloaded, the completion handler is
        appended to the already existing request. Once the request completes, all completion handlers attached to the
        request are executed in the order they were added.

        - parameter URLRequest: The URL request.
        - parameter completion: The closure called when the download request is complete.

        - returns: The created download request if available. `nil` if the image is stored in the image cache and the
                  URL request cache policy allows the cache to be used.
    */
    public func downloadImage(URLRequest URLRequest: URLRequestConvertible, completion: CompletionHandler?) -> Request? {
        return downloadImage(URLRequest: URLRequest, filter: nil, completion: completion)
    }

    /**
        Creates a download request using the internal Alamofire `Manager` instance for the specified URL request.

        If the same download request is already in the queue or currently being downloaded, the filter and completion 
        handler are appended to the already existing request. Once the request completes, all filters and completion 
        handlers attached to the request are executed in the order they were added. Additionally, any filters attached
        to the request with the same identifiers are only executed once. The resulting image is then passed into each
        completion handler paired with the filter.

        - parameter URLRequest: The URL request.
        - parameter filter      The image filter to apply to the image after the download is complete.
        - parameter completion: The closure called when the download request is complete.

        - returns: The created download request if available. `nil` if the image is stored in the image cache and the
                   URL request cache policy allows the cache to be used.
    */
    public func downloadImage(
        URLRequest URLRequest: URLRequestConvertible,
        filter: ImageFilter?,
        completion: CompletionHandler?)
        -> Request?
    {
        var request: Request!

        dispatch_sync(synchronizationQueue) {
            // 1) Append the filter and completion handler to a pre-existing request if it already exists
            let identifier = ImageDownloader.identifierForURLRequest(URLRequest)

            if let responseHandler = self.responseHandlers[identifier] {
                responseHandler.filters.append(filter)
                responseHandler.completionHandlers.append(completion)
                request = responseHandler.request

                return
            }

            // 2) Attempt to load the image from the image cache if the cache policy allows it
            switch URLRequest.URLRequest.cachePolicy {
            case .UseProtocolCachePolicy, .ReturnCacheDataElseLoad, .ReturnCacheDataDontLoad:
                if let image = self.imageCache?.imageForRequest(
                    URLRequest.URLRequest,
                    withAdditionalIdentifier: filter?.identifier)
                {
                    dispatch_async(dispatch_get_main_queue()) {
                        completion?(URLRequest.URLRequest, nil, .Success(image))
                    }

                    return
                }
            default:
                break
            }

            // 3) Create the request and set up authentication, validation and response serialization
            request = self.sessionManager.request(URLRequest)

            if let credential = self.credential {
                request.authenticate(usingCredential: credential)
            }

            request.validate()
            request.response(
                queue: self.responseQueue,
                responseSerializer: Request.imageResponseSerializer(),
                completionHandler: { [weak self] request, response, result in
                    guard let strongSelf = self, let request = request else { return }

                    let responseHandler = strongSelf.safelyRemoveResponseHandlerWithIdentifier(identifier)

                    switch result {
                    case .Success(let image):
                        var filteredImages: [String: Image] = [:]

                        for (filter, completion) in zip(responseHandler.filters, responseHandler.completionHandlers) {
                            var filteredImage: Image

                            if let filter = filter {
                                if let alreadyFilteredImage = filteredImages[filter.identifier] {
                                    filteredImage = alreadyFilteredImage
                                } else {
                                    filteredImage = filter.filter(image)
                                    filteredImages[filter.identifier] = filteredImage
                                }
                            } else {
                                filteredImage = image
                            }

                            strongSelf.imageCache?.addImage(
                                filteredImage,
                                forRequest: request,
                                withAdditionalIdentifier: filter?.identifier
                            )

                            dispatch_async(dispatch_get_main_queue()) {
                                completion?(request, response, .Success(filteredImage))
                            }
                        }
                    case .Failure:
                        for completion in responseHandler.completionHandlers {
                            dispatch_async(dispatch_get_main_queue()) {
                                completion?(request, response, result)
                            }
                        }
                    }

                    strongSelf.safelyDecrementActiveRequestCount()
                    strongSelf.safelyStartNextRequestIfNecessary()
                }
            )

            // 4) Store the response handler for use when the request completes
            let responseHandler = ResponseHandler(request: request, filter: filter, completion: completion)
            self.responseHandlers[identifier] = responseHandler

            // 5) Either start the request or enqueue it depending on the current active request count
            if self.isActiveRequestCountBelowMaximumLimit() {
                self.startRequest(request)
            } else {
                self.enqueueRequest(request)
            }
        }

        return request
    }

    // MARK: - Internal - Thread-Safe Request Methods

    func safelyRemoveResponseHandlerWithIdentifier(identifier: String) -> ResponseHandler {
        var responseHandler: ResponseHandler!

        dispatch_sync(synchronizationQueue) {
            responseHandler = self.responseHandlers.removeValueForKey(identifier)
        }

        return responseHandler
    }

    func safelyStartNextRequestIfNecessary() {
        dispatch_sync(synchronizationQueue) {
            guard self.isActiveRequestCountBelowMaximumLimit() else { return }

            while (!self.queuedRequests.isEmpty) {
                if let request = self.dequeueRequest() where request.task.state == .Suspended {
                    self.startRequest(request)
                    break
                }
            }
        }
    }

    func safelyDecrementActiveRequestCount() {
        dispatch_sync(self.synchronizationQueue) {
            if self.activeRequestCount > 0 {
                self.activeRequestCount -= 1
            }
        }
    }

    // MARK: - Internal - Non Thread-Safe Request Methods

    func startRequest(request: Request) {
        request.resume()
        ++activeRequestCount
    }

    func enqueueRequest(request: Request) {
        switch downloadPrioritization {
        case .FIFO:
            queuedRequests.append(request)
        case .LIFO:
            queuedRequests.insert(request, atIndex: 0)
        }
    }

    func dequeueRequest() -> Request? {
        var request: Request?

        if !queuedRequests.isEmpty {
            request = queuedRequests.removeFirst()
        }

        return request
    }

    func isActiveRequestCountBelowMaximumLimit() -> Bool {
        return activeRequestCount < maximumActiveDownloads
    }

    static func identifierForURLRequest(URLRequest: URLRequestConvertible) -> String {
        return URLRequest.URLRequest.URLString
    }
}
