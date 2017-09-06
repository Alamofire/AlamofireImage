//
//  PersistentImageCacheTests.swift
//  AlamofireImage
//
//  Created by Giuseppe Lanza on 08/08/2017.
//  Copyright © 2017 Alamofire. All rights reserved.
//

@testable import AlamofireImage
import Foundation
import XCTest


class PersistentImageCacheTests: BaseTestCase {
    var cache: PersistentAutoPurgingImageCache!
    var cachePath: String!
    
    override func setUp() {
        super.setUp()
        cachePath = (NSTemporaryDirectory() as NSString).appendingPathComponent(String(format: "test%08x", arc4random()))
        try? FileManager.default.createDirectory(atPath: cachePath, withIntermediateDirectories: false, attributes: nil)
        
        cache = {
            return PersistentAutoPurgingImageCache(persistencePath: self.cachePath)
        }()
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(atPath: cachePath)
        super.tearDown()
    }
    
    func testThatItCanAddImageToCacheWithIdentifier() {
        let image = self.image(forResource: "unicorn", withExtension: "png")
        let identifier = "unicorn"
        
        let expectation1 = expectation(description: "image cache should succeed")

        cache.add(image, withIdentifier: identifier) {
            expectation1.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)

        let expectedImagePath = (cachePath as NSString).appendingPathComponent(identifier + ".afcache")
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedImagePath))
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: expectedImagePath)) else {
            XCTFail("data should not bbe nil")
            return
        }
        
        #if os(iOS) || os(tvOS) || os(watchOS)
            guard let cachedImage = UIImage(data: data, scale: image.scale) else {
                XCTFail("Image should not be nil")
                return
            }
        #elseif os(macOS)
            guard let cachedImage = NSImage(data: data) else {
                XCTFail("Image should not be nil")
                return
            }
        #endif
        
        XCTAssertEqual(cachedImage.size, image.size)
    }
    
    func testThatItCanAddImageToCacheWithRequestIdentifier() {
        let image = self.image(forResource: "unicorn", withExtension: "png")
        let request = try! URLRequest(url: "https://images.example.com/animals", method: .get)
        let identifier = "-unicorn"
        
        let expectation1 = expectation(description: "image cache should succeed")
        
        cache.add(image, for: request, withIdentifier: identifier) {
            expectation1.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)

        let expectedImagePath = (cachePath as NSString).appendingPathComponent(cache.imageCacheKey(for: request, withIdentifier: identifier).addingPercentEncoding(withAllowedCharacters: .letters)! + ".afcache")
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedImagePath))
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: expectedImagePath)) else {
            XCTFail("data should not bbe nil")
            return
        }
        
        #if os(iOS) || os(tvOS) || os(watchOS)
            guard let cachedImage = UIImage(data: data, scale: image.scale) else {
                XCTFail("Image should not be nil")
                return
            }
        #elseif os(macOS)
            guard let cachedImage = NSImage(data: data) else {
                XCTFail("Image should not be nil")
                return
            }
        #endif
        
        XCTAssertEqual(cachedImage.size, image.size)
    }
    
    func testThatAddedImagesHasCorrectExpirationDate() {
        let image = self.image(forResource: "unicorn", withExtension: "png")
        let identifier = "unicorn"
        
        let timeToLive: TimeInterval = 60

        let expectation1 = expectation(description: "image cache should succeed")
        
        cache.add(image, withIdentifier: identifier, andTimeToLive: timeToLive) {
            expectation1.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        let expectedExpiration = Date().addingTimeInterval(timeToLive).timeIntervalSince1970
        let path = (cachePath as NSString).appendingPathComponent(identifier + ".afcache")
        
        var expiration: TimeInterval = 0
        getxattr(path, "org.alamofire.persistentautopurgingimagecache-expiration", &expiration, MemoryLayout<TimeInterval>.size, 0, 0)
        
        XCTAssertEqualWithAccuracy(expectedExpiration, expiration, accuracy: 3)
    }
    
    func testThatAddedImagesHasCorrectRemainingTimeToLive() {
        let image = self.image(forResource: "unicorn", withExtension: "png")
        let identifier = "unicorn"
        
        let timeToLive: TimeInterval = 60
        
        let expectation1 = expectation(description: "image cache should succeed")
        
        cache.add(image, withIdentifier: identifier, andTimeToLive: timeToLive) {
            expectation1.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
        guard let remainingLife = cache.remainingLifeForImage(withIdentifier: identifier) else {
            XCTFail("Remaining life should not be nil")
            return
        }
        
        XCTAssertEqualWithAccuracy(timeToLive, remainingLife, accuracy: 3)
    }
    
    func testThatInexistingFilesReturnsNilTimeToLive() {
        let remainingLife = cache.remainingLifeForImage(withIdentifier: "unexisting")
        XCTAssertNil(remainingLife)
    }
    
    func testThatItCanFetchImageEvenIfNotInMemory() {
        let image = self.image(forResource: "unicorn", withExtension: "png")
        let identifier = "unicorn"
        
        let expectation1 = expectation(description: "image cache should succeed")
        
        cache.add(image, withIdentifier: identifier) {
            expectation1.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
        #if os(iOS) || os(tvOS)
            NotificationCenter.default.post(
                name: Notification.Name.UIApplicationDidReceiveMemoryWarning,
                object: nil
            )
        #elseif os(macOS)
            cache.removeAllImagesInMemory()
        #endif
        let cachedImage = cache.image(withIdentifier: identifier)
        
        XCTAssertNotNil(cachedImage)
        XCTAssertEqual(cachedImage?.size ?? .zero, image.size)
    }
    
    func testThatItCanRemoveCachedImges() {
        let image = self.image(forResource: "unicorn", withExtension: "png")
        let identifier = "unicorn"
        
        let expectation1 = expectation(description: "image cache should succeed")
        
        cache.add(image, withIdentifier: identifier) {
            expectation1.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)

        var cachedImage = cache.image(withIdentifier: identifier)
        XCTAssertNotNil(cachedImage)

        XCTAssertTrue(cache.removeImage(withIdentifier: identifier))
        
        cachedImage = cache.image(withIdentifier: identifier)
        XCTAssertNil(cachedImage)
    }
    
    func testRemovingUnexistingImages() {
        let identifier = "unexisting"
        XCTAssertFalse(cache.removeImage(withIdentifier: identifier))
    }
    
    func testThatItCanRemoveAllCahedImages() {
        let identifiers = ["apple", "rainbow", "pirate"]
        
        for identifier in identifiers {
            let image = self.image(forResource: identifier, withExtension: "jpg")

            let expectation1 = expectation(description: "image cache should succeed")
            
            cache.add(image, withIdentifier: identifier) {
                expectation1.fulfill()
            }
            
            waitForExpectations(timeout: timeout, handler: nil)
        }
        
        //Proove that the images exist
        for identifier in identifiers {
            XCTAssertNotNil(cache.image(withIdentifier: identifier))
        }
        
        XCTAssertTrue(cache.removeAllImages())
        
        //Prove that the images do not exist anymore
        for identifier in identifiers {
            XCTAssertNil(cache.image(withIdentifier: identifier))
        }
    }
    
    func testThatItCanCleanupExpiredImages() {
        let image = self.image(forResource: "unicorn", withExtension: "png")
        let identifier = "unicorn"
        
        let timeToLive: TimeInterval = -60
        
        let expectation1 = expectation(description: "image cache should succeed")
        
        cache.add(image, withIdentifier: identifier, andTimeToLive: timeToLive) {
            expectation1.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
        //Proove that the image exist
        XCTAssertNotNil(cache.image(withIdentifier: identifier))
        
        cache.cleanup()
        
        //Proove that the image does not exist anymore
        XCTAssertNil(cache.image(withIdentifier: identifier))
    }
    
    func testItCanCleanCacheAutomatically() {
        let image = self.image(forResource: "unicorn", withExtension: "png")
        let identifier = "unicorn"
        
        let timeToLive: TimeInterval = 5
        
        let expectation1 = expectation(description: "image cache should succeed")
        
        cache.add(image, withIdentifier: identifier, andTimeToLive: timeToLive) {
            expectation1.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
        //Proove that the image exist
        XCTAssertNotNil(cache.image(withIdentifier: identifier))
        
        let expectation2 = expectation(description: "cache should be cleaned")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + timeToLive + 1) {
            expectation2.fulfill()
        }
        
        waitForExpectations(timeout: 2 * timeToLive, handler: nil)

        //Proove that the image does not exist anymore
        XCTAssertNil(cache.image(withIdentifier: identifier))
    }
}
