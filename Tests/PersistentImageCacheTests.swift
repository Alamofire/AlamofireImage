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

        let expectedImagePath = (cachePath as NSString).appendingPathComponent(identifier)
        
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
        let path = (cachePath as NSString).appendingPathComponent(identifier)
        
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
        let remainingLife = cache.remainingLifeForImage(withIdentifier: "N/A")
        XCTAssertNil(remainingLife)
    }
}
