// ImageTests-OSX.h
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
import Cocoa

class ResponseImageTestCase : BaseImageTestCase {
    
    func testThatResponseImageSerializerHandlesPNGResponseData() {
        
        // Given
        let URLString = "http://httpbin.org/image/png"
        let expectation = expectationWithDescription("Request should return PNG response image")
        var responseImage: NSImage?
        
        // When
        let request = self.manager.request(.GET, URLString)
        request.responseImage { request, response, image, error in
            responseImage = image as? NSImage
            expectation.fulfill()
        }
        
        // Then
        waitForExpectationsWithTimeout(self.defaultTimeoutDuration) { _ in
            XCTAssertNotNil(responseImage, "The response image should NOT be nil")
            
            if let responseImage = responseImage {
                let expectedSize = CGSize(width: 100.0, height: 100.0)
                XCTAssertEqual(expectedSize, responseImage.size, "Response image size should match the expected size")
            }
        }
    }
    
    func testThatResponseImageSerializerHandlesJPGResponseData() {
        
        // Given
        let URLString = "http://httpbin.org/image/jpeg"
        let expectation = expectationWithDescription("Request should return JPG response image")
        var responseImage: NSImage?
        
        // When
        let request = self.manager.request(.GET, URLString)
        request.responseImage { request, response, image, error in
            responseImage = image as? NSImage
            expectation.fulfill()
        }
        
        // Then
        waitForExpectationsWithTimeout(self.defaultTimeoutDuration) { _ in
            XCTAssertNotNil(responseImage, "The response image should NOT be nil")
            
            if let responseImage = responseImage {
                let expectedSize = CGSize(width: 239.0, height: 178.0)
                XCTAssertEqual(expectedSize, responseImage.size, "Response image size should match the expected size")
            }
        }
    }
}
