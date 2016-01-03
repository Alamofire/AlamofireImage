// UIButtonTests.swift
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

@testable import Alamofire
@testable import AlamofireImage
import UIKit
import XCTest

private class TestButton: UIButton {
    var imageObserver: (Void -> Void)?

    required init(imageObserver: (Void -> Void)? = nil) {
        self.imageObserver = imageObserver
        super.init(frame: CGRectZero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setBackgroundImage(image: UIImage?, forState state: UIControlState) {
        super.setBackgroundImage(image, forState: state)
        imageObserver?()
    }

    override func setImage(image: UIImage?, forState state: UIControlState) {
        super.setImage(image, forState: state)
        imageObserver?()
    }
}

// MARK: -

class UIButtonTests: BaseTestCase {
    let URL = NSURL(string: "https://httpbin.org/image/jpeg")!

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()

        ImageDownloader.defaultURLCache().removeAllCachedResponses()
        ImageDownloader.defaultInstance.imageCache?.removeAllImages()
        UIButton.af_sharedImageDownloader = ImageDownloader.defaultInstance
    }

    // MARK: - Image Download

    func testThatImageCanBeDownloadedFromURL() {
        // Given
        let expectation = expectationWithDescription("image should download successfully")
        var imageDownloadComplete = false

        let button = TestButton {
            imageDownloadComplete = true
            expectation.fulfill()
        }

        // When
        button.af_setImageForState(.Normal, URL: URL)
        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertTrue(imageDownloadComplete)
    }

    func testThatBackgroundImageCanBeDownloadedFromURL() {
        // Given
        let expectation = expectationWithDescription("background image should download successfully")
        var backgroundImageDownloadComplete = false

        let button = TestButton {
            backgroundImageDownloadComplete = true
            expectation.fulfill()
        }

        // When
        button.af_setBackgroundImageForState(.Normal, URL: URL)
        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertTrue(backgroundImageDownloadComplete)
    }

    func testThatImageCanBeCancelledAndDownloadedFromURL () {
        // Given
        let expectation = expectationWithDescription("image should cancel and download successfully")
        let button = UIButton()
        var result: Result<UIImage, NSError>?

        // When
        button.af_setImageForState(.Normal, URL: URL)
        button.af_cancelImageRequestForState(.Normal)
        button.af_setImageForState(
            .Normal,
            URLRequest: NSURLRequest(URL: URL),
            placeholderImage: nil) { response in
                result = response.result
                expectation.fulfill()
        }

        // Then
        waitForExpectationsWithTimeout(timeout, handler: nil)
        XCTAssertNotNil(result?.value)
    }

    func testThatBackgroundImageCanBeCancelledAndDownloadedFromURL () {
        // Given
        let expectation = expectationWithDescription("background image should cancel and download successfully")
        let button = UIButton()
        var result: Result<UIImage, NSError>?

        // When
        button.af_setBackgroundImageForState(.Normal, URL: URL)
        button.af_cancelBackgroundImageRequestForState(.Normal)
        button.af_setBackgroundImageForState(
            .Normal,
            URLRequest: NSURLRequest(URL: URL),
            placeholderImage: nil) { response in
                result = response.result
                expectation.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertNotNil(result?.value)
    }

    func testThatActiveImageRequestReceiptIsNilAfterImageDownloadCompletes() {
        // Given
        let expectation = expectationWithDescription("image should download successfully")
        var imageDownloadComplete = false

        let button = TestButton {
            imageDownloadComplete = true
            expectation.fulfill()
        }

        // When
        button.af_setImageForState(.Normal, URL: URL)
        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertTrue(imageDownloadComplete)
        XCTAssertNil(button.backgroundImageRequestReceiptForState(.Normal))
    }

    func testThatActiveBackgroundImageRequestReceiptIsNilAfterImageDownloadCompletes() {
        // Given
        let expectation = expectationWithDescription("background image should download successfully")
        var backgroundImageDownloadComplete = false

        let button = TestButton {
            backgroundImageDownloadComplete = true
            expectation.fulfill()
        }

        // When
        button.af_setBackgroundImageForState(.Normal, URL: URL)
        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertTrue(backgroundImageDownloadComplete)
        XCTAssertNil(button.backgroundImageRequestReceiptForState(.Normal))
    }

    func testThatMultipleImageRequestReceiptStatesCanBeDownloadedInParallel() {
        // Given
        let button = TestButton()
        var _URL = URL

        // When
        let expectation1 = expectationWithDescription("background image should download successfully")
        var normalStateImageDownloadComplete = false
        button.af_setImageForState(.Normal, URL: _URL)
        button.imageObserver = {
            normalStateImageDownloadComplete = true
            expectation1.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        let expectation2 = expectationWithDescription("background image should download successfully")
        var selectedStateImageDownloadComplete = false
        _URL = NSURL(string: "https://httpbin.org/image/jpeg?random=\(random())")!

        button.af_setImageForState(.Selected, URL: _URL)
        button.imageObserver = {
            selectedStateImageDownloadComplete = true
            expectation2.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        let expectation3 = expectationWithDescription("background image should download successfully")
        var highlightedStateImageDownloadComplete = false
        _URL = NSURL(string: "https://httpbin.org/image/jpeg?random=\(random())")!

        button.af_setImageForState(.Highlighted, URL: _URL)
        button.imageObserver = {
            highlightedStateImageDownloadComplete = true
            expectation3.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        let expectation4 = expectationWithDescription("background image should download successfully")
        var disabledStateImageDownloadComplete = false
        _URL = NSURL(string: "https://httpbin.org/image/jpeg?random=\(random())")!

        button.af_setImageForState(.Disabled, URL: _URL)
        button.imageObserver = {
            disabledStateImageDownloadComplete = true
            expectation4.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertTrue(normalStateImageDownloadComplete)
        XCTAssertNotNil(button.imageForState(.Normal))

        XCTAssertTrue(selectedStateImageDownloadComplete)
        XCTAssertNotNil(button.imageForState(.Selected))

        XCTAssertTrue(highlightedStateImageDownloadComplete)
        XCTAssertNotNil(button.imageForState(.Highlighted))

        XCTAssertTrue(disabledStateImageDownloadComplete)
        XCTAssertNotNil(button.imageForState(.Disabled))
    }

    func testThatMultipleBackgroundImageRequestReceiptStatesCanBeDownloadedInParallel() {
        // Given
        let button = TestButton()
        var _URL = URL

        // When
        let expectation1 = expectationWithDescription("background image should download successfully")
        var normalStateBackgroundImageDownloadComplete = false
        button.af_setBackgroundImageForState(.Normal, URL: _URL)
        button.imageObserver = {
            normalStateBackgroundImageDownloadComplete = true
            expectation1.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)
        let expectation2 = expectationWithDescription("background image should download successfully")
        var selectedStateBackgroundImageDownloadComplete = false
        _URL = NSURL(string: "https://httpbin.org/image/jpeg?random=\(random())")!

        button.af_setBackgroundImageForState(.Selected, URL: _URL)
        button.imageObserver = {
            selectedStateBackgroundImageDownloadComplete = true
            expectation2.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        let expectation3 = expectationWithDescription("background image should download successfully")
        var highlightedStateBackgroundImageDownloadComplete = false
        _URL = NSURL(string: "https://httpbin.org/image/jpeg?random=\(random())")!

        button.af_setBackgroundImageForState(.Highlighted, URL: _URL)
        button.imageObserver = {
            highlightedStateBackgroundImageDownloadComplete = true
            expectation3.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        let expectation4 = expectationWithDescription("background image should download successfully")
        var disabledStateBackgroundImageDownloadComplete = false
        _URL = NSURL(string: "https://httpbin.org/image/jpeg?random=\(random())")!

        button.af_setBackgroundImageForState(.Disabled, URL: _URL)
        button.imageObserver = {
            disabledStateBackgroundImageDownloadComplete = true
            expectation4.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertTrue(normalStateBackgroundImageDownloadComplete)
        XCTAssertNotNil(button.backgroundImageForState(.Normal))

        XCTAssertTrue(selectedStateBackgroundImageDownloadComplete)
        XCTAssertNotNil(button.backgroundImageForState(.Selected))

        XCTAssertTrue(highlightedStateBackgroundImageDownloadComplete)
        XCTAssertNotNil(button.backgroundImageForState(.Highlighted))

        XCTAssertTrue(disabledStateBackgroundImageDownloadComplete)
        XCTAssertNotNil(button.backgroundImageForState(.Disabled))
    }

    // MARK: - Image Downloaders

    func testThatImageDownloaderOverridesSharedImageDownloader() {
        // Given
        let expectation = expectationWithDescription("image should download successfully")
        var imageDownloadComplete = false

        let button = TestButton {
            imageDownloadComplete = true
            expectation.fulfill()
        }

        let configuration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        let imageDownloader = ImageDownloader(configuration: configuration)
        button.af_imageDownloader = imageDownloader

        // When
        button.af_setImageForState(.Normal, URL: URL)
        let activeRequestCount = imageDownloader.activeRequestCount

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertTrue(imageDownloadComplete)
        XCTAssertNil(button.imageRequestReceiptForState(.Normal), "active request receipt should be nil after download completes")
        XCTAssertEqual(activeRequestCount, 1, "active request count should be 1")
    }

    // MARK: - Image Cache

    func testThatImageCanBeLoadedFromImageCache() {
        // Given
        let button = UIButton()

        let downloader = ImageDownloader.defaultInstance
        let download = URLRequest(.GET, URL.absoluteString)
        let expectation = expectationWithDescription("image download should succeed")

        downloader.downloadImage(URLRequest: download) { _ in
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // When
        button.af_setImageForState(.Normal, URL: URL)
        button.af_cancelImageRequestForState(.Normal)

        // Then
        XCTAssertNotNil(button.imageForState(.Normal), "button image should not be nil")
    }

    func testThatSharedImageCacheCanBeReplaced() {
        // Given
        let imageDownloader = ImageDownloader()

        // When
        let firstEqualityCheck = UIButton.af_sharedImageDownloader === imageDownloader
        UIButton.af_sharedImageDownloader = imageDownloader
        let secondEqualityCheck = UIButton.af_sharedImageDownloader === imageDownloader

        // Then
        XCTAssertFalse(firstEqualityCheck, "first equality check should be false")
        XCTAssertTrue(secondEqualityCheck, "second equality check should be true")
    }

    // MARK: - Placeholder Images

    func testThatPlaceholderImageIsDisplayedUntilImageIsDownloadedFromURL() {
        // Given
        let placeholderImage = imageForResource("pirate", withExtension: "jpg")
        let expectation = expectationWithDescription("image should download successfully")

        var imageDownloadComplete = false
        var finalImageEqualsPlaceholderImage = false

        let button = TestButton ()

        // When
        button.af_setImageForState(.Normal, URL: URL, placeHolderImage: placeholderImage)
        let initialImageEqualsPlaceholderImage = button.imageForState(.Normal) === placeholderImage

        button.imageObserver = {
            imageDownloadComplete = true
            finalImageEqualsPlaceholderImage = button.imageForState(.Normal) === placeholderImage
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertTrue(imageDownloadComplete)
        XCTAssertTrue(initialImageEqualsPlaceholderImage, "initial image should equal placeholder image")
        XCTAssertFalse(finalImageEqualsPlaceholderImage, "final image should not equal placeholder image")
    }

    func testThatBackgroundPlaceholderImageIsDisplayedUntilImageIsDownloadedFromURL() {
        // Given
        let placeholderImage = imageForResource("pirate", withExtension: "jpg")
        let expectation = expectationWithDescription("image should download successfully")

        var backgroundImageDownloadComplete = false
        var finalBackgroundImageEqualsPlaceholderImage = false

        let button = TestButton ()

        // When
        button.af_setBackgroundImageForState(.Normal, URL: URL, placeHolderImage: placeholderImage)
        let initialImageEqualsPlaceholderImage = button.backgroundImageForState(.Normal) === placeholderImage

        button.imageObserver = {
            backgroundImageDownloadComplete = true
            finalBackgroundImageEqualsPlaceholderImage = button.backgroundImageForState(.Normal) === placeholderImage
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertTrue(backgroundImageDownloadComplete)
        XCTAssertTrue(initialImageEqualsPlaceholderImage, "initial image should equal placeholder image")
        XCTAssertFalse(finalBackgroundImageEqualsPlaceholderImage, "final image should not equal placeholder image")
    }

    func testThatImagePlaceholderIsNeverDisplayedIfCachedImageIsAvailable() {
        // Given
        let placeholderImage = imageForResource("pirate", withExtension: "jpg")
        let button = UIButton()

        let downloader = ImageDownloader.defaultInstance
        let download = URLRequest(.GET, URL.absoluteString)
        let expectation = expectationWithDescription("image download should succeed")

        downloader.downloadImage(URLRequest: download) { _ in
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // When
        button.af_setImageForState(.Normal, URL: URL, placeHolderImage: placeholderImage)

        // Then
        XCTAssertNotNil(button.imageForState(.Normal), "button image should not be nil")
        XCTAssertFalse(button.imageForState(.Normal) === placeholderImage, "button image should not equal placeholder image")
    }

    func testThatBackgroundPlaceholderIsNeverDisplayedIfCachedImageIsAvailable() {
        // Given
        let placeholderImage = imageForResource("pirate", withExtension: "jpg")
        let button = UIButton()

        let downloader = ImageDownloader.defaultInstance
        let download = URLRequest(.GET, URL.absoluteString)
        let expectation = expectationWithDescription("image download should succeed")

        downloader.downloadImage(URLRequest: download) { _ in
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // When
        button.af_setBackgroundImageForState(.Normal, URL: URL, placeHolderImage: placeholderImage)

        // Then
        XCTAssertNotNil(button.backgroundImageForState(.Normal), "button background image should not be nil")
        XCTAssertFalse(button.backgroundImageForState(.Normal) === placeholderImage, "button background image should not equal placeholder image")
    }

    // MARK: - Completion Handler

    func testThatCompletionHandlerIsCalledWhenImageDownloadSucceeds() {
        // Given
        let button = UIButton()

        let URLRequest: NSURLRequest = {
            let request = NSMutableURLRequest(URL: URL)
            request.addValue("image/*", forHTTPHeaderField: "Accept")
            return request
        }()

        let expectation = expectationWithDescription("image download should succeed")

        var completionHandlerCalled = false
        var result: Result<UIImage, NSError>?

        // When
        button.af_setImageForState(.Normal, URLRequest: URLRequest, placeholderImage: nil) { response in
            completionHandlerCalled = true
            result = response.result
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertTrue(completionHandlerCalled, "completion handler called should be true")
        XCTAssertNotNil(button.imageForState(.Normal), "button image should be not be nil")
        XCTAssertTrue(result?.isSuccess ?? false, "result should be a success case")
    }

    func testThatCompletionHandlerIsCalledWhenBackgroundImageDownloadSucceeds() {
        // Given
        let button = UIButton()

        let URLRequest: NSURLRequest = {
            let request = NSMutableURLRequest(URL: URL)
            request.addValue("image/*", forHTTPHeaderField: "Accept")
            return request
        }()

        let expectation = expectationWithDescription("image download should succeed")

        var completionHandlerCalled = false
        var result: Result<UIImage, NSError>?

        // When
        button.af_setBackgroundImageForState(.Normal, URLRequest: URLRequest, placeholderImage: nil) { response in
            completionHandlerCalled = true
            result = response.result
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertTrue(completionHandlerCalled, "completion handler called should be true")
        XCTAssertNotNil(button.backgroundImageForState(.Normal), "button background image should be not be nil")
        XCTAssertTrue(result?.isSuccess ?? false, "result should be a success case")
    }

    func testThatCompletionHandlerIsCalledWhenImageDownloadFails() {
        // Given
        let button = UIButton()
        let URLRequest = NSURLRequest(URL: NSURL(string: "really-bad-domain")!)

        let expectation = expectationWithDescription("image download should succeed")

        var completionHandlerCalled = false
        var result: Result<UIImage, NSError>?

        // When
        button.af_setImageForState(.Normal, URLRequest: URLRequest, placeholderImage: nil) { response in
            completionHandlerCalled = true
            result = response.result
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertTrue(completionHandlerCalled, "completion handler called should be true")
        XCTAssertNil(button.imageForState(.Normal), "button image should be nil")
        XCTAssertTrue(result?.isFailure ?? false, "result should be a failure case")
    }

    func testThatCompletionHandlerIsCalledWhenBackgroundImageDownloadFails() {
        // Given
        let button = UIButton()
        let URLRequest = NSURLRequest(URL: NSURL(string: "really-bad-domain")!)

        let expectation = expectationWithDescription("image download should succeed")

        var completionHandlerCalled = false
        var result: Result<UIImage, NSError>?

        // When
        button.af_setBackgroundImageForState(.Normal, URLRequest: URLRequest, placeholderImage: nil) { response in
            completionHandlerCalled = true
            result = response.result
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertTrue(completionHandlerCalled, "completion handler called should be true")
        XCTAssertNil(button.backgroundImageForState(.Normal), "button background image should be nil")
        XCTAssertTrue(result?.isFailure ?? false, "result should be a failure case")
    }

    // MARK: - Cancellation

    func testThatImageDownloadCanBeCancelled() {
        // Given
        let button = UIButton()
        let URLRequest = NSURLRequest(URL: NSURL(string: "domain-name-does-not-exist")!)

        let expectation = expectationWithDescription("image download should succeed")

        var completionHandlerCalled = false
        var result: Result<UIImage, NSError>?

        // When
        button.af_setImageForState(
            .Normal,
            URLRequest: URLRequest,
            placeholderImage: nil,
            completion: { closureResponse in
                completionHandlerCalled = true
                result = closureResponse.result
                expectation.fulfill()
            }
        )

        button.af_cancelImageRequestForState(.Normal)
        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertTrue(completionHandlerCalled)
        XCTAssertNil(button.imageForState(.Normal))
        XCTAssertTrue(result?.isFailure ?? false)
    }

    func testThatBackgroundImageDownloadCanBeCancelled() {
        // Given
        let button = UIButton()
        let URLRequest = NSURLRequest(URL: NSURL(string: "domain-name-does-not-exist")!)

        let expectation = expectationWithDescription("background image download should succeed")

        var completionHandlerCalled = false
        var result: Result<UIImage, NSError>?

        // When
        button.af_setBackgroundImageForState(
            .Normal,
            URLRequest: URLRequest,
            placeholderImage: nil,
            completion: { closureResponse in
                completionHandlerCalled = true
                result = closureResponse.result
                expectation.fulfill()
            }
        )

        button.af_cancelBackgroundImageRequestForState(.Normal)
        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertTrue(completionHandlerCalled)
        XCTAssertNil(button.backgroundImageForState(.Normal))
        XCTAssertTrue(result?.isFailure ?? false)
    }

    func testThatActiveImageRequestIsAutomaticallyCancelledBySettingNewURL() {
        // Given
        let button = UIButton()
        let expectation = expectationWithDescription("image download should succeed")

        var completion1Called = false
        var completion2Called = false
        var result: Result<UIImage, NSError>?

        // When
        button.af_setImageForState(
            .Normal,
            URLRequest: NSURLRequest(URL: URL),
            placeholderImage: nil,
            completion: { closureResponse in
                completion1Called = true
            }
        )

        button.af_setImageForState(
            .Normal,
            URLRequest: NSURLRequest(URL: NSURL(string: "https://httpbin.org/image/png")!),
            placeholderImage: nil,
            completion: { closureResponse in
                completion2Called = true
                result = closureResponse.result
                expectation.fulfill()
            }
        )

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertTrue(completion1Called)
        XCTAssertTrue(completion2Called)
        XCTAssertNotNil(button.imageForState(.Normal))
        XCTAssertTrue(result?.isSuccess ?? false)
    }

    func testThatActiveBackgroundImageRequestIsAutomaticallyCancelledBySettingNewURL() {
        // Given
        let button = UIButton()
        let expectation = expectationWithDescription("background image download should succeed")

        var completion1Called = false
        var completion2Called = false
        var result: Result<UIImage, NSError>?

        // When
        button.af_setBackgroundImageForState(
            .Normal,
            URLRequest: NSURLRequest(URL: URL),
            placeholderImage: nil,
            completion: { closureResponse in
                completion1Called = true
            }
        )

        button.af_setBackgroundImageForState(
            .Normal,
            URLRequest: NSURLRequest(URL: NSURL(string: "https://httpbin.org/image/png")!),
            placeholderImage: nil,
            completion: { closureResponse in
                completion2Called = true
                result = closureResponse.result
                expectation.fulfill()
            }
        )

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertTrue(completion1Called)
        XCTAssertTrue(completion2Called)
        XCTAssertNotNil(button.backgroundImageForState(.Normal))
        XCTAssertTrue(result?.isSuccess ?? false)
    }

    func testThatActiveImageRequestCanBeCancelledAndRestartedSuccessfully() {
        // Given
        let button = UIButton()
        let expectation = expectationWithDescription("image download should succeed")

        var completion1Called = false
        var completion2Called = false
        var result: Result<UIImage, NSError>?

        // When
        button.af_setImageForState(
            .Normal,
            URLRequest: NSURLRequest(URL: URL),
            placeholderImage: nil,
            completion: { closureResponse in
                completion1Called = true
            }
        )

        button.af_cancelImageRequestForState(.Normal)

        button.af_setImageForState(
            .Normal,
            URLRequest: NSURLRequest(URL: URL),
            placeholderImage: nil,
            completion: { closureResponse in
                completion2Called = true
                result = closureResponse.result
                expectation.fulfill()
            }
        )

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertTrue(completion1Called)
        XCTAssertTrue(completion2Called)
        XCTAssertNotNil(button.imageForState(.Normal))
        XCTAssertTrue(result?.isSuccess ?? false)
    }

    func testThatActiveBackgroundImageRequestCanBeCancelledAndRestartedSuccessfully() {
        // Given
        let button = UIButton()
        let expectation = expectationWithDescription("background image download should succeed")

        var completion1Called = false
        var completion2Called = false
        var result: Result<UIImage, NSError>?

        // When
        button.af_setBackgroundImageForState(
            .Normal,
            URLRequest: NSURLRequest(URL: URL),
            placeholderImage: nil,
            completion: { closureResponse in
                completion1Called = true
            }
        )

        button.af_cancelBackgroundImageRequestForState(.Normal)

        button.af_setBackgroundImageForState(
            .Normal,
            URLRequest: NSURLRequest(URL: URL),
            placeholderImage: nil,
            completion: { closureResponse in
                completion2Called = true
                result = closureResponse.result
                expectation.fulfill()
            }
        )

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertTrue(completion1Called)
        XCTAssertTrue(completion2Called)
        XCTAssertNotNil(button.backgroundImageForState(.Normal))
        XCTAssertTrue(result?.isSuccess ?? false)
    }

    // MARK: - Redirects

    func testThatImageBehindRedirectCanBeDownloaded() {
        // Given
        let redirectURLString = "https://httpbin.org/image/png"
        let URL = NSURL(string: "https://httpbin.org/redirect-to?url=\(redirectURLString)")!

        let expectation = expectationWithDescription("image should download successfully")
        var imageDownloadComplete = false

        let button = TestButton {
            imageDownloadComplete = true
            expectation.fulfill()
        }

        // When
        button.af_setImageForState(.Normal, URL: URL)
        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertTrue(imageDownloadComplete, "image download complete should be true")
        XCTAssertNotNil(button.imageForState(.Normal), "button image should not be nil")
    }

    func testThatBackgroundImageBehindRedirectCanBeDownloaded() {
        // Given
        let redirectURLString = "https://httpbin.org/image/png"
        let URL = NSURL(string: "https://httpbin.org/redirect-to?url=\(redirectURLString)")!

        let expectation = expectationWithDescription("image should download successfully")
        var backgroundImageDownloadComplete = false

        let button = TestButton {
            backgroundImageDownloadComplete = true
            expectation.fulfill()
        }

        // When
        button.af_setBackgroundImageForState(.Normal, URL: URL)
        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertTrue(backgroundImageDownloadComplete, "image download complete should be true")
        XCTAssertNotNil(button.backgroundImageForState(.Normal), "button background image should not be nil")
    }

    // MARK: - Accept Header

    func testThatAcceptHeaderMatchesAcceptableContentTypes() {
        // Given
        let button = UIButton()

        // When
        button.af_setImageForState(.Normal, URL: URL)
        let acceptField = button.imageRequestReceiptForState(.Normal)?.request.request?.allHTTPHeaderFields?["Accept"]
        button.af_cancelImageRequestForState(.Normal)

        // Then
        XCTAssertNotNil(acceptField)

        if let acceptField = acceptField {
            XCTAssertEqual(acceptField, Request.acceptableImageContentTypes.joinWithSeparator(","))
        }
    }
}
