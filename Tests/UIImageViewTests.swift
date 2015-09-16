// UIImageViewTests.swift
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

@testable import Alamofire
@testable import AlamofireImage
import Foundation
import UIKit
import XCTest

private class TestImageView: UIImageView {
    let imageKeyPath = "image"
    var kvoContext: UInt8 = 1
    var imageObserver: (Void -> Void)?

    convenience init(imageObserver: (Void -> Void)? = nil) {
        self.init(frame: CGRectZero)
        self.imageObserver = imageObserver
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addObserver(self, forKeyPath: imageKeyPath, options: NSKeyValueObservingOptions.New, context: &kvoContext)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        removeObserver(self, forKeyPath: imageKeyPath, context: &kvoContext)
    }

    override func observeValueForKeyPath(
        keyPath: String?,
        ofObject object: AnyObject?,
        change: [String: AnyObject]?,
        context: UnsafeMutablePointer<Void>)
    {
        if context == &kvoContext {
            imageObserver?()
        }
    }
}

// MARK: -

class UIImageViewTestCase: BaseTestCase {
    let URL = NSURL(string: "https://httpbin.org/image/jpeg")!

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()

        ImageDownloader.defaultURLCache().removeAllCachedResponses()
        ImageDownloader.defaultInstance.imageCache?.removeAllImages()
        UIImageView.af_sharedImageDownloader = ImageDownloader.defaultInstance
    }

    // MARK: - Image Download

    func testThatImageCanBeDownloadedFromURL() {
        // Given
        let expectation = expectationWithDescription("image should download successfully")
        var imageDownloadComplete = false

        let imageView = TestImageView {
            imageDownloadComplete = true
            expectation.fulfill()
        }

        // When
        imageView.af_setImageWithURL(URL)
        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertTrue(imageDownloadComplete, "image download complete should be true")
    }

    func testThatActiveRequestIsNilAfterImageDownloadCompletes() {
        // Given
        let expectation = expectationWithDescription("image should download successfully")
        var imageDownloadComplete = false

        let imageView = TestImageView {
            imageDownloadComplete = true
            expectation.fulfill()
        }

        // When
        imageView.af_setImageWithURL(URL)
        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertTrue(imageDownloadComplete, "image download complete should be true")
        XCTAssertNil(imageView.af_activeRequest, "active request should be nil after download completes")
    }

    // MARK: - Image Cache

    func testThatImageCanBeLoadedFromImageCacheFromRequestIdentifierIfAvailable() {
        // Given
        let imageView = UIImageView()

        let downloader = ImageDownloader.defaultInstance
        let download = URLRequest(.GET, "https://httpbin.org/image/jpeg")
        let expectation = expectationWithDescription("image download should succeed")

        downloader.downloadImage(URLRequest: download) { _, _, _ in
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // When
        imageView.af_setImageWithURL(URL)
        imageView.af_cancelImageRequest()

        // Then
        XCTAssertNotNil(imageView.image, "image view image should not be nil")
    }

    func testThatImageCanBeLoadedFromImageCacheFromRequestAndFilterIdentifierIfAvailable() {
        // Given
        let imageView = UIImageView()

        let downloader = ImageDownloader.defaultInstance
        let download = URLRequest(.GET, "https://httpbin.org/image/jpeg")
        let expectation = expectationWithDescription("image download should succeed")

        downloader.downloadImage(URLRequest: download, filter: CircleFilter()) { _, _, _ in
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // When
        imageView.af_setImageWithURL(URL, filter: CircleFilter())
        imageView.af_cancelImageRequest()

        // Then
        XCTAssertNotNil(imageView.image, "image view image should not be nil")
    }

    func testThatSharedImageCacheCanBeReplaced() {
        // Given
        let imageDownloader = ImageDownloader()

        // When
        let firstEqualityCheck = UIImageView.af_sharedImageDownloader === imageDownloader
        UIImageView.af_sharedImageDownloader = imageDownloader
        let secondEqualityCheck = UIImageView.af_sharedImageDownloader === imageDownloader

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

        let imageView = TestImageView()

        // When
        imageView.af_setImageWithURL(URL, placeholderImage: placeholderImage)
        let initialImageEqualsPlaceholderImage = imageView.image === placeholderImage

        imageView.imageObserver = {
            imageDownloadComplete = true
            finalImageEqualsPlaceholderImage = imageView.image === placeholderImage
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertTrue(imageDownloadComplete, "image download complete should be true")
        XCTAssertTrue(initialImageEqualsPlaceholderImage, "initial image should equal placeholder image")
        XCTAssertFalse(finalImageEqualsPlaceholderImage, "final image should not equal placeholder image")
    }

    func testThatPlaceholderIsNeverDisplayedIfCachedImageIsAvailable() {
        // Given
        let placeholderImage = imageForResource("pirate", withExtension: "jpg")
        let imageView = UIImageView()

        let downloader = ImageDownloader.defaultInstance
        let download = URLRequest(.GET, "https://httpbin.org/image/jpeg")
        let expectation = expectationWithDescription("image download should succeed")

        downloader.downloadImage(URLRequest: download) { _, _, _ in
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // When
        imageView.af_setImageWithURL(URL, placeholderImage: placeholderImage)

        // Then
        XCTAssertNotNil(imageView.image, "image view image should not be nil")
        XCTAssertFalse(imageView.image === placeholderImage, "image view should not equal placeholder image")
    }

    // MARK: - Image Filters

    func testThatImageFilterCanBeAppliedToDownloadedImageBeforeBeingDisplayed() {
        // Given
        let size = CGSize(width: 20, height: 20)
        let filter = ScaledToSizeFilter(size: size)

        let expectation = expectationWithDescription("image download should succeed")
        var imageDownloadComplete = false

        let imageView = TestImageView {
            imageDownloadComplete = true
            expectation.fulfill()
        }

        // When
        imageView.af_setImageWithURL(URL, filter: filter)
        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertTrue(imageDownloadComplete, "image download complete should be true")
        XCTAssertNotNil(imageView.image, "image view image should not be nil")

        if let image = imageView.image {
            XCTAssertEqual(image.size, size, "image size does not match expected value")
        }
    }

    // MARK: - Image Transitions

    func testThatImageTransitionIsAppliedAfterImageDownloadIsComplete() {
        // Given
        let expectation = expectationWithDescription("image download should succeed")
        var imageDownloadComplete = false

        let imageView = TestImageView {
            imageDownloadComplete = true
            expectation.fulfill()
        }

        // When
        imageView.af_setImageWithURL(URL, placeholderImage: nil, filter: nil, imageTransition: .CrossDissolve(0.5))
        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertTrue(imageDownloadComplete, "image download complete should be true")
        XCTAssertNotNil(imageView.image, "image view image should not be nil")
    }

    func testThatAllImageTransitionsCanBeApplied() {
        // Given
        let imageView = TestImageView()
        var imageTransitionsComplete = false

        // When
        let expectation1 = expectationWithDescription("image download should succeed")
        imageView.imageObserver = { expectation1.fulfill() }
        imageView.af_setImageWithURL(URL, imageTransition: .None)
        waitForExpectationsWithTimeout(timeout, handler: nil)

        let expectation2 = expectationWithDescription("image download should succeed")
        imageView.imageObserver = { expectation2.fulfill() }
        ImageDownloader.defaultInstance.imageCache?.removeAllImages()
        imageView.af_setImageWithURL(URL, imageTransition: .CrossDissolve(0.1))
        waitForExpectationsWithTimeout(timeout, handler: nil)

        let expectation3 = expectationWithDescription("image download should succeed")
        imageView.imageObserver = { expectation3.fulfill() }
        ImageDownloader.defaultInstance.imageCache?.removeAllImages()
        imageView.af_setImageWithURL(URL, imageTransition: .CurlDown(0.1))
        waitForExpectationsWithTimeout(timeout, handler: nil)

        let expectation4 = expectationWithDescription("image download should succeed")
        imageView.imageObserver = { expectation4.fulfill() }
        ImageDownloader.defaultInstance.imageCache?.removeAllImages()
        imageView.af_setImageWithURL(URL, imageTransition: .CurlUp(0.1))
        waitForExpectationsWithTimeout(timeout, handler: nil)

        let expectation5 = expectationWithDescription("image download should succeed")
        imageView.imageObserver = { expectation5.fulfill() }
        ImageDownloader.defaultInstance.imageCache?.removeAllImages()
        imageView.af_setImageWithURL(URL, imageTransition: .FlipFromBottom(0.1))
        waitForExpectationsWithTimeout(timeout, handler: nil)

        let expectation6 = expectationWithDescription("image download should succeed")
        imageView.imageObserver = { expectation6.fulfill() }
        ImageDownloader.defaultInstance.imageCache?.removeAllImages()
        imageView.af_setImageWithURL(URL, imageTransition: .FlipFromLeft(0.1))
        waitForExpectationsWithTimeout(timeout, handler: nil)

        let expectation7 = expectationWithDescription("image download should succeed")
        imageView.imageObserver = { expectation7.fulfill() }
        ImageDownloader.defaultInstance.imageCache?.removeAllImages()
        imageView.af_setImageWithURL(URL, imageTransition: .FlipFromRight(0.1))
        waitForExpectationsWithTimeout(timeout, handler: nil)

        let expectation8 = expectationWithDescription("image download should succeed")
        imageView.imageObserver = {
            expectation8.fulfill()
        }
        ImageDownloader.defaultInstance.imageCache?.removeAllImages()
        imageView.af_setImageWithURL(URL, imageTransition: .FlipFromTop(0.1))
        waitForExpectationsWithTimeout(timeout, handler: nil)

        let customTransition = UIImageView.ImageTransition.Custom(0.5, UIViewAnimationOptions(), {$0.image = $1}, nil)
        let expectation9 = expectationWithDescription("image download should succeed")
        imageView.imageObserver = {
            imageTransitionsComplete = true
            expectation9.fulfill()
        }
        ImageDownloader.defaultInstance.imageCache?.removeAllImages()
        imageView.af_setImageWithURL(URL, imageTransition: customTransition)
        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertTrue(imageTransitionsComplete, "image transitions complete should be true")
        XCTAssertNotNil(imageView.image, "image view image should not be nil")
    }

    // MARK: - Completion Handler

    func testThatCompletionHandlerIsCalledWhenImageDownloadSucceeds() {
        // Given
        let imageView = UIImageView()

        let URLRequest: NSURLRequest = {
            let request = NSMutableURLRequest(URL: URL)
            request.addValue("image/*", forHTTPHeaderField: "Accept")
            return request
        }()

        let expectation = expectationWithDescription("image download should succeed")

        var completionHandlerCalled = false
        var result: Result<UIImage>?

        // When
        imageView.af_setImageWithURLRequest(
            URLRequest,
            placeholderImage: nil,
            filter: nil,
            imageTransition: .None,
            completion: { _, _, responseResult in
                completionHandlerCalled = true
                result = responseResult
                expectation.fulfill()
            }
        )

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertTrue(completionHandlerCalled, "completion handler called should be true")
        XCTAssertNotNil(imageView.image, "image view image should be not be nil when completion handler is not nil")
        XCTAssertTrue(result?.isSuccess ?? false, "result should be a success case")
    }

    func testThatCompletionHandlerIsCalledWhenImageDownloadFails() {
        // Given
        let imageView = UIImageView()
        let URLRequest = NSURLRequest(URL: NSURL(string: "domain-name-does-not-exist")!)

        let expectation = expectationWithDescription("image download should succeed")

        var completionHandlerCalled = false
        var result: Result<UIImage>?

        // When
        imageView.af_setImageWithURLRequest(
            URLRequest,
            placeholderImage: nil,
            filter: nil,
            imageTransition: .None,
            completion: { _, _, responseResult in
                completionHandlerCalled = true
                result = responseResult
                expectation.fulfill()
            }
        )

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertTrue(completionHandlerCalled, "completion handler called should be true")
        XCTAssertNil(imageView.image, "image view image should be nil when completion handler is not nil")
        XCTAssertTrue(result?.isFailure ?? false, "result should be a failure case")
    }

    func testThatCompletionHandlerAndCustomTransitionHandlerAreBothCalled() {
        // Given
        let imageView = UIImageView()

        let URLRequest: NSURLRequest = {
            let request = NSMutableURLRequest(URL: URL)
            request.addValue("image/*", forHTTPHeaderField: "Accept")
            return request
            }()

        let transitionExpectation = expectationWithDescription("image transition should complete")
        var transitionCompletionHandlerCalled = false
        let customTransition = UIImageView.ImageTransition.Custom(0.5, UIViewAnimationOptions(), {$0.image = $1}, { (_) in
            transitionCompletionHandlerCalled = true
            transitionExpectation.fulfill()
        })

        let expectation = expectationWithDescription("image download should succeed")
        var completionHandlerCalled = false
        var result: Result<UIImage>?

        // When
        imageView.af_setImageWithURLRequest(
            URLRequest,
            placeholderImage: nil,
            filter: nil,
            imageTransition: customTransition,
            completion: { _, _, responseResult in
                completionHandlerCalled = true
                result = responseResult
                expectation.fulfill()
            }
        )

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertTrue(completionHandlerCalled, "completion handler called should be true")
        XCTAssertTrue(transitionCompletionHandlerCalled, "transition completion hanlder called should be true")
        XCTAssertNotNil(imageView.image, "image view image should be not be nil when completion handler is not nil")
        XCTAssertTrue(result?.isSuccess ?? false, "result should be a success case")
    }

    // MARK: - Cancellation

    func testThatImageDownloadCanBeCancelled() {
        // Given
        let imageView = UIImageView()
        let URLRequest = NSURLRequest(URL: NSURL(string: "domain-name-does-not-exist")!)

        let expectation = expectationWithDescription("image download should succeed")

        var completionHandlerCalled = false
        var result: Result<UIImage>?

        // When
        imageView.af_setImageWithURLRequest(
            URLRequest,
            placeholderImage: nil,
            filter: nil,
            imageTransition: .None,
            completion: { _, _, responseResult in
                completionHandlerCalled = true
                result = responseResult
                expectation.fulfill()
            }
        )

        imageView.af_cancelImageRequest()
        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertTrue(completionHandlerCalled, "completion handler called should be true")
        XCTAssertNil(imageView.image, "image view image should be nil when completion handler is not nil")
        XCTAssertTrue(result?.isFailure ?? false, "result should be a failure case")
    }

    func testThatActiveRequestIsAutomaticallyCancelledBySettingNewURL() {
        // Given
        let imageView = UIImageView()
        let expectation = expectationWithDescription("image download should succeed")

        var completion1Called = false
        var completion2Called = false
        var result: Result<UIImage>?

        // When
        imageView.af_setImageWithURLRequest(
            NSURLRequest(URL: URL),
            placeholderImage: nil,
            filter: nil,
            imageTransition: .None,
            completion: { _, _, _ in
                completion1Called = true
            }
        )

        imageView.af_cancelImageRequest()

        imageView.af_setImageWithURLRequest(
            NSURLRequest(URL: NSURL(string: "https://httpbin.org/image/png")!),
            placeholderImage: nil,
            filter: nil,
            imageTransition: .None,
            completion: { _, _, responseResult in
                completion2Called = true
                result = responseResult
                expectation.fulfill()
            }
        )

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertFalse(completion1Called, "completion 1 called should be false")
        XCTAssertTrue(completion2Called, "completion 2 called should be true")
        XCTAssertNotNil(imageView.image, "image view image should not be nil when completion handler is not nil")
        XCTAssertTrue(result?.isSuccess ?? false, "result should be a success case")
    }
}
