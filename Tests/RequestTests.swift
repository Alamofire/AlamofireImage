//
//  RequestTests.swift
//
//  Copyright (c) 2015-2018 Alamofire Software Foundation (http://alamofire.org/)
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

import Alamofire
@testable import AlamofireImage
import Foundation
import XCTest

class DataRequestTestCase: BaseTestCase {
    var acceptableImageContentTypes: Set<String>!

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()
        acceptableImageContentTypes = DataRequest.acceptableImageContentTypes
    }

    override func tearDown() {
        super.tearDown()
        DataRequest.acceptableImageContentTypes = acceptableImageContentTypes
    }

    // MARK: - Tests - Image Content Type

    func testThatAddingAcceptableImageContentTypesInsertsThemIntoTheGlobalList() {
        // Given
        let contentTypes: Set<String> = ["image/jpg", "binary/octet-stream"]

        // When
        let beforeCount = DataRequest.acceptableImageContentTypes.count
        DataRequest.addAcceptableImageContentTypes(contentTypes)
        let afterCount = DataRequest.acceptableImageContentTypes.count

        // Then
        XCTAssertEqual(beforeCount, 11, "before count should be 11")
        XCTAssertEqual(afterCount, 13, "after count should be 13")
    }

    // MARK: - Tests - Image Serialization

    func testThatImageResponseSerializerCanDownloadPNGImage() {
        // Given
        let urlString = "https://httpbin.org/image/png"
        let expectation = self.expectation(description: "Request should return PNG response image")

        var response: DataResponse<Image>?

        // When
        sessionManager.request(urlString)
            .responseImage { closureResponse in
                response = closureResponse
                expectation.fulfill()
            }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNotNil(response?.response, "response should not be nil")
        XCTAssertTrue(response?.result.isSuccess ?? false, "result should be success")

        if let image = response?.result.value {
            #if os(iOS)
                let screenScale = UIScreen.main.scale
                let expectedSize = CGSize(width: CGFloat(100) / screenScale, height: CGFloat(100) / screenScale)
                XCTAssertEqual(image.size, expectedSize, "image size does not match expected value")
                XCTAssertEqual(image.scale, screenScale, "image scale does not match expected value")
            #elseif os(macOS)
                let expectedSize = CGSize(width: 100.0, height: 100.0)
                XCTAssertEqual(image.size, expectedSize, "image size does not match expected value")
            #endif
        } else {
            XCTFail("result image should not be nil")
        }
    }

    func testThatImageResponseSerializerCanDownloadJPGImage() {
        // Given
        let urlString = "https://httpbin.org/image/jpeg"
        let expectation = self.expectation(description: "Request should return JPG response image")

        var response: DataResponse<Image>?

        // When
        sessionManager.request(urlString)
            .responseImage { closureResponse in
                response = closureResponse
                expectation.fulfill()
            }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNotNil(response?.response, "response should not be nil")
        XCTAssertTrue(response?.result.isSuccess ?? false, "result should be success")

        if let image = response?.result.value {
            #if os(iOS)
                let screenScale = UIScreen.main.scale
                let expectedSize = CGSize(width: CGFloat(239) / screenScale, height: CGFloat(178) / screenScale)
                XCTAssertEqual(image.size, expectedSize, "image size does not match expected value")
                XCTAssertEqual(image.scale, screenScale, "image scale does not match expected value")
            #elseif os(macOS)
                let expectedSize = CGSize(width: 239.0, height: 178.0)
                XCTAssertEqual(image.size, expectedSize, "image size does not match expected value")
            #endif
        } else {
            XCTFail("result image should not be nil")
        }
    }

    func testThatImageResponseSerializerCanDownloadImageFromFileURL() {
        // Given
        let url = self.url(forResource: "apple", withExtension: "jpg")
        let expectation = self.expectation(description: "Request should return JPG response image")

        var response: DataResponse<Image>?

        // When
        sessionManager.request(url)
            .responseImage { closureResponse in
                response = closureResponse
                expectation.fulfill()
            }

        waitForExpectations(timeout: timeout, handler: nil)

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

#if os(iOS) || os(tvOS)

    // MARK: - Tests - Image Inflation

    func testThatImageResponseSerializerCanDownloadAndInflatePNGImage() {
        // Given
        let urlString = "https://httpbin.org/image/png"
        let expectation = self.expectation(description: "Request should return PNG response image")

        var response: DataResponse<Image>?

        // When
        sessionManager.request(urlString)
            .responseImage { closureResponse in
                response = closureResponse
                expectation.fulfill()
            }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNotNil(response?.response, "response should not be nil")
        XCTAssertTrue(response?.result.isSuccess ?? false, "result should be success")

        if let image = response?.result.value {
            let screenScale = UIScreen.main.scale
            let expectedSize = CGSize(width: CGFloat(100) / screenScale, height: CGFloat(100) / screenScale)

            XCTAssertEqual(image.size, expectedSize, "image size does not match expected value")
            XCTAssertEqual(image.scale, screenScale, "image scale does not match expected value")
        } else {
            XCTFail("result image should not be nil")
        }
    }

    func testThatImageResponseSerializerCanDownloadAndInflateJPGImage() {
        // Given
        let urlString = "https://httpbin.org/image/jpeg"
        let expectation = self.expectation(description: "Request should return JPG response image")

        var response: DataResponse<Image>?

        // When
        sessionManager.request(urlString)
            .responseImage { closureResponse in
                response = closureResponse
                expectation.fulfill()
            }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNotNil(response?.response, "response should not be nil")
        XCTAssertTrue(response?.result.isSuccess ?? false, "result should be success")

        if let image = response?.result.value {
            let screenScale = UIScreen.main.scale
            let expectedSize = CGSize(width: CGFloat(239) / screenScale, height: CGFloat(178) / screenScale)

            XCTAssertEqual(image.size, expectedSize, "image size does not match expected value")
            XCTAssertEqual(image.scale, screenScale, "image scale does not match expected value")
        } else {
            XCTFail("result image should not be nil")
        }
    }

#endif

    // MARK: - Tests - Image Serialization Errors

    func testThatAttemptingToDownloadImageFromBadURLReturnsFailureResult() {
        // Given
        let urlString = "https://invalid.for.sure"
        let expectation = self.expectation(description: "Request should fail with bad URL")

        var response: DataResponse<Image>?

        // When
        sessionManager.request(urlString)
            .responseImage { closureResponse in
                response = closureResponse
                expectation.fulfill()
            }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNil(response?.response, "response should be nil")
        XCTAssertTrue(response?.result.isFailure ?? false, "result should be failure")
        XCTAssertNotNil(response?.result.error, "result error should not be nil")
    }

    func testThatAttemptingToDownloadUnsupportedImageTypeReturnsFailureResult() {
        // Given
        let urlString = "https://httpbin.org/image/webp"
        let expectation = self.expectation(description: "Request should return webp response image")

        var response: DataResponse<Image>?

        // When
        sessionManager.request(urlString)
            .responseImage { closureResponse in
                response = closureResponse
                expectation.fulfill()
            }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNotNil(response?.response, "response should not be nil")
        XCTAssertTrue(response?.result.isFailure ?? false, "result should be failure")
        XCTAssertNotNil(response?.result.error, "result error should not be nil")

        if let error = response?.result.error as? AFError {
            XCTAssertTrue(error.isUnacceptableContentType)
        } else {
            XCTFail("error should not be nil")
        }
    }

    func testThatAttemptingToSerializeEmptyDataReturnsFailureResult() {
        // Given
        let urlString = "https://httpbin.org/bytes/0"
        let expectation = self.expectation(description: "Request should download no bytes")

        var response: DataResponse<Image>?

        // When
        sessionManager.request(urlString)
            .responseImage { closureResponse in
                response = closureResponse
                expectation.fulfill()
            }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNotNil(response?.response, "response should not be nil")
        XCTAssertTrue(response?.result.isFailure ?? false, "result should be failure")
        XCTAssertNotNil(response?.result.error, "result error should not be nil")

        if let error = response?.result.error as? AFError {
            XCTAssertTrue(error.isUnacceptableContentType)
        } else {
            XCTFail("error should not be nil")
        }
    }

    func testThatAttemptingToSerializeRandomStreamDataReturnsFailureResult() {
        // Given
        let randomBytes = 4 * 1024 * 1024
        let urlString = "https://httpbin.org/bytes/\(randomBytes)"
        let expectation = self.expectation(description: "Request should download random bytes")

        var response: DataResponse<Image>?

        // When
        sessionManager.request(urlString)
            .responseImage { closureResponse in
                response = closureResponse
                expectation.fulfill()
            }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNotNil(response?.response, "response should not be nil")
        XCTAssertTrue(response?.result.isFailure ?? false, "result should be failure")
        XCTAssertNotNil(response?.result.error, "result error should not be nil")

        if let error = response?.result.error as? AFError {
            XCTAssertTrue(error.isUnacceptableContentType)
        } else {
            XCTFail("error should not be nil")
        }
    }

    func testThatAttemptingToSerializeJSONResponseIntoImageReturnsFailureResult() {
        // Given
        let urlString = "https://httpbin.org/get"
        let expectation = self.expectation(description: "Request should return JSON")

        var response: DataResponse<Image>?

        // When
        sessionManager.request(urlString)
            .responseImage { closureResponse in
                response = closureResponse
                expectation.fulfill()
            }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNotNil(response?.response, "response should not be nil")
        XCTAssertTrue(response?.result.isFailure ?? false, "result should be failure")
        XCTAssertNotNil(response?.result.error, "result error should not be nil")

        if let error = response?.result.error as? AFError {
            XCTAssertTrue(error.isUnacceptableContentType)
        } else {
            XCTFail("error should not be nil")
        }
    }

    // MARK: - Tests - Stream Images
    // Server no longer functions correctly. - JS 3/29/18
    func _testThatImagesCanBeStreamedDynamicallyFromMJPEGStream() {
        // Given
        let urlString = "http://173.14.66.201/anony/mjpg.cgi" // Northgate Launder Land
        let expectation = self.expectation(description: "Request should return images")

        let expectedImageCount = 8
        var imageCount = 0

        // When
        let request = sessionManager.request(urlString)

        request.streamImage { image in
            guard imageCount < expectedImageCount else { return }

            imageCount += 1

            if imageCount == expectedImageCount {
                request.cancel()
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertEqual(imageCount, expectedImageCount)
    }
}
