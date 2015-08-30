// UIImageExtensionTests.swift
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

import AlamofireImage
import Foundation
import UIKit
import XCTest

extension UIImage {
    /**
        Modifies the underlying UIImage data to use a PNG representation.
        
        This is important in verifying pixel data between two images. If one has been exported out with PNG 
        compression and another has not, the image data between the two images will never be equal. This helper 
        method helps ensure comparisons will be valid.

        - returns: The PNG representation image.
    */
    private func imageWithPNGRepresentation() -> UIImage {
        let data = UIImagePNGRepresentation(self)!
        let image = UIImage(data: data, scale: UIScreen.mainScreen().scale)!

        return image
    }
}

// MARK: -

class UIImageBaseTestCase: BaseTestCase {
    let appleImage = BaseTestCase.imageForResource("apple", withExtension: "jpg")
    let pirateImage = BaseTestCase.imageForResource("pirate", withExtension: "jpg")
    let rainbowImage = BaseTestCase.imageForResource("rainbow", withExtension: "jpg")
    let unicornImage = BaseTestCase.imageForResource("unicorn", withExtension: "png")

    let scale = Int(round(UIScreen.mainScreen().scale))

    let squareSize = CGSize(width: 50, height: 50)
    let horizontalRectangularSize = CGSize(width: 60, height: 30)
    let verticalRectangularSize = CGSize(width: 30, height: 60)
}

// MARK: -

class UIImageScalingTestCase: UIImageBaseTestCase {

    // MARK: Scaled to Size

    func testThatImageIsScaledToSquareSize() {
        executeImageScaledToSizeTest(squareSize)
    }

    func testThatImageIsScaledToHorizontalRectangularSize() {
        executeImageScaledToSizeTest(horizontalRectangularSize)
    }

    func testThatImageIsScaledToVerticalRectangularSize() {
        executeImageScaledToSizeTest(verticalRectangularSize)
    }

    // MARK: Aspect Scaled to Fit

    func testThatImageIsAspectScaledToFitSquareSize() {
        executeImageAspectScaledToFitSizeTest(squareSize)
    }

    func testThatImageIsAspectScaledToFitHorizontalRectangularSize() {
        executeImageAspectScaledToFitSizeTest(horizontalRectangularSize)
    }

    func testThatImageIsAspectScaledToFitVerticalRectangularSize() {
        executeImageAspectScaledToFitSizeTest(verticalRectangularSize)
    }

    // MARK: Aspect Scaled to Fill

    func testThatImageIsAspectScaledToFillSquareSize() {
        executeImageAspectScaledToFillSizeTest(squareSize)
    }

    func testThatImageIsAspectScaledToFillHorizontalRectangularSize() {
        executeImageAspectScaledToFillSizeTest(horizontalRectangularSize)
    }

    func testThatImageIsAspectScaledToFillVerticalRectangularSize() {
        executeImageAspectScaledToFillSizeTest(verticalRectangularSize)
    }

    // MARK: Private - Test Execution

    private func executeImageScaledToSizeTest(size: CGSize) {
        // Given
        let w = Int(round(size.width))
        let h = Int(round(size.height))

        // When
        let scaledAppleImage = appleImage.af_imageScaledToSize(size).imageWithPNGRepresentation()
        let scaledPirateImage = pirateImage.af_imageScaledToSize(size).imageWithPNGRepresentation()
        let scaledRainbowImage = rainbowImage.af_imageScaledToSize(size).imageWithPNGRepresentation()
        let scaledUnicornImage = unicornImage.af_imageScaledToSize(size).imageWithPNGRepresentation()

        // Then
        let expectedAppleImage = BaseTestCase.imageForResource("apple-scaled-\(w)x\(h)-@\(scale)x", withExtension: "png")
        let expectedPirateImage = BaseTestCase.imageForResource("pirate-scaled-\(w)x\(h)-@\(scale)x", withExtension: "png")
        let expectedRainbowImage = BaseTestCase.imageForResource("rainbow-scaled-\(w)x\(h)-@\(scale)x", withExtension: "png")
        let expectedUnicornImage = BaseTestCase.imageForResource("unicorn-scaled-\(w)x\(h)-@\(scale)x", withExtension: "png")

        XCTAssertTrue(scaledAppleImage.af_isEqualToImage(expectedAppleImage), "scaled apple image pixels do not match")
        XCTAssertTrue(scaledPirateImage.af_isEqualToImage(expectedPirateImage), "scaled pirate image pixels do not match")
        XCTAssertTrue(scaledRainbowImage.af_isEqualToImage(expectedRainbowImage), "scaled rainbow image pixels do not match")
        XCTAssertTrue(scaledUnicornImage.af_isEqualToImage(expectedUnicornImage), "scaled unicorn image pixels do not match")

        XCTAssertEqual(scaledAppleImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
        XCTAssertEqual(scaledPirateImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
        XCTAssertEqual(scaledRainbowImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
        XCTAssertEqual(scaledUnicornImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
    }

    private func executeImageAspectScaledToFitSizeTest(size: CGSize) {
        // Given
        let w = Int(round(size.width))
        let h = Int(round(size.height))

        // When
        let scaledAppleImage = appleImage.af_imageAspectScaledToFitSize(size).imageWithPNGRepresentation()
        let scaledPirateImage = pirateImage.af_imageAspectScaledToFitSize(size).imageWithPNGRepresentation()
        let scaledRainbowImage = rainbowImage.af_imageAspectScaledToFitSize(size).imageWithPNGRepresentation()
        let scaledUnicornImage = unicornImage.af_imageAspectScaledToFitSize(size).imageWithPNGRepresentation()

        // Then
        let expectedAppleImage = BaseTestCase.imageForResource("apple-aspect.scaled.to.fit-\(w)x\(h)-@\(scale)x", withExtension: "png")
        let expectedPirateImage = BaseTestCase.imageForResource("pirate-aspect.scaled.to.fit-\(w)x\(h)-@\(scale)x", withExtension: "png")
        let expectedRainbowImage = BaseTestCase.imageForResource("rainbow-aspect.scaled.to.fit-\(w)x\(h)-@\(scale)x", withExtension: "png")
        let expectedUnicornImage = BaseTestCase.imageForResource("unicorn-aspect.scaled.to.fit-\(w)x\(h)-@\(scale)x", withExtension: "png")

        XCTAssertTrue(scaledAppleImage.af_isEqualToImage(expectedAppleImage), "scaled apple image pixels do not match")
        XCTAssertTrue(scaledPirateImage.af_isEqualToImage(expectedPirateImage), "scaled pirate image pixels do not match")
        XCTAssertTrue(scaledRainbowImage.af_isEqualToImage(expectedRainbowImage), "scaled rainbow image pixels do not match")
        XCTAssertTrue(scaledUnicornImage.af_isEqualToImage(expectedUnicornImage), "scaled unicorn image pixels do not match")

        XCTAssertEqual(scaledAppleImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
        XCTAssertEqual(scaledPirateImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
        XCTAssertEqual(scaledRainbowImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
        XCTAssertEqual(scaledUnicornImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
    }

    private func executeImageAspectScaledToFillSizeTest(size: CGSize) {
        // Given
        let w = Int(round(size.width))
        let h = Int(round(size.height))

        // When
        let scaledAppleImage = appleImage.af_imageAspectScaledToFillSize(size).imageWithPNGRepresentation()
        let scaledPirateImage = pirateImage.af_imageAspectScaledToFillSize(size).imageWithPNGRepresentation()
        let scaledRainbowImage = rainbowImage.af_imageAspectScaledToFillSize(size).imageWithPNGRepresentation()
        let scaledUnicornImage = unicornImage.af_imageAspectScaledToFillSize(size).imageWithPNGRepresentation()

        // Then
        let expectedAppleImage = BaseTestCase.imageForResource("apple-aspect.scaled.to.fill-\(w)x\(h)-@\(scale)x", withExtension: "png")
        let expectedPirateImage = BaseTestCase.imageForResource("pirate-aspect.scaled.to.fill-\(w)x\(h)-@\(scale)x", withExtension: "png")
        let expectedRainbowImage = BaseTestCase.imageForResource("rainbow-aspect.scaled.to.fill-\(w)x\(h)-@\(scale)x", withExtension: "png")
        let expectedUnicornImage = BaseTestCase.imageForResource("unicorn-aspect.scaled.to.fill-\(w)x\(h)-@\(scale)x", withExtension: "png")

        XCTAssertTrue(scaledAppleImage.af_isEqualToImage(expectedAppleImage), "scaled apple image pixels do not match")
        XCTAssertTrue(scaledPirateImage.af_isEqualToImage(expectedPirateImage), "scaled pirate image pixels do not match")
        XCTAssertTrue(scaledRainbowImage.af_isEqualToImage(expectedRainbowImage), "scaled rainbow image pixels do not match")
        XCTAssertTrue(scaledUnicornImage.af_isEqualToImage(expectedUnicornImage), "scaled unicorn image pixels do not match")

        XCTAssertEqual(scaledAppleImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
        XCTAssertEqual(scaledPirateImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
        XCTAssertEqual(scaledRainbowImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
        XCTAssertEqual(scaledUnicornImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
    }
}

// MARK: -

class UIImageRoundedCornersTestCase: UIImageBaseTestCase {

    // MARK: Rounded Corners

    func testThatImageCornersAreRoundedToRadius() {
        // Given
        let radius: CGFloat = 20
        let r = Int(round(radius))

        // When
        let roundedAppleImage = appleImage.af_imageWithRoundedCornerRadius(radius).imageWithPNGRepresentation()
        let roundedPirateImage = pirateImage.af_imageWithRoundedCornerRadius(radius).imageWithPNGRepresentation()
        let roundedRainbowImage = rainbowImage.af_imageWithRoundedCornerRadius(radius).imageWithPNGRepresentation()
        let roundedUnicornImage = unicornImage.af_imageWithRoundedCornerRadius(radius).imageWithPNGRepresentation()

        // Then
        let expectedAppleImage = BaseTestCase.imageForResource("apple-radius-\(r)", withExtension: "png")
        let expectedPirateImage = BaseTestCase.imageForResource("pirate-radius-\(r)", withExtension: "png")
        let expectedRainbowImage = BaseTestCase.imageForResource("rainbow-radius-\(r)", withExtension: "png")
        let expectedUnicornImage = BaseTestCase.imageForResource("unicorn-radius-\(r)", withExtension: "png")

        XCTAssertTrue(roundedAppleImage.af_isEqualToImage(expectedAppleImage), "rounded apple image pixels do not match")
        XCTAssertTrue(roundedPirateImage.af_isEqualToImage(expectedPirateImage), "rounded pirate image pixels do not match")
        XCTAssertTrue(roundedRainbowImage.af_isEqualToImage(expectedRainbowImage), "rounded rainbow image pixels do not match")
        XCTAssertTrue(roundedUnicornImage.af_isEqualToImage(expectedUnicornImage), "rounded unicorn image pixels do not match")

        XCTAssertEqual(roundedAppleImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
        XCTAssertEqual(roundedPirateImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
        XCTAssertEqual(roundedRainbowImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
        XCTAssertEqual(roundedUnicornImage.scale, CGFloat(scale), "image scale should be equal to screen scale")
    }

    // MARK: Circle

    func testThatImageIsRoundedIntoCircle() {
        // Given, When
        let circularAppleImage = appleImage.af_imageRoundedIntoCircle().imageWithPNGRepresentation()
        let circularPirateImage = pirateImage.af_imageRoundedIntoCircle().imageWithPNGRepresentation()
        let circularRainbowImage = rainbowImage.af_imageRoundedIntoCircle().imageWithPNGRepresentation()
        let circularUnicornImage = unicornImage.af_imageRoundedIntoCircle().imageWithPNGRepresentation()

        // Then
        let expectedAppleImage = BaseTestCase.imageForResource("apple-circle", withExtension: "png")
        let expectedPirateImage = BaseTestCase.imageForResource("pirate-circle", withExtension: "png")
        let expectedRainbowImage = BaseTestCase.imageForResource("rainbow-circle", withExtension: "png")
        let expectedUnicornImage = BaseTestCase.imageForResource("unicorn-circle", withExtension: "png")

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

    // MARK: Private - Size Conversion

    private func expectedImageSizeForCircularImage(image: UIImage) -> CGSize {
        let dimension = min(image.size.width, image.size.height)
        return CGSize(width: dimension, height: dimension)
    }
}

// MARK: -

class UIImageCoreImageFilterTestCase: UIImageBaseTestCase {
    func testThatImageWithAppliedGaussianBlurFilterReturnsBlurredImage() {
        // Given
        let parameters: [String: AnyObject] = ["inputRadius": 8]

        // When
        let blurredImage = unicornImage.af_imageWithAppliedCoreImageFilter("CIGaussianBlur", filterParameters: parameters)

        // Then
        if var blurredImage = blurredImage {
            blurredImage = blurredImage.imageWithPNGRepresentation()
            let expectedBlurredImage = BaseTestCase.imageForResource("unicorn-blurred-8", withExtension: "png")
            XCTAssertTrue(blurredImage.af_isEqualToImage(expectedBlurredImage), "blurred image pixels do not match")
        } else {
            XCTFail("blurred image should not be nil")
        }
    }

    func testThatImageWithAppliedSepiaToneFilterReturnsSepiaImage() {
        // Given, When
        let sepiaImage = unicornImage.af_imageWithAppliedCoreImageFilter("CISepiaTone")

        // Then
        if var sepiaImage = sepiaImage {
            sepiaImage = sepiaImage.imageWithPNGRepresentation()
            let expectedSepiaImage = BaseTestCase.imageForResource("unicorn-sepia.tone", withExtension: "png")
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
