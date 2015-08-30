// ImageTests-iOS.swift
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

import Alamofire
import AlamofireImage
import Foundation
import UIKit
import XCTest

class ResponseImageWithInflationTestCase : BaseTestCase {
    func testPNGResponseDataWithInflation() {
        // Given
        let URLString = "http://httpbin.org/image/png"
        let expectation = expectationWithDescription("Request should return PNG response image")

        var request: NSURLRequest?
        var response: NSHTTPURLResponse?
        var result: Result<UIImage>?

        // When
        manager.request(.GET, URLString)
            .responseImage { responseRequest, responseResponse, responseResult in
                request = responseRequest
                response = responseResponse
                result = responseResult

                expectation.fulfill()
            }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertNotNil(request, "request should not be nil")
        XCTAssertNotNil(response, "response should not be nil")
        XCTAssertTrue(result?.isSuccess ?? false, "result should be success")

        if let result = result, let image = result.value {
            let screenScale = UIScreen.mainScreen().scale
            let expectedSize = CGSize(width: CGFloat(100) / screenScale, height: CGFloat(100) / screenScale)

            XCTAssertEqual(image.size, expectedSize, "image size does not match expected value")
            XCTAssertEqual(image.scale, screenScale, "image scale does not match expected value")
        } else {
            XCTFail("result image should not be nil")
        }
    }

    func testJPGResponseDataWithInflation() {
        // Given
        let URLString = "http://httpbin.org/image/jpeg"
        let expectation = expectationWithDescription("Request should return JPG response image")

        var request: NSURLRequest?
        var response: NSHTTPURLResponse?
        var result: Result<UIImage>?

        // When
        manager.request(.GET, URLString)
            .responseImage { responseRequest, responseResponse, responseResult in
                request = responseRequest
                response = responseResponse
                result = responseResult

                expectation.fulfill()
            }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertNotNil(request, "request should not be nil")
        XCTAssertNotNil(response, "response should not be nil")
        XCTAssertTrue(result?.isSuccess ?? false, "result should be success")

        if let result = result, let image = result.value {
            let screenScale = UIScreen.mainScreen().scale
            let expectedSize = CGSize(width: CGFloat(239) / screenScale, height: CGFloat(178) / screenScale)

            XCTAssertEqual(image.size, expectedSize, "image size does not match expected value")
            XCTAssertEqual(image.scale, screenScale, "image scale does not match expected value")
        } else {
            XCTFail("result image should not be nil")
        }
    }
}

// MARK: -

class ResponseImageWithoutInflationTestCase : BaseTestCase {
    func testPNGResponseDataWithoutInflation() {
        // Given
        let URLString = "http://httpbin.org/image/png"
        let expectation = expectationWithDescription("Request should return PNG response image")

        var request: NSURLRequest?
        var response: NSHTTPURLResponse?
        var result: Result<UIImage>?

        // When
        manager.request(.GET, URLString)
            .responseImage(automaticallyInflateResponseImage: false) { responseRequest, responseResponse, responseResult in
                request = responseRequest
                response = responseResponse
                result = responseResult

                expectation.fulfill()
            }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertNotNil(request, "request should not be nil")
        XCTAssertNotNil(response, "response should not be nil")
        XCTAssertTrue(result?.isSuccess ?? false, "result should be success")

        if let result = result, let image = result.value {
            let screenScale = UIScreen.mainScreen().scale
            let expectedSize = CGSize(width: CGFloat(100) / screenScale, height: CGFloat(100) / screenScale)

            XCTAssertEqual(image.size, expectedSize, "image size does not match expected value")
            XCTAssertEqual(image.scale, screenScale, "image scale does not match expected value")
        } else {
            XCTFail("result image should not be nil")
        }
    }

    func testJPGResponseDataWithoutInflation() {
        // Given
        let URLString = "http://httpbin.org/image/jpeg"
        let expectation = expectationWithDescription("Request should return JPG response image")

        var request: NSURLRequest?
        var response: NSHTTPURLResponse?
        var result: Result<UIImage>?

        // When
        manager.request(.GET, URLString)
            .responseImage(automaticallyInflateResponseImage: false) { responseRequest, responseResponse, responseResult in
                request = responseRequest
                response = responseResponse
                result = responseResult

                expectation.fulfill()
            }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertNotNil(request, "request should not be nil")
        XCTAssertNotNil(response, "response should not be nil")
        XCTAssertTrue(result?.isSuccess ?? false, "result should be success")

        if let result = result, let image = result.value {
            let screenScale = UIScreen.mainScreen().scale
            let expectedSize = CGSize(width: CGFloat(239) / screenScale, height: CGFloat(178) / screenScale)

            XCTAssertEqual(image.size, expectedSize, "image size does not match expected value")
            XCTAssertEqual(image.scale, screenScale, "image scale does not match expected value")
        } else {
            XCTFail("result image should not be nil")
        }
    }
}
