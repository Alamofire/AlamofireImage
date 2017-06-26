//
//  ImageCache.swift
//
//  Copyright (c) 2015-2016 Alamofire Software Foundation (http://alamofire.org/)
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

// MARK: ImageCache

/// The `ImageCache` protocol defines a set of APIs for adding, removing and fetching images from a cache.
public protocol ImageCache {
    /// Adds the image to the cache with the given identifier.
    func add(_ image: Image, withIdentifier identifier: String)

    /// Removes the image from the cache matching the given identifier.
    func removeImage(withIdentifier identifier: String) -> Bool

    /// Removes all images stored in the cache.
    @discardableResult
    func removeAllImages() -> Bool

    /// Returns the image in the cache associated with the given identifier.
    func image(withIdentifier identifier: String) -> Image?
}

/// The `ImageRequestCache` protocol extends the `ImageCache` protocol by adding methods for adding, removing and
/// fetching images from a cache given an `URLRequest` and additional identifier.
public protocol ImageRequestCache: ImageCache {
    /// Adds the image to the cache using an identifier created from the request and identifier.
    func add(_ image: Image, for request: URLRequest, withIdentifier identifier: String?)

    /// Removes the image from the cache using an identifier created from the request and identifier.
    func removeImage(for request: URLRequest, withIdentifier identifier: String?) -> Bool

    /// Returns the image from the cache associated with an identifier created from the request and identifier.
    func image(for request: URLRequest, withIdentifier identifier: String?) -> Image?
}

// MARK: -

/// The `AutoPurgingImageCache` in an in-memory image cache used to store images up to a given memory capacity. When
/// the memory capacity is reached, the image cache is sorted by last access date, then the oldest image is continuously
/// purged until the preferred memory usage after purge is met. Each time an image is accessed through the cache, the
/// internal access date of the image is updated.
open class AutoPurgingImageCache: ImageRequestCache {
    class CachedImage {
        let image: Image
        let identifier: String
        let totalBytes: UInt64
        var lastAccessDate: Date

        init(_ image: Image, identifier: String) {
            self.image = image
            self.identifier = identifier
            self.lastAccessDate = Date()

            self.totalBytes = {
                #if os(iOS) || os(tvOS) || os(watchOS)
                    let size = CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
                #elseif os(macOS)
                    let size = CGSize(width: image.size.width, height: image.size.height)
                #endif

                let bytesPerPixel: CGFloat = 4.0
                let bytesPerRow = size.width * bytesPerPixel
                let totalBytes = UInt64(bytesPerRow) * UInt64(size.height)

                return totalBytes
            }()
        }

        func accessImage() -> Image {
            lastAccessDate = Date()
            return image
        }
    }

    // MARK: Properties

    /// The current total memory usage in bytes of all images stored within the cache.
    open var memoryUsage: UInt64 {
        var memoryUsage: UInt64 = 0
        synchronizationQueue.sync { memoryUsage = self.currentMemoryUsage }

        return memoryUsage
    }

    /// The total memory capacity of the cache in bytes.
    open let memoryCapacity: UInt64

    /// The preferred memory usage after purge in bytes. During a purge, images will be purged until the memory
    /// capacity drops below this limit.
    open let preferredMemoryUsageAfterPurge: UInt64

    private let synchronizationQueue: DispatchQueue
    private var cachedImages: [String: CachedImage]
    private var currentMemoryUsage: UInt64

    // MARK: Initialization

    /// Initialies the `AutoPurgingImageCache` instance with the given memory capacity and preferred memory usage
    /// after purge limit.
    ///
    /// Please note, the memory capacity must always be greater than or equal to the preferred memory usage after purge.
    ///
    /// - parameter memoryCapacity:                 The total memory capacity of the cache in bytes. `100 MB` by default.
    /// - parameter preferredMemoryUsageAfterPurge: The preferred memory usage after purge in bytes. `60 MB` by default.
    ///
    /// - returns: The new `AutoPurgingImageCache` instance.
    public init(memoryCapacity: UInt64 = 100_000_000, preferredMemoryUsageAfterPurge: UInt64 = 60_000_000) {
        self.memoryCapacity = memoryCapacity
        self.preferredMemoryUsageAfterPurge = preferredMemoryUsageAfterPurge

        precondition(
            memoryCapacity >= preferredMemoryUsageAfterPurge,
            "The `memoryCapacity` must be greater than or equal to `preferredMemoryUsageAfterPurge`"
        )

        self.cachedImages = [:]
        self.currentMemoryUsage = 0

        self.synchronizationQueue = {
            let name = String(format: "org.alamofire.autopurgingimagecache-%08x%08x", arc4random(), arc4random())
            return DispatchQueue(label: name, attributes: .concurrent)
        }()

        #if os(iOS) || os(tvOS)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(AutoPurgingImageCache.removeAllImages),
                name: Notification.Name.UIApplicationDidReceiveMemoryWarning,
                object: nil
            )
        #endif
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Add Image to Cache

    /// Adds the image to the cache using an identifier created from the request and optional identifier.
    ///
    /// - parameter image:      The image to add to the cache.
    /// - parameter request:    The request used to generate the image's unique identifier.
    /// - parameter identifier: The additional identifier to append to the image's unique identifier.
    open func add(_ image: Image, for request: URLRequest, withIdentifier identifier: String? = nil) {
        let requestIdentifier = imageCacheKey(for: request, withIdentifier: identifier)
        add(image, withIdentifier: requestIdentifier)
    }

    /// Adds the image to the cache with the given identifier.
    ///
    /// - parameter image:      The image to add to the cache.
    /// - parameter identifier: The identifier to use to uniquely identify the image.
    open func add(_ image: Image, withIdentifier identifier: String) {
        synchronizationQueue.async(flags: [.barrier]) {
            let cachedImage = CachedImage(image, identifier: identifier)

            if let previousCachedImage = self.cachedImages[identifier] {
                self.currentMemoryUsage -= previousCachedImage.totalBytes
            }

            self.cachedImages[identifier] = cachedImage
            self.currentMemoryUsage += cachedImage.totalBytes
        }

        synchronizationQueue.async(flags: [.barrier]) {
            if self.currentMemoryUsage > self.memoryCapacity {
                let bytesToPurge = self.currentMemoryUsage - self.preferredMemoryUsageAfterPurge

            #if swift(>=4.0)
                var sortedImages = self.cachedImages.map { $0.1 }
            #else
                var sortedImages = self.cachedImages.map { $1 }
            #endif
                
                sortedImages.sort {
                    let date1 = $0.lastAccessDate
                    let date2 = $1.lastAccessDate

                    return date1.timeIntervalSince(date2) < 0.0
                }

                var bytesPurged = UInt64(0)

                for cachedImage in sortedImages {
                    self.cachedImages.removeValue(forKey: cachedImage.identifier)
                    bytesPurged += cachedImage.totalBytes

                    if bytesPurged >= bytesToPurge {
                        break
                    }
                }

                self.currentMemoryUsage -= bytesPurged
            }
        }
    }

    // MARK: Remove Image from Cache

    /// Removes the image from the cache using an identifier created from the request and optional identifier.
    ///
    /// - parameter request:    The request used to generate the image's unique identifier.
    /// - parameter identifier: The additional identifier to append to the image's unique identifier.
    ///
    /// - returns: `true` if the image was removed, `false` otherwise.
    @discardableResult
    open func removeImage(for request: URLRequest, withIdentifier identifier: String?) -> Bool {
        let requestIdentifier = imageCacheKey(for: request, withIdentifier: identifier)
        return removeImage(withIdentifier: requestIdentifier)
    }

    /// Removes all images from the cache created from the request.
    ///
    /// - parameter request: The request used to generate the image's unique identifier.
    ///
    /// - returns: `true` if any images were removed, `false` otherwise.
    @discardableResult
    open func removeImages(matching request: URLRequest) -> Bool {
        let requestIdentifier = imageCacheKey(for: request, withIdentifier: nil)
        var removed = false

        synchronizationQueue.sync {
            for key in self.cachedImages.keys where key.hasPrefix(requestIdentifier) {
                if let cachedImage = self.cachedImages.removeValue(forKey: key) {
                    self.currentMemoryUsage -= cachedImage.totalBytes
                    removed = true
                }
            }
        }

        return removed
    }

    /// Removes the image from the cache matching the given identifier.
    ///
    /// - parameter identifier: The unique identifier for the image.
    ///
    /// - returns: `true` if the image was removed, `false` otherwise.
    @discardableResult
    open func removeImage(withIdentifier identifier: String) -> Bool {
        var removed = false

        synchronizationQueue.sync {
            if let cachedImage = self.cachedImages.removeValue(forKey: identifier) {
                self.currentMemoryUsage -= cachedImage.totalBytes
                removed = true
            }
        }

        return removed
    }

    /// Removes all images stored in the cache.
    ///
    /// - returns: `true` if images were removed from the cache, `false` otherwise.
    @discardableResult @objc
    open func removeAllImages() -> Bool {
        var removed = false

        synchronizationQueue.sync {
            if !self.cachedImages.isEmpty {
                self.cachedImages.removeAll()
                self.currentMemoryUsage = 0

                removed = true
            }
        }

        return removed
    }

    // MARK: Fetch Image from Cache

    /// Returns the image from the cache associated with an identifier created from the request and optional identifier.
    ///
    /// - parameter request:    The request used to generate the image's unique identifier.
    /// - parameter identifier: The additional identifier to append to the image's unique identifier.
    ///
    /// - returns: The image if it is stored in the cache, `nil` otherwise.
    open func image(for request: URLRequest, withIdentifier identifier: String? = nil) -> Image? {
        let requestIdentifier = imageCacheKey(for: request, withIdentifier: identifier)
        return image(withIdentifier: requestIdentifier)
    }

    /// Returns the image in the cache associated with the given identifier.
    ///
    /// - parameter identifier: The unique identifier for the image.
    ///
    /// - returns: The image if it is stored in the cache, `nil` otherwise.
    open func image(withIdentifier identifier: String) -> Image? {
        var image: Image?

        synchronizationQueue.sync {
            if let cachedImage = self.cachedImages[identifier] {
                image = cachedImage.accessImage()
            }
        }

        return image
    }

    // MARK: Image Cache Keys

    /// Returns the unique image cache key for the specified request and additional identifier.
    ///
    /// - parameter request:    The request.
    /// - parameter identifier: The additional identifier.
    ///
    /// - returns: The unique image cache key.
    open func imageCacheKey(for request: URLRequest, withIdentifier identifier: String?) -> String {
        var key = request.url?.absoluteString ?? ""

        if let identifier = identifier {
            key += "-\(identifier)"
        }

        return key
    }
}
