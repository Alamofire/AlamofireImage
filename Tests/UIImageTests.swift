//
//  UIImageTests.swift
//
//  Copyright (c) 2015-2017 Alamofire Software Foundation (http://alamofire.org/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#if !os(macOS)

import AlamofireImage
import Foundation
import UIKit
import XCTest

class UIImageTestCase: BaseTestCase {

    // MARK: - Properties

    var appleImage: UIImage { return image(forResource: "apple", withExtension: "jpg") }
    var pirateImage: UIImage { return image(forResource: "pirate", withExtension: "jpg") }
    var rainbowImage: UIImage { return image(forResource: "rainbow", withExtension: "jpg") }
    var unicornImage: UIImage { return image(forResource: "unicorn", withExtension: "png") }

    let scale = Int(UIScreen.main.scale.rounded())

    let squareSize = CGSize(width: 50, height: 50)
    let horizontalRectangularSize = CGSize(width: 60, height: 30)
    let verticalRectangularSize = CGSize(width: 30, height: 60)

    // MARK: - Initialization Tests

    func testThatHundredsOfLargeImagesCanBeInitializedAcrossMultipleThreads() {
        // Given
        let url = self.url(forResource: "huge_map", withExtension: "jpg")
        let data = try! Data(contentsOf: url)

        let lock = NSLock()
        var images: [UIImage?] = []
        let totalIterations = 200

        // When
        for _ in 0..<totalIterations {
            let expectation = self.expectation(description: "image should be created successfully")

            DispatchQueue.global(qos: .utility).async {
                let image = UIImage(data: data)
                let imageWithScale = UIImage(data: data, scale: CGFloat(self.scale))

                lock.lock()
                images.append(image)
                images.append(imageWithScale)
                lock.unlock()

                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        images.forEach { XCTAssertNotNil($0, "image should not be nil") }
    }

    func testThatHundredsOfLargeImagesCanBeInitializedAcrossMultipleThreadsWithThreadSafeInitializers() {
        // Given
        let url = self.url(forResource: "huge_map", withExtension: "jpg")
        let data = try! Data(contentsOf: url)

        let lock = NSLock()
        var images: [UIImage?] = []
        let totalIterations = 200

        // When
        for _ in 0..<totalIterations {
            let expectation = self.expectation(description: "image should be created successfully")

            DispatchQueue.global(qos: .utility).async {
                let image = UIImage.af_threadSafeImage(with: data)
                let imageWithScale = UIImage.af_threadSafeImage(with: data, scale: CGFloat(self.scale))

                lock.lock()
                images.append(image)
                images.append(imageWithScale)
                lock.unlock()

                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        images.forEach { XCTAssertNotNil($0, "image should not be nil") }
    }

    // MARK: - Inflation Tests

    func testThatImageCanBeInflated() {
        // Given
        let rainbowImage = image(forResource: "rainbow", withExtension: "jpg")
        let unicornImage = image(forResource: "unicorn", withExtension: "png")

        // When, Then
        rainbowImage.af_inflate()
        unicornImage.af_inflate()
    }

    func testThatImageThatHasAlreadyBeenInflatedIsNotInflatedAgain() {
        // Given
        let unicornImage = image(forResource: "unicorn", withExtension: "png")
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

    private func executeImageScaledToSizeTest(_ size: CGSize) {
        // Given
        let w = Int(size.width.rounded())
        let h = Int(size.height.rounded())

        // When
        let scaledAppleImage = appleImage.af_imageScaled(to: size)
        let scaledPirateImage = pirateImage.af_imageScaled(to: size)
        let scaledRainbowImage = rainbowImage.af_imageScaled(to: size)
        let scaledUnicornImage = unicornImage.af_imageScaled(to: size)

        // Then
        let expectedAppleImage = image(forResource: "apple-scaled-\(w)x\(h)-@\(scale)x", withExtension: "png")
        let expectedPirateImage = image(forResource: "pirate-scaled-\(w)x\(h)-@\(scale)x", withExtension: "png")
        let expectedRainbowImage = image(forResource: "rainbow-scaled-\(w)x\(h)-@\(scale)x", withExtension: "png")
        let expectedUnicornImage = image(forResource: "unicorn-scaled-\(w)x\(h)-@\(scale)x", withExtension: "png")

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

    private func executeImageAspectScaledToFitSizeTest(_ size: CGSize) {
        // Given
        let w = Int(size.width.rounded())
        let h = Int(size.height.rounded())

        // When
        let scaledAppleImage = appleImage.af_imageAspectScaled(toFit: size)
        let scaledPirateImage = pirateImage.af_imageAspectScaled(toFit: size)
        let scaledRainbowImage = rainbowImage.af_imageAspectScaled(toFit: size)
        let scaledUnicornImage = unicornImage.af_imageAspectScaled(toFit: size)

        // Then
        let expectedAppleImage = image(forResource: "apple-aspect.scaled.to.fit-\(w)x\(h)-@\(scale)x", withExtension: "png")
        let expectedPirateImage = image(forResource: "pirate-aspect.scaled.to.fit-\(w)x\(h)-@\(scale)x", withExtension: "png")
        let expectedRainbowImage = image(forResource: "rainbow-aspect.scaled.to.fit-\(w)x\(h)-@\(scale)x", withExtension: "png")
        let expectedUnicornImage = image(forResource: "unicorn-aspect.scaled.to.fit-\(w)x\(h)-@\(scale)x", withExtension: "png")

        XCTAssertTrue(scaledAppleImage.af_isEqualToImage(expectedAppleImage, withinTolerance: 4), "scaled apple image pixels do not match")
        XCTAssertTrue(scaledPirateImage.af_isEqualToImage(expectedPirateImage), "scaled pirate image pixels do not match")
        XCTAssertTrue(scaledRainbowImage.af_isEqualToImage(expectedRainbowImage, withinTolerance: 46), "scaled rainbow image pixels do not match")
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

    private func executeImageAspectScaledToFillSizeTest(_ size: CGSize) {
        // Given
        let w = Int(size.width.rounded())
        let h = Int(size.height.rounded())

        // When
        let scaledAppleImage = appleImage.af_imageAspectScaled(toFill: size)
        let scaledPirateImage = pirateImage.af_imageAspectScaled(toFill: size)
        let scaledRainbowImage = rainbowImage.af_imageAspectScaled(toFill: size)
        let scaledUnicornImage = unicornImage.af_imageAspectScaled(toFill: size)

        // Then
        let expectedAppleImage = image(forResource: "apple-aspect.scaled.to.fill-\(w)x\(h)-@\(scale)x", withExtension: "png")
        let expectedPirateImage = image(forResource: "pirate-aspect.scaled.to.fill-\(w)x\(h)-@\(scale)x", withExtension: "png")
        let expectedRainbowImage = image(forResource: "rainbow-aspect.scaled.to.fill-\(w)x\(h)-@\(scale)x", withExtension: "png")
        let expectedUnicornImage = image(forResource: "unicorn-aspect.scaled.to.fill-\(w)x\(h)-@\(scale)x", withExtension: "png")

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
        let r = Int(radius.rounded())

        // When
        let roundedAppleImage = appleImage.af_imageRounded(withCornerRadius: radius, divideRadiusByImageScale: true)
        let roundedPirateImage = pirateImage.af_imageRounded(withCornerRadius: radius, divideRadiusByImageScale: true)
        let roundedRainbowImage = rainbowImage.af_imageRounded(withCornerRadius: radius, divideRadiusByImageScale: true)
        let roundedUnicornImage = unicornImage.af_imageRounded(withCornerRadius: radius, divideRadiusByImageScale: true)

        // Then
        let expectedAppleImage = image(forResource: "apple-radius-\(r)", withExtension: "png")
        let expectedPirateImage = image(forResource: "pirate-radius-\(r)", withExtension: "png")
        let expectedRainbowImage = image(forResource: "rainbow-radius-\(r)", withExtension: "png")
        let expectedUnicornImage = image(forResource: "unicorn-radius-\(r)", withExtension: "png")

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
        let expectedAppleImage = image(forResource: "apple-circle", withExtension: "png")
        let expectedPirateImage = image(forResource: "pirate-circle", withExtension: "png")
        let expectedRainbowImage = image(forResource: "rainbow-circle", withExtension: "png")
        let expectedUnicornImage = image(forResource: "unicorn-circle", withExtension: "png")

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

    private func expectedImageSizeForCircularImage(_ image: UIImage) -> CGSize {
        let dimension = min(image.size.width, image.size.height)
        return CGSize(width: dimension, height: dimension)
    }

    // MARK: - Core Image Filters

    func testThatImageWithAppliedGaussianBlurFilterReturnsBlurredImage() {
        guard #available(iOS 9.0, *) else { return }

        // Given
        let parameters: [String: Any] = ["inputRadius": 8]

        // When
        let blurredImage = unicornImage.af_imageFiltered(withCoreImageFilter: "CIGaussianBlur", parameters: parameters)

        // Then
        if let blurredImage = blurredImage {
            let expectedBlurredImage = image(forResource: "unicorn-blurred-8", withExtension: "png")
            let pixelsMatch = blurredImage.af_isEqualToImage(expectedBlurredImage)

            XCTAssertTrue(pixelsMatch, "pixels match should be true")
        } else {
            XCTFail("blurred image should not be nil")
        }
    }

    func testThatImageWithAppliedSepiaToneFilterReturnsSepiaImage() {
        guard #available(iOS 9.0, *) else { return }

        // Given, When
        let sepiaImage = unicornImage.af_imageFiltered(withCoreImageFilter: "CISepiaTone")

        // Then
        if let sepiaImage = sepiaImage {
            let expectedSepiaImage = image(forResource: "unicorn-sepia.tone", withExtension: "png")
            XCTAssertTrue(sepiaImage.af_isEqualToImage(expectedSepiaImage), "sepia image pixels do not match")
        } else {
            XCTFail("sepia image should not be nil")
        }
    }

    func testThatInvalidCoreImageFilterReturnsNil() {
        guard #available(iOS 9.0, *) else { return }

        // Given
        let filterName = "SomeFilterThatDoesNotExist"

        // When
        let filteredImage = unicornImage.af_imageFiltered(withCoreImageFilter: filterName)

        // Then
        XCTAssertNil(filteredImage, "filtered image should be nil")
    }
}

#endif
