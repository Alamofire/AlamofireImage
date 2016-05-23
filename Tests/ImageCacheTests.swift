// ImageCacheTests.swift
//
// Copyright (c) 2015-2016 Alamofire Software Foundation (http://alamofire.org/)
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

@testable import Alamofire
@testable import AlamofireImage
import Foundation
import XCTest

class ImageCacheTestCase: BaseTestCase {
    var cache: AutoPurgingImageCache!

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()

        cache = {
            let memoryCapacity: UInt64 = 100 * 1024 * 1024 // 10 MB
            let preferredSizeAfterPurge: UInt64 = 60 * 1024 * 1024 // 4 MB

            return AutoPurgingImageCache(
                memoryCapacity: memoryCapacity,
                preferredMemoryUsageAfterPurge: preferredSizeAfterPurge
            )
        }()
    }

    // MARK: - Initialization Tests

    func testThatCacheCanBeInitializedAndDeinitialized() {
        // Given
        var cache: AutoPurgingImageCache? = AutoPurgingImageCache()

        // When
        cache = nil

        // Then
        XCTAssertNil(cache, "cache should be nil after deinit")
    }

    // MARK: - Add Image Tests

    func testThatItCanAddImageToCacheWithIdentifier() {
        // Given
        let image = imageForResource("unicorn", withExtension: "png")
        let identifier = "unicorn"

        // When
        cache.addImage(image, withIdentifier: identifier)
        let cachedImage = cache.imageWithIdentifier(identifier)

        // Then
        XCTAssertNotNil(cachedImage, "cached image should not be nil")
        XCTAssertEqual(cachedImage, image, "cached image should be equal to image")
    }

    func testThatItCanAddImageToCacheWithRequestIdentifier() {
        // Given
        let image = imageForResource("unicorn", withExtension: "png")
        let request = URLRequest(.GET, "https://images.example.com/animals")
        let identifier = "-unicorn"

        // When
        cache.addImage(image, forRequest: request, withAdditionalIdentifier: identifier)
        let cachedImage = cache.imageForRequest(request, withAdditionalIdentifier: identifier)

        // Then
        XCTAssertNotNil(cachedImage, "cached image should not be nil")
        XCTAssertEqual(cachedImage, image, "cached image should be equal to image")
    }

    func testThatAddingImageToCacheWithDuplicateIdentifierReplacesCachedImage() {
        // Given
        let unicornImage = imageForResource("unicorn", withExtension: "png")
        let pirateImage = imageForResource("pirate", withExtension: "jpg")
        let identifier = "animal"

        // When
        cache.addImage(unicornImage, withIdentifier: identifier)
        let cachedImage1 = cache.imageWithIdentifier(identifier)

        cache.addImage(pirateImage, withIdentifier: identifier)
        let cachedImage2 = cache.imageWithIdentifier(identifier)

        // Then
        XCTAssertNotNil(cachedImage1, "cached image 1 should not be nil")
        XCTAssertNotNil(cachedImage2, "cached image 2 should not be nil")

        XCTAssertEqual(cachedImage1, unicornImage, "cached image 1 should be equal to unicorn image")
        XCTAssertEqual(cachedImage2, pirateImage, "cached image 2 should be equal to pirate image")
        XCTAssertNotEqual(cachedImage1, cachedImage2, "cached image 1 should not be equal to cached image 2")
    }

    func testThatAddingImageToCacheWithDuplicateRequestIdentifierReplacesCachedImage() {
        // Given
        let unicornImage = imageForResource("unicorn", withExtension: "png")
        let pirateImage = imageForResource("pirate", withExtension: "jpg")
        let request = URLRequest(.GET, "https://images.example.com/animals")
        let identifier = "animal"

        // When
        cache.addImage(unicornImage, forRequest: request, withAdditionalIdentifier: identifier)
        let cachedImage1 = cache.imageForRequest(request, withAdditionalIdentifier: identifier)

        cache.addImage(pirateImage, forRequest: request, withAdditionalIdentifier: identifier)
        let cachedImage2 = cache.imageForRequest(request, withAdditionalIdentifier: identifier)

        // Then
        XCTAssertNotNil(cachedImage1, "cached image 1 should not be nil")
        XCTAssertNotNil(cachedImage2, "cached image 2 should not be nil")

        XCTAssertEqual(cachedImage1, unicornImage, "cached image 1 should be equal to unicorn image")
        XCTAssertEqual(cachedImage2, pirateImage, "cached image 2 should be equal to pirate image")
        XCTAssertNotEqual(cachedImage1, cachedImage2, "cached image 1 should not be equal to cached image 2")
    }

    // MARK: - Remove Image Tests

    func testThatItCanRemoveImageFromCacheWithIdentifier() {
        // Given
        let image = imageForResource("unicorn", withExtension: "png")
        let identifier = "unicorn"

        // When
        cache.addImage(image, withIdentifier: identifier)
        let cachedImageExists = cache.imageWithIdentifier(identifier) != nil

        cache.removeImageWithIdentifier(identifier)
        let cachedImageExistsAfterRemoval = cache.imageWithIdentifier(identifier) != nil

        // Then
        XCTAssertTrue(cachedImageExists, "cached image exists should be true")
        XCTAssertFalse(cachedImageExistsAfterRemoval, "cached image exists after removal should be false")
    }

    func testThatItCanRemoveImageFromCacheWithRequestIdentifier() {
        // Given
        let image = imageForResource("unicorn", withExtension: "png")
        let request = URLRequest(.GET, "https://images.example.com/animals")
        let identifier = "unicorn"

        // When
        cache.addImage(image, forRequest: request, withAdditionalIdentifier: identifier)
        let cachedImageExists = cache.imageForRequest(request, withAdditionalIdentifier: identifier) != nil

        cache.removeImageForRequest(request, withAdditionalIdentifier: identifier)
        let cachedImageExistsAfterRemoval = cache.imageForRequest(request, withAdditionalIdentifier: identifier) != nil

        // Then
        XCTAssertTrue(cachedImageExists, "cached image exists should be true")
        XCTAssertFalse(cachedImageExistsAfterRemoval, "cached image exists after removal should be false")
    }

    func testThatItCanRemoveAllImagesFromCache() {
        // Given
        let image = imageForResource("unicorn", withExtension: "png")
        let identifier = "unicorn"

        // When
        cache.addImage(image, withIdentifier: identifier)
        let cachedImageExists = cache.imageWithIdentifier(identifier) != nil

        cache.removeAllImages()
        let cachedImageExistsAfterRemoval = cache.imageWithIdentifier(identifier) != nil

        // Then
        XCTAssertTrue(cachedImageExists, "cached image exists should be true")
        XCTAssertFalse(cachedImageExistsAfterRemoval, "cached image exists after removal should be false")
    }

#if os(iOS) || os(tvOS)

    func testThatItRemovesAllImagesFromCacheWhenReceivingMemoryWarningNotification() {
        // Given
        let image = imageForResource("unicorn", withExtension: "png")
        let identifier = "unicorn"

        // When
        cache.addImage(image, withIdentifier: identifier)
        let cachedImageExists = cache.imageWithIdentifier(identifier) != nil

        NSNotificationCenter.defaultCenter().postNotificationName(
            UIApplicationDidReceiveMemoryWarningNotification,
            object: nil
        )

        let cachedImageExistsAfterNotification = cache.imageWithIdentifier(identifier) != nil

        // Then
        XCTAssertTrue(cachedImageExists, "cached image exists should be true")
        XCTAssertFalse(cachedImageExistsAfterNotification, "cached image exists after notification should be false")
    }

#endif

    // MARK: - Fetch Image Tests

    func testThatItCanFetchImageFromCacheWithIdentifier() {
        // Given
        let image = imageForResource("unicorn", withExtension: "png")
        let identifier = "unicorn"

        // When
        let cachedImageBeforeAdd = cache.imageWithIdentifier(identifier)
        cache.addImage(image, withIdentifier: identifier)
        let cachedImageAfterAdd = cache.imageWithIdentifier(identifier)

        // Then
        XCTAssertNil(cachedImageBeforeAdd, "cached image before add should be nil")
        XCTAssertNotNil(cachedImageAfterAdd, "cached image after add should not be nil")
    }

    func testThatItCanFetchImageFromCacheWithRequestIdentifier() {
        // Given
        let image = imageForResource("unicorn", withExtension: "png")
        let request = URLRequest(.GET, "https://images.example.com/animals")
        let identifier = "unicorn"

        // When
        let cachedImageBeforeAdd = cache.imageForRequest(request, withAdditionalIdentifier: identifier)
        cache.addImage(image, forRequest: request, withAdditionalIdentifier: identifier)
        let cachedImageAfterAdd = cache.imageForRequest(request, withAdditionalIdentifier: identifier)

        // Then
        XCTAssertNil(cachedImageBeforeAdd, "cached image before add should be nil")
        XCTAssertNotNil(cachedImageAfterAdd, "cached image after add should not be nil")
    }

    // MARK: - Memory Usage Tests

    func testThatItIncrementsMemoryUsageWhenAddingImageToCache() {
        // Given
        let image = imageForResource("unicorn", withExtension: "png")
        let identifier = "unicorn"

        // When
        let initialMemoryUsage = cache.memoryUsage
        cache.addImage(image, withIdentifier: identifier)
        let currentMemoryUsage = cache.memoryUsage

        // Then
        XCTAssertEqual(initialMemoryUsage, 0, "initial memory usage should be 0")
        XCTAssertEqual(currentMemoryUsage, 164000, "current memory usage should be 164000")
    }

    func testThatItDecrementsMemoryUsageWhenRemovingImageFromCache() {
        // Given
        let image = imageForResource("unicorn", withExtension: "png")
        let identifier = "unicorn"

        // When
        cache.addImage(image, withIdentifier: identifier)
        let initialMemoryUsage = cache.memoryUsage
        cache.removeImageWithIdentifier(identifier)
        let currentMemoryUsage = cache.memoryUsage

        // Then
        XCTAssertEqual(initialMemoryUsage, 164000, "initial memory usage should be 164000")
        XCTAssertEqual(currentMemoryUsage, 0, "current memory usage should be 0")
    }

    func testThatItDecrementsMemoryUsageWhenRemovingAllImagesFromCache() {
        // Given
        let image = imageForResource("unicorn", withExtension: "png")
        let identifier = "unicorn"

        // When
        cache.addImage(image, withIdentifier: identifier)
        let initialMemoryUsage = cache.memoryUsage
        cache.removeAllImages()
        let currentMemoryUsage = cache.memoryUsage

        // Then
        XCTAssertEqual(initialMemoryUsage, 164000, "initial memory usage should be 164000")
        XCTAssertEqual(currentMemoryUsage, 0, "current memory usage should be 0")
    }

    // MARK: - Purging Tests

    func testThatItPurgesImagesWhenMemoryCapacityIsReached() {
        // Given
        let image = imageForResource("unicorn", withExtension: "png")
        let identifier = "unicorn"

        var memoryUsage: [UInt64] = []

        // When
        for index in 1...640 {
            cache.addImage(image, withIdentifier: "\(identifier)-\(index)")
            memoryUsage.append(cache.memoryUsage)
        }

        memoryUsage = Array(memoryUsage.dropFirst(638))

        // Then
        XCTAssertEqual(memoryUsage[0], 104796000, "memory usage prior to purge does not match expected value")
        XCTAssertEqual(memoryUsage[1], 62812000, "memory usage after purge does not match expected value")
    }

    func testThatItPrioritizesImagesWithOldestLastAccessDatesDuringPurge() {
        // Given
        let image = imageForResource("unicorn", withExtension: "png")
        let identifier = "unicorn"

        // When
        for index in 1...640 {
            cache.addImage(image, withIdentifier: "\(identifier)-\(index)")
        }

        // Then
        for index in 1...257 {
            let cachedImage = cache.imageWithIdentifier("\(identifier)-\(index)")
            XCTAssertNil(cachedImage, "cached image with identifier: \"\(identifier)-\(index)\" should be nil")
        }

        for index in 258...640 {
            let cachedImage = cache.imageWithIdentifier("\(identifier)-\(index)")
            XCTAssertNotNil(cachedImage, "cached image with identifier: \"\(identifier)-\(index)\" should not be nil")
        }
    }

    func testThatAccessingCachedImageUpdatesLastAccessDate() {
        // Given
        let image = imageForResource("unicorn", withExtension: "png")
        let identifier = "unicorn"

        // When
        for index in 1...639 {
            cache.addImage(image, withIdentifier: "\(identifier)-\(index)")
        }

        cache.imageWithIdentifier("\(identifier)-1")
        cache.addImage(image, withIdentifier: "\(identifier)-640")

        // Then
        let firstCachedImage = cache.imageWithIdentifier("\(identifier)-1")
        XCTAssertNotNil(firstCachedImage, "first cached image should not be nil")

        for index in 2...258 {
            let cachedImage = cache.imageWithIdentifier("\(identifier)-\(index)")
            XCTAssertNil(cachedImage, "cached image with identifier: \"\(identifier)-\(index)\" should be nil")
        }

        for index in 259...640 {
            let cachedImage = cache.imageWithIdentifier("\(identifier)-\(index)")
            XCTAssertNotNil(cachedImage, "cached image with identifier: \"\(identifier)-\(index)\" should not be nil")
        }
    }
}
