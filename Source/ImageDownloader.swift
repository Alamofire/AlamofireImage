//
//  ImageDownloader.swift
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

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif

/// The `RequestReceipt` is an object vended by the `ImageDownloader` when starting a download request. It can be used
/// to cancel active requests running on the `ImageDownloader` session. As a general rule, image download requests
/// should be cancelled using the `RequestReceipt` instead of calling `cancel` directly on the `request` itself. The
/// `ImageDownloader` is optimized to handle duplicate request scenarios as well as pending versus active downloads.
open class RequestReceipt {
    /// The download request created by the `ImageDownloader`.
    public let request: Request

    /// The unique identifier for the image filters and completion handlers when duplicate requests are made.
    public let receiptID: String

    init(request: Request, receiptID: String) {
        self.request = request
        self.receiptID = receiptID
    }
}

// MARK: -

/// The `ImageDownloader` class is responsible for downloading images in parallel on a prioritized queue. Incoming
/// downloads are added to the front or back of the queue depending on the download prioritization. Each downloaded
/// image is cached in the underlying `NSURLCache` as well as the in-memory image cache that supports image filters.
/// By default, any download request with a cached image equivalent in the image cache will automatically be served the
/// cached image representation. Additional advanced features include supporting multiple image filters and completion
/// handlers for a single request.
open class ImageDownloader {
    /// The completion handler closure used when an image download completes.
    public typealias CompletionHandler = (DataResponse<Image>) -> Void

    /// The progress handler closure called periodically during an image download.
    public typealias ProgressHandler = DataRequest.ProgressHandler

    // MARK: Helper Types

    /// Defines the order prioritization of incoming download requests being inserted into the queue.
    ///
    /// - fifo: All incoming downloads are added to the back of the queue.
    /// - lifo: All incoming downloads are added to the front of the queue.
    public enum DownloadPrioritization {
        case fifo, lifo
    }

    class ResponseHandler {
        let urlID: String
        let handlerID: String
        let request: DataRequest
        var operations: [(receiptID: String, filter: ImageFilter?, completion: CompletionHandler?)]

        init(
            request: DataRequest,
            handlerID: String,
            receiptID: String,
            filter: ImageFilter?,
            completion: CompletionHandler?)
        {
            self.request = request
            self.urlID = ImageDownloader.urlIdentifier(for: request.request!)
            self.handlerID = handlerID
            self.operations = [(receiptID: receiptID, filter: filter, completion: completion)]
        }
    }

    // MARK: Properties

    /// The image cache used to store all downloaded images in.
    public let imageCache: ImageRequestCache?

    /// The credential used for authenticating each download request.
    open private(set) var credential: URLCredential?

    /// Response serializer used to convert the image data to UIImage.
    public var imageResponseSerializer = DataRequest.imageResponseSerializer()

    /// The underlying Alamofire `Manager` instance used to handle all download requests.
    public let sessionManager: SessionManager

    let downloadPrioritization: DownloadPrioritization
    let maximumActiveDownloads: Int

    var activeRequestCount = 0
    var queuedRequests: [Request] = []
    var responseHandlers: [String: ResponseHandler] = [:]

    private let synchronizationQueue: DispatchQueue = {
        let name = String(format: "org.alamofire.imagedownloader.synchronizationqueue-%08x%08x", arc4random(), arc4random())
        return DispatchQueue(label: name)
    }()

    private let responseQueue: DispatchQueue = {
        let name = String(format: "org.alamofire.imagedownloader.responsequeue-%08x%08x", arc4random(), arc4random())
        return DispatchQueue(label: name, attributes: .concurrent)
    }()

    // MARK: Initialization

    /// The default instance of `ImageDownloader` initialized with default values.
    public static let `default` = ImageDownloader()

    /// Creates a default `URLSessionConfiguration` with common usage parameter values.
    ///
    /// - returns: The default `URLSessionConfiguration` instance.
    open class func defaultURLSessionConfiguration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default

        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        configuration.httpShouldSetCookies = true
        configuration.httpShouldUsePipelining = false

        configuration.requestCachePolicy = .useProtocolCachePolicy
        configuration.allowsCellularAccess = true
        configuration.timeoutIntervalForRequest = 60

        configuration.urlCache = ImageDownloader.defaultURLCache()

        return configuration
    }

    /// Creates a default `URLCache` with common usage parameter values.
    ///
    /// - returns: The default `URLCache` instance.
    open class func defaultURLCache() -> URLCache {
        return URLCache(
            memoryCapacity: 20 * 1024 * 1024, // 20 MB
            diskCapacity: 150 * 1024 * 1024,  // 150 MB
            diskPath: "org.alamofire.imagedownloader"
        )
    }

    /// Initializes the `ImageDownloader` instance with the given configuration, download prioritization, maximum active
    /// download count and image cache.
    ///
    /// - parameter configuration:          The `URLSessionConfiguration` to use to create the underlying Alamofire
    ///                                     `SessionManager` instance.
    /// - parameter downloadPrioritization: The download prioritization of the download queue. `.fifo` by default.
    /// - parameter maximumActiveDownloads: The maximum number of active downloads allowed at any given time.
    /// - parameter imageCache:             The image cache used to store all downloaded images in.
    ///
    /// - returns: The new `ImageDownloader` instance.
    public init(
        configuration: URLSessionConfiguration = ImageDownloader.defaultURLSessionConfiguration(),
        downloadPrioritization: DownloadPrioritization = .fifo,
        maximumActiveDownloads: Int = 4,
        imageCache: ImageRequestCache? = AutoPurgingImageCache())
    {
        self.sessionManager = SessionManager(configuration: configuration)
        self.sessionManager.startRequestsImmediately = false

        self.downloadPrioritization = downloadPrioritization
        self.maximumActiveDownloads = maximumActiveDownloads
        self.imageCache = imageCache
    }

    /// Initializes the `ImageDownloader` instance with the given session manager, download prioritization, maximum
    /// active download count and image cache.
    ///
    /// - parameter sessionManager:         The Alamofire `SessionManager` instance to handle all download requests.
    /// - parameter downloadPrioritization: The download prioritization of the download queue. `.fifo` by default.
    /// - parameter maximumActiveDownloads: The maximum number of active downloads allowed at any given time.
    /// - parameter imageCache:             The image cache used to store all downloaded images in.
    ///
    /// - returns: The new `ImageDownloader` instance.
    public init(
        sessionManager: SessionManager,
        downloadPrioritization: DownloadPrioritization = .fifo,
        maximumActiveDownloads: Int = 4,
        imageCache: ImageRequestCache? = AutoPurgingImageCache())
    {
        self.sessionManager = sessionManager
        self.sessionManager.startRequestsImmediately = false

        self.downloadPrioritization = downloadPrioritization
        self.maximumActiveDownloads = maximumActiveDownloads
        self.imageCache = imageCache
    }

    // MARK: Authentication

    /// Associates an HTTP Basic Auth credential with all future download requests.
    ///
    /// - parameter user:        The user.
    /// - parameter password:    The password.
    /// - parameter persistence: The URL credential persistence. `.forSession` by default.
    open func addAuthentication(
        user: String,
        password: String,
        persistence: URLCredential.Persistence = .forSession)
    {
        let credential = URLCredential(user: user, password: password, persistence: persistence)
        addAuthentication(usingCredential: credential)
    }

    /// Associates the specified credential with all future download requests.
    ///
    /// - parameter credential: The credential.
    open func addAuthentication(usingCredential credential: URLCredential) {
        synchronizationQueue.sync {
            self.credential = credential
        }
    }

    // MARK: Download

    /// Creates a download request using the internal Alamofire `SessionManager` instance for the specified URL request.
    ///
    /// If the same download request is already in the queue or currently being downloaded, the filter and completion
    /// handler are appended to the already existing request. Once the request completes, all filters and completion
    /// handlers attached to the request are executed in the order they were added. Additionally, any filters attached
    /// to the request with the same identifiers are only executed once. The resulting image is then passed into each
    /// completion handler paired with the filter.
    ///
    /// You should not attempt to directly cancel the `request` inside the request receipt since other callers may be
    /// relying on the completion of that request. Instead, you should call `cancelRequestForRequestReceipt` with the
    /// returned request receipt to allow the `ImageDownloader` to optimize the cancellation on behalf of all active
    /// callers.
    ///
    /// - parameter urlRequest:     The URL request.
    /// - parameter receiptID:      The `identifier` for the `RequestReceipt` returned. Defaults to a new, randomly
    ///                             generated UUID.
    /// - parameter filter:         The image filter to apply to the image after the download is complete. Defaults
    ///                             to `nil`.
    /// - parameter progress:       The closure to be executed periodically during the lifecycle of the request.
    ///                             Defaults to `nil`.
    /// - parameter progressQueue:  The dispatch queue to call the progress closure on. Defaults to the main queue.
    /// - parameter completion:     The closure called when the download request is complete. Defaults to `nil`.
    ///
    /// - returns: The request receipt for the download request if available. `nil` if the image is stored in the image
    ///            cache and the URL request cache policy allows the cache to be used.
    @discardableResult
    open func download(
        _ urlRequest: URLRequestConvertible,
        receiptID: String = UUID().uuidString,
        filter: ImageFilter? = nil,
        progress: ProgressHandler? = nil,
        progressQueue: DispatchQueue = DispatchQueue.main,
        completion: CompletionHandler?)
        -> RequestReceipt?
    {
        var request: DataRequest!

        synchronizationQueue.sync {
            // 1) Append the filter and completion handler to a pre-existing request if it already exists
            let urlID = ImageDownloader.urlIdentifier(for: urlRequest)

            if let responseHandler = self.responseHandlers[urlID] {
                responseHandler.operations.append((receiptID: receiptID, filter: filter, completion: completion))
                request = responseHandler.request
                return
            }

            // 2) Attempt to load the image from the image cache if the cache policy allows it
            if let request = urlRequest.urlRequest {
                switch request.cachePolicy {
                case .useProtocolCachePolicy, .returnCacheDataElseLoad, .returnCacheDataDontLoad:
                    if let image = self.imageCache?.image(for: request, withIdentifier: filter?.identifier) {
                        DispatchQueue.main.async {
                            let response = DataResponse<Image>(
                                request: urlRequest.urlRequest,
                                response: nil,
                                data: nil,
                                result: .success(image)
                            )

                            completion?(response)
                        }

                        return
                    }
                default:
                    break
                }
            }

            // 3) Create the request and set up authentication, validation and response serialization
            request = self.sessionManager.request(urlRequest)

            if let credential = self.credential {
                request.authenticate(usingCredential: credential)
            }

            request.validate()

            if let progress = progress {
                request.downloadProgress(queue: progressQueue, closure: progress)
            }

            // Generate a unique handler id to check whether the active request has changed while downloading
            let handlerID = UUID().uuidString

            request.response(
                queue: self.responseQueue,
                responseSerializer: imageResponseSerializer,
                completionHandler: { [weak self] response in
                    guard let strongSelf = self, let request = response.request else { return }

                    defer {
                        strongSelf.safelyDecrementActiveRequestCount()
                        strongSelf.safelyStartNextRequestIfNecessary()
                    }

                    // Early out if the request has changed out from under us
                    let handler = strongSelf.safelyFetchResponseHandler(withURLIdentifier: urlID)
                    guard handler?.handlerID == handlerID else { return }

                    guard let responseHandler = strongSelf.safelyRemoveResponseHandler(withURLIdentifier: urlID) else {
                        return
                    }

                    switch response.result {
                    case .success(let image):
                        var filteredImages: [String: Image] = [:]

                        for (_, filter, completion) in responseHandler.operations {
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

                            strongSelf.imageCache?.add(filteredImage, for: request, withIdentifier: filter?.identifier)

                            DispatchQueue.main.async {
                                let response = DataResponse<Image>(
                                    request: response.request,
                                    response: response.response,
                                    data: response.data,
                                    result: .success(filteredImage),
                                    timeline: response.timeline
                                )

                                completion?(response)
                            }
                        }
                    case .failure:
                        for (_, _, completion) in responseHandler.operations {
                            DispatchQueue.main.async { completion?(response) }
                        }
                    }
                }
            )

            // 4) Store the response handler for use when the request completes
            let responseHandler = ResponseHandler(
                request: request,
                handlerID: handlerID,
                receiptID: receiptID,
                filter: filter,
                completion: completion
            )

            self.responseHandlers[urlID] = responseHandler

            // 5) Either start the request or enqueue it depending on the current active request count
            if self.isActiveRequestCountBelowMaximumLimit() {
                self.start(request)
            } else {
                self.enqueue(request)
            }
        }

        if let request = request {
            return RequestReceipt(request: request, receiptID: receiptID)
        }

        return nil
    }

    /// Creates a download request using the internal Alamofire `SessionManager` instance for each specified URL request.
    ///
    /// For each request, if the same download request is already in the queue or currently being downloaded, the
    /// filter and completion handler are appended to the already existing request. Once the request completes, all
    /// filters and completion handlers attached to the request are executed in the order they were added.
    /// Additionally, any filters attached to the request with the same identifiers are only executed once. The
    /// resulting image is then passed into each completion handler paired with the filter.
    ///
    /// You should not attempt to directly cancel any of the `request`s inside the request receipts array since other
    /// callers may be relying on the completion of that request. Instead, you should call
    /// `cancelRequestForRequestReceipt` with the returned request receipt to allow the `ImageDownloader` to optimize
    /// the cancellation on behalf of all active callers.
    ///
    /// - parameter urlRequests:   The URL requests.
    /// - parameter filter         The image filter to apply to the image after each download is complete.
    /// - parameter progress:      The closure to be executed periodically during the lifecycle of the request. Defaults
    ///                            to `nil`.
    /// - parameter progressQueue: The dispatch queue to call the progress closure on. Defaults to the main queue.
    /// - parameter completion:    The closure called when each download request is complete.
    ///
    /// - returns: The request receipts for the download requests if available. If an image is stored in the image
    ///            cache and the URL request cache policy allows the cache to be used, a receipt will not be returned
    ///            for that request.
    @discardableResult
    open func download(
        _ urlRequests: [URLRequestConvertible],
        filter: ImageFilter? = nil,
        progress: ProgressHandler? = nil,
        progressQueue: DispatchQueue = DispatchQueue.main,
        completion: CompletionHandler? = nil)
        -> [RequestReceipt]
    {
        #if swift(>=4.1)
        return urlRequests.compactMap {
            download($0, filter: filter, progress: progress, progressQueue: progressQueue, completion: completion)
        }
        #else
        return urlRequests.flatMap {
            download($0, filter: filter, progress: progress, progressQueue: progressQueue, completion: completion)
        }
        #endif
    }

    /// Cancels the request in the receipt by removing the response handler and cancelling the request if necessary.
    ///
    /// If the request is pending in the queue, it will be cancelled if no other response handlers are registered with
    /// the request. If the request is currently executing or is already completed, the response handler is removed and
    /// will not be called.
    ///
    /// - parameter requestReceipt: The request receipt to cancel.
    open func cancelRequest(with requestReceipt: RequestReceipt) {
        synchronizationQueue.sync {
            let urlID = ImageDownloader.urlIdentifier(for: requestReceipt.request.request!)
            guard let responseHandler = self.responseHandlers[urlID] else { return }

            if let index = responseHandler.operations.firstIndex(where: { $0.receiptID == requestReceipt.receiptID }) {
                let operation = responseHandler.operations.remove(at: index)

                let response: DataResponse<Image> = {
                    let urlRequest = requestReceipt.request.request
                    let error = AFIError.requestCancelled

                    return DataResponse(request: urlRequest, response: nil, data: nil, result: .failure(error))
                }()

                DispatchQueue.main.async { operation.completion?(response) }
            }

            if responseHandler.operations.isEmpty && requestReceipt.request.task?.state == .suspended {
                requestReceipt.request.cancel()
                self.responseHandlers.removeValue(forKey: urlID)
            }
        }
    }

    // MARK: Internal - Thread-Safe Request Methods

    func safelyFetchResponseHandler(withURLIdentifier urlIdentifier: String) -> ResponseHandler? {
        var responseHandler: ResponseHandler?

        synchronizationQueue.sync {
            responseHandler = self.responseHandlers[urlIdentifier]
        }

        return responseHandler
    }

    func safelyRemoveResponseHandler(withURLIdentifier identifier: String) -> ResponseHandler? {
        var responseHandler: ResponseHandler?

        synchronizationQueue.sync {
            responseHandler = self.responseHandlers.removeValue(forKey: identifier)
        }

        return responseHandler
    }

    func safelyStartNextRequestIfNecessary() {
        synchronizationQueue.sync {
            guard self.isActiveRequestCountBelowMaximumLimit() else { return }

            while !self.queuedRequests.isEmpty {
                if let request = self.dequeue(), request.task?.state == .suspended {
                    self.start(request)
                    break
                }
            }
        }
    }

    func safelyDecrementActiveRequestCount() {
        self.synchronizationQueue.sync {
            if self.activeRequestCount > 0 {
                self.activeRequestCount -= 1
            }
        }
    }

    // MARK: Internal - Non Thread-Safe Request Methods

    func start(_ request: Request) {
        request.resume()
        activeRequestCount += 1
    }

    func enqueue(_ request: Request) {
        switch downloadPrioritization {
        case .fifo:
            queuedRequests.append(request)
        case .lifo:
            queuedRequests.insert(request, at: 0)
        }
    }

    @discardableResult
    func dequeue() -> Request? {
        var request: Request?

        if !queuedRequests.isEmpty {
            request = queuedRequests.removeFirst()
        }

        return request
    }

    func isActiveRequestCountBelowMaximumLimit() -> Bool {
        return activeRequestCount < maximumActiveDownloads
    }

    static func urlIdentifier(for urlRequest: URLRequestConvertible) -> String {
        return urlRequest.urlRequest?.url?.absoluteString ?? ""
    }
}
