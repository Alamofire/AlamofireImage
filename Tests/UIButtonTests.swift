//
//  UIButtonTests.swift
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

#if !os(macOS) && !os(watchOS)

@testable import Alamofire
@testable import AlamofireImage
import UIKit
import XCTest

private final class TestButton: UIButton {
    var imageObserver: (() -> Void)?

    required init(imageObserver: (() -> Void)? = nil) {
        self.imageObserver = imageObserver

        super.init(frame: CGRect.zero)
    }

    override func setBackgroundImage(_ image: UIImage?, for state: ControlState) {
        super.setBackgroundImage(image, for: state)

        imageObserver?()
    }

    override func setImage(_ image: UIImage?, for state: ControlState) {
        super.setImage(image, for: state)

        imageObserver?()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: -

final class UIButtonTests: BaseTestCase {
    let endpoint = Endpoint.image(.jpeg)
    var url: URL { endpoint.url }

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()

        ImageDownloader.defaultURLCache().removeAllCachedResponses()
        ImageDownloader.default.imageCache?.removeAllImages()
        UIButton.af.sharedImageDownloader = ImageDownloader.default
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
        button.af.setImage(for: [], url: url)
        waitForExpectations(timeout: timeout)

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
        button.af.setBackgroundImage(for: [], url: url)
        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(backgroundImageDownloadComplete)
    }

    func testThatImageCanBeCancelledAndDownloadedFromURL() {
        // Given
        let expectation = self.expectation(description: "image should cancel and download successfully")
        let button = UIButton()
        var result: AFIResult<UIImage>?

        // When
        button.af.setImage(for: [], url: url)
        button.af.cancelImageRequest(for: [])
        button.af.setImage(for: [],
                           urlRequest: URLRequest(url: url),
                           placeholderImage: nil,
                           completion: { response in
                               result = response.result
                               expectation.fulfill()
                           })

        // Then
        waitForExpectations(timeout: timeout)
        XCTAssertNotNil(result?.value)
    }

    func testThatBackgroundImageCanBeCancelledAndDownloadedFromURL() {
        // Given
        let expectation = self.expectation(description: "background image should cancel and download successfully")
        let button = UIButton()
        var result: AFIResult<UIImage>?

        // When
        button.af.setBackgroundImage(for: [], url: url)
        button.af.cancelBackgroundImageRequest(for: [])
        button.af.setBackgroundImage(for: [],
                                     urlRequest: URLRequest(url: url),
                                     placeholderImage: nil,
                                     completion: { response in
                                         result = response.result
                                         expectation.fulfill()
                                     })

        waitForExpectations(timeout: timeout)

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
        button.af.setImage(for: [], url: url)
        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(imageDownloadComplete)
        XCTAssertNil(button.af.backgroundImageRequestReceipt(for: []))
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
        button.af.setBackgroundImage(for: [], url: url)
        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(backgroundImageDownloadComplete)
        XCTAssertNil(button.af.backgroundImageRequestReceipt(for: []))
    }

    func testThatMultipleImageRequestReceiptStatesCanBeDownloadedInParallel() {
        // Given
        let button = TestButton()
        var url = self.url

        // When
        let expectation1 = expectation(description: "background image should download successfully")
        var normalStateImageDownloadComplete = false
        button.af.setImage(for: [], url: url)
        button.imageObserver = {
            normalStateImageDownloadComplete = true
            expectation1.fulfill()
        }

        waitForExpectations(timeout: timeout)

        let expectation2 = expectation(description: "background image should download successfully")
        var selectedStateImageDownloadComplete = false
        url = Endpoint.image(.jpeg)
            .modifying(\.queryItems, to: [.init(name: "random", value: "\(arc4random())")])
            .url

        button.af.setImage(for: [.selected], url: url)
        button.imageObserver = {
            selectedStateImageDownloadComplete = true
            expectation2.fulfill()
        }

        waitForExpectations(timeout: timeout)

        let expectation3 = expectation(description: "background image should download successfully")
        var highlightedStateImageDownloadComplete = false
        url = Endpoint.image(.jpeg)
            .modifying(\.queryItems, to: [.init(name: "random", value: "\(arc4random())")])
            .url

        button.af.setImage(for: [.highlighted], url: url)
        button.imageObserver = {
            highlightedStateImageDownloadComplete = true
            expectation3.fulfill()
        }

        waitForExpectations(timeout: timeout)

        let expectation4 = expectation(description: "background image should download successfully")
        var disabledStateImageDownloadComplete = false
        url = Endpoint.image(.jpeg)
            .modifying(\.queryItems, to: [.init(name: "random", value: "\(arc4random())")])
            .url

        button.af.setImage(for: [.disabled], url: url)
        button.imageObserver = {
            disabledStateImageDownloadComplete = true
            expectation4.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(normalStateImageDownloadComplete)
        XCTAssertNotNil(button.image(for: []))

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
        var url = self.url

        // When
        let expectation1 = expectation(description: "background image should download successfully")
        var normalStateBackgroundImageDownloadComplete = false
        button.af.setBackgroundImage(for: [], url: url)
        button.imageObserver = {
            normalStateBackgroundImageDownloadComplete = true
            expectation1.fulfill()
        }

        waitForExpectations(timeout: timeout)
        let expectation2 = expectation(description: "background image should download successfully")
        var selectedStateBackgroundImageDownloadComplete = false
        url = Endpoint.image(.jpeg)
            .modifying(\.queryItems, to: [.init(name: "random", value: "\(arc4random())")])
            .url

        button.af.setBackgroundImage(for: [.selected], url: url)
        button.imageObserver = {
            selectedStateBackgroundImageDownloadComplete = true
            expectation2.fulfill()
        }

        waitForExpectations(timeout: timeout)

        let expectation3 = expectation(description: "background image should download successfully")
        var highlightedStateBackgroundImageDownloadComplete = false
        url = Endpoint.image(.jpeg)
            .modifying(\.queryItems, to: [.init(name: "random", value: "\(arc4random())")])
            .url

        button.af.setBackgroundImage(for: [.highlighted], url: url)
        button.imageObserver = {
            highlightedStateBackgroundImageDownloadComplete = true
            expectation3.fulfill()
        }

        waitForExpectations(timeout: timeout)

        let expectation4 = expectation(description: "background image should download successfully")
        var disabledStateBackgroundImageDownloadComplete = false
        url = Endpoint.image(.jpeg)
            .modifying(\.queryItems, to: [.init(name: "random", value: "\(arc4random())")])
            .url

        button.af.setBackgroundImage(for: [.disabled], url: url)
        button.imageObserver = {
            disabledStateBackgroundImageDownloadComplete = true
            expectation4.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(normalStateBackgroundImageDownloadComplete)
        XCTAssertNotNil(button.backgroundImage(for: []))

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
        button.af.imageDownloader = imageDownloader

        // When
        button.af.setImage(for: [], url: url)
        let activeRequestCount = imageDownloader.activeRequestCount

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(imageDownloadComplete)
        XCTAssertNil(button.af.imageRequestReceipt(for: []), "active request receipt should be nil after download completes")
        XCTAssertEqual(activeRequestCount, 1, "active request count should be 1")
    }

    // MARK: - Image Response Serializers

    func testThatCustomImageSerializerCanBeUsed() {
        // Given
        let expectation = self.expectation(description: "image should download successfully")
        var imageDownloadComplete = false

        let button = TestButton {
            imageDownloadComplete = true
            expectation.fulfill()
        }

        // When
        button.af.setImage(for: .normal,
                           url: url,
                           serializer: ImageResponseSerializer(imageScale: 4.0, inflateResponseImage: false))

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(imageDownloadComplete, "image download complete should be true")
        XCTAssertEqual(button.image(for: .normal)?.scale, 4.0)
        XCTAssertEqual(button.image(for: .normal)?.af.isInflated, false)
    }

    func testThatCustomImageSerializerCanBeUsedForBackgroundImage() {
        // Given
        let expectation = self.expectation(description: "image should download successfully")
        var imageDownloadComplete = false

        let button = TestButton {
            imageDownloadComplete = true
            expectation.fulfill()
        }

        // When
        button.af.setBackgroundImage(for: .normal,
                                     url: url,
                                     serializer: ImageResponseSerializer(imageScale: 4.0, inflateResponseImage: false))

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(imageDownloadComplete, "image download complete should be true")
        XCTAssertEqual(button.backgroundImage(for: .normal)?.scale, 4.0)
        XCTAssertEqual(button.backgroundImage(for: .normal)?.af.isInflated, false)
    }

    // MARK: - Image Cache

    func testThatImageCanBeLoadedFromImageCache() {
        // Given
        let button = UIButton()

        let downloader = ImageDownloader.default
        let urlRequest = try! URLRequest(url: url.absoluteString, method: .get)
        let expectation = self.expectation(description: "image download should succeed")

        downloader.download(urlRequest, completion: { _ in
            expectation.fulfill()
        })

        waitForExpectations(timeout: timeout)

        // When
        button.af.setImage(for: [], url: url)
        button.af.cancelImageRequest(for: [])

        // Then
        XCTAssertNotNil(button.image(for: []), "button image should not be nil")
    }

    func testThatSharedImageCacheCanBeReplaced() {
        // Given
        let imageDownloader = ImageDownloader()

        // When
        let firstEqualityCheck = UIButton.af.sharedImageDownloader === imageDownloader
        UIButton.af.sharedImageDownloader = imageDownloader
        let secondEqualityCheck = UIButton.af.sharedImageDownloader === imageDownloader

        // Then
        XCTAssertFalse(firstEqualityCheck, "first equality check should be false")
        XCTAssertTrue(secondEqualityCheck, "second equality check should be true")
    }

    func testThatImageCanBeLoadedFromImageCacheFromRequestAndFilterIdentifierIfAvailable() {
        // Given
        let button = UIButton()

        let downloader = ImageDownloader.default
        let expectation = self.expectation(description: "image download should succeed")

        downloader.download(endpoint, filter: CircleFilter(), completion: { _ in
            expectation.fulfill()
        })

        waitForExpectations(timeout: timeout)

        // When
        button.af.setImage(for: .normal, url: url, filter: CircleFilter())
        button.af.cancelImageRequest(for: .normal)

        // Then
        XCTAssertNotNil(button.image(for: .normal), "button image should not be nil")
    }

    func testThatImageCanBeCachedWithACustomCacheKey() {
        // Given
        let expectation = self.expectation(description: "image should download and be cached with custom key")
        let cacheKey = "cache-key"
        var imageCached = false

        let button = TestButton {
            imageCached = (ImageDownloader.default.imageCache?.image(withIdentifier: cacheKey) != nil)
            expectation.fulfill()
        }

        // When
        button.af.setImage(for: .normal, url: url, cacheKey: cacheKey)
        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(imageCached, "image cached should be true")
    }

    func testThatBackgroundImageCanBeCachedWithACustomCacheKey() {
        // Given
        let expectation = self.expectation(description: "image should download and be cached with custom key")
        let cacheKey = "cache-key"
        var imageCached = false

        let button = TestButton {
            imageCached = (ImageDownloader.default.imageCache?.image(withIdentifier: cacheKey) != nil)
            expectation.fulfill()
        }

        // When
        button.af.setBackgroundImage(for: .normal, url: url, cacheKey: cacheKey)
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

        let button = TestButton()

        // When
        button.af.setImage(for: [], url: url, placeholderImage: placeholderImage)
        let initialImageEqualsPlaceholderImage = button.image(for: []) === placeholderImage

        button.imageObserver = {
            imageDownloadComplete = true
            finalImageEqualsPlaceholderImage = button.image(for: []) === placeholderImage
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(imageDownloadComplete)
        XCTAssertTrue(initialImageEqualsPlaceholderImage, "initial image should equal placeholder image")
        XCTAssertFalse(finalImageEqualsPlaceholderImage, "final image should not equal placeholder image")
    }

    func testThatBackgroundPlaceholderImageIsDisplayedUntilImageIsDownloadedFromURL() {
        // Given
        let placeholderImage = image(forResource: "pirate", withExtension: "jpg")
        let expectation = self.expectation(description: "image should download successfully")

        var backgroundImageDownloadComplete = false
        var finalBackgroundImageEqualsPlaceholderImage = false

        let button = TestButton()

        // When
        button.af.setBackgroundImage(for: [], url: url, placeholderImage: placeholderImage)
        let initialImageEqualsPlaceholderImage = button.backgroundImage(for: []) === placeholderImage

        button.imageObserver = {
            backgroundImageDownloadComplete = true
            finalBackgroundImageEqualsPlaceholderImage = button.backgroundImage(for: []) === placeholderImage
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(backgroundImageDownloadComplete)
        XCTAssertTrue(initialImageEqualsPlaceholderImage, "initial image should equal placeholder image")
        XCTAssertFalse(finalBackgroundImageEqualsPlaceholderImage, "final image should not equal placeholder image")
    }

    func testThatImagePlaceholderIsNeverDisplayedIfCachedImageIsAvailable() {
        // Given
        let placeholderImage = image(forResource: "pirate", withExtension: "jpg")
        let button = UIButton()

        let downloader = ImageDownloader.default
        let urlRequest = try! URLRequest(url: url.absoluteString, method: .get)
        let expectation = self.expectation(description: "image download should succeed")

        downloader.download(urlRequest, completion: { _ in
            expectation.fulfill()
        })

        waitForExpectations(timeout: timeout)

        // When
        button.af.setImage(for: [], url: url, placeholderImage: placeholderImage)

        // Then
        XCTAssertNotNil(button.image(for: []), "button image should not be nil")
        XCTAssertFalse(button.image(for: []) === placeholderImage, "button image should not equal placeholder image")
    }

    func testThatBackgroundPlaceholderIsNeverDisplayedIfCachedImageIsAvailable() {
        // Given
        let placeholderImage = image(forResource: "pirate", withExtension: "jpg")
        let button = UIButton()

        let downloader = ImageDownloader.default
        let urlRequest = try! URLRequest(url: url.absoluteString, method: .get)
        let expectation = self.expectation(description: "image download should succeed")

        downloader.download(urlRequest, completion: { _ in
            expectation.fulfill()
        })

        waitForExpectations(timeout: timeout)

        // When
        button.af.setBackgroundImage(for: [], url: url, placeholderImage: placeholderImage)

        // Then
        XCTAssertNotNil(button.backgroundImage(for: []), "button background image should not be nil")
        XCTAssertFalse(button.backgroundImage(for: []) === placeholderImage, "button background image should not equal placeholder image")
    }

    func testThatPlaceholderImageIsDisplayedWithThrowingURLConvertible() {
        // Given
        let placeholderImage = image(forResource: "pirate", withExtension: "jpg")
        let button = TestButton()

        // When
        button.af.setImage(for: [], url: url, placeholderImage: placeholderImage)
        let initialImageEqualsPlaceholderImage = button.image(for: []) === placeholderImage

        // Then
        XCTAssertTrue(initialImageEqualsPlaceholderImage, "initial image should equal placeholder image")
    }

    func testThatBackgroundPlaceholderImageIsDisplayedWithThrowingURLConvertible() {
        // Given
        let placeholderImage = image(forResource: "pirate", withExtension: "jpg")
        let button = TestButton()

        // When
        button.af.setBackgroundImage(for: [], url: url, placeholderImage: placeholderImage)
        let initialImageEqualsPlaceholderImage = button.backgroundImage(for: []) === placeholderImage

        // Then
        XCTAssertTrue(initialImageEqualsPlaceholderImage, "initial image should equal placeholder image")
    }

    // MARK: - Image Filters

    func testThatImageFilterCanBeAppliedToDownloadedImageBeforeBeingDisplayed() {
        // Given
        let size = CGSize(width: 20, height: 20)
        let filter = ScaledToSizeFilter(size: size)

        let expectation = self.expectation(description: "image download should succeed")
        var imageDownloadComplete = false

        let button = TestButton {
            imageDownloadComplete = true
            expectation.fulfill()
        }

        // When
        button.af.setImage(for: .normal, url: url, filter: filter)
        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(imageDownloadComplete, "image download complete should be true")
        XCTAssertNotNil(button.image(for: .normal), "image view image should not be nil")

        if let image = button.image(for: .normal) {
            XCTAssertEqual(image.size, size, "image size does not match expected value")
        }
    }

    func testThatSetBackgroundImageAppliesFilter() {
        // Given
        let size = CGSize(width: 20, height: 20)
        let filter = ScaledToSizeFilter(size: size)

        let expectation = self.expectation(description: "image download should succeed")
        var imageDownloadComplete = false

        let button = TestButton {
            imageDownloadComplete = true
            expectation.fulfill()
        }

        // When
        button.af.setBackgroundImage(for: .normal, url: url, filter: filter)
        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(imageDownloadComplete, "image download complete should be true")
        XCTAssertNotNil(button.backgroundImage(for: .normal), "image view image should not be nil")

        if let image = button.backgroundImage(for: .normal) {
            XCTAssertEqual(image.size, size, "image size does not match expected value")
        }
    }

    // MARK: - Completion Handler

    func testThatCompletionHandlerIsCalledWhenImageDownloadSucceeds() {
        // Given
        let button = UIButton()

        let urlRequest: URLRequest = {
            var request = endpoint.urlRequest
            request.addValue("image/*", forHTTPHeaderField: "Accept")
            return request
        }()

        let expectation = self.expectation(description: "image download should succeed")

        var completionHandlerCalled = false
        var result: AFIResult<UIImage>?

        // When
        button.af.setImage(for: [], urlRequest: urlRequest, placeholderImage: nil, completion: { response in
            completionHandlerCalled = true
            result = response.result
            expectation.fulfill()
        })

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(completionHandlerCalled, "completion handler called should be true")
        XCTAssertNotNil(button.image(for: []), "button image should be not be nil")
        XCTAssertTrue(result?.isSuccess ?? false, "result should be a success case")
    }

    func testThatCompletionHandlerIsCalledWhenBackgroundImageDownloadSucceeds() {
        // Given
        let button = UIButton()

        let urlRequest: URLRequest = {
            var request = endpoint.urlRequest
            request.addValue("image/*", forHTTPHeaderField: "Accept")
            return request
        }()

        let expectation = self.expectation(description: "image download should succeed")

        var completionHandlerCalled = false
        var result: AFIResult<UIImage>?

        // When
        button.af.setBackgroundImage(for: [], urlRequest: urlRequest, placeholderImage: nil, completion: { response in
            completionHandlerCalled = true
            result = response.result
            expectation.fulfill()
        })

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(completionHandlerCalled, "completion handler called should be true")
        XCTAssertNotNil(button.backgroundImage(for: []), "button background image should be not be nil")
        XCTAssertTrue(result?.isSuccess ?? false, "result should be a success case")
    }

    func testThatCompletionHandlerIsCalledWhenImageDownloadFails() {
        // Given
        let button = UIButton()

        let expectation = self.expectation(description: "image download should complete")

        var completionHandlerCalled = false
        var result: AFIResult<UIImage>?

        // When
        button.af.setImage(for: [], urlRequest: Endpoint.nonexistent, placeholderImage: nil, completion: { response in
            completionHandlerCalled = true
            result = response.result
            expectation.fulfill()
        })

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(completionHandlerCalled, "completion handler called should be true")
        XCTAssertNil(button.image(for: []), "button image should be nil")
        XCTAssertTrue(result?.isFailure ?? false, "result should be a failure case")
    }

    func testThatCompletionHandlerIsCalledWhenBackgroundImageDownloadFails() {
        // Given
        let button = UIButton()

        let expectation = self.expectation(description: "image download should complete")

        var completionHandlerCalled = false
        var result: AFIResult<UIImage>?

        // When
        button.af.setBackgroundImage(for: [], urlRequest: Endpoint.nonexistent, placeholderImage: nil, completion: { response in
            completionHandlerCalled = true
            result = response.result
            expectation.fulfill()
        })

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(completionHandlerCalled, "completion handler called should be true")
        XCTAssertNil(button.backgroundImage(for: []), "button background image should be nil")
        XCTAssertTrue(result?.isFailure ?? false, "result should be a failure case")
    }

    func testThatCompletionHandlerIsCalledWhenURLRequestConvertibleThrows() {
        // Given
        let button = UIButton()
        let urlRequest = ThrowingURLRequestConvertible()

        let expectation = self.expectation(description: "image download should complete")

        var completionHandlerCalled = false
        var result: AFIResult<UIImage>?

        // When
        button.af.setImage(for: [], urlRequest: urlRequest, placeholderImage: nil, completion: { response in
            completionHandlerCalled = true
            result = response.result
            expectation.fulfill()
        })

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(completionHandlerCalled, "completion handler called should be true")
        XCTAssertNil(button.image(for: []), "button image should be nil")
        XCTAssertTrue(result?.isFailure ?? false, "result should be a failure case")
    }

    func testThatCompletionHandlerIsCalledWhenBackgroundImageURLRequestConvertibleThrows() {
        // Given
        let button = UIButton()
        let urlRequest = ThrowingURLRequestConvertible()

        let expectation = self.expectation(description: "image download should complete")

        var completionHandlerCalled = false
        var result: AFIResult<UIImage>?

        // When
        button.af.setBackgroundImage(for: [], urlRequest: urlRequest, placeholderImage: nil, completion: { response in
            completionHandlerCalled = true
            result = response.result
            expectation.fulfill()
        })

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(completionHandlerCalled, "completion handler called should be true")
        XCTAssertNil(button.backgroundImage(for: []), "button background image should be nil")
        XCTAssertTrue(result?.isFailure ?? false, "result should be a failure case")
    }

    // MARK: - Cancellation

    func testThatImageDownloadCanBeCancelled() {
        // Given
        let button = UIButton()

        let expectation = self.expectation(description: "image download should succeed")

        var completionHandlerCalled = false
        var result: AFIResult<UIImage>?

        // When
        button.af.setImage(for: [],
                           urlRequest: Endpoint.nonexistent,
                           placeholderImage: nil,
                           completion: { closureResponse in
                               completionHandlerCalled = true
                               result = closureResponse.result
                               expectation.fulfill()
                           })

        button.af.cancelImageRequest(for: [])
        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(completionHandlerCalled)
        XCTAssertNil(button.image(for: []))
        XCTAssertTrue(result?.isFailure ?? false)
    }

    func testThatBackgroundImageDownloadCanBeCancelled() {
        // Given
        let button = UIButton()

        let expectation = self.expectation(description: "background image download should succeed")

        var completionHandlerCalled = false
        var result: AFIResult<UIImage>?

        // When
        button.af.setBackgroundImage(for: [],
                                     urlRequest: Endpoint.nonexistent,
                                     placeholderImage: nil,
                                     completion: { closureResponse in
                                         completionHandlerCalled = true
                                         result = closureResponse.result
                                         expectation.fulfill()
                                     })

        button.af.cancelBackgroundImageRequest(for: [])
        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(completionHandlerCalled)
        XCTAssertNil(button.backgroundImage(for: []))
        XCTAssertTrue(result?.isFailure ?? false)
    }

    func testThatActiveImageRequestIsAutomaticallyCancelledBySettingNewURL() {
        // Given
        let button = UIButton()
        let expectation = self.expectation(description: "image download should succeed")

        var completion1Called = false
        var completion2Called = false
        var result: AFIResult<UIImage>?

        // When
        button.af.setImage(for: [],
                           urlRequest: endpoint,
                           placeholderImage: nil,
                           completion: { _ in
                               completion1Called = true
                           })

        button.af.setImage(for: [],
                           urlRequest: Endpoint.image(.png),
                           placeholderImage: nil,
                           completion: { closureResponse in
                               completion2Called = true
                               result = closureResponse.result
                               expectation.fulfill()
                           })

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(completion1Called)
        XCTAssertTrue(completion2Called)
        XCTAssertNotNil(button.image(for: []))
        XCTAssertTrue(result?.isSuccess ?? false)
    }

    func testThatActiveBackgroundImageRequestIsAutomaticallyCancelledBySettingNewURL() {
        // Given
        let button = UIButton()
        let expectation = self.expectation(description: "background image download should succeed")

        var completion1Called = false
        var completion2Called = false
        var result: AFIResult<UIImage>?

        // When
        button.af.setBackgroundImage(for: [],
                                     urlRequest: endpoint,
                                     placeholderImage: nil,
                                     completion: { _ in
                                         completion1Called = true
                                     })

        button.af.setBackgroundImage(for: [],
                                     urlRequest: Endpoint.image(.png),
                                     placeholderImage: nil,
                                     completion: { closureResponse in
                                         completion2Called = true
                                         result = closureResponse.result
                                         expectation.fulfill()
                                     })

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(completion1Called)
        XCTAssertTrue(completion2Called)
        XCTAssertNotNil(button.backgroundImage(for: []))
        XCTAssertTrue(result?.isSuccess ?? false)
    }

    func testThatActiveImageRequestCanBeCancelledAndRestartedSuccessfully() {
        // Given
        let button = UIButton()
        let expectation = self.expectation(description: "image download should succeed")
        expectation.expectedFulfillmentCount = 2

        var completion1Called = false
        var completion2Called = false
        var result: AFIResult<UIImage>?

        // When
        button.af.setImage(for: [],
                           urlRequest: endpoint,
                           placeholderImage: nil,
                           completion: { _ in
                               completion1Called = true
                               expectation.fulfill()
                           })

        button.af.cancelImageRequest(for: [])

        button.af.setImage(for: [],
                           urlRequest: endpoint,
                           placeholderImage: nil,
                           completion: { closureResponse in
                               completion2Called = true
                               result = closureResponse.result
                               expectation.fulfill()
                           })

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(completion1Called)
        XCTAssertTrue(completion2Called)
        XCTAssertNotNil(button.image(for: []))
        XCTAssertTrue(result?.isSuccess ?? false)
    }

    func testThatActiveBackgroundImageRequestCanBeCancelledAndRestartedSuccessfully() {
        // Given
        let button = UIButton()
        let expectation = self.expectation(description: "background image download should succeed")

        var completion1Called = false
        var completion2Called = false
        var result: AFIResult<UIImage>?

        // When
        button.af.setBackgroundImage(for: [],
                                     urlRequest: endpoint,
                                     placeholderImage: nil,
                                     completion: { _ in
                                         completion1Called = true
                                     })

        button.af.cancelBackgroundImageRequest(for: [])

        button.af.setBackgroundImage(for: [],
                                     urlRequest: endpoint,
                                     placeholderImage: nil,
                                     completion: { closureResponse in
                                         completion2Called = true
                                         result = closureResponse.result
                                         expectation.fulfill()
                                     })

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(completion1Called)
        XCTAssertTrue(completion2Called)
        XCTAssertNotNil(button.backgroundImage(for: []))
        XCTAssertTrue(result?.isSuccess ?? false)
    }

    func testThatImageRequestCanBeCancelledAndButtonIsDeallocated() {
        // Given
        var button: UIButton? = UIButton()
        let expectation = self.expectation(description: "image download should succeed")

        var completionCalled: Bool?
        var buttonReleased: Bool?

        // When
        button?.af.setImage(for: .normal,
                            urlRequest: endpoint,
                            completion: { [weak button] _ in
                                completionCalled = true
                                buttonReleased = button == nil

                                expectation.fulfill()
                            })

        button = nil
        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertEqual(completionCalled, true)
        XCTAssertEqual(buttonReleased, true)
    }

    func testThatBackgroundImageRequestCanBeCancelledAndButtonIsDeallocated() {
        // Given
        var button: UIButton? = UIButton()
        let expectation = self.expectation(description: "image download should succeed")

        var completionCalled: Bool?
        var buttonReleased: Bool?

        // When
        button?.af.setBackgroundImage(for: .normal,
                                      urlRequest: endpoint,
                                      completion: { [weak button] _ in
                                          completionCalled = true
                                          buttonReleased = button == nil

                                          expectation.fulfill()
                                      })

        button = nil
        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertEqual(completionCalled, true)
        XCTAssertEqual(buttonReleased, true)
    }

    // MARK: - Redirects

    func testThatImageBehindRedirectCanBeDownloaded() {
        // Given
        let expectation = self.expectation(description: "image should download successfully")
        var imageDownloadComplete = false

        let button = TestButton {
            imageDownloadComplete = true
            expectation.fulfill()
        }

        // When
        button.af.setImage(for: [], url: Endpoint.redirectTo(.image(.png)).url)
        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(imageDownloadComplete, "image download complete should be true")
        XCTAssertNotNil(button.image(for: []), "button image should not be nil")
    }

    func testThatBackgroundImageBehindRedirectCanBeDownloaded() {
        // Given
        let expectation = self.expectation(description: "image should download successfully")
        var backgroundImageDownloadComplete = false

        let button = TestButton {
            backgroundImageDownloadComplete = true
            expectation.fulfill()
        }

        // When
        button.af.setBackgroundImage(for: [], url: Endpoint.redirectTo(.image(.png)).url)
        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(backgroundImageDownloadComplete, "image download complete should be true")
        XCTAssertNotNil(button.backgroundImage(for: []), "button background image should not be nil")
    }

    // MARK: - Accept Header

    func testThatAcceptHeaderMatchesAcceptableContentTypes() {
        // Given
        let expectation = self.expectation(description: "image should download successfully")
        var acceptField: String?

        var button: TestButton?
        button = TestButton {
            acceptField = button?.af.imageRequestReceipt(for: [])?.request.request?.headers["Accept"]
            expectation.fulfill()
        }

        // When
        button?.af.setImage(for: [], url: url)
        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertEqual(acceptField, ImageResponseSerializer.acceptableImageContentTypes.sorted().joined(separator: ","))
    }
}

#endif
