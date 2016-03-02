// ImageDownloaderTests.swift
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

    func testThatImageDownloaderCanBeInitializedWithManagerInstanceAndDeinitialized() {
        // Given
        var downloader: ImageDownloader? = ImageDownloader(sessionManager: Manager())

        // When
        downloader = nil

        // Then
        XCTAssertNil(downloader, "downloader should be nil")
    }

    func testThatImageDownloaderCanBeInitializedAndDeinitializedWithActiveDownloads() {
        // Given
        var downloader: ImageDownloader? = ImageDownloader()

        // When
        downloader?.downloadImage(URLRequest: URLRequest(.GET, "https://httpbin.org/image/png")) { _ in
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

        var response: Response<Image, NSError>?

        // When
        downloader.downloadImage(URLRequest: download) { closureResponse in
            response = closureResponse
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNotNil(response?.response, "response should not be nil")
        XCTAssertNotNil(response?.result, "result should not be nil")
        XCTAssertTrue(response?.result.isSuccess ?? false, "result should be a success case")
    }

    func testThatItCanDownloadMultipleImagesSimultaneously() {
        // Given
        let downloader = ImageDownloader()

        let download1 = URLRequest(.GET, "https://httpbin.org/image/jpeg")
        let download2 = URLRequest(.GET, "https://httpbin.org/image/png")

        let expectation1 = expectationWithDescription("download 1 should succeed")
        let expectation2 = expectationWithDescription("download 2 should succeed")

        var result1: Result<Image, NSError>?
        var result2: Result<Image, NSError>?

        // When
        downloader.downloadImage(URLRequest: download1) { closureResponse in
            result1 = closureResponse.result
            expectation1.fulfill()
        }

        downloader.downloadImage(URLRequest: download2) { closureResponse in
            result2 = closureResponse.result
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

    func testThatItCanEnqueueMultipleImages() {
        // Given
        let downloader = ImageDownloader()

        let download1 = URLRequest(.GET, "https://httpbin.org/image/jpeg")
        let download2 = URLRequest(.GET, "https://httpbin.org/image/png")

        let expectation = expectationWithDescription("both downloads should succeed")
        var completedDownloads = 0

        var results: [Result<Image, NSError>] = []

        // When
        downloader.downloadImages(URLRequests: [download1, download2], filter: nil) { closureResponse in
            results.append(closureResponse.result)

            completedDownloads += 1
            if completedDownloads == 2 { expectation.fulfill() }
        }

        let activeRequestCount = downloader.activeRequestCount

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertEqual(activeRequestCount, 2, "active request count should be 2")

        XCTAssertTrue(results[0].isSuccess, "the first result should be a success case")
        XCTAssertTrue(results[1].isSuccess, "the second result should be a success case")
    }

    func testThatItDoesNotExceedTheMaximumActiveDownloadsLimit() {
        // Given
        let downloader = ImageDownloader(maximumActiveDownloads: 1)

        let download1 = URLRequest(.GET, "https://httpbin.org/image/jpeg")
        let download2 = URLRequest(.GET, "https://httpbin.org/image/png")

        // When
        let requestReceipt1 = downloader.downloadImage(URLRequest: download1) { _ in
            // No-op
        }

        let requestReceipt2 = downloader.downloadImage(URLRequest: download2) { _ in
            // No-op
        }

        let activeRequestCount = downloader.activeRequestCount
        requestReceipt1?.request.cancel()
        requestReceipt2?.request.cancel()

        // Then
        XCTAssertEqual(activeRequestCount, 1, "active request count should be 1")
    }

    func testThatItCallsTheCompletionHandlerEvenWhenDownloadFails() {
        // Given
        let downloader = ImageDownloader()
        let download = URLRequest(.GET, "https://httpbin.org/get")
        let expectation = expectationWithDescription("download request should fail")

        var response: Response<Image, NSError>?

        // When
        downloader.downloadImage(URLRequest: download) { closureResponse in
            response = closureResponse
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNotNil(response?.response, "response should not be nil")
        XCTAssertTrue(response?.result.isFailure ?? false, "result should be a failure case")
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

        var response: Response<Image, NSError>?

        // When
        downloader.downloadImage(URLRequest: download) { closureResponse in
            response = closureResponse
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNotNil(response?.response, "response should not be nil")
        XCTAssertTrue(response?.result.isSuccess ?? false, "result should be a success case")
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

        var response: Response<Image, NSError>?

        // When
        downloader.downloadImage(URLRequest: download, filter: filter) { closureResponse in
            response = closureResponse
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNotNil(response?.response, "response should not be nil")
        XCTAssertTrue(response?.result.isSuccess ?? false, "result should be a success case")

        if let image = response?.result.value {
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

        var result1: Result<Image, NSError>?
        var result2: Result<Image, NSError>?

        // When
        let requestReceipt1 = downloader.downloadImage(URLRequest: download1, filter: filter1) { closureResponse in
            result1 = closureResponse.result
            expectation1.fulfill()
        }

        let requestReceipt2 = downloader.downloadImage(URLRequest: download2, filter: filter2) { closureResponse in
            result2 = closureResponse.result
            expectation2.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertEqual(requestReceipt1?.request.task, requestReceipt2?.request.task, "request 1 and 2 should be equal")

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

        var result1: Result<Image, NSError>?
        var result2: Result<Image, NSError>?

        // When
        let requestReceipt1 = downloader.downloadImage(URLRequest: download1, filter: filter1) { closureResponse in
            result1 = closureResponse.result
            expectation1.fulfill()
        }

        let requestReceipt2 = downloader.downloadImage(URLRequest: download2, filter: filter2) { closureResponse in
            result2 = closureResponse.result
            expectation2.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertEqual(requestReceipt1?.request.task, requestReceipt2?.request.task, "tasks 1 and 2 should be equal")

        XCTAssertNotNil(result1, "result 1 should not be nil")
        XCTAssertNotNil(result2, "result 2 should not be nil")

        XCTAssertTrue(result1?.isSuccess ?? false, "result 1 should be a success case")
        XCTAssertTrue(result2?.isSuccess ?? false, "result 2 should be a success case")

        XCTAssertTrue(filter1.filterOperationCompleted, "the filter 1 filter operation completed flag should be true")
        XCTAssertFalse(filter2.filterOperationCompleted, "the filter 2 filter operation completed flag should be false")
    }

#endif

    // MARK: - Cancellation Tests

    func testThatCancellingDownloadCallsCompletionWithCancellationError() {
        // Given
        let downloader = ImageDownloader()
        let download = URLRequest(.GET, "https://httpbin.org/image/jpeg")

        let expectation = expectationWithDescription("download request should succeed")

        var response: Response<Image, NSError>?

        // When
        let requestReceipt = downloader.downloadImage(URLRequest: download) { closureResponse in
            response = closureResponse
            expectation.fulfill()
        }

        downloader.cancelRequestForRequestReceipt(requestReceipt!)

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertNotNil(response, "response should not be nil")
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNil(response?.response, "response should be nil")
        XCTAssertNil(response?.data, "data should be nil")
        XCTAssertTrue(response?.result.isFailure ?? false, "result should be a failure case")

        if let error = response?.result.error {
            XCTAssertEqual(error.domain, Error.Domain, "error domain should be com.alamofire.error")
            XCTAssertEqual(error.code, NSURLErrorCancelled, "error code should be cancelled")
        }
    }

    func testThatCancellingDownloadWithMultipleResponseHandlersCancelsFirstYetAllowsSecondToComplete() {
        // Given
        let downloader = ImageDownloader()

        let download1 = URLRequest(.GET, "https://httpbin.org/image/jpeg")
        let download2 = URLRequest(.GET, "https://httpbin.org/image/jpeg")

        let expectation1 = expectationWithDescription("download request 1 should succeed")
        let expectation2 = expectationWithDescription("download request 2 should succeed")

        var response1: Response<Image, NSError>?
        var response2: Response<Image, NSError>?

        // When
        let requestReceipt1 = downloader.downloadImage(URLRequest: download1) { closureResponse in
            response1 = closureResponse
            expectation1.fulfill()
        }

        let requestReceipt2 = downloader.downloadImage(URLRequest: download2) { closureResponse in
            response2 = closureResponse
            expectation2.fulfill()
        }

        downloader.cancelRequestForRequestReceipt(requestReceipt1!)

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertEqual(requestReceipt1?.request.task, requestReceipt2?.request.task, "tasks 1 and 2 should be equal")

        XCTAssertNotNil(response1, "response 1 should not be nil")
        XCTAssertNotNil(response1?.request, "response 1 request should not be nil")
        XCTAssertNil(response1?.response, "response 1 response should be nil")
        XCTAssertNil(response1?.data, "response 1 data should be nil")
        XCTAssertTrue(response1?.result.isFailure ?? false, "response 1 result should be a failure case")

        if let error = response1?.result.error {
            XCTAssertEqual(error.domain, Error.Domain, "error domain should be com.alamofire.error")
            XCTAssertEqual(error.code, NSURLErrorCancelled, "error code should be cancelled")
        }

        XCTAssertNotNil(response2, "response 2 should not be nil")
        XCTAssertNotNil(response2?.request, "response 2 request should not be nil")
        XCTAssertNotNil(response2?.response, "response 2 response should not be nil")
        XCTAssertNotNil(response2?.data, "response 2 data should not be nil")
        XCTAssertTrue(response2?.result.isSuccess ?? false, "response 2 result should be a success case")
    }

    // MARK: - Authentication Tests

    func testThatItDoesNotAttachAuthenticationCredentialToRequestIfItDoesNotExist() {
        // Given
        let downloader = ImageDownloader()
        let download = URLRequest(.GET, "https://httpbin.org/image/jpeg")

        // When
        let requestReceipt = downloader.downloadImage(URLRequest: download) { _ in
            // No-op
        }

        let credential = requestReceipt?.request.delegate.credential
        requestReceipt?.request.cancel()

        // Then
        XCTAssertNil(credential, "credential should be nil")
    }

    func testThatItAttachsUsernamePasswordCredentialToRequestIfItExists() {
        // Given
        let downloader = ImageDownloader()
        let download = URLRequest(.GET, "https://httpbin.org/image/jpeg")

        // When
        downloader.addAuthentication(user: "foo", password: "bar")

        let requestReceipt = downloader.downloadImage(URLRequest: download) { _ in
            // No-op
        }

        let credential = requestReceipt?.request.delegate.credential
        requestReceipt?.request.cancel()

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

        let requestReceipt = downloader.downloadImage(URLRequest: download) { _ in
            // No-op
        }

        let requestCredential = requestReceipt?.request.delegate.credential
        requestReceipt?.request.cancel()

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
        downloader.downloadImage(URLRequest: download) { _ in
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
        downloader.downloadImage(URLRequest: download, filter: filter) { _ in
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
        let requestReceipt1 = downloader.downloadImage(URLRequest: download1) { _ in
            expectation1.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        let download2 = URLRequest(.GET, "https://httpbin.org/image/jpeg")
        download2.cachePolicy = .ReturnCacheDataElseLoad

        let expectation2 = expectationWithDescription("image download should succeed")

        let requestReceipt2 = downloader.downloadImage(URLRequest: download2) { _ in
            expectation2.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertNotNil(requestReceipt1, "request receipt 1 should not be nil")
        XCTAssertNil(requestReceipt2, "request receipt 2 should be nil")
    }

    func testThatCachedImageIsNotReturnedIfNotAllowedByCachePolicy() {
        // Given
        let downloader = ImageDownloader()
        let download1 = URLRequest(.GET, "https://httpbin.org/image/jpeg")

        let expectation1 = expectationWithDescription("image download should succeed")

        // When
        let requestReceipt1 = downloader.downloadImage(URLRequest: download1) { _ in
            expectation1.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        let download2 = URLRequest(.GET, "https://httpbin.org/image/jpeg")
        download2.cachePolicy = .ReloadIgnoringLocalCacheData

        let expectation2 = expectationWithDescription("image download should succeed")

        let requestReceipt2 = downloader.downloadImage(URLRequest: download2) { _ in
            expectation2.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertNotNil(requestReceipt1, "request receipt 1 should not be nil")
        XCTAssertNotNil(requestReceipt2, "request receipt 2 should not be nil")
    }

    func testThatItCanDownloadImagesWhenNoImageCacheIsAvailable() {
        // Given
        let downloader = ImageDownloader(imageCache: nil)
        let download = URLRequest(.GET, "https://httpbin.org/image/jpeg")
        let expectation = expectationWithDescription("image download should succeed")

        var response: Response<Image, NSError>?

        // When
        downloader.downloadImage(URLRequest: download) { closureResponse in
            response = closureResponse
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNotNil(response?.response, "response should not be nil")
        XCTAssertTrue(response?.result.isSuccess ?? false, "result should be a success case")
    }

    func testThatItAutomaticallyCachesDownloadedImageIfCacheIsAvailable() {
        // Given
        let downloader = ImageDownloader()
        let download = URLRequest(.GET, "https://httpbin.org/image/jpeg")

        let expectation1 = expectationWithDescription("image download should succeed")

        var result1: Result<Image, NSError>?
        var result2: Result<Image, NSError>?

        // When
        let requestReceipt1 = downloader.downloadImage(URLRequest: download) { closureResponse in
            result1 = closureResponse.result
            expectation1.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        let expectation2 = expectationWithDescription("image download should succeed")

        let requestReceipt2 = downloader.downloadImage(URLRequest: download) { closureResponse in
            result2 = closureResponse.result
            expectation2.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertNotNil(requestReceipt1, "request receipt 1 should not be nil")
        XCTAssertNil(requestReceipt2, "request receipt 2 should be nil")

        XCTAssertNotNil(result1, "result 1 should not be nil")
        XCTAssertNotNil(result2, "result 2 should not be nil")

        XCTAssertTrue(result1?.isSuccess ?? false, "result 1 should be a success case")
        XCTAssertTrue(result2?.isSuccess ?? false, "result 2 should be a success case")

        if let image1 = result1?.value, let image2 = result2?.value {
            XCTAssertEqual(image1, image2, "images 1 and 2 should be equal")
        }
    }

#if os(iOS)

    func testThatFilteredImageIsStoredInCacheIfCacheIsAvailable() {
        // Given
        let downloader = ImageDownloader()
        let download = URLRequest(.GET, "https://httpbin.org/image/jpeg")
        let size  = CGSize(width: 20, height: 20)
        let filter = ScaledToSizeFilter(size: size)

        let expectation1 = expectationWithDescription("image download should succeed")

        var result1: Result<Image, NSError>?
        var result2: Result<Image, NSError>?

        // When
        let requestReceipt1 = downloader.downloadImage(URLRequest: download, filter: filter) { closureResponse in
            result1 = closureResponse.result
            expectation1.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        let expectation2 = expectationWithDescription("image download should succeed")

        let requestReceipt2 = downloader.downloadImage(URLRequest: download, filter: filter) { closureResponse in
            result2 = closureResponse.result
            expectation2.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)

        // Then
        XCTAssertNotNil(requestReceipt1, "request receipt 1 should not be nil")
        XCTAssertNil(requestReceipt2, "request receipt 2 should be nil")

        XCTAssertNotNil(result1, "result 1 should not be nil")
        XCTAssertNotNil(result2, "result 2 should not be nil")

        XCTAssertTrue(result1?.isSuccess ?? false, "result 1 should be a success case")
        XCTAssertTrue(result2?.isSuccess ?? false, "result 2 should be a success case")

        if let image1 = result1?.value, let image2 = result2?.value {
            XCTAssertEqual(image1, image2, "images 1 and 2 should be equal")
            XCTAssertEqual(image1.size, size, "image size should match expected size")
            XCTAssertEqual(image2.size, size, "image size should match expected size")
        } else {
            XCTFail("images should not be nil")
        }
    }

#endif

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
