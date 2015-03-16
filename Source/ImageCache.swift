//
//  ImageCache.swift
//  AlamofireImage
//
//  Created by Christian Noon on 3/14/15.
//  Copyright (c) 2015 Alamofire. All rights reserved.
//

import Alamofire
import CoreGraphics
import Foundation
import UIKit

import Swift

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
            if var cachedImage = self.cachedImages[key] {
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
            println("Cached image: \(key) total bytes: \(self.currentMemoryUsage)")
        }
        
        dispatch_barrier_async(self.synchronizationQueue) {
            if self.currentMemoryUsage > self.memoryCapacity {
                // purge me some bytes!!!
                let bytesOverMaximumAllowed = self.currentMemoryUsage - self.memoryCapacity
                println("Bytes over maximum allowed: \(bytesOverMaximumAllowed)")
                
                let bytesToPurge = self.currentMemoryUsage - self.preferredMemoryUsageAfterPurge
                
                var sortedImages = [CachedImage](self.cachedImages.values)
                sortedImages.sort {
                    let date1 = $0.lastAccessDate
                    let date2 = $1.lastAccessDate
                    
                    return date1.timeIntervalSinceDate(date2) < 0.0
                }
                
                var bytesPurged = UInt64(0)
                
                println("================== STARTING PURGE \(self.currentMemoryUsage) ==========================")
                
                for cachedImage in sortedImages {
                    println("Purging Cached Image: \(cachedImage.lastAccessDate) \(cachedImage.totalBytes) \(cachedImage.URLString)")
                    
                    self.cachedImages.removeValueForKey(cachedImage.URLString)
                    bytesPurged += cachedImage.totalBytes
                    
                    if bytesPurged >= bytesToPurge {
                        break
                    }
                }
                
                self.currentMemoryUsage -= bytesPurged
                
                println("================== FINISHED PURGE \(self.currentMemoryUsage) ==========================")
            }
        }
    }
    
    public func removeAllCachedImages() {
        dispatch_barrier_async(self.synchronizationQueue) {
            println("Removed all cached images!!!")
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
