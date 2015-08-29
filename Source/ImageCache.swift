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

#if os(iOS)
import UIKit
public typealias Image = UIImage
#elseif os(OSX)
import Cocoa
public typealias Image = NSImage
#endif

// MARK: ImageCache

public protocol ImageCache {
    func cachedImageWithIdentifier(identifier: String) -> Image?
    func cacheImage(image: Image, withIdentifier identifier: String)
    func removeAllCachedImages()
}

public protocol ImageRequestCache: ImageCache {
    func cachedImageForRequest(request: NSURLRequest, withIdentifier identifier: String?) -> Image?
    func cacheImage(image: Image, forRequest request: NSURLRequest, withIdentifier identifier: String?)
}

// MARK: -

public class AutoPurgingImageCache: ImageRequestCache {

    // MARK: CachedImage

    class CachedImage {
        private let image: Image
        let identifier: String
        let totalBytes: UInt64
        var lastAccessDate: NSDate

        init(_ image: Image, identifier: String) {
            self.image = image
            self.identifier = identifier
            self.lastAccessDate = NSDate()

            self.totalBytes = {
                #if os(iOS)
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

    public private(set) var currentMemoryUsage: UInt64
    public let memoryCapacity: UInt64
    public let preferredMemoryUsageAfterPurge: UInt64

    private var cachedImages: [String: CachedImage]
    private let synchronizationQueue: dispatch_queue_t

    // MARK: Initialization

    init(memoryCapacity: UInt64 = 100 * 1024 * 1024, preferredMemoryUsageAfterPurge: UInt64 = 60 * 1024 * 1024) {
        self.memoryCapacity = memoryCapacity
        self.preferredMemoryUsageAfterPurge = preferredMemoryUsageAfterPurge

        self.cachedImages = [:]
        self.currentMemoryUsage = 0

        self.synchronizationQueue = {
            let name = String(format: "com.alamofire.autopurgingimagecache-%08%08", arc4random(), arc4random())
            let attributes = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT, QOS_CLASS_UTILITY, 0)

            return dispatch_queue_create(name, attributes)
        }()

        #if os(iOS)
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "removeAllCachedImages",
            name: UIApplicationDidReceiveMemoryWarningNotification,
            object: nil
        )
        #endif
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: Cache Methods

    public func cachedImageForRequest(request: NSURLRequest, withIdentifier identifier: String? = nil) -> Image? {
        let requestIdentifier = imageCacheKeyFromURLRequest(request, withIdentifier: identifier)
        return cachedImageWithIdentifier(requestIdentifier)
    }

    public func cachedImageWithIdentifier(identifier: String) -> Image? {
        var image: Image?

        dispatch_sync(synchronizationQueue) {
            if let cachedImage = self.cachedImages[identifier] {
                image = cachedImage.accessImage()
            }
        }

        return image
    }

    public func cacheImage(image: Image, forRequest request: NSURLRequest, withIdentifier identifier: String? = nil) {
        let requestIdentifier = imageCacheKeyFromURLRequest(request, withIdentifier: identifier)
        cacheImage(image, withIdentifier: requestIdentifier)
    }

    public func cacheImage(image: Image, withIdentifier identifier: String) {
        dispatch_barrier_async(self.synchronizationQueue) {
            let cachedImage = CachedImage(image, identifier: identifier)

            if let previousCachedImage = self.cachedImages[identifier] {
                self.currentMemoryUsage -= previousCachedImage.totalBytes
            }

            self.cachedImages[identifier] = cachedImage
            self.currentMemoryUsage += cachedImage.totalBytes
            print("Cached image: \(identifier) total bytes: \(self.currentMemoryUsage)")
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
                    print("Purging Cached Image: \(cachedImage.lastAccessDate) \(cachedImage.totalBytes) \(cachedImage.identifier)")

                    self.cachedImages.removeValueForKey(cachedImage.identifier)
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
