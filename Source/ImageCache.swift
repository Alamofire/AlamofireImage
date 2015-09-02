// ImageCache.swift
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

// MARK: ImageCache

public protocol ImageCache {
    func addImage(image: Image, withIdentifier identifier: String)
    func removeImageWithIdentifier(identifier: String) -> Bool
    func removeAllImages() -> Bool
    func imageWithIdentifier(identifier: String) -> Image?
}

public protocol ImageRequestCache: ImageCache {
    func addImage(image: Image, forRequest request: NSURLRequest, withIdentifier identifier: String?)
    func removeImageForRequest(request: NSURLRequest, withIdentifier identifier: String?) -> Bool
    func imageForRequest(request: NSURLRequest, withIdentifier identifier: String?) -> Image?
}

// MARK: -

public class AutoPurgingImageCache: ImageRequestCache {
    private class CachedImage {
        let image: Image
        let identifier: String
        let totalBytes: UInt64
        var lastAccessDate: NSDate

        init(_ image: Image, identifier: String) {
            self.image = image
            self.identifier = identifier
            self.lastAccessDate = NSDate()

            self.totalBytes = {
                #if os(iOS) || os(watchOS)
                    let size = CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
                #elseif os(OSX)
                    let size = CGSize(width: image.size.width, height: image.size.height)
                #endif

                let bytesPerPixel: CGFloat = 4.0
                let bytesPerRow = size.width * bytesPerPixel
                let totalBytes = UInt64(bytesPerRow) * UInt64(size.height)

                return totalBytes
            }()
        }

        func accessImage() -> Image {
            lastAccessDate = NSDate()
            return image
        }
    }

    // MARK: Properties

    public var memoryUsage: UInt64 {
        var memoryUsage: UInt64 = 0

        dispatch_sync(synchronizationQueue) {
            memoryUsage = self.currentMemoryUsage
        }

        return memoryUsage
    }

    public let memoryCapacity: UInt64
    public let preferredMemoryUsageAfterPurge: UInt64

    private var cachedImages: [String: CachedImage]
    private let synchronizationQueue: dispatch_queue_t

    private var currentMemoryUsage: UInt64

    // MARK: Initialization

    public init(memoryCapacity: UInt64 = 100 * 1024 * 1024, preferredMemoryUsageAfterPurge: UInt64 = 60 * 1024 * 1024) {
        self.memoryCapacity = memoryCapacity
        self.preferredMemoryUsageAfterPurge = preferredMemoryUsageAfterPurge

        self.cachedImages = [:]
        self.currentMemoryUsage = 0

        self.synchronizationQueue = {
            let name = String(format: "com.alamofire.autopurgingimagecache-%08%08", arc4random(), arc4random())
            return dispatch_queue_create(name, DISPATCH_QUEUE_CONCURRENT)
        }()

        #if os(iOS)
            NSNotificationCenter.defaultCenter().addObserver(
                self,
                selector: "removeAllImages",
                name: UIApplicationDidReceiveMemoryWarningNotification,
                object: nil
            )
        #endif
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: Add Image to Cache

    public func addImage(image: Image, forRequest request: NSURLRequest, withIdentifier identifier: String? = nil) {
        let requestIdentifier = imageCacheKeyFromURLRequest(request, withIdentifier: identifier)
        addImage(image, withIdentifier: requestIdentifier)
    }

    public func addImage(image: Image, withIdentifier identifier: String) {
        dispatch_barrier_async(synchronizationQueue) {
            let cachedImage = CachedImage(image, identifier: identifier)

            if let previousCachedImage = self.cachedImages[identifier] {
                self.currentMemoryUsage -= previousCachedImage.totalBytes
            }

            self.cachedImages[identifier] = cachedImage
            self.currentMemoryUsage += cachedImage.totalBytes
        }

        dispatch_barrier_async(synchronizationQueue) {
            if self.currentMemoryUsage > self.memoryCapacity {
                let bytesToPurge = self.currentMemoryUsage - self.preferredMemoryUsageAfterPurge

                var sortedImages = [CachedImage](self.cachedImages.values)
                sortedImages.sortInPlace {
                    let date1 = $0.lastAccessDate
                    let date2 = $1.lastAccessDate

                    return date1.timeIntervalSinceDate(date2) < 0.0
                }

                var bytesPurged = UInt64(0)

                for cachedImage in sortedImages {
                    self.cachedImages.removeValueForKey(cachedImage.identifier)
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

    public func removeImageForRequest(request: NSURLRequest, withIdentifier identifier: String?) -> Bool {
        let requestIdentifier = imageCacheKeyFromURLRequest(request, withIdentifier: identifier)
        return removeImageWithIdentifier(requestIdentifier)
    }

    public func removeImageWithIdentifier(identifier: String) -> Bool {
        var removed = false

        dispatch_barrier_async(synchronizationQueue) {
            if let cachedImage = self.cachedImages.removeValueForKey(identifier) {
                self.currentMemoryUsage -= cachedImage.totalBytes
                removed = true
            }
        }

        return removed
    }

    @objc public func removeAllImages() -> Bool {
        var removed = false

        dispatch_sync(synchronizationQueue) {
            if !self.cachedImages.isEmpty {
                self.cachedImages.removeAll()
                self.currentMemoryUsage = 0
            }

            self.cachedImages.removeAll()
            self.currentMemoryUsage = 0

            removed = true
        }

        return removed
    }

    // MARK: Fetch Image from Cache

    public func imageForRequest(request: NSURLRequest, withIdentifier identifier: String? = nil) -> Image? {
        let requestIdentifier = imageCacheKeyFromURLRequest(request, withIdentifier: identifier)
        return imageWithIdentifier(requestIdentifier)
    }

    public func imageWithIdentifier(identifier: String) -> Image? {
        var image: Image?

        dispatch_sync(synchronizationQueue) {
            if let cachedImage = self.cachedImages[identifier] {
                image = cachedImage.accessImage()
            }
        }

        return image
    }

    // MARK: Private - Helper Methods

    private func imageCacheKeyFromURLRequest(request: NSURLRequest, withIdentifier identifier: String?) -> String {
        var key = request.URLString

        if let identifier = identifier {
            key += "-\(identifier)"
        }

        return key
    }
}
