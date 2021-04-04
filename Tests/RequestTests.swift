//
//  RequestTests.swift
//
//  Copyright (c) 2015 Alamofire Software Foundation (http://alamofire.org/)
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

@testable import AlamofireImage
import Alamofire
import Foundation
import XCTest

final class DataRequestTestCase: BaseTestCase {
    var acceptableImageContentTypes: Set<String>!

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()
        acceptableImageContentTypes = ImageResponseSerializer.acceptableImageContentTypes
    }

    override func tearDown() {
        super.tearDown()
        ImageResponseSerializer.acceptableImageContentTypes = acceptableImageContentTypes
    }

    // MARK: - Tests - Image Content Type

    func testThatAddingAcceptableImageContentTypesInsertsThemIntoTheGlobalList() {
        // Given
        let contentTypes: Set<String> = ["binary/octet-stream"]

        // When
        let beforeCount = ImageResponseSerializer.acceptableImageContentTypes.count
        ImageResponseSerializer.addAcceptableImageContentTypes(contentTypes)
        let afterCount = ImageResponseSerializer.acceptableImageContentTypes.count

        // Then
        #if os(iOS) || os(macOS)
        if #available(macOS 11, iOS 14, *) {
            XCTAssertEqual(beforeCount, 17, "before count should be 17")
            XCTAssertEqual(afterCount, 18, "after count should be 18")
        } else {
            XCTAssertEqual(beforeCount, 16, "before count should be 16")
            XCTAssertEqual(afterCount, 17, "after count should be 17")
        }
        #else
        XCTAssertEqual(beforeCount, 16, "before count should be 16")
        XCTAssertEqual(afterCount, 17, "after count should be 17")
        #endif
    }

    // MARK: - Tests - Image Serialization

    func testThatImageResponseSerializerCanDownloadAllUniversalImageTypes() {
        func download(_ imageType: Endpoint.Image) {
            // Given
            let expectation = self.expectation(description: "Request should return \(imageType.rawValue) response image")

            var response: AFDataResponse<Image>?

            // When
            // Automatically inflates on supported platforms.
            session.request(.image(imageType))
                .responseImage { closureResponse in
                    response = closureResponse
                    expectation.fulfill()
                }

            waitForExpectations(timeout: timeout)

            // Then
            XCTAssertNotNil(response?.request, "request should not be nil")
            XCTAssertNotNil(response?.response, "response should not be nil")
            XCTAssertTrue(response?.result.isSuccess ?? false, "result should be success")

            guard let image = response?.result.value else {
                XCTFail("\(imageType.rawValue) image should not be nil")
                return
            }

            let expectedSize = imageType.expectedSize
            #if os(iOS) || os(tvOS)
            XCTAssertEqual(image.size, expectedSize.scaledToScreen, "image size does not match expected value")
            XCTAssertTrue(image.isScaledToScreen, "image scale does not match expected value")
            #elseif os(macOS)
            XCTAssertEqual(image.size, expectedSize, "image size does not match expected value")
            #endif
        }

        var images = Set(Endpoint.Image.allCases)
        images.remove(.webp) // WebP is only supported on macOS 11+ and iOS 14+.
        images.remove(.pdf) // No platform supports direct PDF downloads.

        images.forEach(download)
    }

    #if os(macOS) || os(iOS) // No WebP support on tvOS or watchOS.

    @available(macOS 11, iOS 14, *)
    func testThatImageResponseSerializerCanDownloadWebPImage() {
        guard #available(macOS 11, iOS 14, *) else { return }

        // Given
        let expectation = self.expectation(description: "Request should return WebP response image")

        var response: AFDataResponse<Image>?

        // When
        session.request(.image(.webp))
            .responseImage { closureResponse in
                response = closureResponse
                expectation.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNotNil(response?.response, "response should not be nil")
        XCTAssertTrue(response?.result.isSuccess ?? false, "result should be success")

        guard let image = response?.result.value else {
            XCTFail("WebP image should not be nil")
            return
        }

        let expectedSize = Endpoint.Image.png.expectedSize
        #if os(iOS)
        XCTAssertEqual(image.size, expectedSize.scaledToScreen, "image size does not match expected value")
        XCTAssertTrue(image.isScaledToScreen, "image scale does not match expected value")
        #elseif os(macOS)
        XCTAssertEqual(image.size, expectedSize, "image size does not match expected value")
        #endif
    }

    #endif

    func testThatImageResponseSerializerCanDownloadImageFromFileURL() {
        // Given
        let url = self.url(forResource: "apple", withExtension: "jpg")
        let expectation = self.expectation(description: "Request should return JPG response image")

        var response: AFDataResponse<Image>?

        // When
        session.request(url)
            .responseImage { closureResponse in
                response = closureResponse
                expectation.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNil(response?.response, "response should be nil")
        XCTAssertTrue(response?.result.isSuccess ?? false, "result should be success")

        if let image = response?.result.value {
            #if os(iOS)
            let screenScale = UIScreen.main.scale
            let expectedSize = CGSize(width: CGFloat(180) / screenScale, height: CGFloat(260) / screenScale)
            XCTAssertEqual(image.size, expectedSize, "image size does not match expected value")
            XCTAssertEqual(image.scale, screenScale, "image scale does not match expected value")
            #elseif os(macOS)
            let expectedSize = CGSize(width: 180.0, height: 260.0)
            XCTAssertEqual(image.size, expectedSize, "image size does not match expected value")
            #endif
        } else {
            XCTFail("result image should not be nil")
        }
    }

    // MARK: - Tests - Image Serialization Errors

    func testThatAttemptingToDownloadImageFromBadURLReturnsFailureResult() {
        // Given
        let expectation = self.expectation(description: "Request should fail with bad URL")

        var response: AFDataResponse<Image>?

        // When
        session.request(.nonexistent)
            .responseImage { closureResponse in
                response = closureResponse
                expectation.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNil(response?.response, "response should be nil")
        XCTAssertTrue(response?.result.isFailure ?? false, "result should be failure")
        XCTAssertNotNil(response?.result.error, "result error should not be nil")
    }

    func testThatAttemptingToDownloadUnsupportedImageTypeReturnsFailureResult() {
        // Given
        let expectation = self.expectation(description: "Request should return pdf response image")

        var response: AFDataResponse<Image>?

        // When
        session.request(.image(.pdf))
            .responseImage { closureResponse in
                response = closureResponse
                expectation.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNotNil(response?.response, "response should not be nil")
        XCTAssertTrue(response?.result.isFailure ?? false, "result should be failure")
        XCTAssertNotNil(response?.result.error, "result error should not be nil")

        if let error = response?.result.error {
            XCTAssertTrue(error.isUnacceptableContentType)
        } else {
            XCTFail("error should not be nil")
        }
    }

    func testThatAttemptingToSerializeEmptyDataReturnsFailureResult() {
        // Given
        let expectation = self.expectation(description: "Request should download no bytes")

        var response: AFDataResponse<Image>?

        // When
        session.request(.bytes(0))
            .responseImage { closureResponse in
                response = closureResponse
                expectation.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNotNil(response?.response, "response should not be nil")
        XCTAssertTrue(response?.result.isFailure ?? false, "result should be failure")
        XCTAssertNotNil(response?.result.error, "result error should not be nil")

        if let error = response?.result.error {
            XCTAssertTrue(error.isInputDataNilOrZeroLength)
        } else {
            XCTFail("error should not be nil")
        }
    }

    func testThatAttemptingToSerializeRandomStreamDataReturnsFailureResult() {
        // Given
        let randomBytes = 4 * 1024 * 1024
        let expectation = self.expectation(description: "Request should download random bytes")

        var response: AFDataResponse<Image>?

        // When
        session.request(.bytes(randomBytes))
            .responseImage { closureResponse in
                response = closureResponse
                expectation.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNotNil(response?.response, "response should not be nil")
        XCTAssertTrue(response?.result.isFailure ?? false, "result should be failure")
        XCTAssertNotNil(response?.result.error, "result error should not be nil")

        if let error = response?.result.error {
            XCTAssertFalse(error.isUnacceptableContentType)
        } else {
            XCTFail("error should not be nil")
        }
    }

    func testThatAttemptingToSerializeJSONResponseIntoImageReturnsFailureResult() {
        // Given
        let expectation = self.expectation(description: "Request should return JSON")

        var response: AFDataResponse<Image>?

        // When
        session.request(.get)
            .responseImage { closureResponse in
                response = closureResponse
                expectation.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNotNil(response?.response, "response should not be nil")
        XCTAssertTrue(response?.result.isFailure ?? false, "result should be failure")
        XCTAssertNotNil(response?.result.error, "result error should not be nil")

        if let error = response?.result.error {
            XCTAssertTrue(error.isUnacceptableContentType)
        } else {
            XCTFail("error should not be nil")
        }
    }
}
