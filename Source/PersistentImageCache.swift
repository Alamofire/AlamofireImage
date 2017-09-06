//
//  PersistentImageCache.swift
//  AlamofireImage
//
//  Created by Giuseppe Lanza on 08/08/2017.
//  Copyright © 2017 Alamofire. All rights reserved.
//

import Foundation

#if os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif

// MARK: PersistentImageCache

public protocol PersistentImageCache: ImageRequestCache {
    var defaultTimeToLive: TimeInterval { get set }
    
    func remainingLifeForImage(withIdentifier identifier: String) -> TimeInterval?
    func remainingLifeForImage(for request: URLRequest, withIdentifier identifier: String) -> TimeInterval?

    func add(_ image: Image, withIdentifier identifier: String, andTimeToLive timeToLive: TimeInterval)
    func add(_ image: Image, withIdentifier identifier: String, andTimeToLive timeToLive: TimeInterval, withCompletion completion: @escaping ()->())
    
    func add(_ image: Image, for request: URLRequest, withIdentifier identifier: String?, andTimeToLive timeToLive: TimeInterval)
    func add(_ image: Image, for request: URLRequest, withIdentifier identifier: String?, andTimeToLive timeToLive: TimeInterval, withCompletion completion: @escaping ()->())
    
    func removeAllImagesInMemory() -> Bool
    
    func cleanup() -> Bool
}

// MARK: -

open class PersistentAutoPurgingImageCache: AutoPurgingImageCache, PersistentImageCache {
    
    // MARK: Properties
    
    ///The default time to live for any new added image.
    public var defaultTimeToLive: TimeInterval
    
    private let synchronizationQueue: DispatchQueue
    private let fileManager = FileManager()
    
    private let persistencePath: String
    
    private var cleanupTimer: Timer?
    
    // MARK: Initialization

    ///Initializes the `PersistentAutoPurgingImageCache` instance with the given memory capacity, preferred memory usage after purge limit, 
    ///default time to live and cache path.
    ///
    /// Please note, the memory capacity must always be greater than or equal to the preferred memory usage after purge.
    /// - parameter memoryCapacity:                 The total memory capacity of the cache in bytes. `100 MB` by default.
    /// - parameter preferredMemoryUsageAfterPurge: The preferred memory usage after purge in bytes. `60 MB` by default.
    /// - parameter defaultTimeToLive:              The default time to live for any new added image
    /// - parameter persistencePath:                The cahce folder path.
    ///
    /// - returns: The new `AutoPurgingImageCache` instance.
    public init(memoryCapacity: UInt64 = 100_000_000, preferredMemoryUsageAfterPurge: UInt64 = 60_000_000, defaultTimeToLive: TimeInterval = 7 * 24 * 3600, persistencePath: String = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!) {
        self.defaultTimeToLive = defaultTimeToLive
        
        var isDir: ObjCBool = false
        precondition(FileManager.default.fileExists(atPath: persistencePath, isDirectory: &isDir) && isDir.boolValue, "The persistence path should exist, and it should be a directory")
        self.persistencePath = persistencePath
        
        self.synchronizationQueue = {
            let name = String(format: "org.alamofire.persistentautopurgingimagecache-%08x%08x", arc4random(), arc4random())
            return DispatchQueue(label: name, attributes: .concurrent)
        }()
        
        super.init(memoryCapacity: memoryCapacity, preferredMemoryUsageAfterPurge: preferredMemoryUsageAfterPurge)
        
        #if os(iOS) || os(tvOS)
            //Remove the previous observer set by super init
            NotificationCenter.default.removeObserver(self, name: Notification.Name.UIApplicationDidReceiveMemoryWarning, object: nil)
            
            //And add the custom new one to avoid that memory warning purge disk cache as well
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(PersistentAutoPurgingImageCache.removeAllImagesInMemory),
                name: Notification.Name.UIApplicationDidReceiveMemoryWarning,
                object: nil
            )
        #endif
        
        cleanup()
    }
    
    // MARK: Add Image to Cache
    
    /// Adds the image to the cache with the given identifier.
    ///
    /// - parameter image:      The image to add to the cache.
    /// - parameter identifier: The identifier to use to uniquely identify the image.
    open override func add(_ image: Image, withIdentifier identifier: String) {
        self.add(image, withIdentifier: identifier, andTimeToLive: defaultTimeToLive)
    }
    
    /// Adds the image to the cache with the given identifier.
    ///
    /// - parameter image:      The image to add to the cache.
    /// - parameter identifier: The identifier to use to uniquely identify the image.
    /// - parameter completion: The code to be executed when the add operation is accomplished.
    open override func add(_ image: Image, withIdentifier identifier: String, andCompletion completion: @escaping () -> ()) {
        self.add(image, withIdentifier: identifier, andTimeToLive: defaultTimeToLive, withCompletion: completion)
    }
    
    /// Adds the image to the cache with the given identifier.
    ///
    /// - parameter image:      The image to add to the cache.
    /// - parameter identifier: The identifier to use to uniquely identify the image.
    /// - parameter timeToLive: The amount of seconds of lif granted to the cached image on disk.
    open func add(_ image: Image, withIdentifier identifier: String, andTimeToLive timeToLive: TimeInterval) {
        self.add(image, withIdentifier: identifier, andTimeToLive: timeToLive, withCompletion: ({ }))
    }
    
    /// Adds the image to the cache with the given identifier.
    ///
    /// - parameter image:      The image to add to the cache.
    /// - parameter identifier: The identifier to use to uniquely identify the image.
    /// - parameter timeToLive: The amount of seconds of lif granted to the cached image on disk.
    /// - parameter completion: The code to be executed when the add operation is accomplished.
    open func add(_ image: Image, withIdentifier identifier: String, andTimeToLive timeToLive: TimeInterval, withCompletion completion: @escaping ()->()) {
        synchronizationQueue.async(flags: [.barrier]) {
            let path = self.pathForResource(withIdentifier: identifier)
            
            defer {
                //We want to update the time to live if the image was added again.
                if self.fileManager.fileExists(atPath: path) {
                    var expiration = Date().addingTimeInterval(timeToLive).timeIntervalSince1970
                    
                    setxattr(path, "org.alamofire.persistentautopurgingimagecache-expiration", &expiration, MemoryLayout<TimeInterval>.size, 0, 0)
                }
            }
            
            guard !self.fileManager.fileExists(atPath: path) else {
                return
            }
            
            #if os(iOS) || os(tvOS) || os(watchOS)
                guard let data = UIImageJPEGRepresentation(image, 1.0) as NSData? else {
                    return
                }
            #elseif os(macOS)
                guard let imageData = image.tiffRepresentation,
                    let rep = NSBitmapImageRep(data: imageData),
                    let data = rep.representation(using: .JPEG, properties: [NSImageCompressionFactor: 1.0]) as NSData? else {
                        return
                }
            #endif
            
            try? data.write(toFile: path, options: .atomic)
            self.scheduleTimer()
        }
        
        //super add uses a different synchronization queue, therefore to synchronize the completion at the end of the add
        //operation we need to schedule on our synchronization queue the completion, when the super add is finished. The
        //barrier flags will ensure us that there are no data race condition, bbecause if the previous block is still running,
        //the barrier will prevent the completion block to bbe executed. If it is no longer running, then it means that we are
        //ready to complete.
        super.add(image, withIdentifier: identifier) {
            self.synchronizationQueue.async(flags: [.barrier], execute: completion)
        }
    }
    
    /// Adds the image to the cache using an identifier created from the request and optional identifier.
    ///
    /// - parameter image:      The image to add to the cache.
    /// - parameter request:    The request used to generate the image's unique identifier.
    /// - parameter identifier: The additional identifier to append to the image's unique identifier.
    open override func add(_ image: Image, for request: URLRequest, withIdentifier identifier: String?) {
        add(image, for: request, withIdentifier: identifier, andTimeToLive: defaultTimeToLive)
    }
    
    /// Adds the image to the cache using an identifier created from the request and optional identifier.
    ///
    /// - parameter image:      The image to add to the cache.
    /// - parameter request:    The request used to generate the image's unique identifier.
    /// - parameter identifier: The additional identifier to append to the image's unique identifier.
    /// - parameter completion: The block to be executed at the end of the add operation.
    open override func add(_ image: Image, for request: URLRequest, withIdentifier identifier: String?, andCompletion completion: @escaping () -> ()) {
        add(image, for: request, withIdentifier: identifier, andTimeToLive: defaultTimeToLive, withCompletion: completion)
    }
    
    /// Adds the image to the cache using an identifier created from the request and optional identifier.
    ///
    /// - parameter image:      The image to add to the cache.
    /// - parameter request:    The request used to generate the image's unique identifier.
    /// - parameter identifier: The additional identifier to append to the image's unique identifier.
    /// - parameter timeToLive: The amount of seconds of lif granted to the cached image on disk.
    open func add(_ image: Image, for request: URLRequest, withIdentifier identifier: String?, andTimeToLive timeToLive: TimeInterval) {
        let requestIdentifier = imageCacheKey(for: request, withIdentifier: identifier)
        add(image, withIdentifier: requestIdentifier, andTimeToLive: timeToLive)
    }
    
    /// Adds the image to the cache using an identifier created from the request and optional identifier.
    ///
    /// - parameter image:      The image to add to the cache.
    /// - parameter request:    The request used to generate the image's unique identifier.
    /// - parameter identifier: The additional identifier to append to the image's unique identifier.
    /// - parameter timeToLive: The amount of seconds of lif granted to the cached image on disk.
    /// - parameter completion: The block to be executed at the end of the add operation.
    open func add(_ image: Image, for request: URLRequest, withIdentifier identifier: String?, andTimeToLive timeToLive: TimeInterval, withCompletion completion: @escaping ()->()) {
        let requestIdentifier = imageCacheKey(for: request, withIdentifier: identifier)
        add(image, withIdentifier: requestIdentifier, andTimeToLive: timeToLive, withCompletion: completion)
    }
    
    // MARK: Remove Image from Cache

    /// Removes the image from the cache matching the given identifier.
    ///
    /// - parameter identifier: The unique identifier for the image.
    ///
    /// - returns: `true` if the image was removed, `false` otherwise.
    @discardableResult
    open override func removeImage(withIdentifier identifier: String) -> Bool {
        var diskRemoved = false
        synchronizationQueue.sync {
            let path = pathForResource(withIdentifier: identifier)
            do {
                try self.fileManager.removeItem(atPath: path)
                diskRemoved = true
            } catch let error {
                print("ERROR Removing file: ", error)
            }
            
            self.scheduleTimer()
        }
        
        super.removeImage(withIdentifier: identifier)
        return diskRemoved
    }
    
    /// Removes the image from the cache using an identifier created from the request and optional identifier.
    ///
    /// - parameter request:    The request used to generate the image's unique identifier.
    /// - parameter identifier: The additional identifier to append to the image's unique identifier.
    ///
    /// - returns: `true` if the image was removed, `false` otherwise.
    open override func removeImage(for request: URLRequest, withIdentifier identifier: String?) -> Bool {
        let requestIdentifier = imageCacheKey(for: request, withIdentifier: identifier)
        return removeImage(withIdentifier: requestIdentifier)
    }
    
    /// Removes all images from the cache created from the request.
    ///
    /// - parameter request: The request used to generate the image's unique identifier.
    ///
    /// - returns: `true` if any images were removed, `false` otherwise.
    @discardableResult
    open override func removeImages(matching request: URLRequest) -> Bool {
        let requestIdentifier = imageCacheKey(for: request, withIdentifier: nil).addingPercentEncoding(withAllowedCharacters: .letters)!
        var removed = false
        
        synchronizationQueue.sync {
            let files = self.cachedFileNames().filter { $0.hasPrefix(requestIdentifier) }
            removed = self.removeFiles(matchingFileNames: files)
            
            self.scheduleTimer()
        }
        
        super.removeImages(matching: request)
        
        return removed
    }
    
    /// Removes all images stored in the memory cache.
    ///
    /// - returns: `true` if images were removed from the memory cache, `false` otherwise.
    @discardableResult @objc
    open func removeAllImagesInMemory() -> Bool {
        return super.removeAllImages()
    }
    
    /// Removes all images stored in the cache.
    ///
    /// - returns: `true` if images were removed from the cache, `false` otherwise.
    @discardableResult
    open override func removeAllImages() -> Bool {
        var removed = false
        
        synchronizationQueue.sync {
            let files = self.cachedFileNames()
            removed = self.removeFiles(matchingFileNames: files)
            
            self.scheduleTimer()
        }
        
        let _ = super.removeAllImages()
        return removed
    }
    
    ///Remove the images with specified file names.
    ///
    /// - parameter fileNames: The names of the files you wish to remove from the disk cache
    ///
    /// - returns: `true` if images were removed from the disk cache, `false` otherwise.
    private func removeFiles(matchingFileNames fileNames: [String]) -> Bool {
        guard fileNames.count > 0 else { return false }
        
        //Let's assume removed true
        var removed = true
        for fileName in fileNames {
            let path = pathForResource(withFileName: fileName)
            do {
                try fileManager.removeItem(atPath: path)
            } catch let error {
                print("ERROR Removing file: ", error)
                //removed must be marked as false even if the failure is related to just one file
                removed = false
            }
        }
        return removed
    }
    
    // MARK: Fetch Image from Cache
    
    /// Returns the image in the cache associated with the given identifier.
    ///
    /// - parameter identifier: The unique identifier for the image.
    ///
    /// - returns: The image if it is stored in the cache, `nil` otherwise.
    open override func image(withIdentifier identifier: String) -> Image? {
        var image = super.image(withIdentifier: identifier)
        synchronizationQueue.sync {
            let path = self.pathForResource(withIdentifier: identifier)
            if image == nil,
                let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                
                #if os(iOS) || os(tvOS)
                    image = UIImage(data: data, scale: UIScreen.main.scale)
                #elseif os(watchOS)
                    image = UIImage(data: data, scale: 1)
                #elseif os(macOS)
                    image = NSImage(data: data)
                #endif
                
                if let diskCachedImage = image {
                    //if requested the image must be back in memory for future access.
                    super.add(diskCachedImage, withIdentifier: identifier)
                }
            }
        }
        return image
    }
    
    /// Returns the image from the cache associated with an identifier created from the request and optional identifier.
    ///
    /// - parameter request:    The request used to generate the image's unique identifier.
    /// - parameter identifier: The additional identifier to append to the image's unique identifier.
    ///
    /// - returns: The image if it is stored in the cache, `nil` otherwise.
    open override func image(for request: URLRequest, withIdentifier identifier: String?) -> Image? {
        let requestIdentifier = imageCacheKey(for: request, withIdentifier: identifier)
        return image(withIdentifier: requestIdentifier)
    }

    // MARK: Cache life management
    ///Returns the remaining life time for the cached image with the specified identifier in seconds, or nil if the image with the specified
    ///identifier is not cached.
    ///
    /// - parameter request:    The request used to generate the image's unique identifier.
    /// - parameter identifier: The additional identifier to append to the image's unique identifier.
    ///
    /// - returns: The life time in seconds or nil if there is no cached image for the specified identifier
    public func remainingLifeForImage(for request: URLRequest, withIdentifier identifier: String) -> TimeInterval? {
        let requestIdentifier = imageCacheKey(for: request, withIdentifier: identifier)
        return remainingLifeForImage(withIdentifier: requestIdentifier)
    }
    
    ///Returns the remaining life time for the cached image with the specified identifier in seconds, or nil if the image with the specified
    ///identifier is not cached.
    ///
    /// - parameter identifier: The identifier for the cached image.
    ///
    /// - returns: The life time in seconds or nil if there is no cached image for the specified identifier
    public func remainingLifeForImage(withIdentifier identifier: String) -> TimeInterval? {
        let path = self.pathForResource(withIdentifier: identifier)
        guard fileManager.fileExists(atPath: path) else { return nil }
        
        var expiration: TimeInterval = 0
        getxattr(path, "org.alamofire.persistentautopurgingimagecache-expiration", &expiration, MemoryLayout<TimeInterval>.size, 0, 0)
        
        return expiration - NSDate().timeIntervalSince1970
    }
    
    ///Clean the cache folder by deleting files with remaining life < 0. All memory instance of the removed image will be removed too from cache.
    ///
    ///- returns: True if at least one file was deleted from disk.
    @objc @discardableResult
    open func cleanup() -> Bool {
        var removedFiles = false
        synchronizationQueue.sync {
            let files = self.cachedFileNames()
            
            for fileName in files {
                let identifier = identifierFromFileName(fileName)
                guard let life = remainingLifeForImage(withIdentifier: identifier),
                    life <= 0 else {
                        continue
                }
                
                let path = self.pathForResource(withFileName: fileName)
                if let _ = try? self.fileManager.removeItem(atPath: path) {
                    //The image must be purged also from memory
                    super.removeImage(withIdentifier: identifier)
                    removedFiles = true
                }
            }
            
            self.scheduleTimer()
        }
        return removedFiles
    }
    
    ///Schedule a timer for the closest expiration date. The timer will trigger the *cleanup* method. If the closest expiration date is in the past
    ///the timer will be scheduled for the next closest expiration date in the future.
    private func scheduleTimer() {
        synchronizationQueue.async(flags: [.barrier]) {
            if let timer = self.cleanupTimer,
                timer.isValid {
                timer.invalidate()
            }
            self.cleanupTimer = nil
            
            let remainingTimes = self.cachedIdentifiers()
                .flatMap(self.remainingLifeForImage)
                .sorted(by: >)
            
            guard let closestRemainingTime = remainingTimes.first(where: { $0 > 0 }) else {
                return
            }
            
            let fireDate = Date().addingTimeInterval(closestRemainingTime)
            
            self.cleanupTimer = Timer(fireAt: fireDate, interval: 0, target: self, selector: #selector(self.cleanup), userInfo: nil, repeats: false)
            RunLoop.main.add(self.cleanupTimer!, forMode: .commonModes)
        }
    }

    // MARK: Utility methods
    
    ///Returns the path for a resource having the specified identifier
    ///
    /// - warning: This method will not check the existence of the resource. It will simply compute the path for the specified identifier.
    /// - parameter identifier:  The identifier for the resource you want the path of.
    ///
    /// - returns: The path for the resource with the specified *identifier*.
    private func pathForResource(withIdentifier identifier: String) -> String {
        return pathForResource(withFileName: identifier.addingPercentEncoding(withAllowedCharacters: .letters)! + ".afcache")
    }
    
    ///Returns the path for a resource having the specified file name.
    ///
    /// - warning: This method will not check the existence of the resource. It will simply compute the path for the specified file name.
    /// - parameter fileName: The file name for the resource you want the path of.
    ///
    /// - returns: The path for the resource with the specified *fileName*.
    private func pathForResource(withFileName fileName: String) -> String {
        return (self.persistencePath as NSString).appendingPathComponent(fileName)
    }
    
    ///Returns all the file names for the cached images in the *persistencePath*.
    ///
    /// - returns: An array of file names for the cached files in the *persistencePath* folder. If there aren't cached files on disk then
    ///this method will return empty array.
    private func cachedFileNames() -> [String] {
        guard let files = try? fileManager.contentsOfDirectory(atPath: persistencePath).filter({ $0.hasSuffix(".afcache") }) else {
            return []
        }
        
        return files
    }
    
    ///Returns all the identifiers for the cached images in *persistencePath*.
    ///
    /// - returns: An array of identifiers for the cached files in the *persistencePath* folder. If there aren't cached files on disk then
    ///this method will return empty array.
    private func cachedIdentifiers() -> [String] {
        return cachedFileNames().map(identifierFromFileName)
    }
    
    ///Returns the identifier, extracted from the file name.
    ///
    /// - parameter fileName: The file name you want the identifier of.
    ///
    /// - returns: The identifier extracted from the specified file name.
    private func identifierFromFileName(_ fileName: String) -> String {
        return fileName.replacingOccurrences(of: ".afcache", with: "")
    }
}
