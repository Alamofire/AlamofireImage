// ImageDownloaderTests.swift
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
import XCTest

private class ThreadCheckFilter: ImageFilter {
    var calledOnMainQueue = false

    init() {}

    var filter: Image -> Image {
        return { image in
            self.calledOnMainQueue = NSThread.isMainThread()
            return image
        }
    }
}

// MARK: -

#if os(iOS)

private class TestCircleFilter: ImageFilter {
    var filterOperationCompleted = false

    var filter: Image -> Image {
        return { image in
            self.filterOperationCompleted = true
            return image.af_imageRoundedIntoCircle()
        }
    }
}

#endif

// MARK: -

class ImageDownloaderTestCase: BaseTestCase {

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()
        ImageDownloader.defaultURLCache().removeAllCachedResponses()
    }

    // MARK: - Initialization Tests

    func testThatImageDownloaderSingletonCanBeInitialized() {
        // Given, When
        let downloader = ImageDownloader.defaultInstance

        // Then
        XCTAssertNotNil(downloader, "downloader should not be nil")
    }

    func testThatImageDownloaderCanBeInitializedAndDeinitialized() {
        // Given
        var downloader: ImageDownloader? = ImageDownloader()

        // When
        downloader = nil

        // Then
        XCTAssertNil(downloader, "downloader should be nil")
    }

    func testThatImageDownloaderCanBeInitializedAndDeinitializedWithActiveDownloads() {
        // Given
        var downloader: ImageDownloader? = ImageDownloader()

        // When
        downloader?.downloadImage(URLRequest: URLRequest(.GET, "https://httpbin.org/image/png")) { _, _, _ in
            // No-op
        }

        downloader = nil

        // Then
        XCTAssertNil(downloader, "downloader should be nil")
    }

    // MARK: - Image Download Tests

    func testThatItCanDownloadAnImage() {
        // Given
        let downloader = ImageDownloader()
        let download = URLRequest(.GET, "https://httpbin.org/image/jpeg")
        let expectation = expectationWithDescription("image download should succeed")

        var request: NSURLRequest?
        var response: NSHTTPURLResponse?
        var result: Result<Image>?

        // When
        downloader.downloadImage(URLRequest: download) { responseRequest, responseResponse, responseResult in
            request = responseRequest
            response = responseResponse
            result = responseResult

            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertNotNil(request, "request should not be nil")
        XCTAssertNotNil(response, "response should not be nil")
        XCTAssertNotNil(result, "result should not be nil")
        XCTAssertTrue(result?.isSuccess ?? false, "result should be a success case")
    }

    func testThatItCanDownloadMultipleImagesSimultaneously() {
        // Given
        let downloader = ImageDownloader()

        let download1 = URLRequest(.GET, "https://httpbin.org/image/jpeg")
        let download2 = URLRequest(.GET, "https://httpbin.org/image/png")

        let expectation1 = expectationWithDescription("download 1 should succeed")
        let expectation2 = expectationWithDescription("download 2 should succeed")

        var result1: Result<Image>?
        var result2: Result<Image>?

        // When
        downloader.downloadImage(URLRequest: download1) { _, _, responseResult in
            result1 = responseResult
            expectation1.fulfill()
        }

        downloader.downloadImage(URLRequest: download2) { _, _, responseResult in
            result2 = responseResult
            expectation2.fulfill()
        }

        let activeRequestCount = downloader.activeRequestCount

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertEqual(activeRequestCount, 2, "active request count should be 2")

        XCTAssertNotNil(result1, "result 1 should not be nil")
        XCTAssertNotNil(result2, "result 2 should not be nil")

        XCTAssertTrue(result1?.isSuccess ?? false, "result 1 should be a success case")
        XCTAssertTrue(result2?.isSuccess ?? false, "result 2 should be a success case")
    }

    func testThatItDoesNotExceedTheMaximumActiveDownloadsLimit() {
        // Given
        let downloader = ImageDownloader(maximumActiveDownloads: 1)

        let download1 = URLRequest(.GET, "https://httpbin.org/image/jpeg")
        let download2 = URLRequest(.GET, "https://httpbin.org/image/png")

        // When
        let request1 = downloader.downloadImage(URLRequest: download1) { _, _, _ in
            // No-op
        }

        let request2 = downloader.downloadImage(URLRequest: download2) { _, _, _ in
            // No-op
        }

        let activeRequestCount = downloader.activeRequestCount
        request1?.cancel()
        request2?.cancel()

        // Then
        XCTAssertEqual(activeRequestCount, 1, "active request count should be 1")
    }

    func testThatItCallsTheCompletionHandlerEvenWhenDownloadFails() {
        // Given
        let downloader = ImageDownloader()
        let download = URLRequest(.GET, "https://httpbin.org/get")

        let expectation = expectationWithDescription("download request should fail")

        var request: NSURLRequest?
        var response: NSHTTPURLResponse?
        var result: Result<Image>?

        // When
        downloader.downloadImage(URLRequest: download) { responseRequest, responseResponse, responseResult in
            request = responseRequest
            response = responseResponse
            result = responseResult

            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertNotNil(request, "request should not be nil")
        XCTAssertNotNil(response, "response should not be nil")
        XCTAssertNotNil(result, "result should not be nil")
        XCTAssertTrue(result?.isFailure ?? false, "result should be a failure case")
    }

    func testThatItCanDownloadImagesWithDisabledURLCacheInSessionConfiguration() {
        // Given
        let downloader: ImageDownloader = {
            let configuration: NSURLSessionConfiguration = {
                let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
                configuration.URLCache = nil

                return configuration
            }()

            let downloader = ImageDownloader(configuration: configuration)
            return downloader
        }()

        let download = URLRequest(.GET, "https://httpbin.org/image/jpeg")

        let expectation = expectationWithDescription("image download should succeed")

        var request: NSURLRequest?
        var response: NSHTTPURLResponse?
        var result: Result<Image>?

        // When
        downloader.downloadImage(URLRequest: download) { responseRequest, responseResponse, responseResult in
            request = responseRequest
            response = responseResponse
            result = responseResult

            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertNotNil(request, "request should not be nil")
        XCTAssertNotNil(response, "response should not be nil")
        XCTAssertNotNil(result, "result should not be nil")
        XCTAssertTrue(result?.isSuccess ?? false, "result should be a success case")
    }

#if os(iOS)

    // MARK: - Image Download Tests (iOS Only)

    func testThatItCanDownloadImageAndApplyImageFilter() {
        // Given
        let downloader = ImageDownloader()
        let download = URLRequest(.GET, "https://httpbin.org/image/jpeg")
        let scaledSize = CGSize(width: 100, height: 60)
        let filter = ScaledToSizeFilter(size: scaledSize)

        let expectation = expectationWithDescription("image download should succeed")

        var request: NSURLRequest?
        var response: NSHTTPURLResponse?
        var result: Result<Image>?

        // When
        downloader.downloadImage(URLRequest: download, filter: filter) { responseRequest, responseResponse, responseResult in
            request = responseRequest
            response = responseResponse
            result = responseResult

            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertNotNil(request, "request should not be nil")
        XCTAssertNotNil(response, "response should not be nil")
        XCTAssertNotNil(result, "result should not be nil")
        XCTAssertTrue(result?.isSuccess ?? false, "result should be a success case")

        if let image = result?.value {
            XCTAssertEqual(image.size, scaledSize, "image size does not match expected value")
        }
    }

    func testThatItCanAppendFilterAndCompletionHandlerToExistingDownload() {
        // Given
        let downloader = ImageDownloader()

        let download1 = URLRequest(.GET, "https://httpbin.org/image/jpeg")
        let download2 = URLRequest(.GET, "https://httpbin.org/image/jpeg")

        let filter1 = ScaledToSizeFilter(size: CGSize(width: 50, height: 50))
        let filter2 = ScaledToSizeFilter(size: CGSize(width: 75, height: 75))

        let expectation1 = expectationWithDescription("download request 1 should succeed")
        let expectation2 = expectationWithDescription("download request 2 should succeed")

        var result1: Result<Image>?
        var result2: Result<Image>?

        // When
        let request1 = downloader.downloadImage(URLRequest: download1, filter: filter1) { _, _, responseResult in
            result1 = responseResult
            expectation1.fulfill()
        }

        let request2 = downloader.downloadImage(URLRequest: download2, filter: filter2) { _, _, responseResult in
            result2 = responseResult
            expectation2.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertEqual(request1?.task, request2?.task, "request 1 and 2 should be equal")

        XCTAssertNotNil(result1, "result 1 should not be nil")
        XCTAssertNotNil(result2, "result 2 should not be nil")

        XCTAssertTrue(result1?.isSuccess ?? false, "result 1 should be a success case")
        XCTAssertTrue(result2?.isSuccess ?? false, "result 2 should be a success case")

        if let image = result1?.value {
            XCTAssertEqual(image.size, CGSize(width: 50, height: 50), "image size does not match expected value")
        }

        if let image = result2?.value {
            XCTAssertEqual(image.size, CGSize(width: 75, height: 75), "image size does not match expected value")
        }
    }

    func testThatDownloadsWithMultipleResponseHandlersOnlyRunDuplicateImageFiltersOnce() {
        // Given
        let downloader = ImageDownloader()

        let download1 = URLRequest(.GET, "https://httpbin.org/image/jpeg")
        let download2 = URLRequest(.GET, "https://httpbin.org/image/jpeg")

        let filter1 = TestCircleFilter()
        let filter2 = TestCircleFilter()

        let expectation1 = expectationWithDescription("download request 1 should succeed")
        let expectation2 = expectationWithDescription("download request 2 should succeed")

        var result1: Result<Image>?
        var result2: Result<Image>?

        // When
        let request1 = downloader.downloadImage(URLRequest: download1, filter: filter1) { _, _, responseResult in
            result1 = responseResult
            expectation1.fulfill()
        }

        let request2 = downloader.downloadImage(URLRequest: download2, filter: filter2) { _, _, responseResult in
            result2 = responseResult
            expectation2.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertEqual(request1?.task, request2?.task, "request 1 and 2 should be equal")

        XCTAssertNotNil(result1, "result 1 should not be nil")
        XCTAssertNotNil(result2, "result 2 should not be nil")

        XCTAssertTrue(result1?.isSuccess ?? false, "result 1 should be a success case")
        XCTAssertTrue(result2?.isSuccess ?? false, "result 2 should be a success case")

        XCTAssertTrue(filter1.filterOperationCompleted, "the filter 1 filter operation completed flag should be true")
        XCTAssertFalse(filter2.filterOperationCompleted, "the filter 2 filter operation completed flag should be false")
    }

#endif

    // MARK: - Authentication Tests

    func testThatItDoesNotAttachAuthenticationCredentialToRequestIfItDoesNotExist() {
        // Given
        let downloader = ImageDownloader()
        let download = URLRequest(.GET, "https://httpbin.org/image/jpeg")

        // When
        let request = downloader.downloadImage(URLRequest: download) { _, _, _ in
            // No-op
        }

        let credential = request?.delegate.credential
        request?.cancel()

        // Then
        XCTAssertNil(credential, "credential should be nil")
    }

    func testThatItAttachsUsernamePasswordCredentialToRequestIfItExists() {
        // Given
        let downloader = ImageDownloader()
        let download = URLRequest(.GET, "https://httpbin.org/image/jpeg")

        // When
        downloader.addAuthentication(user: "foo", password: "bar")

        let request = downloader.downloadImage(URLRequest: download) { _, _, _ in
            // No-op
        }

        let credential = request?.delegate.credential
        request?.cancel()

        // Then
        XCTAssertNotNil(credential, "credential should not be nil")
    }

    func testThatItAttachsAuthenticationCredentialToRequestIfItExists() {
        // Given
        let downloader = ImageDownloader()
        let download = URLRequest(.GET, "https://httpbin.org/image/jpeg")

        // When
        let credential = NSURLCredential(user: "foo", password: "bar", persistence: .ForSession)
        downloader.addAuthentication(usingCredential: credential)

        let request = downloader.downloadImage(URLRequest: download) { _, _, _ in
            // No-op
        }

        let requestCredential = request?.delegate.credential
        request?.cancel()

        // Then
        XCTAssertNotNil(requestCredential, "request credential should not be nil")
    }

    // MARK: - Threading Tests

    func testThatItAlwaysCallsTheCompletionHandlerOnTheMainQueue() {
        // Given
        let downloader = ImageDownloader()
        let download = URLRequest(.GET, "https://httpbin.org/image/jpeg")

        let expectation = expectationWithDescription("download request should succeed")

        var calledOnMainQueue = false

        // When
        downloader.downloadImage(URLRequest: download) { _, _, _ in
            calledOnMainQueue = NSThread.isMainThread()
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertTrue(calledOnMainQueue, "completion handler should be called on main queue")
    }

    func testThatItNeverCallsTheImageFilterOnTheMainQueue() {
        // Given
        let downloader = ImageDownloader()
        let download = URLRequest(.GET, "https://httpbin.org/image/jpeg")
        let filter = ThreadCheckFilter()

        let expectation = expectationWithDescription("download request should succeed")

        // When
        downloader.downloadImage(URLRequest: download, filter: filter) { _, _, _ in
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertFalse(filter.calledOnMainQueue, "filter should not be called on main queue")
    }

    // MARK: - Image Caching Tests

    func testThatCachedImageIsReturnedIfAllowedByCachePolicy() {
        // Given
        let downloader = ImageDownloader()
        let download1 = URLRequest(.GET, "https://httpbin.org/image/jpeg")

        let expectation1 = expectationWithDescription("image download should succeed")

        // When
        let request1 = downloader.downloadImage(URLRequest: download1) { _, _, _ in
            expectation1.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        let download2 = URLRequest(.GET, "https://httpbin.org/image/jpeg")
        download2.cachePolicy = .ReturnCacheDataElseLoad

        let expectation2 = expectationWithDescription("image download should succeed")

        let request2 = downloader.downloadImage(URLRequest: download2) { _, _, _ in
            expectation2.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertNotNil(request1, "request 1 should not be nil")
        XCTAssertNil(request2, "request 2 should be nil")
    }

    func testThatCachedImageIsNotReturnedIfNotAllowedByCachePolicy() {
        // Given
        let downloader = ImageDownloader()
        let download1 = URLRequest(.GET, "https://httpbin.org/image/jpeg")

        let expectation1 = expectationWithDescription("image download should succeed")

        // When
        let request1 = downloader.downloadImage(URLRequest: download1) { _, _, _ in
            expectation1.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        let download2 = URLRequest(.GET, "https://httpbin.org/image/jpeg")
        download2.cachePolicy = .ReloadIgnoringLocalCacheData

        let expectation2 = expectationWithDescription("image download should succeed")

        let request2 = downloader.downloadImage(URLRequest: download2) { _, _, _ in
            expectation2.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertNotNil(request1, "request 1 should not be nil")
        XCTAssertNotNil(request2, "request 2 should not be nil")
    }

    func testThatItCanDownloadImagesWhenNoImageCacheIsAvailable() {
        // Given
        let downloader = ImageDownloader(imageCache: nil)
        let download = URLRequest(.GET, "https://httpbin.org/image/jpeg")
        let expectation = expectationWithDescription("image download should succeed")

        var request: NSURLRequest?
        var response: NSHTTPURLResponse?
        var result: Result<Image>?

        // When
        downloader.downloadImage(URLRequest: download) { responseRequest, responseResponse, responseResult in
            request = responseRequest
            response = responseResponse
            result = responseResult

            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertNotNil(request, "request should not be nil")
        XCTAssertNotNil(response, "response should not be nil")
        XCTAssertNotNil(result, "result should not be nil")
        XCTAssertTrue(result?.isSuccess ?? false, "result should be a success case")
    }

    func testThatItAutomaticallyCachesDownloadedImageIfCacheIsAvailable() {
        // Given
        let downloader = ImageDownloader()
        let download = URLRequest(.GET, "https://httpbin.org/image/jpeg")

        let expectation1 = expectationWithDescription("image download should succeed")

        var result1: Result<Image>?
        var result2: Result<Image>?

        // When
        let request1 = downloader.downloadImage(URLRequest: download) { _, _, responseResult in
            result1 = responseResult
            expectation1.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        let expectation2 = expectationWithDescription("image download should succeed")

        let request2 = downloader.downloadImage(URLRequest: download) { _, _, responseResult in
            result2 = responseResult
            expectation2.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertNotNil(request1, "request 1 should not be nil")
        XCTAssertNil(request2, "request 2 should be nil")

        XCTAssertNotNil(result1, "result 1 should not be nil")
        XCTAssertNotNil(result2, "result 2 should not be nil")

        XCTAssertTrue(result1?.isSuccess ?? false, "result 1 should be a success case")
        XCTAssertTrue(result2?.isSuccess ?? false, "result 2 should be a success case")

        if let image1 = result1?.value, let image2 = result2?.value {
            XCTAssertEqual(image1, image2, "images 1 and 2 should be equal")
        }
    }

    // MARK: - Internal Logic Tests

    func testThatStartingRequestIncrementsActiveRequestCount() {
        // Given
        let downloader = ImageDownloader()
        let download = URLRequest(.GET, "https://httpbin.org/image/jpeg")
        let request = downloader.sessionManager.request(download)

        // When
        let activeRequestCountBefore = downloader.activeRequestCount
        downloader.startRequest(request)
        let activeRequestCountAfter = downloader.activeRequestCount

        request.cancel()

        // Then
        XCTAssertEqual(activeRequestCountBefore, 0, "active request count before should be 0")
        XCTAssertEqual(activeRequestCountAfter, 1, "active request count after should be 1")
    }

    func testThatEnqueueRequestInsertsRequestAtTheBackOfTheQueueWithFIFODownloadPrioritization() {
        // Given
        let downloader = ImageDownloader()

        let download1 = URLRequest(.GET, "https://httpbin.org/image/jpeg")
        let download2 = URLRequest(.GET, "https://httpbin.org/image/png")

        let request1 = downloader.sessionManager.request(download1)
        let request2 = downloader.sessionManager.request(download2)

        // When
        downloader.enqueueRequest(request1)
        downloader.enqueueRequest(request2)

        let queuedRequests = downloader.queuedRequests

        // Then
        XCTAssertEqual(queuedRequests.count, 2, "queued requests count should be 1")
        XCTAssertEqual(queuedRequests[0].task, request1.task, "first queued request should be request 1")
        XCTAssertEqual(queuedRequests[1].task, request2.task, "second queued request should be request 2")
    }

    func testThatEnqueueRequestInsertsRequestAtTheFrontOfTheQueueWithLIFODownloadPrioritization() {
        // Given
        let downloader = ImageDownloader(downloadPrioritization: .LIFO)

        let download1 = URLRequest(.GET, "https://httpbin.org/image/jpeg")
        let download2 = URLRequest(.GET, "https://httpbin.org/image/png")

        let request1 = downloader.sessionManager.request(download1)
        let request2 = downloader.sessionManager.request(download2)

        // When
        downloader.enqueueRequest(request1)
        downloader.enqueueRequest(request2)

        let queuedRequests = downloader.queuedRequests

        // Then
        XCTAssertEqual(queuedRequests.count, 2, "queued requests count should be 1")
        XCTAssertEqual(queuedRequests[0].task, request2.task, "first queued request should be request 2")
        XCTAssertEqual(queuedRequests[1].task, request1.task, "second queued request should be request 1")
    }

    func testThatDequeueRequestAlwaysRemovesRequestFromTheFrontOfTheQueue() {
        // Given
        let downloader = ImageDownloader(downloadPrioritization: .FIFO)

        let download1 = URLRequest(.GET, "https://httpbin.org/image/jpeg")
        let download2 = URLRequest(.GET, "https://httpbin.org/image/png")

        let request1 = downloader.sessionManager.request(download1)
        let request2 = downloader.sessionManager.request(download2)

        // When
        downloader.enqueueRequest(request1)
        downloader.enqueueRequest(request2)
        downloader.dequeueRequest()

        let queuedRequests = downloader.queuedRequests

        // Then
        XCTAssertEqual(queuedRequests.count, 1, "queued requests count should be 1")
        XCTAssertEqual(queuedRequests[0].task, request2.task, "queued request should be request 2")
    }
}
