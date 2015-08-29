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
import CoreGraphics
import Foundation
import UIKit

// MARK: ImageCache

public protocol ImageCache {
    func cachedImageForRequest(request: NSURLRequest, withIdentifier identifier: String?) -> UIImage?
    func cacheImage(image: UIImage, forRequest request: NSURLRequest, withIdentifier identifier: String?)
    func removeAllCachedImages()
}

// MARK: -

// TODO: Land on a final name for the auto purging image cache
// AutomaticImageCache
// PurgableImageCache
// MonitoringImageCache
// SizableImageCache
// ConfigurableImageCache
// SmartImageCache
// RationalImageCache
// TrackableImageCache
// DynamicImageCache
// FlexibleImageCache
// AutoPurgingImageCache
// AutoSizingImageCache

public class AutoPurgingImageCache: ImageCache {

    class CachedImage {
        private let image: UIImage
        let URLString: String
        let totalBytes: UInt64
        var lastAccessDate: NSDate

        init(_ image: UIImage, URLString: String) {
            self.image = image
            self.URLString = URLString
            self.lastAccessDate = NSDate()

            self.totalBytes = {
                let cgImage = image.CGImage
                let bytesPerRow = CGImageGetBytesPerRow(cgImage)
                let height = CGImageGetHeight(cgImage)

                return UInt64(bytesPerRow) * UInt64(height)
            }()
        }

        func accessImage() -> UIImage {
            self.lastAccessDate = NSDate()
            return self.image
        }
    }

    public private(set) var currentMemoryUsage: UInt64
    public let memoryCapacity: UInt64
    public let preferredMemoryUsageAfterPurge: UInt64

    private var cachedImages: [String: CachedImage]
    private let synchronizationQueue: dispatch_queue_t

    // MARK: Lifecycle Methods

    init(memoryCapacity: UInt64 = 100 * 1024 * 1024, preferredMemoryUsageAfterPurge: UInt64 = 60 * 1024 * 1024) {
        self.memoryCapacity = memoryCapacity
        self.preferredMemoryUsageAfterPurge = preferredMemoryUsageAfterPurge

        self.cachedImages = [:]
        self.currentMemoryUsage = 0

        self.synchronizationQueue = {
            let name = String(format: "com.alamofire.autopurgingimagecache-%08%08", arc4random(), arc4random())
            return dispatch_queue_create(name, DISPATCH_QUEUE_CONCURRENT)
        }()

        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "removeAllCachedImages",
            name: UIApplicationDidReceiveMemoryWarningNotification,
            object: nil
        )
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: Cache Methods

    public func cachedImageForRequest(request: NSURLRequest, withIdentifier identifier: String? = nil) -> UIImage? {
        var image: UIImage?

        dispatch_sync(self.synchronizationQueue) {
            let key = self.imageCacheKeyFromURLRequest(request, withIdentifier: identifier)
            if let cachedImage = self.cachedImages[key] {
                image = cachedImage.accessImage()
            }
        }

        return image
    }

    public func cacheImage(image: UIImage, forRequest request: NSURLRequest, withIdentifier identifier: String? = nil) {
        dispatch_barrier_async(self.synchronizationQueue) {
            let key = self.imageCacheKeyFromURLRequest(request, withIdentifier: identifier)
            let cachedImage = CachedImage(image, URLString: key)

            if let previousCachedImage = self.cachedImages[key] {
                self.currentMemoryUsage -= previousCachedImage.totalBytes
            }

            self.cachedImages[key] = cachedImage
            self.currentMemoryUsage += cachedImage.totalBytes
            print("Cached image: \(key) total bytes: \(self.currentMemoryUsage)")
        }

        dispatch_barrier_async(self.synchronizationQueue) {
            if self.currentMemoryUsage > self.memoryCapacity {
                // purge me some bytes!!!
                let bytesOverMaximumAllowed = self.currentMemoryUsage - self.memoryCapacity
                print("Bytes over maximum allowed: \(bytesOverMaximumAllowed)")

                let bytesToPurge = self.currentMemoryUsage - self.preferredMemoryUsageAfterPurge

                var sortedImages = [CachedImage](self.cachedImages.values)
                sortedImages.sortInPlace {
                    let date1 = $0.lastAccessDate
                    let date2 = $1.lastAccessDate

                    return date1.timeIntervalSinceDate(date2) < 0.0
                }

                var bytesPurged = UInt64(0)

                print("================== STARTING PURGE \(self.currentMemoryUsage) ==========================")

                for cachedImage in sortedImages {
                    print("Purging Cached Image: \(cachedImage.lastAccessDate) \(cachedImage.totalBytes) \(cachedImage.URLString)")

                    self.cachedImages.removeValueForKey(cachedImage.URLString)
                    bytesPurged += cachedImage.totalBytes

                    if bytesPurged >= bytesToPurge {
                        break
                    }
                }

                self.currentMemoryUsage -= bytesPurged

                print("================== FINISHED PURGE \(self.currentMemoryUsage) ==========================")
            }
        }
    }

    public func removeAllCachedImages() {
        dispatch_barrier_async(self.synchronizationQueue) {
            print("Removed all cached images!!!")
            self.cachedImages.removeAll()
            self.currentMemoryUsage = 0
        }
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
