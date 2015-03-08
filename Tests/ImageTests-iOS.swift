// ImageTests-iOS.h
//
// Copyright (c) 2014–2015 Alamofire (http://alamofire.org)
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

import XCTest
import Alamofire
import AlamofireImage
import UIKit

class ResponseImageWithInflationTestCase: BaseImageTestCase {
    
    func testPNGResponseDataWithInflation() {
        
        // Given
        let URLString = "http://httpbin.org/image/png"
        let expectation = expectationWithDescription("Request should return PNG response image")
        var responseImage: UIImage?
        
        // When
        let request = self.manager.request(.GET, URLString)
        request.responseImage { request, response, image, error in
            responseImage = image as? UIImage
            expectation.fulfill()
        }
        
        // Then
        waitForExpectationsWithTimeout(self.defaultTimeoutDuration) { _ in
            XCTAssertNotNil(responseImage, "The response image should NOT be nil")
            
            if let responseImage = responseImage {
                let screenScale = UIScreen.mainScreen().scale
                let expectedSize = CGSize(width: CGFloat(100) / screenScale, height: CGFloat(100) / screenScale)
                
                XCTAssertEqual(expectedSize, responseImage.size, "Response image size should match the expected size")
                XCTAssertEqual(screenScale, responseImage.scale, "Response image scale should match the main screen scale")
            }
        }
    }
    
    func testJPGResponseDataWithInflation() {
        
        // Given
        let URLString = "http://httpbin.org/image/jpeg"
        let expectation = expectationWithDescription("Request should return JPG response image")
        var responseImage: UIImage?
        
        // When
        let request = self.manager.request(.GET, URLString)
        request.responseImage { request, response, image, error in
            responseImage = image as? UIImage
            expectation.fulfill()
        }
        
        // Then
        waitForExpectationsWithTimeout(self.defaultTimeoutDuration) { _ in
            XCTAssertNotNil(responseImage, "The response image should NOT be nil")
            
            if let responseImage = responseImage {
                let screenScale = UIScreen.mainScreen().scale
                let expectedSize = CGSize(width: CGFloat(239) / screenScale, height: CGFloat(178) / screenScale)
                
                XCTAssertEqual(expectedSize, responseImage.size, "Response image size should match the expected size")
                XCTAssertEqual(screenScale, responseImage.scale, "Response image scale should match the main screen scale")
            }
        }
    }
}

// MARK: -

class ResponseImageWithoutInflationTestCase: BaseImageTestCase {
    
    func testPNGResponseDataWithoutInflation() {
        
        // Given
        let URLString = "http://httpbin.org/image/png"
        let expectation = expectationWithDescription("Request should return PNG response image")
        var responseImage: UIImage?
        
        // When
        let request = self.manager.request(.GET, URLString)
        request.responseImage(automaticallyInflateResponseImage: false) { request, response, image, error in
            responseImage = image as? UIImage
            expectation.fulfill()
        }
        
        // Then
        waitForExpectationsWithTimeout(self.defaultTimeoutDuration) { _ in
            XCTAssertNotNil(responseImage, "The response image should NOT be nil")
            
            if let responseImage = responseImage {
                let screenScale = UIScreen.mainScreen().scale
                let expectedSize = CGSize(width: CGFloat(100) / screenScale, height: CGFloat(100) / screenScale)
                
                XCTAssertEqual(expectedSize, responseImage.size, "Response image size should match the expected size")
                XCTAssertEqual(screenScale, responseImage.scale, "Response image scale should match the main screen scale")
            }
        }
    }
    
    func testJPGResponseDataWithoutInflation() {
        
        // Given
        let URLString = "http://httpbin.org/image/jpeg"
        let expectation = expectationWithDescription("Request should return JPG response image")
        var responseImage: UIImage?
        
        // When
        let request = self.manager.request(.GET, URLString)
        request.responseImage(automaticallyInflateResponseImage: false) { request, response, image, error in
            responseImage = image as? UIImage
            expectation.fulfill()
        }
        
        // Then
        waitForExpectationsWithTimeout(self.defaultTimeoutDuration) { _ in
            XCTAssertNotNil(responseImage, "The response image should NOT be nil")
            
            if let responseImage = responseImage {
                let screenScale = UIScreen.mainScreen().scale
                let expectedSize = CGSize(width: CGFloat(239) / screenScale, height: CGFloat(178) / screenScale)
                
                XCTAssertEqual(expectedSize, responseImage.size, "Response image size should match the expected size")
                XCTAssertEqual(screenScale, responseImage.scale, "Response image scale should match the main screen scale")
            }
        }
    }
}
