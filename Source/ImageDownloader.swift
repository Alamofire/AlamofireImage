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

public class ImageDownloader {
    public typealias CompletionHandler = (NSURLRequest?, NSHTTPURLResponse?, Result<Image>) -> Void

    public enum DownloadPrioritization {
        case FIFO, LIFO
    }

    private class ResponseHandler {
        let identifier: String
        let request: Request
        var filters: [ImageFilter?]
        var completionHandlers: [CompletionHandler]

        init(request: Request, filter: ImageFilter?, completion: CompletionHandler) {
            self.request = request
            self.identifier = ImageDownloader.identifierForURLRequest(request.request!)
            self.filters = [filter]
            self.completionHandlers = [completion]
        }
    }

    // MARK: - Properties

    public let imageCache: ImageRequestCache
    public private(set) var credential: NSURLCredential?

    private let sessionManager: Alamofire.Manager

    private var queuedRequests: [Request]
    private var responseHandlers: [String: ResponseHandler]

    private let synchronizationQueue: dispatch_queue_t
    private let responseQueue: dispatch_queue_t
    private let downloadPrioritization: DownloadPrioritization

    private var activeRequestCount: Int
    private let maximumActiveDownloads: Int

    // MARK: - Initialization

    public static let defaultInstance = ImageDownloader()

    public class func defaultURLSessionConfiguration() -> NSURLSessionConfiguration {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()

        configuration.HTTPAdditionalHeaders = Manager.defaultHTTPHeaders
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
        return NSURLCache(
            memoryCapacity: 50 * 1024 * 1024, // 50 MB
            diskCapacity: 100 * 1024 * 1024, // 100 MB
            diskPath: "com.alamofire.imagedownloader"
        )
    }

    public init(
        configuration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration(),
        downloadPrioritization: DownloadPrioritization = .FIFO,
        maximumActiveDownloads: Int = 4,
        imageCache: ImageRequestCache = AutoPurgingImageCache())
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

    public func addAuthentication(
        username username: String,
        password: String,
        persistence: NSURLCredentialPersistence = .ForSession)
    {
        let credential = NSURLCredential(user: username, password: password, persistence: persistence)
        addAuthentication(usingCredential: credential)
    }

    public func addAuthentication(usingCredential credential: NSURLCredential) {
        dispatch_sync(synchronizationQueue) {
            self.credential = credential
        }
    }

    // MARK: - Download

    public func downloadImage(URLRequest URLRequest: URLRequestConvertible, completion: CompletionHandler) -> Request? {
        return downloadImage(URLRequest: URLRequest, filter: nil, completion: completion)
    }

    public func downloadImage(
        URLRequest URLRequest: URLRequestConvertible,
        filter: ImageFilter?,
        completion: CompletionHandler)
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
                if let image = self.imageCache.cachedImageForRequest(URLRequest.URLRequest, withIdentifier: filter?.identifier) {
                    dispatch_async(dispatch_get_main_queue()) {
                        completion(URLRequest.URLRequest, nil, .Success(image))
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
                    case .Success(var image):
                        for (filter, completion) in zip(responseHandler.filters, responseHandler.completionHandlers) {
                            if let filter = filter {
                                image = filter.filter(image)
                            }

                            dispatch_async(dispatch_get_main_queue()) {
                                completion(request, response, .Success(image))
                            }

                            strongSelf.imageCache.cacheImage(image, forRequest: request, withIdentifier: filter?.identifier)
                        }
                    case .Failure:
                        for completion in responseHandler.completionHandlers {
                            dispatch_async(dispatch_get_main_queue()) {
                                completion(request, response, result)
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

    // MARK: - Private - Thread-Safe Request Methods

    private func safelyRemoveResponseHandlerWithIdentifier(identifier: String) -> ResponseHandler {
        var responseHandler: ResponseHandler!

        dispatch_sync(synchronizationQueue) {
            responseHandler = self.responseHandlers.removeValueForKey(identifier)
        }

        return responseHandler
    }

    private func safelyStartNextRequestIfNecessary() {
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
        ++activeRequestCount
    }

    private func enqueueRequest(request: Request) {
        switch downloadPrioritization {
        case .FIFO:
            queuedRequests.append(request)
        case .LIFO:
            queuedRequests.insert(request, atIndex: 0)
        }
    }

    private func dequeueRequest() -> Request? {
        var request: Request?

        if !queuedRequests.isEmpty {
            request = queuedRequests.removeFirst()
        }

        return request
    }

    private func isActiveRequestCountBelowMaximumLimit() -> Bool {
        return activeRequestCount < maximumActiveDownloads
    }

    private static func identifierForURLRequest(URLRequest: URLRequestConvertible) -> String {
        return URLRequest.URLRequest.URLString
    }
}
