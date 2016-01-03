// RequestTests.swift
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

import Alamofire
@testable import AlamofireImage
import Foundation
import XCTest

class RequestTestCase: BaseTestCase {
    var acceptableImageContentTypes: Set<String>!

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()
        acceptableImageContentTypes = Request.acceptableImageContentTypes
    }

    override func tearDown() {
        super.tearDown()
        Request.acceptableImageContentTypes = acceptableImageContentTypes
    }

    // MARK: - Image Content Type Tests

    func testThatAddingAcceptableImageContentTypesInsertsThemIntoTheGlobalList() {
        // Given
        let contentTypes: Set<String> = ["image/jpg", "binary/octet-stream"]

        // When
        let beforeCount = Request.acceptableImageContentTypes.count
        Request.addAcceptableImageContentTypes(contentTypes)
        let afterCount = Request.acceptableImageContentTypes.count

        // Then
        XCTAssertEqual(beforeCount, 10, "before count should be 10")
        XCTAssertEqual(afterCount, 12, "after count should be 12")
    }

    // MARK: - Image Serialization Tests

    func testThatImageResponseSerializerCanDownloadPNGImage() {
        // Given
        let URLString = "https://httpbin.org/image/png"
        let expectation = expectationWithDescription("Request should return PNG response image")

        var response: Response<Image, NSError>?

        // When
        manager.request(.GET, URLString)
            .responseImage { closureResponse in
                response = closureResponse
                expectation.fulfill()
            }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNotNil(response?.response, "response should not be nil")
        XCTAssertTrue(response?.result.isSuccess ?? false, "result should be success")

        if let image = response?.result.value {
            #if os(iOS)
                let screenScale = UIScreen.mainScreen().scale
                let expectedSize = CGSize(width: CGFloat(100) / screenScale, height: CGFloat(100) / screenScale)
                XCTAssertEqual(image.size, expectedSize, "image size does not match expected value")
                XCTAssertEqual(image.scale, screenScale, "image scale does not match expected value")
            #elseif os(OSX)
                let expectedSize = CGSize(width: 100.0, height: 100.0)
                XCTAssertEqual(image.size, expectedSize, "image size does not match expected value")
            #endif
        } else {
            XCTFail("result image should not be nil")
        }
    }

    func testThatImageResponseSerializerCanDownloadJPGImage() {
        // Given
        let URLString = "https://httpbin.org/image/jpeg"
        let expectation = expectationWithDescription("Request should return JPG response image")

        var response: Response<Image, NSError>?

        // When
        manager.request(.GET, URLString)
            .responseImage { closureResponse in
                response = closureResponse
                expectation.fulfill()
            }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNotNil(response?.response, "response should not be nil")
        XCTAssertTrue(response?.result.isSuccess ?? false, "result should be success")

        if let image = response?.result.value {
            #if os(iOS)
                let screenScale = UIScreen.mainScreen().scale
                let expectedSize = CGSize(width: CGFloat(239) / screenScale, height: CGFloat(178) / screenScale)
                XCTAssertEqual(image.size, expectedSize, "image size does not match expected value")
                XCTAssertEqual(image.scale, screenScale, "image scale does not match expected value")
            #elseif os(OSX)
                let expectedSize = CGSize(width: 239.0, height: 178.0)
                XCTAssertEqual(image.size, expectedSize, "image size does not match expected value")
            #endif
        } else {
            XCTFail("result image should not be nil")
        }
    }

    func testThatImageResponseSerializerCanDownloadImageFromFileURL() {
        // Given
        let URL = URLForResource("apple", withExtension: "jpg")
        let expectation = expectationWithDescription("Request should return JPG response image")

        var response: Response<Image, NSError>?

        // When
        manager.request(.GET, URL)
            .responseImage { closureResponse in
                response = closureResponse
                expectation.fulfill()
            }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNil(response?.response, "response should be nil")
        XCTAssertTrue(response?.result.isSuccess ?? false, "result should be success")

        if let image = response?.result.value {
            #if os(iOS)
                let screenScale = UIScreen.mainScreen().scale
                let expectedSize = CGSize(width: CGFloat(180) / screenScale, height: CGFloat(260) / screenScale)
                XCTAssertEqual(image.size, expectedSize, "image size does not match expected value")
                XCTAssertEqual(image.scale, screenScale, "image scale does not match expected value")
            #elseif os(OSX)
                let expectedSize = CGSize(width: 180.0, height: 260.0)
                XCTAssertEqual(image.size, expectedSize, "image size does not match expected value")
            #endif
        } else {
            XCTFail("result image should not be nil")
        }
    }

#if os(iOS)

    // MARK: - Image Inflation Tests

    func testThatImageResponseSerializerCanDownloadAndInflatePNGImage() {
        // Given
        let URLString = "https://httpbin.org/image/png"
        let expectation = expectationWithDescription("Request should return PNG response image")

        var response: Response<Image, NSError>?

        // When
        manager.request(.GET, URLString)
            .responseImage { closureResponse in
                response = closureResponse
                expectation.fulfill()
            }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNotNil(response?.response, "response should not be nil")
        XCTAssertTrue(response?.result.isSuccess ?? false, "result should be success")

        if let image = response?.result.value {
            let screenScale = UIScreen.mainScreen().scale
            let expectedSize = CGSize(width: CGFloat(100) / screenScale, height: CGFloat(100) / screenScale)

            XCTAssertEqual(image.size, expectedSize, "image size does not match expected value")
            XCTAssertEqual(image.scale, screenScale, "image scale does not match expected value")
        } else {
            XCTFail("result image should not be nil")
        }
    }

    func testThatImageResponseSerializerCanDownloadAndInflateJPGImage() {
        // Given
        let URLString = "https://httpbin.org/image/jpeg"
        let expectation = expectationWithDescription("Request should return JPG response image")

        var response: Response<Image, NSError>?

        // When
        manager.request(.GET, URLString)
            .responseImage { closureResponse in
                response = closureResponse
                expectation.fulfill()
            }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNotNil(response?.response, "response should not be nil")
        XCTAssertTrue(response?.result.isSuccess ?? false, "result should be success")

        if let image = response?.result.value {
            let screenScale = UIScreen.mainScreen().scale
            let expectedSize = CGSize(width: CGFloat(239) / screenScale, height: CGFloat(178) / screenScale)

            XCTAssertEqual(image.size, expectedSize, "image size does not match expected value")
            XCTAssertEqual(image.scale, screenScale, "image scale does not match expected value")
        } else {
            XCTFail("result image should not be nil")
        }
    }

#endif

    // MARK: - Image Serialization Error Tests

    func testThatAttemptingToDownloadImageFromBadURLReturnsFailureResult() {
        // Given
        let URLString = "https://invalid.for.sure"
        let expectation = expectationWithDescription("Request should fail with bad URL")

        var response: Response<Image, NSError>?

        // When
        manager.request(.GET, URLString)
            .responseImage { closureResponse in
                response = closureResponse
                expectation.fulfill()
            }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNil(response?.response, "response should be nil")
        XCTAssertTrue(response?.result.isFailure ?? false, "result should be failure")
        XCTAssertNotNil(response?.result.error, "result error should not be nil")
    }

    func testThatAttemptingToDownloadUnsupportedImageTypeReturnsFailureResult() {
        // Given
        let URLString = "https://httpbin.org/image/webp"
        let expectation = expectationWithDescription("Request should return webp response image")

        var response: Response<Image, NSError>?

        // When
        manager.request(.GET, URLString)
            .responseImage { closureResponse in
                response = closureResponse
                expectation.fulfill()
            }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNotNil(response?.response, "response should not be nil")
        XCTAssertTrue(response?.result.isFailure ?? false, "result should be failure")
        XCTAssertNotNil(response?.result.error, "result error should not be nil")

        if let error = response?.result.error {
            XCTAssertEqual(error.domain, Error.Domain, "error domain should be com.alamofire.error")
            XCTAssertEqual(error.code, NSURLErrorCannotDecodeContentData, "error code should be -1016")
        }
    }

    func testThatAttemptingToSerializeEmptyDataReturnsFailureResult() {
        // Given
        let URLString = "https://httpbin.org/bytes/0"
        let expectation = expectationWithDescription("Request should download no bytes")

        var response: Response<Image, NSError>?

        // When
        manager.request(.GET, URLString)
            .responseImage { closureResponse in
                response = closureResponse
                expectation.fulfill()
            }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNotNil(response?.response, "response should not be nil")
        XCTAssertTrue(response?.result.isFailure ?? false, "result should be failure")
        XCTAssertNotNil(response?.result.error, "result error should not be nil")

        if let error = response?.result.error {
            XCTAssertEqual(error.domain, Error.Domain, "error domain should be com.alamofire.error")
            XCTAssertEqual(error.code, NSURLErrorCannotDecodeContentData, "error code should be -1016")
        }
    }

    func testThatAttemptingToSerializeRandomStreamDataReturnsFailureResult() {
        // Given
        let randomBytes = 4 * 1024 * 1024
        let URLString = "https://httpbin.org/bytes/\(randomBytes)"
        let expectation = expectationWithDescription("Request should download random bytes")

        var response: Response<Image, NSError>?

        // When
        manager.request(.GET, URLString)
            .responseImage { closureResponse in
                response = closureResponse
                expectation.fulfill()
            }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNotNil(response?.response, "response should not be nil")
        XCTAssertTrue(response?.result.isFailure ?? false, "result should be failure")
        XCTAssertNotNil(response?.result.error, "result error should not be nil")

        if let error = response?.result.error {
            XCTAssertEqual(error.domain, Error.Domain, "error domain should be com.alamofire.error")
            XCTAssertEqual(error.code, NSURLErrorCannotDecodeContentData, "error code should be -1016")
        }
    }

    func testThatAttemptingToSerializeJSONResponseIntoImageReturnsFailureResult() {
        // Given
        let URLString = "https://httpbin.org/get"
        let expectation = expectationWithDescription("Request should return JSON")

        var response: Response<Image, NSError>?

        // When
        manager.request(.GET, URLString)
            .responseImage { closureResponse in
                response = closureResponse
                expectation.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNotNil(response?.response, "response should not be nil")
        XCTAssertTrue(response?.result.isFailure ?? false, "result should be failure")
        XCTAssertNotNil(response?.result.error, "result error should not be nil")

        if let error = response?.result.error {
            XCTAssertEqual(error.domain, Error.Domain, "error domain should be com.alamofire.error")
            XCTAssertEqual(error.code, NSURLErrorCannotDecodeContentData, "error code should be -1016")
        }
    }
}
