// UIImageTests.swift
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

import AlamofireImage
import Foundation
import UIKit
import XCTest

class UIImageTestCase: BaseTestCase {

    // MARK: - Properties

    var appleImage: UIImage { return imageForResource("apple", withExtension: "jpg") }
    var pirateImage: UIImage { return imageForResource("pirate", withExtension: "jpg") }
    var rainbowImage: UIImage { return imageForResource("rainbow", withExtension: "jpg") }
    var unicornImage: UIImage { return imageForResource("unicorn", withExtension: "png") }

    let scale = Int(round(UIScreen.mainScreen().scale))

    let squareSize = CGSize(width: 50, height: 50)
    let horizontalRectangularSize = CGSize(width: 60, height: 30)
    let verticalRectangularSize = CGSize(width: 30, height: 60)

    // MARK: - Initialization Tests

    func testThatHundredsOfLargeImagesCanBeInitializedAcrossMultipleThreads() {
        // Given
        let URL = URLForResource("huge_map", withExtension: "jpg")
        let data = NSData(contentsOfURL: URL)!

        let lock = NSLock()
        var images: [UIImage?] = []
        let totalIterations = 1_500

        // When
        for _ in 0..<totalIterations {
            let expectation = expectationWithDescription("image should be created successfully")

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                let image = UIImage(data: data)
                let imageWithScale = UIImage(data: data, scale: CGFloat(self.scale))

                lock.lock()
                images.append(image)
                images.append(imageWithScale)
                lock.unlock()

                expectation.fulfill()
            }
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        images.forEach {
            XCTAssertNotNil($0, "image should not be nil")
        }
    }

    func testThatHundredsOfLargeImagesCanBeInitializedAcrossMultipleThreadsWithThreadSafeInitializers() {
        // Given
        let URL = URLForResource("huge_map", withExtension: "jpg")
        let data = NSData(contentsOfURL: URL)!

        let lock = NSLock()
        var images: [UIImage?] = []
        let totalIterations = 1_500

        // When
        for _ in 0..<totalIterations {
            let expectation = expectationWithDescription("image should be created successfully")

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                let image = UIImage.af_threadSafeImageWithData(data)
                let imageWithScale = UIImage.af_threadSafeImageWithData(data, scale: CGFloat(self.scale))

                lock.lock()
                images.append(image)
                images.append(imageWithScale)
                lock.unlock()

                expectation.fulfill()
            }
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        images.forEach {
            XCTAssertNotNil($0, "image should not be nil")
        }
    }

    // MARK: - Inflation Tests

    func testThatImageCanBeInflated() {
        // Given
        let rainbowImage = imageForResource("rainbow", withExtension: "jpg")
        let unicornImage = imageForResource("unicorn", withExtension: "png")

        // When, Then
        rainbowImage.af_inflate()
        unicornImage.af_inflate()
    }

    func testThatImageThatHasAlreadyBeenInflatedIsNotInflatedAgain() {
        // Given
        let unicornImage = imageForResource("unicorn", withExtension: "png")
        unicornImage.af_inflate()

        // When, Then
        unicornImage.af_inflate()
    }

    // MARK: - Alpha Tests

    func testThatImageAlphaComponentPropertiesReturnExpectedValues() {
        // Given, When, Then
        XCTAssertTrue(appleImage.af_isOpaque)
        XCTAssertTrue(pirateImage.af_isOpaque)
        XCTAssertTrue(rainbowImage.af_isOpaque)
        XCTAssertFalse(unicornImage.af_isOpaque)

        XCTAssertFalse(appleImage.af_containsAlphaComponent)
        XCTAssertFalse(pirateImage.af_containsAlphaComponent)
        XCTAssertFalse(rainbowImage.af_containsAlphaComponent)
        XCTAssertTrue(unicornImage.af_containsAlphaComponent)
    }

    // MARK: - Scaling Tests

    func testThatImageIsScaledToSquareSize() {
        executeImageScaledToSizeTest(squareSize)
    }

    func testThatImageIsScaledToHorizontalRectangularSize() {
        executeImageScaledToSizeTest(horizontalRectangularSize)
    }

    func testThatImageIsScaledToVerticalRectangularSize() {
        executeImageScaledToSizeTest(verticalRectangularSize)
    }

    private func executeImageScaledToSizeTest(size: CGSize) {
        // Given
        let w = Int(round(size.width))
        let h = Int(round(size.height))

        // When
        let scaledAppleImage = appleImage.af_imageScaledToSize(size)
        let scaledPirateImage = pirateImage.af_imageScaledToSize(size)
        let scaledRainbowImage = rainbowImage.af_imageScaledToSize(size)
        let scaledUnicornImage = unicornImage.af_imageScaledToSize(size)

        // Then
        let expectedAppleImage = imageForResource("apple-scaled-\(w)x\(h)-@\(scale)x", withExtension: "png")
        let expectedPirateImage = imageForResource("pirate-scaled-\(w)x\(h)-@\(scale)x", withExtension: "png")
        let expectedRainbowImage = imageForResource("rainbow-scaled-\(w)x\(h)-@\(scale)x", withExtension: "png")
        let expectedUnicornImage = imageForResource("unicorn-scaled-\(w)x\(h)-@\(scale)x", withExtension: "png")

        XCTAssertTrue(scaledAppleImage.af_isEqualToImage(expectedAppleImage), "scaled apple image pixels do not match")
        XCTAssertTrue(scaledPirateImage.af_isEqualToImage(expectedPirateImage), "scaled pirate image pixels do not match")
        XCTAssertTrue(scaledRainbowImage.af_isEqualToImage(expectedRainbowImage), "scaled rainbow image pixels do not match")
        XCTAssertTrue(scaledUnicornImage.af_isEqualToImage(expectedUnicornImage), "scaled unicorn image pixels do not match")

        XCTAssertEqual(scaledAppleImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
        XCTAssertEqual(scaledPirateImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
        XCTAssertEqual(scaledRainbowImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
        XCTAssertEqual(scaledUnicornImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
    }

    func testThatImageIsAspectScaledToFitSquareSize() {
        executeImageAspectScaledToFitSizeTest(squareSize)
    }

    func testThatImageIsAspectScaledToFitHorizontalRectangularSize() {
        executeImageAspectScaledToFitSizeTest(horizontalRectangularSize)
    }

    func testThatImageIsAspectScaledToFitVerticalRectangularSize() {
        executeImageAspectScaledToFitSizeTest(verticalRectangularSize)
    }

    private func executeImageAspectScaledToFitSizeTest(size: CGSize) {
        // Given
        let w = Int(round(size.width))
        let h = Int(round(size.height))

        // When
        let scaledAppleImage = appleImage.af_imageAspectScaledToFitSize(size)
        let scaledPirateImage = pirateImage.af_imageAspectScaledToFitSize(size)
        let scaledRainbowImage = rainbowImage.af_imageAspectScaledToFitSize(size)
        let scaledUnicornImage = unicornImage.af_imageAspectScaledToFitSize(size)

        // Then
        let expectedAppleImage = imageForResource("apple-aspect.scaled.to.fit-\(w)x\(h)-@\(scale)x", withExtension: "png")
        let expectedPirateImage = imageForResource("pirate-aspect.scaled.to.fit-\(w)x\(h)-@\(scale)x", withExtension: "png")
        let expectedRainbowImage = imageForResource("rainbow-aspect.scaled.to.fit-\(w)x\(h)-@\(scale)x", withExtension: "png")
        let expectedUnicornImage = imageForResource("unicorn-aspect.scaled.to.fit-\(w)x\(h)-@\(scale)x", withExtension: "png")

        XCTAssertTrue(scaledAppleImage.af_isEqualToImage(expectedAppleImage, withinTolerance: 4), "scaled apple image pixels do not match")
        XCTAssertTrue(scaledPirateImage.af_isEqualToImage(expectedPirateImage), "scaled pirate image pixels do not match")
        XCTAssertTrue(scaledRainbowImage.af_isEqualToImage(expectedRainbowImage, withinTolerance: 5), "scaled rainbow image pixels do not match")
        XCTAssertTrue(scaledUnicornImage.af_isEqualToImage(expectedUnicornImage, withinTolerance: 26), "scaled unicorn image pixels do not match")

        XCTAssertEqual(scaledAppleImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
        XCTAssertEqual(scaledPirateImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
        XCTAssertEqual(scaledRainbowImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
        XCTAssertEqual(scaledUnicornImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
    }

    func testThatImageIsAspectScaledToFillSquareSize() {
        executeImageAspectScaledToFillSizeTest(squareSize)
    }

    func testThatImageIsAspectScaledToFillHorizontalRectangularSize() {
        executeImageAspectScaledToFillSizeTest(horizontalRectangularSize)
    }

    func testThatImageIsAspectScaledToFillVerticalRectangularSize() {
        executeImageAspectScaledToFillSizeTest(verticalRectangularSize)
    }

    private func executeImageAspectScaledToFillSizeTest(size: CGSize) {
        // Given
        let w = Int(round(size.width))
        let h = Int(round(size.height))

        // When
        let scaledAppleImage = appleImage.af_imageAspectScaledToFillSize(size)
        let scaledPirateImage = pirateImage.af_imageAspectScaledToFillSize(size)
        let scaledRainbowImage = rainbowImage.af_imageAspectScaledToFillSize(size)
        let scaledUnicornImage = unicornImage.af_imageAspectScaledToFillSize(size)

        // Then
        let expectedAppleImage = imageForResource("apple-aspect.scaled.to.fill-\(w)x\(h)-@\(scale)x", withExtension: "png")
        let expectedPirateImage = imageForResource("pirate-aspect.scaled.to.fill-\(w)x\(h)-@\(scale)x", withExtension: "png")
        let expectedRainbowImage = imageForResource("rainbow-aspect.scaled.to.fill-\(w)x\(h)-@\(scale)x", withExtension: "png")
        let expectedUnicornImage = imageForResource("unicorn-aspect.scaled.to.fill-\(w)x\(h)-@\(scale)x", withExtension: "png")

        XCTAssertTrue(scaledAppleImage.af_isEqualToImage(expectedAppleImage), "scaled apple image pixels do not match")
        XCTAssertTrue(scaledPirateImage.af_isEqualToImage(expectedPirateImage), "scaled pirate image pixels do not match")
        XCTAssertTrue(scaledRainbowImage.af_isEqualToImage(expectedRainbowImage), "scaled rainbow image pixels do not match")
        XCTAssertTrue(scaledUnicornImage.af_isEqualToImage(expectedUnicornImage), "scaled unicorn image pixels do not match")

        XCTAssertEqual(scaledAppleImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
        XCTAssertEqual(scaledPirateImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
        XCTAssertEqual(scaledRainbowImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
        XCTAssertEqual(scaledUnicornImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
    }

    // MARK: - Rounded Corners

    func testThatImageCornersAreRoundedToRadius() {
        // Given
        let radius: CGFloat = 20
        let r = Int(round(radius))

        // When
        let roundedAppleImage = appleImage.af_imageWithRoundedCornerRadius(radius, divideRadiusByImageScale: true)
        let roundedPirateImage = pirateImage.af_imageWithRoundedCornerRadius(radius, divideRadiusByImageScale: true)
        let roundedRainbowImage = rainbowImage.af_imageWithRoundedCornerRadius(radius, divideRadiusByImageScale: true)
        let roundedUnicornImage = unicornImage.af_imageWithRoundedCornerRadius(radius, divideRadiusByImageScale: true)

        // Then
        let expectedAppleImage = imageForResource("apple-radius-\(r)", withExtension: "png")
        let expectedPirateImage = imageForResource("pirate-radius-\(r)", withExtension: "png")
        let expectedRainbowImage = imageForResource("rainbow-radius-\(r)", withExtension: "png")
        let expectedUnicornImage = imageForResource("unicorn-radius-\(r)", withExtension: "png")

        XCTAssertTrue(roundedAppleImage.af_isEqualToImage(expectedAppleImage), "rounded apple image pixels do not match")
        XCTAssertTrue(roundedPirateImage.af_isEqualToImage(expectedPirateImage), "rounded pirate image pixels do not match")
        XCTAssertTrue(roundedRainbowImage.af_isEqualToImage(expectedRainbowImage), "rounded rainbow image pixels do not match")
        XCTAssertTrue(roundedUnicornImage.af_isEqualToImage(expectedUnicornImage), "rounded unicorn image pixels do not match")

        XCTAssertEqual(roundedAppleImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
        XCTAssertEqual(roundedPirateImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
        XCTAssertEqual(roundedRainbowImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
        XCTAssertEqual(roundedUnicornImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
    }

    func testThatImageIsRoundedIntoCircle() {
        // Given, When
        let circularAppleImage = appleImage.af_imageRoundedIntoCircle()
        let circularPirateImage = pirateImage.af_imageRoundedIntoCircle()
        let circularRainbowImage = rainbowImage.af_imageRoundedIntoCircle()
        let circularUnicornImage = unicornImage.af_imageRoundedIntoCircle()

        // Then
        let expectedAppleImage = imageForResource("apple-circle", withExtension: "png")
        let expectedPirateImage = imageForResource("pirate-circle", withExtension: "png")
        let expectedRainbowImage = imageForResource("rainbow-circle", withExtension: "png")
        let expectedUnicornImage = imageForResource("unicorn-circle", withExtension: "png")

        XCTAssertTrue(circularAppleImage.af_isEqualToImage(expectedAppleImage), "rounded apple image pixels do not match")
        XCTAssertTrue(circularPirateImage.af_isEqualToImage(expectedPirateImage), "rounded pirate image pixels do not match")
        XCTAssertTrue(circularRainbowImage.af_isEqualToImage(expectedRainbowImage), "rounded rainbow image pixels do not match")
        XCTAssertTrue(circularUnicornImage.af_isEqualToImage(expectedUnicornImage), "rounded unicorn image pixels do not match")

        XCTAssertEqual(circularAppleImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
        XCTAssertEqual(circularPirateImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
        XCTAssertEqual(circularRainbowImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
        XCTAssertEqual(circularUnicornImage.scale, CGFloat(scale), "image scale should be equal to screen scale")

        let expectedAppleSize = expectedImageSizeForCircularImage(circularAppleImage)
        let expectedPirateSize = expectedImageSizeForCircularImage(circularPirateImage)
        let expectedRainbowSize = expectedImageSizeForCircularImage(circularRainbowImage)
        let expectedUnicornSize = expectedImageSizeForCircularImage(circularUnicornImage)

        XCTAssertEqual(circularAppleImage.size, expectedAppleSize, "image scale should be equal to screen scale")
        XCTAssertEqual(circularPirateImage.size, expectedPirateSize, "image scale should be equal to screen scale")
        XCTAssertEqual(circularRainbowImage.size, expectedRainbowSize, "image scale should be equal to screen scale")
        XCTAssertEqual(circularUnicornImage.size, expectedUnicornSize, "image scale should be equal to screen scale")
    }

    private func expectedImageSizeForCircularImage(image: UIImage) -> CGSize {
        let dimension = min(image.size.width, image.size.height)
        return CGSize(width: dimension, height: dimension)
    }

    // MARK: - Core Image Filters

    func testThatImageWithAppliedGaussianBlurFilterReturnsBlurredImage() {
        // Given
        let parameters: [String: AnyObject] = ["inputRadius": 8]

        // When
        let blurredImage = unicornImage.af_imageWithAppliedCoreImageFilter("CIGaussianBlur", filterParameters: parameters)

        // Then
        if let blurredImage = blurredImage {
            let expectedBlurredImage: UIImage

            if #available(iOS 9.0, *) {
                expectedBlurredImage = imageForResource("unicorn-blurred-8-ios-9", withExtension: "png")
            } else if #available(iOS 8.3, *) {
                expectedBlurredImage = imageForResource("unicorn-blurred-8-ios-8.3", withExtension: "png")
            } else {
                expectedBlurredImage = imageForResource("unicorn-blurred-8-ios-8.1", withExtension: "png")
            }

            let pixelsMatch = blurredImage.af_isEqualToImage(expectedBlurredImage)

            XCTAssertTrue(pixelsMatch, "pixels match should be true")
        } else {
            XCTFail("blurred image should not be nil")
        }
    }

    func testThatImageWithAppliedSepiaToneFilterReturnsSepiaImage() {
        // Given, When
        let sepiaImage = unicornImage.af_imageWithAppliedCoreImageFilter("CISepiaTone")

        // Then
        if let sepiaImage = sepiaImage {
            let expectedSepiaImage = imageForResource("unicorn-sepia.tone", withExtension: "png")
            XCTAssertTrue(sepiaImage.af_isEqualToImage(expectedSepiaImage), "sepia image pixels do not match")
        } else {
            XCTFail("sepia image should not be nil")
        }
    }

    func testThatInvalidCoreImageFilterReturnsNil() {
        // Given
        let filterName = "SomeFilterThatDoesNotExist"

        // When
        let filteredImage = unicornImage.af_imageWithAppliedCoreImageFilter(filterName)

        // Then
        XCTAssertNil(filteredImage, "filtered image should be nil")
    }
}
