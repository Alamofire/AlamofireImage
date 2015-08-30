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

class UIImageScalingTestCase: BaseTestCase {

    // MARK: Properties

    let appleImage = BaseTestCase.imageForResource("apple", withExtension: "jpg")
    let pirateImage = BaseTestCase.imageForResource("pirate", withExtension: "jpg")
    let rainbowImage = BaseTestCase.imageForResource("rainbow", withExtension: "jpg")
    let unicornImage = BaseTestCase.imageForResource("unicorn", withExtension: "png")

    let scale = Int(round(UIScreen.mainScreen().scale))

    let squareSize = CGSize(width: 50, height: 50)
    let horizontalRectangularSize = CGSize(width: 60, height: 30)
    let verticalRectangularSize = CGSize(width: 30, height: 60)

    // MARK: Image Scaled to Size

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
    }

    // MARK: Image Aspect Scaled to Fit

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
    }

    // MARK: Image Aspect Scaled to Fill

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
    }
}
