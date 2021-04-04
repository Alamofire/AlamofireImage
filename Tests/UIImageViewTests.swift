//
//  UIImageViewTests.swift
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

#if !os(macOS)

@testable import Alamofire
@testable import AlamofireImage
import Foundation
import UIKit
import XCTest

private final class TestImageView: UIImageView {
    var imageObserver: (() -> Void)?

    convenience init(imageObserver: (() -> Void)? = nil) {
        self.init(frame: CGRect.zero)
        self.imageObserver = imageObserver
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var image: UIImage? {
        get {
            super.image
        }
        set {
            super.image = newValue
            imageObserver?()
        }
    }
}

// MARK: -

final class UIImageViewTestCase: BaseTestCase {
    let endpoint = Endpoint.image(.jpeg)
    var url: URL { endpoint.url }

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()

        ImageDownloader.defaultURLCache().removeAllCachedResponses()
        ImageDownloader.default.imageCache?.removeAllImages()
        UIImageView.af.sharedImageDownloader = ImageDownloader.default
    }

    // MARK: - Image Download

    func testThatImageCanBeDownloadedFromURL() {
        // Given
        let expectation = self.expectation(description: "image should download successfully")
        var imageDownloadComplete = false

        let imageView = TestImageView {
            imageDownloadComplete = true
            expectation.fulfill()
        }

        // When
        imageView.af.setImage(withURL: url)
        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(imageDownloadComplete, "image download complete should be true")
    }

    func testThatImageDownloadSucceedsWhenDuplicateRequestIsSentToImageView() {
        // Given
        let expectation = self.expectation(description: "image should download successfully")
        var imageDownloadComplete = false

        let imageView = TestImageView {
            imageDownloadComplete = true
            expectation.fulfill()
        }

        // When
        imageView.af.setImage(withURL: url)
        imageView.af.setImage(withURL: url)
        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(imageDownloadComplete, "image download complete should be true")
        XCTAssertNotNil(imageView.image, "image view image should not be nil")
    }

    func testThatActiveRequestIsNilAfterImageDownloadCompletes() {
        // Given
        let expectation = self.expectation(description: "image should download successfully")
        var imageDownloadComplete = false

        let imageView = TestImageView {
            imageDownloadComplete = true
            expectation.fulfill()
        }

        // When
        imageView.af.setImage(withURL: url)
        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(imageDownloadComplete, "image download complete should be true")
        XCTAssertNil(imageView.af.activeRequestReceipt, "active request receipt should be nil after download completes")
    }

    // MARK: - Image Downloaders

    func testThatImageDownloaderOverridesSharedImageDownloader() {
        // Given
        let expectation = self.expectation(description: "image should download successfully")
        var imageDownloadComplete = false

        let imageView = TestImageView {
            imageDownloadComplete = true
            expectation.fulfill()
        }

        let configuration = URLSessionConfiguration.ephemeral
        let imageDownloader = ImageDownloader(configuration: configuration)
        imageView.af.imageDownloader = imageDownloader

        // When
        imageView.af.setImage(withURL: url)
        let activeRequestCount = imageDownloader.activeRequestCount

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(imageDownloadComplete, "image download complete should be true")
        XCTAssertNil(imageView.af.activeRequestReceipt, "active request receipt should be nil after download completes")
        XCTAssertEqual(activeRequestCount, 1, "active request count should be 1")
    }

    // MARK: - Image Response Serializers

    func testThatCustomImageSerializerCanBeUsed() {
        // Given
        let expectation = self.expectation(description: "image should download successfully")
        var imageDownloadComplete = false

        let imageView = TestImageView {
            imageDownloadComplete = true
            expectation.fulfill()
        }

        // When
        imageView.af.setImage(withURL: url,
                              serializer: ImageResponseSerializer(imageScale: 4.0, inflateResponseImage: false))

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(imageDownloadComplete, "image download complete should be true")
        XCTAssertEqual(imageView.image?.scale, 4.0)
        XCTAssertEqual(imageView.image?.af.isInflated, false)
    }

    // MARK: - Image Cache

    func testThatImageCanBeLoadedFromImageCacheFromRequestIdentifierIfAvailable() {
        // Given
        let imageView = UIImageView()

        let downloader = ImageDownloader.default
        let expectation = self.expectation(description: "image download should succeed")

        downloader.download(endpoint, completion: { _ in
            expectation.fulfill()
        })

        waitForExpectations(timeout: timeout)

        // When
        imageView.af.setImage(withURL: url)
        imageView.af.cancelImageRequest()

        // Then
        XCTAssertNotNil(imageView.image, "image view image should not be nil")
    }

    func testThatImageCanBeLoadedFromImageCacheFromRequestAndFilterIdentifierIfAvailable() {
        // Given
        let imageView = UIImageView()

        let downloader = ImageDownloader.default
        let expectation = self.expectation(description: "image download should succeed")

        downloader.download(endpoint, filter: CircleFilter(), completion: { _ in
            expectation.fulfill()
        })

        waitForExpectations(timeout: timeout)

        // When
        imageView.af.setImage(withURL: url, filter: CircleFilter())
        imageView.af.cancelImageRequest()

        // Then
        XCTAssertNotNil(imageView.image, "image view image should not be nil")
    }

    func testThatSharedImageCacheCanBeReplaced() {
        // Given
        let imageDownloader = ImageDownloader()

        // When
        let firstEqualityCheck = UIImageView.af.sharedImageDownloader === imageDownloader
        UIImageView.af.sharedImageDownloader = imageDownloader
        let secondEqualityCheck = UIImageView.af.sharedImageDownloader === imageDownloader

        // Then
        XCTAssertFalse(firstEqualityCheck, "first equality check should be false")
        XCTAssertTrue(secondEqualityCheck, "second equality check should be true")
    }

    func testThatImageCanBeCachedWithACustomCacheKey() {
        // Given
        let expectation = self.expectation(description: "image should download and be cached with custom key")
        let cacheKey = "cache-key"
        var imageCached = false

        let imageView = TestImageView {
            imageCached = (ImageDownloader.default.imageCache?.image(withIdentifier: cacheKey) != nil)
            expectation.fulfill()
        }

        // When
        imageView.af.setImage(withURL: url, cacheKey: cacheKey)
        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(imageCached, "image cached should be true")
    }

    // MARK: - Placeholder Images

    func testThatPlaceholderImageIsDisplayedUntilImageIsDownloadedFromURL() {
        // Given
        let placeholderImage = image(forResource: "pirate", withExtension: "jpg")
        let expectation = self.expectation(description: "image should download successfully")

        var imageDownloadComplete = false
        var finalImageEqualsPlaceholderImage = false

        let imageView = TestImageView()

        // When
        imageView.af.setImage(withURL: url, placeholderImage: placeholderImage)
        let initialImageEqualsPlaceholderImage = imageView.image === placeholderImage

        imageView.imageObserver = {
            imageDownloadComplete = true
            finalImageEqualsPlaceholderImage = imageView.image === placeholderImage
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(imageDownloadComplete, "image download complete should be true")
        XCTAssertTrue(initialImageEqualsPlaceholderImage, "initial image should equal placeholder image")
        XCTAssertFalse(finalImageEqualsPlaceholderImage, "final image should not equal placeholder image")
    }

    func testThatPlaceholderImageIsDisplayedWithThrowingURLConvertible() {
        // Given
        let placeholderImage = image(forResource: "pirate", withExtension: "jpg")
        let imageView = TestImageView()

        // When
        imageView.af.setImage(withURLRequest: ThrowingURLRequestConvertible(), placeholderImage: placeholderImage)
        let initialImageEqualsPlaceholderImage = imageView.image === placeholderImage

        // Then
        XCTAssertTrue(initialImageEqualsPlaceholderImage, "initial image should equal placeholder image")
    }

    func testThatPlaceholderIsNeverDisplayedIfCachedImageIsAvailable() {
        // Given
        let placeholderImage = image(forResource: "pirate", withExtension: "jpg")
        let imageView = UIImageView()

        let downloader = ImageDownloader.default
        let expectation = self.expectation(description: "image download should succeed")
        downloader.download(endpoint, completion: { _ in
            expectation.fulfill()
        })

        waitForExpectations(timeout: timeout)

        // When
        imageView.af.setImage(withURL: url, placeholderImage: placeholderImage)

        // Then
        XCTAssertNotNil(imageView.image, "image view image should not be nil")
        XCTAssertFalse(imageView.image === placeholderImage, "image view should not equal placeholder image")
    }

    // MARK: - Image Filters

    func testThatImageFilterCanBeAppliedToDownloadedImageBeforeBeingDisplayed() {
        // Given
        let size = CGSize(width: 20, height: 20)
        let filter = ScaledToSizeFilter(size: size)

        let expectation = self.expectation(description: "image download should succeed")
        var imageDownloadComplete = false

        let imageView = TestImageView {
            imageDownloadComplete = true
            expectation.fulfill()
        }

        // When
        imageView.af.setImage(withURL: url, filter: filter)
        waitForExpectations(timeout: timeout)

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
        let expectation = self.expectation(description: "image download should succeed")
        var imageDownloadComplete = false

        let imageView = TestImageView {
            imageDownloadComplete = true
            expectation.fulfill()
        }

        // When
        imageView.af.setImage(withURL: url, placeholderImage: nil, filter: nil, imageTransition: .crossDissolve(0.5))
        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(imageDownloadComplete, "image download complete should be true")
        XCTAssertNotNil(imageView.image, "image view image should not be nil")
    }

    func testThatAllImageTransitionsCanBeApplied() {
        // Given
        let imageView = TestImageView()
        var imageTransitionsComplete = false

        // When
        let expectation1 = expectation(description: "image download should succeed")
        imageView.imageObserver = { expectation1.fulfill() }
        imageView.af.setImage(withURL: url, imageTransition: .noTransition)
        waitForExpectations(timeout: timeout)

        let expectation2 = expectation(description: "image download should succeed")
        imageView.imageObserver = { expectation2.fulfill() }
        ImageDownloader.default.imageCache?.removeAllImages()
        imageView.af.setImage(withURL: url, imageTransition: .crossDissolve(0.1))
        waitForExpectations(timeout: timeout)

        let expectation3 = expectation(description: "image download should succeed")
        imageView.imageObserver = { expectation3.fulfill() }
        ImageDownloader.default.imageCache?.removeAllImages()
        imageView.af.setImage(withURL: url, imageTransition: .curlDown(0.1))
        waitForExpectations(timeout: timeout)

        let expectation4 = expectation(description: "image download should succeed")
        imageView.imageObserver = { expectation4.fulfill() }
        ImageDownloader.default.imageCache?.removeAllImages()
        imageView.af.setImage(withURL: url, imageTransition: .curlUp(0.1))
        waitForExpectations(timeout: timeout)

        let expectation5 = expectation(description: "image download should succeed")
        imageView.imageObserver = { expectation5.fulfill() }
        ImageDownloader.default.imageCache?.removeAllImages()
        imageView.af.setImage(withURL: url, imageTransition: .flipFromBottom(0.1))
        waitForExpectations(timeout: timeout)

        let expectation6 = expectation(description: "image download should succeed")
        imageView.imageObserver = { expectation6.fulfill() }
        ImageDownloader.default.imageCache?.removeAllImages()
        imageView.af.setImage(withURL: url, imageTransition: .flipFromLeft(0.1))
        waitForExpectations(timeout: timeout)

        let expectation7 = expectation(description: "image download should succeed")
        imageView.imageObserver = { expectation7.fulfill() }
        ImageDownloader.default.imageCache?.removeAllImages()
        imageView.af.setImage(withURL: url, imageTransition: .flipFromRight(0.1))
        waitForExpectations(timeout: timeout)

        let expectation8 = expectation(description: "image download should succeed")
        imageView.imageObserver = {
            expectation8.fulfill()
        }
        ImageDownloader.default.imageCache?.removeAllImages()
        imageView.af.setImage(withURL: url, imageTransition: .flipFromTop(0.1))
        waitForExpectations(timeout: timeout)

        let expectation9 = expectation(description: "image download should succeed")
        imageView.imageObserver = {
            imageTransitionsComplete = true
            expectation9.fulfill()
        }
        ImageDownloader.default.imageCache?.removeAllImages()
        imageView.af.setImage(withURL: url,
                              imageTransition: .custom(duration: 0.5,
                                                       animationOptions: [],
                                                       animations: { $0.image = $1 },
                                                       completion: nil))
        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(imageTransitionsComplete, "image transitions complete should be true")
        XCTAssertNotNil(imageView.image, "image view image should not be nil")
    }

    // MARK: - Completion Handler

    func testThatCompletionHandlerIsCalledWhenImageDownloadSucceeds() {
        // Given
        let imageView = UIImageView()

        let urlRequest: URLRequest = {
            var request = endpoint.urlRequest
            request.addValue("image/*", forHTTPHeaderField: "Accept")
            return request
        }()

        let expectation = self.expectation(description: "image download should succeed")

        var completionHandlerCalled = false
        var result: AFIResult<UIImage>?

        // When
        imageView.af.setImage(withURLRequest: urlRequest,
                              placeholderImage: nil,
                              filter: nil,
                              imageTransition: .noTransition,
                              completion: { closureResponse in
                                  completionHandlerCalled = true
                                  result = closureResponse.result
                                  expectation.fulfill()
                              })

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(completionHandlerCalled, "completion handler called should be true")
        XCTAssertNotNil(imageView.image, "image view image should be not be nil when completion handler is not nil")
        XCTAssertTrue(result?.isSuccess ?? false, "result should be a success case")
    }

    func testThatCompletionHandlerIsCalledWhenImageDownloadFails() {
        // Given
        let imageView = UIImageView()

        let expectation = self.expectation(description: "image download should complete")

        var completionHandlerCalled = false
        var result: AFIResult<UIImage>?

        // When
        imageView.af.setImage(withURLRequest: Endpoint.nonexistent,
                              placeholderImage: nil,
                              filter: nil,
                              imageTransition: .noTransition,
                              completion: { closureResponse in
                                  completionHandlerCalled = true
                                  result = closureResponse.result
                                  expectation.fulfill()
                              })

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(completionHandlerCalled, "completion handler called should be true")
        XCTAssertNil(imageView.image, "image view image should be nil when completion handler is not nil")
        XCTAssertTrue(result?.isFailure ?? false, "result should be a failure case")
    }

    func testThatCompletionHandlerIsCalledWhenURLRequestConvertibleThrows() {
        // Given
        let imageView = UIImageView()
        let urlRequest = ThrowingURLRequestConvertible()

        let expectation = self.expectation(description: "image download should complete")

        var completionHandlerCalled = false
        var result: AFIResult<UIImage>?

        // When
        imageView.af.setImage(withURLRequest: urlRequest,
                              placeholderImage: nil,
                              filter: nil,
                              imageTransition: .noTransition,
                              completion: { closureResponse in
                                  completionHandlerCalled = true
                                  result = closureResponse.result
                                  expectation.fulfill()
                              })

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(completionHandlerCalled, "completion handler called should be true")
        XCTAssertNil(imageView.image, "image view image should be nil when completion handler is not nil")
        XCTAssertEqual(result?.isFailure, true, "result should be a failure case")
    }

    func testThatCompletionHandlerAndCustomTransitionHandlerAreBothCalled() {
        // Given
        let imageView = UIImageView()

        let completionExpectation = expectation(description: "image download should succeed")
        let transitionExpectation = expectation(description: "image transition should complete")

        var completionHandlerCalled = false
        var transitionCompletionHandlerCalled = false

        var result: AFIResult<UIImage>?

        // When
        imageView.af.setImage(withURL: url,
                              placeholderImage: nil,
                              filter: nil,
                              imageTransition: .custom(duration: 0.1,
                                                       animationOptions: [],
                                                       animations: { $0.image = $1 },
                                                       completion: { _ in
                                                           transitionCompletionHandlerCalled = true
                                                           transitionExpectation.fulfill()
                                                       }),
                              completion: { closureResponse in
                                  completionHandlerCalled = true
                                  result = closureResponse.result

                                  completionExpectation.fulfill()
                              })

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(completionHandlerCalled, "completion handler called should be true")
        XCTAssertTrue(transitionCompletionHandlerCalled, "transition completion handler called should be true")
        XCTAssertNotNil(imageView.image, "image view image should be not be nil when completion handler is not nil")
        XCTAssertTrue(result?.isSuccess ?? false, "result should be a success case")
    }

    func testThatImageIsSetWhenReturnedFromCacheAndCompletionHandlerSet() {
        // Given
        let imageView = UIImageView()
        let urlRequest: URLRequest = {
            var request = endpoint.urlRequest
            request.addValue("image/*", forHTTPHeaderField: "Accept")
            return request
        }()

        let downloadExpectation = expectation(description: "image download should succeed")

        // When
        UIImageView.af.sharedImageDownloader.download(urlRequest, completion: { _ in
            downloadExpectation.fulfill()
        })

        waitForExpectations(timeout: timeout)

        let cachedExpectation = expectation(description: "image should be cached")
        var result: AFIResult<UIImage>?

        imageView.af.setImage(withURLRequest: urlRequest,
                              placeholderImage: nil,
                              filter: nil,
                              imageTransition: .noTransition,
                              completion: { closureResponse in
                                  result = closureResponse.result
                                  cachedExpectation.fulfill()
                              })

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(result?.value, "result value should not be nil")
        XCTAssertEqual(result?.value, imageView.image, "result value should be equal to image view image")
    }

    // MARK: - Cancellation

    func testThatImageDownloadCanBeCancelled() {
        // Given
        let imageView = UIImageView()

        let expectation = self.expectation(description: "image download should succeed")

        var completionHandlerCalled = false
        var result: AFIResult<UIImage>?

        // When
        imageView.af.setImage(withURLRequest: Endpoint.nonexistent,
                              placeholderImage: nil,
                              filter: nil,
                              imageTransition: .noTransition,
                              completion: { closureResponse in
                                  completionHandlerCalled = true
                                  result = closureResponse.result
                                  expectation.fulfill()
                              })

        imageView.af.cancelImageRequest()
        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(completionHandlerCalled, "completion handler called should be true")
        XCTAssertNil(imageView.image, "image view image should be nil when completion handler is not nil")
        XCTAssertTrue(result?.isFailure ?? false, "result should be a failure case")
    }

    func testThatActiveRequestIsAutomaticallyCancelledBySettingNewURL() {
        // Given
        let imageView = UIImageView()
        let expectation = self.expectation(description: "image download should succeed")

        var completion1Called = false
        var completion2Called = false
        var result: AFIResult<UIImage>?

        // When
        imageView.af.setImage(withURLRequest: endpoint,
                              placeholderImage: nil,
                              filter: nil,
                              imageTransition: .noTransition,
                              completion: { _ in
                                  completion1Called = true
                              })

        imageView.af.setImage(withURLRequest: Endpoint.image(.png),
                              placeholderImage: nil,
                              filter: nil,
                              imageTransition: .noTransition,
                              completion: { closureResponse in
                                  completion2Called = true
                                  result = closureResponse.result
                                  expectation.fulfill()
                              })

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(completion1Called, "completion 1 called should be true")
        XCTAssertTrue(completion2Called, "completion 2 called should be true")
        XCTAssertNotNil(imageView.image, "image view image should not be nil when completion handler is not nil")
        XCTAssertTrue(result?.isSuccess ?? false, "result should be a success case")
    }

    func testThatActiveRequestCanBeCancelledAndRestartedSuccessfully() {
        // Given
        let imageView = UIImageView()
        let expectation = self.expectation(description: "image download should succeed")

        var completion1Called = false
        var completion2Called = false
        var result: AFIResult<UIImage>?

        // When
        imageView.af.setImage(withURLRequest: endpoint,
                              placeholderImage: nil,
                              filter: nil,
                              imageTransition: .noTransition,
                              completion: { _ in
                                  completion1Called = true
                              })

        imageView.af.cancelImageRequest()

        imageView.af.setImage(withURLRequest: endpoint,
                              placeholderImage: nil,
                              filter: nil,
                              imageTransition: .noTransition,
                              completion: { closureResponse in
                                  completion2Called = true
                                  result = closureResponse.result
                                  expectation.fulfill()
                              })

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(completion1Called, "completion 1 called should be true")
        XCTAssertTrue(completion2Called, "completion 2 called should be true")
        XCTAssertNotNil(imageView.image, "image view image should not be nil when completion handler is not nil")
        XCTAssertTrue(result?.isSuccess ?? false, "result should be a success case")
    }

    func testThatActiveRequestCanBeCancelledAndImageViewIsDeallocated() {
        // Given
        var imageView: UIImageView? = UIImageView()
        let expectation = self.expectation(description: "image download should succeed")

        var completionCalled: Bool?
        var imageViewReleased: Bool?

        // When
        imageView?.af.setImage(withURLRequest: endpoint,
                               completion: { [weak imageView] _ in
                                   completionCalled = true
                                   imageViewReleased = imageView == nil

                                   expectation.fulfill()
                               })

        imageView = nil
        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertEqual(completionCalled, true)
        XCTAssertEqual(imageViewReleased, true)
    }

    // MARK: - Redirects

    func testThatImageBehindRedirectCanBeDownloaded() {
        // Given
        let expectation = self.expectation(description: "image should download successfully")
        var imageDownloadComplete = false

        let imageView = TestImageView {
            imageDownloadComplete = true
            expectation.fulfill()
        }

        // When
        imageView.af.setImage(withURL: Endpoint.redirectTo(.image(.png)).url)
        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(imageDownloadComplete, "image download complete should be true")
        XCTAssertNotNil(imageView.image, "image view image should not be nil")
    }

    // MARK: - Accept Header

    func testThatAcceptHeaderMatchesAcceptableContentTypes() {
        // Given
        let expectation = self.expectation(description: "image should download successfully")
        var acceptField: String?

        var imageView: TestImageView?
        imageView = TestImageView {
            acceptField = imageView?.af.activeRequestReceipt?.request.request?.headers["Accept"]
            expectation.fulfill()
        }

        // When
        imageView?.af.setImage(withURL: url)
        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertEqual(acceptField, ImageResponseSerializer.acceptableImageContentTypes.sorted().joined(separator: ","))
    }
}

#endif
