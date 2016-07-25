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
    var imageObserver: ((Void) -> Void)?

    required init(imageObserver: ((Void) -> Void)? = nil) {
        self.imageObserver = imageObserver
        super.init(frame: CGRect.zero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setBackgroundImage(_ image: UIImage?, for state: UIControlState) {
        super.setBackgroundImage(image, for: state)
        imageObserver?()
    }

    override func setImage(_ image: UIImage?, for state: UIControlState) {
        super.setImage(image, for: state)
        imageObserver?()
    }
}

// MARK: -

class UIButtonTests: BaseTestCase {
    let url = Foundation.URL(string: "https://httpbin.org/image/jpeg")!

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
        let expectation = self.expectation(description: "image should download successfully")
        var imageDownloadComplete = false

        let button = TestButton {
            imageDownloadComplete = true
            expectation.fulfill()
        }

        // When
        button.af_setImageForState([], url: url)
        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertTrue(imageDownloadComplete)
    }

    func testThatBackgroundImageCanBeDownloadedFromURL() {
        // Given
        let expectation = self.expectation(description: "background image should download successfully")
        var backgroundImageDownloadComplete = false

        let button = TestButton {
            backgroundImageDownloadComplete = true
            expectation.fulfill()
        }

        // When
        button.af_setBackgroundImageForState([], url: url)
        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertTrue(backgroundImageDownloadComplete)
    }

    func testThatImageCanBeCancelledAndDownloadedFromURL () {
        // Given
        let expectation = self.expectation(description: "image should cancel and download successfully")
        let button = UIButton()
        var result: Result<UIImage, NSError>?

        // When
        button.af_setImageForState([], url: url)
        button.af_cancelImageRequestForState([])
        button.af_setImageForState(
            [],
            urlRequest: URLRequest(url: url),
            placeholderImage: nil) { response in
                result = response.result
                expectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: timeout, handler: nil)
        XCTAssertNotNil(result?.value)
    }

    func testThatBackgroundImageCanBeCancelledAndDownloadedFromURL () {
        // Given
        let expectation = self.expectation(description: "background image should cancel and download successfully")
        let button = UIButton()
        var result: Result<UIImage, NSError>?

        // When
        button.af_setBackgroundImageForState([], url: url)
        button.af_cancelBackgroundImageRequestForState([])
        button.af_setBackgroundImageForState(
            [],
            urlRequest: URLRequest(url: url),
            placeholderImage: nil) { response in
                result = response.result
                expectation.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertNotNil(result?.value)
    }

    func testThatActiveImageRequestReceiptIsNilAfterImageDownloadCompletes() {
        // Given
        let expectation = self.expectation(description: "image should download successfully")
        var imageDownloadComplete = false

        let button = TestButton {
            imageDownloadComplete = true
            expectation.fulfill()
        }

        // When
        button.af_setImageForState([], url: url)
        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertTrue(imageDownloadComplete)
        XCTAssertNil(button.backgroundImageRequestReceiptForState([]))
    }

    func testThatActiveBackgroundImageRequestReceiptIsNilAfterImageDownloadCompletes() {
        // Given
        let expectation = self.expectation(description: "background image should download successfully")
        var backgroundImageDownloadComplete = false

        let button = TestButton {
            backgroundImageDownloadComplete = true
            expectation.fulfill()
        }

        // When
        button.af_setBackgroundImageForState([], url: url)
        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertTrue(backgroundImageDownloadComplete)
        XCTAssertNil(button.backgroundImageRequestReceiptForState([]))
    }

    func testThatMultipleImageRequestReceiptStatesCanBeDownloadedInParallel() {
        // Given
        let button = TestButton()
        var _url = url

        // When
        let expectation1 = expectation(description: "background image should download successfully")
        var normalStateImageDownloadComplete = false
        button.af_setImageForState([], url: _url)
        button.imageObserver = {
            normalStateImageDownloadComplete = true
            expectation1.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        let expectation2 = expectation(description: "background image should download successfully")
        var selectedStateImageDownloadComplete = false
        _url = Foundation.URL(string: "https://httpbin.org/image/jpeg?random=\(arc4random())")!

        button.af_setImageForState([.selected], url: _url)
        button.imageObserver = {
            selectedStateImageDownloadComplete = true
            expectation2.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        let expectation3 = expectation(description: "background image should download successfully")
        var highlightedStateImageDownloadComplete = false
        _url = Foundation.URL(string: "https://httpbin.org/image/jpeg?random=\(arc4random())")!

        button.af_setImageForState([.highlighted], url: _url)
        button.imageObserver = {
            highlightedStateImageDownloadComplete = true
            expectation3.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        let expectation4 = expectation(description: "background image should download successfully")
        var disabledStateImageDownloadComplete = false
        _url = Foundation.URL(string: "https://httpbin.org/image/jpeg?random=\(arc4random())")!

        button.af_setImageForState([.disabled], url: _url)
        button.imageObserver = {
            disabledStateImageDownloadComplete = true
            expectation4.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertTrue(normalStateImageDownloadComplete)
        XCTAssertNotNil(button.image(for: UIControlState()))

        XCTAssertTrue(selectedStateImageDownloadComplete)
        XCTAssertNotNil(button.image(for: .selected))

        XCTAssertTrue(highlightedStateImageDownloadComplete)
        XCTAssertNotNil(button.image(for: .highlighted))

        XCTAssertTrue(disabledStateImageDownloadComplete)
        XCTAssertNotNil(button.image(for: .disabled))
    }

    func testThatMultipleBackgroundImageRequestReceiptStatesCanBeDownloadedInParallel() {
        // Given
        let button = TestButton()
        var _url = url

        // When
        let expectation1 = expectation(description: "background image should download successfully")
        var normalStateBackgroundImageDownloadComplete = false
        button.af_setBackgroundImageForState([], url: _url)
        button.imageObserver = {
            normalStateBackgroundImageDownloadComplete = true
            expectation1.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
        let expectation2 = expectation(description: "background image should download successfully")
        var selectedStateBackgroundImageDownloadComplete = false
        _url = Foundation.URL(string: "https://httpbin.org/image/jpeg?random=\(arc4random())")!

        button.af_setBackgroundImageForState([.selected], url: _url)
        button.imageObserver = {
            selectedStateBackgroundImageDownloadComplete = true
            expectation2.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        let expectation3 = expectation(description: "background image should download successfully")
        var highlightedStateBackgroundImageDownloadComplete = false
        _url = Foundation.URL(string: "https://httpbin.org/image/jpeg?random=\(arc4random())")!

        button.af_setBackgroundImageForState([.highlighted], url: _url)
        button.imageObserver = {
            highlightedStateBackgroundImageDownloadComplete = true
            expectation3.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        let expectation4 = expectation(description: "background image should download successfully")
        var disabledStateBackgroundImageDownloadComplete = false
        _url = Foundation.URL(string: "https://httpbin.org/image/jpeg?random=\(arc4random())")!

        button.af_setBackgroundImageForState([.disabled], url: _url)
        button.imageObserver = {
            disabledStateBackgroundImageDownloadComplete = true
            expectation4.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertTrue(normalStateBackgroundImageDownloadComplete)
        XCTAssertNotNil(button.backgroundImage(for: UIControlState()))

        XCTAssertTrue(selectedStateBackgroundImageDownloadComplete)
        XCTAssertNotNil(button.backgroundImage(for: .selected))

        XCTAssertTrue(highlightedStateBackgroundImageDownloadComplete)
        XCTAssertNotNil(button.backgroundImage(for: .highlighted))

        XCTAssertTrue(disabledStateBackgroundImageDownloadComplete)
        XCTAssertNotNil(button.backgroundImage(for: .disabled))
    }

    // MARK: - Image Downloaders

    func testThatImageDownloaderOverridesSharedImageDownloader() {
        // Given
        let expectation = self.expectation(description: "image should download successfully")
        var imageDownloadComplete = false

        let button = TestButton {
            imageDownloadComplete = true
            expectation.fulfill()
        }

        let configuration = URLSessionConfiguration.ephemeral
        let imageDownloader = ImageDownloader(configuration: configuration)
        button.af_imageDownloader = imageDownloader

        // When
        button.af_setImageForState([], url: url)
        let activeRequestCount = imageDownloader.activeRequestCount

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertTrue(imageDownloadComplete)
        XCTAssertNil(button.imageRequestReceiptForState([]), "active request receipt should be nil after download completes")
        XCTAssertEqual(activeRequestCount, 1, "active request count should be 1")
    }

    // MARK: - Image Cache

    func testThatImageCanBeLoadedFromImageCache() {
        // Given
        let button = UIButton()

        let downloader = ImageDownloader.defaultInstance
        let download = URLRequest(.GET, url.absoluteString!)
        let expectation = self.expectation(description: "image download should succeed")

        downloader.downloadImage(urlRequest: download) { _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // When
        button.af_setImageForState([], url: url)
        button.af_cancelImageRequestForState([])

        // Then
        XCTAssertNotNil(button.image(for: UIControlState()), "button image should not be nil")
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
        let expectation = self.expectation(description: "image should download successfully")

        var imageDownloadComplete = false
        var finalImageEqualsPlaceholderImage = false

        let button = TestButton ()

        // When
        button.af_setImageForState([], url: url, placeHolderImage: placeholderImage)
        let initialImageEqualsPlaceholderImage = button.image(for:[]) === placeholderImage

        button.imageObserver = {
            imageDownloadComplete = true
            finalImageEqualsPlaceholderImage = button.image(for:[]) === placeholderImage
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertTrue(imageDownloadComplete)
        XCTAssertTrue(initialImageEqualsPlaceholderImage, "initial image should equal placeholder image")
        XCTAssertFalse(finalImageEqualsPlaceholderImage, "final image should not equal placeholder image")
    }

    func testThatBackgroundPlaceholderImageIsDisplayedUntilImageIsDownloadedFromURL() {
        // Given
        let placeholderImage = imageForResource("pirate", withExtension: "jpg")
        let expectation = self.expectation(description: "image should download successfully")

        var backgroundImageDownloadComplete = false
        var finalBackgroundImageEqualsPlaceholderImage = false

        let button = TestButton ()

        // When
        button.af_setBackgroundImageForState([], url: url, placeHolderImage: placeholderImage)
        let initialImageEqualsPlaceholderImage = button.backgroundImage(for:[]) === placeholderImage

        button.imageObserver = {
            backgroundImageDownloadComplete = true
            finalBackgroundImageEqualsPlaceholderImage = button.backgroundImage(for:[]) === placeholderImage
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

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
        let download = URLRequest(.GET, url.absoluteString!)
        let expectation = self.expectation(description: "image download should succeed")

        downloader.downloadImage(urlRequest: download) { _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // When
        button.af_setImageForState([], url: url, placeHolderImage: placeholderImage)

        // Then
        XCTAssertNotNil(button.image(for: UIControlState()), "button image should not be nil")
        XCTAssertFalse(button.image(for:[]) === placeholderImage, "button image should not equal placeholder image")
    }

    func testThatBackgroundPlaceholderIsNeverDisplayedIfCachedImageIsAvailable() {
        // Given
        let placeholderImage = imageForResource("pirate", withExtension: "jpg")
        let button = UIButton()

        let downloader = ImageDownloader.defaultInstance
        let download = URLRequest(.GET, url.absoluteString!)
        let expectation = self.expectation(description: "image download should succeed")

        downloader.downloadImage(urlRequest: download) { _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // When
        button.af_setBackgroundImageForState([], url: url, placeHolderImage: placeholderImage)

        // Then
        XCTAssertNotNil(button.backgroundImage(for: UIControlState()), "button background image should not be nil")
        XCTAssertFalse(button.backgroundImage(for:[]) === placeholderImage, "button background image should not equal placeholder image")
    }

    // MARK: - Completion Handler

    func testThatCompletionHandlerIsCalledWhenImageDownloadSucceeds() {
        // Given
        let button = UIButton()

        let urlRequest: Foundation.URLRequest = {
            var request = URLRequest(url: url)
            request.addValue("image/*", forHTTPHeaderField: "Accept")
            return request
        }()

        let expectation = self.expectation(description: "image download should succeed")

        var completionHandlerCalled = false
        var result: Result<UIImage, NSError>?

        // When
        button.af_setImageForState([], urlRequest: urlRequest, placeholderImage: nil) { response in
            completionHandlerCalled = true
            result = response.result
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertTrue(completionHandlerCalled, "completion handler called should be true")
        XCTAssertNotNil(button.image(for: UIControlState()), "button image should be not be nil")
        XCTAssertTrue(result?.isSuccess ?? false, "result should be a success case")
    }

    func testThatCompletionHandlerIsCalledWhenBackgroundImageDownloadSucceeds() {
        // Given
        let button = UIButton()

        let urlRequest: Foundation.URLRequest = {
            var request = URLRequest(url: url)
            request.addValue("image/*", forHTTPHeaderField: "Accept")
            return request
        }()

        let expectation = self.expectation(description: "image download should succeed")

        var completionHandlerCalled = false
        var result: Result<UIImage, NSError>?

        // When
        button.af_setBackgroundImageForState([], urlRequest: urlRequest, placeholderImage: nil) { response in
            completionHandlerCalled = true
            result = response.result
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertTrue(completionHandlerCalled, "completion handler called should be true")
        XCTAssertNotNil(button.backgroundImage(for: UIControlState()), "button background image should be not be nil")
        XCTAssertTrue(result?.isSuccess ?? false, "result should be a success case")
    }

    func testThatCompletionHandlerIsCalledWhenImageDownloadFails() {
        // Given
        let button = UIButton()
        let urlRequest = Foundation.URLRequest(url: Foundation.URL(string: "really-bad-domain")!)

        let expectation = self.expectation(description: "image download should succeed")

        var completionHandlerCalled = false
        var result: Result<UIImage, NSError>?

        // When
        button.af_setImageForState([], urlRequest: urlRequest, placeholderImage: nil) { response in
            completionHandlerCalled = true
            result = response.result
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertTrue(completionHandlerCalled, "completion handler called should be true")
        XCTAssertNil(button.image(for: UIControlState()), "button image should be nil")
        XCTAssertTrue(result?.isFailure ?? false, "result should be a failure case")
    }

    func testThatCompletionHandlerIsCalledWhenBackgroundImageDownloadFails() {
        // Given
        let button = UIButton()
        let urlRequest = Foundation.URLRequest(url: Foundation.URL(string: "really-bad-domain")!)

        let expectation = self.expectation(description: "image download should succeed")

        var completionHandlerCalled = false
        var result: Result<UIImage, NSError>?

        // When
        button.af_setBackgroundImageForState([], urlRequest: urlRequest, placeholderImage: nil) { response in
            completionHandlerCalled = true
            result = response.result
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertTrue(completionHandlerCalled, "completion handler called should be true")
        XCTAssertNil(button.backgroundImage(for: UIControlState()), "button background image should be nil")
        XCTAssertTrue(result?.isFailure ?? false, "result should be a failure case")
    }

    // MARK: - Cancellation

    func testThatImageDownloadCanBeCancelled() {
        // Given
        let button = UIButton()
        let urlRequest = Foundation.URLRequest(url: Foundation.URL(string: "domain-name-does-not-exist")!)

        let expectation = self.expectation(description: "image download should succeed")

        var completionHandlerCalled = false
        var result: Result<UIImage, NSError>?

        // When
        button.af_setImageForState(
            [],
            urlRequest: urlRequest,
            placeholderImage: nil,
            completion: { closureResponse in
                completionHandlerCalled = true
                result = closureResponse.result
                expectation.fulfill()
            }
        )

        button.af_cancelImageRequestForState([])
        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertTrue(completionHandlerCalled)
        XCTAssertNil(button.image(for: UIControlState()))
        XCTAssertTrue(result?.isFailure ?? false)
    }

    func testThatBackgroundImageDownloadCanBeCancelled() {
        // Given
        let button = UIButton()
        let urlRequest = Foundation.URLRequest(url: Foundation.URL(string: "domain-name-does-not-exist")!)

        let expectation = self.expectation(description: "background image download should succeed")

        var completionHandlerCalled = false
        var result: Result<UIImage, NSError>?

        // When
        button.af_setBackgroundImageForState(
            [],
            urlRequest: urlRequest,
            placeholderImage: nil,
            completion: { closureResponse in
                completionHandlerCalled = true
                result = closureResponse.result
                expectation.fulfill()
            }
        )

        button.af_cancelBackgroundImageRequestForState([])
        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertTrue(completionHandlerCalled)
        XCTAssertNil(button.backgroundImage(for: UIControlState()))
        XCTAssertTrue(result?.isFailure ?? false)
    }

    func testThatActiveImageRequestIsAutomaticallyCancelledBySettingNewURL() {
        // Given
        let button = UIButton()
        let expectation = self.expectation(description: "image download should succeed")

        var completion1Called = false
        var completion2Called = false
        var result: Result<UIImage, NSError>?

        // When
        button.af_setImageForState(
            [],
            urlRequest: URLRequest(url: url),
            placeholderImage: nil,
            completion: { closureResponse in
                completion1Called = true
            }
        )

        button.af_setImageForState(
            [],
            urlRequest: URLRequest(url: Foundation.URL(string: "https://httpbin.org/image/png")!),
            placeholderImage: nil,
            completion: { closureResponse in
                completion2Called = true
                result = closureResponse.result
                expectation.fulfill()
            }
        )

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertTrue(completion1Called)
        XCTAssertTrue(completion2Called)
        XCTAssertNotNil(button.image(for: UIControlState()))
        XCTAssertTrue(result?.isSuccess ?? false)
    }

    func testThatActiveBackgroundImageRequestIsAutomaticallyCancelledBySettingNewURL() {
        // Given
        let button = UIButton()
        let expectation = self.expectation(description: "background image download should succeed")

        var completion1Called = false
        var completion2Called = false
        var result: Result<UIImage, NSError>?

        // When
        button.af_setBackgroundImageForState(
            [],
            urlRequest: URLRequest(url: url),
            placeholderImage: nil,
            completion: { closureResponse in
                completion1Called = true
            }
        )

        button.af_setBackgroundImageForState(
            [],
            urlRequest: URLRequest(url: Foundation.URL(string: "https://httpbin.org/image/png")!),
            placeholderImage: nil,
            completion: { closureResponse in
                completion2Called = true
                result = closureResponse.result
                expectation.fulfill()
            }
        )

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertTrue(completion1Called)
        XCTAssertTrue(completion2Called)
        XCTAssertNotNil(button.backgroundImage(for: UIControlState()))
        XCTAssertTrue(result?.isSuccess ?? false)
    }

    func testThatActiveImageRequestCanBeCancelledAndRestartedSuccessfully() {
        // Given
        let button = UIButton()
        let expectation = self.expectation(description: "image download should succeed")

        var completion1Called = false
        var completion2Called = false
        var result: Result<UIImage, NSError>?

        // When
        button.af_setImageForState(
            [],
            urlRequest: URLRequest(url: url),
            placeholderImage: nil,
            completion: { closureResponse in
                completion1Called = true
            }
        )

        button.af_cancelImageRequestForState([])

        button.af_setImageForState(
            [],
            urlRequest: URLRequest(url: url),
            placeholderImage: nil,
            completion: { closureResponse in
                completion2Called = true
                result = closureResponse.result
                expectation.fulfill()
            }
        )

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertTrue(completion1Called)
        XCTAssertTrue(completion2Called)
        XCTAssertNotNil(button.image(for: UIControlState()))
        XCTAssertTrue(result?.isSuccess ?? false)
    }

    func testThatActiveBackgroundImageRequestCanBeCancelledAndRestartedSuccessfully() {
        // Given
        let button = UIButton()
        let expectation = self.expectation(description: "background image download should succeed")

        var completion1Called = false
        var completion2Called = false
        var result: Result<UIImage, NSError>?

        // When
        button.af_setBackgroundImageForState(
            [],
            urlRequest: URLRequest(url: url),
            placeholderImage: nil,
            completion: { closureResponse in
                completion1Called = true
            }
        )

        button.af_cancelBackgroundImageRequestForState([])

        button.af_setBackgroundImageForState(
            [],
            urlRequest: URLRequest(url: url),
            placeholderImage: nil,
            completion: { closureResponse in
                completion2Called = true
                result = closureResponse.result
                expectation.fulfill()
            }
        )

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertTrue(completion1Called)
        XCTAssertTrue(completion2Called)
        XCTAssertNotNil(button.backgroundImage(for: UIControlState()))
        XCTAssertTrue(result?.isSuccess ?? false)
    }

    // MARK: - Redirects

    func testThatImageBehindRedirectCanBeDownloaded() {
        // Given
        let redirectURLString = "https://httpbin.org/image/png"
        let url = Foundation.URL(string: "https://httpbin.org/redirect-to?url=\(redirectURLString)")!

        let expectation = self.expectation(description: "image should download successfully")
        var imageDownloadComplete = false

        let button = TestButton {
            imageDownloadComplete = true
            expectation.fulfill()
        }

        // When
        button.af_setImageForState([], url: url)
        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertTrue(imageDownloadComplete, "image download complete should be true")
        XCTAssertNotNil(button.image(for: UIControlState()), "button image should not be nil")
    }

    func testThatBackgroundImageBehindRedirectCanBeDownloaded() {
        // Given
        let redirectURLString = "https://httpbin.org/image/png"
        let url = Foundation.URL(string: "https://httpbin.org/redirect-to?url=\(redirectURLString)")!

        let expectation = self.expectation(description: "image should download successfully")
        var backgroundImageDownloadComplete = false

        let button = TestButton {
            backgroundImageDownloadComplete = true
            expectation.fulfill()
        }

        // When
        button.af_setBackgroundImageForState([], url: url)
        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertTrue(backgroundImageDownloadComplete, "image download complete should be true")
        XCTAssertNotNil(button.backgroundImage(for: UIControlState()), "button background image should not be nil")
    }

    // MARK: - Accept Header

    func testThatAcceptHeaderMatchesAcceptableContentTypes() {
        // Given
        let button = UIButton()

        // When
        button.af_setImageForState([], url: url)
        let acceptField = button.imageRequestReceiptForState([])?.request.request?.allHTTPHeaderFields?["Accept"]
        button.af_cancelImageRequestForState([])

        // Then
        XCTAssertNotNil(acceptField)

        if let acceptField = acceptField {
            XCTAssertEqual(acceptField, Request.acceptableImageContentTypes.joined(separator: ","))
        }
    }
}
