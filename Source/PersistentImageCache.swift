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

public protocol PersistentImageCache: ImageCache {
    var defaultTimeToLive: TimeInterval { get set }
    
    func remainingLifeForImage(withIdentifier identifier: String) -> TimeInterval?
    
    func add(_ image: Image, withIdentifier identifier: String, andTimeToLive timeToLive: TimeInterval)
    func add(_ image: Image, withIdentifier identifier: String, andTimeToLive timeToLive: TimeInterval,  withCompletion completion: @escaping ()->())
}

open class PersistentAutoPurgingImageCache: AutoPurgingImageCache, PersistentImageCache {
    public var defaultTimeToLive: TimeInterval
    
    private let synchronizationQueue: DispatchQueue
    private let fileManager = FileManager()
    
    private let persistencePath: String
    
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
    }
    
    public func remainingLifeForImage(withIdentifier identifier: String) -> TimeInterval? {
        let path = self.pathForResource(withIdentifier: identifier)
        guard fileManager.fileExists(atPath: path) else { return nil }
        
        var expiration: TimeInterval = 0
        getxattr(path, "org.alamofire.persistentautopurgingimagecache-expiration", &expiration, MemoryLayout<TimeInterval>.size, 0, 0)
        
        return expiration - NSDate().timeIntervalSince1970
    }
    
    open override func add(_ image: Image, withIdentifier identifier: String) {
        self.add(image, withIdentifier: identifier, andTimeToLive: defaultTimeToLive)
    }
    
    open override func add(_ image: Image, withIdentifier identifier: String, andCompletion completion: @escaping () -> ()) {
        self.add(image, withIdentifier: identifier, andTimeToLive: defaultTimeToLive, withCompletion: completion)
    }
    
    open func add(_ image: Image, withIdentifier identifier: String, andTimeToLive timeToLive: TimeInterval) {
        self.add(image, withIdentifier: identifier, andTimeToLive: timeToLive, withCompletion: ({ }))
    }
    
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
                    let data = rep.representation(using: .PNG, properties: [NSImageCompressionFactor: 1.0]) as NSData? else {
                    return
                }
            #endif
            
            try? data.write(toFile: path, options: .atomic)
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

    private func pathForResource(withIdentifier identifier: String) -> String {
        return (self.persistencePath as NSString).appendingPathComponent(identifier)
    }
}
