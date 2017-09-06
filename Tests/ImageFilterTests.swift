//
//  ImageFilterTests.swift
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

class ImageFilterTestCase: BaseTestCase {
    let squareSize = CGSize(width: 50, height: 50)
    let largeSquareSize = CGSize(width: 100, height: 100)
    let scale = Int(round(UIScreen.main.scale))

    // MARK: - ImageFilter Protocol Extension Identifiers

    func testThatImageFilterIdentifierIsImplemented() {
        // Given
        let filter = CircleFilter()

        // When
        let identifier = filter.identifier

        // Then
        XCTAssertEqual(identifier, "CircleFilter", "identifier does not match expected value")
    }

    func testThatImageFilterWhereSelfIsSizableIdentifierIsImplemented() {
        // Given
        let filter = ScaledToSizeFilter(size: CGSize(width: 50.3333334, height: 60.879))

        // When
        let identifier = filter.identifier

        // Then
        XCTAssertEqual(identifier, "ScaledToSizeFilter-size:(50x61)", "identifier does not match expected value")
    }

    func testThatImageFilterWhereSelfIsRoundableIdentifierIsImplemented() {
        // Given
        let filter = RoundedCornersFilter(radius: 12)

        // When
        let identifier = filter.identifier

        // Then
        let expectedIdentifier = "RoundedCornersFilter-radius:(12)-divided:(false)"
        XCTAssertEqual(identifier, expectedIdentifier, "identifier does not match expected value")
    }

    // MARK: - CompositeImageFilter Protocol Extension Identifiers

    func testThatCompositeImageFilterIdentifierIsImplemented() {
        // Given
        let filter = ScaledToSizeWithRoundedCornersFilter(size: CGSize(width: 200, height: 100), radius: 20.0123)

        // When
        let identifier = filter.identifier

        // Then
        let expectedIdentifier = "ScaledToSizeFilter-size:(200x100)_RoundedCornersFilter-radius:(20)-divided:(false)"
        XCTAssertEqual(identifier, expectedIdentifier, "identifier does not match expected value")
    }

    // MARK: - DynamicImageFilter Tests

    func testThatDynamicImageFilterIdentifierIsImplemented() {
        // Given
        let identifier = "DynamicFilter"

        // When
        let filter = DynamicImageFilter(identifier) { $0 }

        // Then
        XCTAssertEqual(filter.identifier, identifier, "identifier does not match expected value")
    }

    func testThatDynamicImageFilterReturnsCorrectFilteredImage() {
        // Given
        let image = self.image(forResource: "pirate", withExtension: "jpg")
        let filter = DynamicImageFilter("DynamicScaleToSizeFilter") { image in
            return image.af_imageScaled(to: CGSize(width: 50.0, height: 50.0))
        }

        // When
        let filteredImage = filter.filter(image)

        // Then
        let expectedFilteredImage = self.image(forResource: "pirate-scaled-50x50-@\(scale)x", withExtension: "png")
        XCTAssertTrue(filteredImage.af_isEqualToImage(expectedFilteredImage), "filtered image pixels do not match")
    }

    // MARK: - DynamicCompositeImageFilter Tests

    func testThatDynamicCompositeImageFilterReturnsCorrectFilteredImage() {
        // Given
        let image = self.image(forResource: "pirate", withExtension: "jpg")
        let filter = DynamicCompositeImageFilter(
            ScaledToSizeFilter(size: largeSquareSize),
            RoundedCornersFilter(radius: 20)
        )

        // When
        let filteredImage = filter.filter(image)

        // Then
        let expectedFilteredImage = self.image(
            forResource: "pirate-scaled.to.size.with.rounded.corners-100x100x20-@\(scale)x",
            withExtension: "png"
        )

        XCTAssertTrue(filteredImage.af_isEqualToImage(expectedFilteredImage), "filtered image pixels do not match")
    }

    // MARK: - Single Pass Image Filter Tests

    func testThatScaledToSizeFilterReturnsCorrectFilteredImage() {
        // Given
        let image = self.image(forResource: "pirate", withExtension: "jpg")
        let filter = ScaledToSizeFilter(size: squareSize)

        // When
        let filteredImage = filter.filter(image)

        // Then
        let expectedFilteredImage = self.image(forResource: "pirate-scaled-50x50-@\(scale)x", withExtension: "png")
        XCTAssertTrue(filteredImage.af_isEqualToImage(expectedFilteredImage), "filtered image pixels do not match")
    }

    func testThatAspectScaledToFitSizeFilterReturnsCorrectFilteredImage() {
        // Given
        let image = self.image(forResource: "pirate", withExtension: "jpg")
        let filter = AspectScaledToFitSizeFilter(size: squareSize)

        // When
        let filteredImage = filter.filter(image)

        // Then
        let expectedFilteredImage = self.image(forResource: "pirate-aspect.scaled.to.fit-50x50-@\(scale)x", withExtension: "png")
        XCTAssertTrue(filteredImage.af_isEqualToImage(expectedFilteredImage), "filtered image pixels do not match")
    }

    func testThatAspectScaledToFillSizeFilterReturnsCorrectFilteredImage() {
        // Given
        let image = self.image(forResource: "pirate", withExtension: "jpg")
        let filter = AspectScaledToFillSizeFilter(size: squareSize)

        // When
        let filteredImage = filter.filter(image)

        // Then
        let expectedFilteredImage = self.image(forResource: "pirate-aspect.scaled.to.fill-50x50-@\(scale)x", withExtension: "png")
        XCTAssertTrue(filteredImage.af_isEqualToImage(expectedFilteredImage), "filtered image pixels do not match")
    }

    func testThatRoundedCornersFilterReturnsCorrectFilteredImage() {
        // Given
        let image = self.image(forResource: "pirate", withExtension: "jpg")
        let filter = RoundedCornersFilter(radius: 20, divideRadiusByImageScale: true)

        // When
        let filteredImage = filter.filter(image)

        // Then
        let expectedFilteredImage = self.image(forResource: "pirate-radius-20", withExtension: "png")
        XCTAssertTrue(filteredImage.af_isEqualToImage(expectedFilteredImage), "filtered image pixels do not match")

        let expectedIdentifier = "RoundedCornersFilter-radius:(20)-divided:(true)"
        XCTAssertEqual(filter.identifier, expectedIdentifier, "filter identifier does not match")
    }

    func testThatCircleFilterReturnsCorrectFilteredImage() {
        // Given
        let image = self.image(forResource: "pirate", withExtension: "jpg")
        let filter = CircleFilter()

        // When
        let filteredImage = filter.filter(image)

        // Then
        let expectedFilteredImage = self.image(forResource: "pirate-circle", withExtension: "png")
        XCTAssertTrue(filteredImage.af_isEqualToImage(expectedFilteredImage), "filtered image pixels do not match")
    }

    func testThatBlurFilterReturnsCorrectFilteredImage() {
        guard #available(iOS 9.0, *) else { return }

        // Given
        let image = self.image(forResource: "unicorn", withExtension: "png")
        let filter = BlurFilter(blurRadius: 8)

        // When
        let filteredImage = filter.filter(image)

        // Then
        let expectedFilteredImage = self.image(forResource: "unicorn-blurred-8", withExtension: "png")
        let pixelsMatch = filteredImage.af_isEqualToImage(expectedFilteredImage)

        XCTAssertTrue(pixelsMatch, "pixels match should be true")
    }

    // MARK: - Composite Image Filter Tests

    func testThatScaledToSizeWithRoundedCornersFilterReturnsCorrectFilteredImage() {
        // Given
        let image = self.image(forResource: "pirate", withExtension: "jpg")
        let filter = ScaledToSizeWithRoundedCornersFilter(size: largeSquareSize, radius: 20)

        // When
        let filteredImage = filter.filter(image)

        // Then
        let expectedFilteredImage = self.image(
            forResource: "pirate-scaled.to.size.with.rounded.corners-100x100x20-@\(scale)x",
            withExtension: "png"
        )

        XCTAssertTrue(filteredImage.af_isEqualToImage(expectedFilteredImage), "filtered image pixels do not match")
    }

    func testThatAspectScaledToFillSizeWithRoundedCornersFilterReturnsCorrectFilteredImage() {
        // Given
        let image = self.image(forResource: "pirate", withExtension: "jpg")
        let filter = AspectScaledToFillSizeWithRoundedCornersFilter(size: largeSquareSize, radius: 20)

        // When
        let filteredImage = filter.filter(image)

        // Then
        let expectedFilteredImage = self.image(
            forResource: "pirate-aspect.scaled.to.fill.size.with.rounded.corners-100x100x20-@\(scale)x",
            withExtension: "png"
        )

        XCTAssertTrue(filteredImage.af_isEqualToImage(expectedFilteredImage), "filtered image pixels do not match")
    }

    func testThatScaledToSizeCircleFilterReturnsCorrectFilteredImage() {
        // Given
        let image = self.image(forResource: "pirate", withExtension: "jpg")
        let filter = ScaledToSizeCircleFilter(size: largeSquareSize)

        // When
        let filteredImage = filter.filter(image)

        // Then
        let expectedFilteredImage = self.image(
            forResource: "pirate-scaled.to.size.circle-100x100-@\(scale)x",
            withExtension: "png"
        )

        XCTAssertTrue(filteredImage.af_isEqualToImage(expectedFilteredImage), "filtered image pixels do not match")
    }

    func testThatAspectScaledToFillSizeCircleFilterReturnsCorrectFilteredImage() {
        // Given
        let image = self.image(forResource: "pirate", withExtension: "jpg")
        let filter = AspectScaledToFillSizeCircleFilter(size: largeSquareSize)

        // When
        let filteredImage = filter.filter(image)

        // Then
        let expectedFilteredImage = self.image(
            forResource: "pirate-aspect.scaled.to.fill.size.circle-100x100-@\(scale)x",
            withExtension: "png"
        )

        XCTAssertTrue(filteredImage.af_isEqualToImage(expectedFilteredImage), "filtered image pixels do not match")
    }
}

#endif
