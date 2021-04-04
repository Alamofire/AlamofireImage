//
//  ImageDownloaderTests.swift
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

@testable import Alamofire
@testable import AlamofireImage

import Foundation
import XCTest

private final class ThreadCheckFilter: ImageFilter {
    var calledOnMainQueue = false

    init() {}

    var filter: (Image) -> Image {
        { image in
            self.calledOnMainQueue = Thread.isMainThread
            return image
        }
    }
}

// MARK: -

#if os(iOS) || os(tvOS)

private final class TestCircleFilter: ImageFilter {
    var filterOperationCompleted = false

    var filter: (Image) -> Image {
        { image in
            self.filterOperationCompleted = true
            return image.af.imageRoundedIntoCircle()
        }
    }
}

#endif

// MARK: -

final class ImageDownloaderTestCase: BaseTestCase {
    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()

        ImageDownloader.defaultURLCache().removeAllCachedResponses()
    }

    // MARK: - Initialization Tests

    func testThatImageDownloaderSingletonCanBeInitialized() {
        // Given, When
        let downloader = ImageDownloader.default

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
        var downloader: ImageDownloader? = ImageDownloader(session: Session(startRequestsImmediately: false))

        // When
        downloader = nil

        // Then
        XCTAssertNil(downloader, "downloader should be nil")
    }

    func testThatImageDownloaderCanBeInitializedAndDeinitializedWithActiveDownloads() {
        // Given
        var downloader: ImageDownloader? = ImageDownloader()

        // When
        _ = downloader?.download(.image(.png), completion: { _ in
            // No-op
        })

        downloader = nil

        // Then
        XCTAssertNil(downloader, "downloader should be nil")
    }

    // MARK: - Image Download Tests

    func testThatItCanDownloadAnImage() {
        // Given
        let downloader = ImageDownloader()
        let expectation = self.expectation(description: "image download should succeed")

        var response: AFIDataResponse<Image>?

        // When
        downloader.download(.image(.jpeg), completion: { closureResponse in
            response = closureResponse
            expectation.fulfill()
        })

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNotNil(response?.response, "response should not be nil")
        XCTAssertNotNil(response?.result, "result should not be nil")
        XCTAssertTrue(response?.result.isSuccess ?? false, "result should be a success case")
    }

    func testThatItCanDownloadMultipleImagesSimultaneously() {
        // Given
        let downloader = ImageDownloader()

        let expectation1 = expectation(description: "download 1 should succeed")
        let expectation2 = expectation(description: "download 2 should succeed")

        var result1: Result<Image, AFIError>?
        var result2: Result<Image, AFIError>?

        // When
        downloader.download(.image(.png), completion: { closureResponse in
            result1 = closureResponse.result
            expectation1.fulfill()
        })

        downloader.download(.image(.jpeg), completion: { closureResponse in
            result2 = closureResponse.result
            expectation2.fulfill()
        })

        let activeRequestCount = downloader.activeRequestCount

        waitForExpectations(timeout: timeout)

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

        let expectation = self.expectation(description: "both downloads should succeed")
        expectation.expectedFulfillmentCount = 2

        var completedDownloads = 0
        var results: [AFIResult<Image>] = []

        // When
        downloader.download([.image(.png), .image(.jpeg)], filter: nil, completion: { closureResponse in
            results.append(closureResponse.result)
            completedDownloads += 1
            expectation.fulfill()
        })

        let activeRequestCount = downloader.activeRequestCount

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertEqual(activeRequestCount, 2, "active request count should be 2")

        XCTAssertTrue(results[0].isSuccess, "the first result should be a success case")
        XCTAssertTrue(results[1].isSuccess, "the second result should be a success case")
    }

    func testThatItDoesNotExceedTheMaximumActiveDownloadsLimit() {
        // Given
        let downloader = ImageDownloader(maximumActiveDownloads: 1)

        // When
        let requestReceipt1 = downloader.download(.image(.png), completion: { _ in
            // No-op
        })

        let requestReceipt2 = downloader.download(.image(.jpeg), completion: { _ in
            // No-op
        })

        let activeRequestCount = downloader.activeRequestCount
        requestReceipt1?.request.cancel()
        requestReceipt2?.request.cancel()

        // Then
        XCTAssertEqual(activeRequestCount, 1, "active request count should be 1")
    }

    func testThatItCallsTheCompletionHandlerEvenWhenDownloadFails() {
        // Given
        let downloader = ImageDownloader()
        let expectation = self.expectation(description: "download request should fail")

        var response: AFIDataResponse<Image>?

        // When
        downloader.download(.get, completion: { closureResponse in
            response = closureResponse
            expectation.fulfill()
        })

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNotNil(response?.response, "response should not be nil")
        XCTAssertTrue(response?.result.isFailure ?? false, "result should be a failure case")
    }

    func testThatItCallsTheCompletionHandlerEvenWhenURLRequestConvertibleThrows() {
        // Given
        let downloader = ImageDownloader()
        let urlRequest = ThrowingURLRequestConvertible()
        let expectation = self.expectation(description: "download request should fail")

        var response: AFIDataResponse<Image>?

        // When
        downloader.download(urlRequest, completion: { closureResponse in
            response = closureResponse
            expectation.fulfill()
        })

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNil(response?.request, "request should not be nil")
        XCTAssertNil(response?.response, "response should not be nil")
        XCTAssertTrue(response?.result.error?.isAlamofireError ?? false, "result should be a failure case")
    }

    func testThatItCanDownloadImagesWithDisabledURLCacheInSessionConfiguration() {
        // Given
        let downloader: ImageDownloader = {
            let configuration: URLSessionConfiguration = {
                let configuration = URLSessionConfiguration.af.default
                configuration.urlCache = nil

                return configuration
            }()

            let downloader = ImageDownloader(configuration: configuration)
            return downloader
        }()

        let expectation = self.expectation(description: "image download should succeed")

        var response: AFIDataResponse<Image>?

        // When
        downloader.download(.image(.jpeg), completion: { closureResponse in
            response = closureResponse
            expectation.fulfill()
        })

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNotNil(response?.response, "response should not be nil")
        XCTAssertTrue(response?.result.isSuccess ?? false, "result should be a success case")
    }

    #if os(iOS) || os(tvOS)

    // MARK: - Image Download Tests (iOS and tvOS Only)

    func testThatItCanDownloadImageAndApplyImageFilter() {
        // Given
        let downloader = ImageDownloader()
        let scaledSize = CGSize(width: 100, height: 60)
        let filter = ScaledToSizeFilter(size: scaledSize)

        let expectation = self.expectation(description: "image download should succeed")

        var response: AFIDataResponse<Image>?

        // When
        downloader.download(.image(.jpeg), filter: filter, completion: { closureResponse in
            response = closureResponse
            expectation.fulfill()
        })

        waitForExpectations(timeout: timeout)

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

        let filter1 = ScaledToSizeFilter(size: CGSize(width: 50, height: 50))
        let filter2 = ScaledToSizeFilter(size: CGSize(width: 75, height: 75))

        let expectation1 = expectation(description: "download request 1 should succeed")
        let expectation2 = expectation(description: "download request 2 should succeed")

        var result1: AFIResult<Image>?
        var result2: AFIResult<Image>?

        // When
        let requestReceipt1 = downloader.download(.image(.jpeg), filter: filter1, completion: { closureResponse in
            result1 = closureResponse.result
            expectation1.fulfill()
        })

        let requestReceipt2 = downloader.download(.image(.jpeg), filter: filter2, completion: { closureResponse in
            result2 = closureResponse.result
            expectation2.fulfill()
        })

        waitForExpectations(timeout: timeout)

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

        let filter1 = TestCircleFilter()
        let filter2 = TestCircleFilter()

        let expectation1 = expectation(description: "download request 1 should succeed")
        let expectation2 = expectation(description: "download request 2 should succeed")

        var result1: AFIResult<Image>?
        var result2: AFIResult<Image>?

        // When
        let requestReceipt1 = downloader.download(.image(.jpeg), filter: filter1, completion: { closureResponse in
            result1 = closureResponse.result
            expectation1.fulfill()
        })

        let requestReceipt2 = downloader.download(.image(.jpeg), filter: filter2, completion: { closureResponse in
            result2 = closureResponse.result
            expectation2.fulfill()
        })

        waitForExpectations(timeout: timeout)

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

    // MARK: - Progress Closure Tests

    func testThatItCallsTheProgressHandlerOnTheMainQueueByDefault() {
        // Given
        let downloader = ImageDownloader()

        let progressExpectation = expectation(description: "progress closure should be called")
        let completedExpectation = expectation(description: "download request should succeed")

        var progressCalled = false
        var calledOnMainQueue = false

        // When
        downloader.download(.image(.jpeg),
                            progress: { _ in
                                if progressCalled == false {
                                    progressCalled = true
                                    calledOnMainQueue = Thread.isMainThread
                                    progressExpectation.fulfill()
                                }
                            },
                            completion: { _ in
                                completedExpectation.fulfill()
                            })

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(calledOnMainQueue, "progress handler should be called on main queue")
    }

    func testThatItCallsTheProgressHandlerOnTheProgressQueue() {
        // Given
        let downloader = ImageDownloader()

        let progressExpectation = expectation(description: "progress closure should be called")
        let completedExpectation = expectation(description: "download request should succeed")

        var progressCalled = false
        var calledOnExpectedQueue = false

        // When
        downloader.download(.image(.jpeg),
                            progress: { _ in
                                if progressCalled == false {
                                    progressCalled = true
                                    calledOnExpectedQueue = !Thread.isMainThread

                                    progressExpectation.fulfill()
                                }
                            },
                            progressQueue: DispatchQueue.global(qos: .utility),
                            completion: { _ in
                                completedExpectation.fulfill()
                            })

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(calledOnExpectedQueue, "progress handler should be called on expected queue")
    }

    // MARK: - Cancellation Tests

    func testThatCancellingDownloadCallsCompletionWithCancellationError() {
        // Given
        let downloader = ImageDownloader()

        let expectation = self.expectation(description: "download request should cancel")

        var response: AFIDataResponse<Image>?

        // When
        let requestReceipt = downloader.download(.image(.jpeg), completion: { closureResponse in
            response = closureResponse
            expectation.fulfill()
        })

        downloader.cancelRequest(with: requestReceipt!)

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(response, "response should not be nil")
        XCTAssertNil(response?.response, "response should be nil")
        XCTAssertNil(response?.data, "data should be nil")
        XCTAssertTrue(response?.result.isFailure ?? false, "result should be a failure case")

        if let error = response?.result.error {
            XCTAssertTrue(error.isRequestCancelledError)
        } else {
            XCTFail("error should not be nil")
        }
    }

    func testThatCancellingDownloadWithMultipleResponseHandlersCancelsFirstYetAllowsSecondToComplete() {
        // Given
        let downloader = ImageDownloader()

        let expectation1 = expectation(description: "download request 1 should succeed")
        let expectation2 = expectation(description: "download request 2 should succeed")

        var response1: AFIDataResponse<Image>?
        var response2: AFIDataResponse<Image>?

        // When
        let requestReceipt1 = downloader.download(.image(.jpeg), completion: { closureResponse in
            response1 = closureResponse
            expectation1.fulfill()
        })

        let requestReceipt2 = downloader.download(.image(.jpeg), completion: { closureResponse in
            response2 = closureResponse
            expectation2.fulfill()
        })

        downloader.cancelRequest(with: requestReceipt1!)

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertEqual(requestReceipt1?.request.task, requestReceipt2?.request.task, "tasks 1 and 2 should be equal")

        XCTAssertNotNil(response1, "response 1 should not be nil")
        XCTAssertNil(response1?.response, "response 1 response should be nil")
        XCTAssertNil(response1?.data, "response 1 data should be nil")
        XCTAssertTrue(response1?.result.isFailure ?? false, "response 1 result should be a failure case")

        if let error = response1?.result.error {
            XCTAssertTrue(error.isRequestCancelledError)
        } else {
            XCTFail("error should not be nil")
        }

        XCTAssertNotNil(response2, "response 2 should not be nil")
        XCTAssertNotNil(response2?.request, "response 2 request should not be nil")
        XCTAssertNotNil(response2?.response, "response 2 response should not be nil")
        XCTAssertNotNil(response2?.data, "response 2 data should not be nil")
        XCTAssertTrue(response2?.result.isSuccess ?? false, "response 2 result should be a success case")
    }

    func testThatItCanDownloadAndCancelAndDownloadAgain() {
        // Given
        let downloader = ImageDownloader()

        let imageEndpoints: [Endpoint] = ["5a105e8b9d40e1329780d62ea2265d8a",
                                          "6a105e8b9d40e1329780d62ea2265d8a",
                                          "7a105e8b9d40e1329780d62ea2265d8a",
                                          "8a105e8b9d40e1329780d62ea2265d8a",
                                          "9a105e8b9d40e1329780d62ea2265d8a"].map(Endpoint.gravatar)

        var initialResults: [AFIResult<Image>] = []
        var finalResults: [AFIResult<Image>] = []

        // When
        for (index, imageRequest) in imageEndpoints.enumerated() {
            let expectation = self.expectation(description: "Download \(index) should be cancelled: \(imageRequest)")

            let receipt = downloader.download(imageRequest, completion: { response in
                switch response.result {
                case .success:
                    initialResults.append(response.result)
                    expectation.fulfill()
                case .failure:
                    initialResults.append(response.result)
                    expectation.fulfill()
                }
            })

            if let receipt = receipt {
                downloader.cancelRequest(with: receipt)
            }
        }

        for (index, imageRequest) in imageEndpoints.enumerated() {
            let expectation = self.expectation(description: "Download \(index) should complete: \(imageRequest)")

            downloader.download(imageRequest, completion: { response in
                switch response.result {
                case .success:
                    finalResults.append(response.result)
                    expectation.fulfill()
                case .failure:
                    finalResults.append(response.result)
                    expectation.fulfill()
                }
            })
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertEqual(initialResults.count, 5)
        XCTAssertEqual(finalResults.count, 5)

        for result in initialResults {
            XCTAssertTrue(result.isFailure)

            if case let .failure(error) = result {
                XCTAssertTrue(error.isRequestCancelledError)
            } else {
                XCTFail("error should not be nil")
            }
        }

        for result in finalResults {
            XCTAssertTrue(result.isSuccess)
        }
    }

    // MARK: - Authentication Tests

    func testThatItDoesNotAttachAuthenticationCredentialToRequestIfItDoesNotExist() {
        // Given
        let downloader = ImageDownloader()

        // When
        let requestReceipt = downloader.download(.image(.jpeg), completion: { _ in
            // No-op
        })

        let credential = requestReceipt?.request.credential
        requestReceipt?.request.cancel()

        // Then
        XCTAssertNil(credential, "credential should be nil")
    }

    func testThatItAttachesUsernamePasswordCredentialToRequestIfItExists() {
        // Given
        let downloader = ImageDownloader()

        // When
        downloader.addAuthentication(user: "foo", password: "bar")

        let requestReceipt = downloader.download(.image(.jpeg), completion: { _ in
            // No-op
        })

        let credential = requestReceipt?.request.credential
        requestReceipt?.request.cancel()

        // Then
        XCTAssertNotNil(credential, "credential should not be nil")
    }

    func testThatItAttachesAuthenticationCredentialToRequestIfItExists() {
        // Given
        let downloader = ImageDownloader()

        // When
        let credential = URLCredential(user: "foo", password: "bar", persistence: .forSession)
        downloader.addAuthentication(usingCredential: credential)

        let requestReceipt = downloader.download(.image(.jpeg), completion: { _ in
            // No-op
        })

        let requestCredential = requestReceipt?.request.credential
        requestReceipt?.request.cancel()

        // Then
        XCTAssertNotNil(requestCredential, "request credential should not be nil")
    }

    // MARK: - Threading Tests

    func testThatItCallsTheCompletionHandlerOnTheMainQueue() {
        // Given
        let downloader = ImageDownloader()
        let urlRequest = try! URLRequest(url: "https://httpbin.org/image/jpeg", method: .get)

        let expectation = self.expectation(description: "download request should succeed")

        var calledOnMainQueue = false

        // When
        downloader.download(urlRequest, completion: { _ in
            calledOnMainQueue = Thread.isMainThread
            expectation.fulfill()
        })

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(calledOnMainQueue, "completion handler should be called on main queue")
    }

    func testThatItCallsTheCompletionHandlerOnTheMainQueueIfRequestFailed() {
        // Given
        let downloader = ImageDownloader()

        let expectation = self.expectation(description: "download request should succeed")

        var calledOnMainQueue = false

        // When
        downloader.download(.nonexistent, completion: { _ in
            calledOnMainQueue = Thread.isMainThread
            expectation.fulfill()
        })

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(calledOnMainQueue, "completion handler should be called on main queue")
    }

    func testThatItCallsTheCompletionHandlerOnTheMainQueueIfURLRequestConvertibleThrows() {
        // Given
        let downloader = ImageDownloader()
        let urlRequest = ThrowingURLRequestConvertible()

        let expectation = self.expectation(description: "download request should succeed")

        var calledOnMainQueue = false

        // When
        downloader.download(urlRequest, completion: { _ in
            calledOnMainQueue = Thread.isMainThread
            expectation.fulfill()
        })

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(calledOnMainQueue, "completion handler should be called on main queue")
    }

    func testThatItNeverCallsTheImageFilterOnTheMainQueue() {
        // Given
        let downloader = ImageDownloader()
        let filter = ThreadCheckFilter()

        let expectation = self.expectation(description: "download request should succeed")

        // When
        downloader.download(.image(.jpeg), filter: filter, completion: { _ in
            expectation.fulfill()
        })

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertFalse(filter.calledOnMainQueue, "filter should not be called on main queue")
    }

    // MARK: - Image Caching Tests

    func testThatCachedImageIsReturnedIfAllowedByCachePolicy() {
        // Given
        let downloader = ImageDownloader()

        let expectation1 = expectation(description: "image download should succeed")

        // When
        let requestReceipt1 = downloader.download(.image(.jpeg), completion: { _ in
            expectation1.fulfill()
        })

        waitForExpectations(timeout: timeout)

        let endpoint = Endpoint.image(.jpeg).modifying(\.cachePolicy, to: .returnCacheDataElseLoad)

        let expectation2 = expectation(description: "image download should succeed")

        let requestReceipt2 = downloader.download(endpoint, completion: { _ in
            expectation2.fulfill()
        })

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(requestReceipt1, "request receipt 1 should not be nil")
        XCTAssertNil(requestReceipt2, "request receipt 2 should be nil")
    }

    func testThatCachedImageIsNotReturnedIfNotAllowedByCachePolicy() {
        // Given
        let downloader = ImageDownloader()

        let expectation1 = expectation(description: "image download should succeed")

        // When
        let requestReceipt1 = downloader.download(.image(.jpeg), completion: { _ in
            expectation1.fulfill()
        })

        waitForExpectations(timeout: timeout)

        let endpoint = Endpoint.image(.jpeg).modifying(\.cachePolicy, to: .reloadIgnoringLocalCacheData)

        let expectation2 = expectation(description: "image download should succeed")

        let requestReceipt2 = downloader.download(endpoint, completion: { _ in
            expectation2.fulfill()
        })

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(requestReceipt1, "request receipt 1 should not be nil")
        XCTAssertNotNil(requestReceipt2, "request receipt 2 should not be nil")
    }

    func testThatItCanDownloadImagesWhenNoImageCacheIsAvailable() {
        // Given
        let downloader = ImageDownloader(imageCache: nil)
        let expectation = self.expectation(description: "image download should succeed")

        var response: AFIDataResponse<Image>?

        // When
        downloader.download(.image(.jpeg), completion: { closureResponse in
            response = closureResponse
            expectation.fulfill()
        })

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(response?.request, "request should not be nil")
        XCTAssertNotNil(response?.response, "response should not be nil")
        XCTAssertTrue(response?.result.isSuccess ?? false, "result should be a success case")
    }

    func testThatItAutomaticallyCachesDownloadedImageIfCacheIsAvailable() {
        // Given
        let downloader = ImageDownloader()

        let expectation1 = expectation(description: "image download should succeed")

        var result1: AFIResult<Image>?
        var result2: AFIResult<Image>?

        // When
        let requestReceipt1 = downloader.download(.image(.jpeg), completion: { closureResponse in
            result1 = closureResponse.result
            expectation1.fulfill()
        })

        waitForExpectations(timeout: timeout)

        let expectation2 = expectation(description: "image download should succeed")

        let requestReceipt2 = downloader.download(.image(.jpeg), completion: { closureResponse in
            result2 = closureResponse.result
            expectation2.fulfill()
        })

        waitForExpectations(timeout: timeout)

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

    #if os(iOS) || os(tvOS)

    func testThatFilteredImageIsStoredInCacheIfCacheIsAvailable() {
        // Given
        let downloader = ImageDownloader()
        let size = CGSize(width: 20, height: 20)
        let filter = ScaledToSizeFilter(size: size)

        let expectation1 = expectation(description: "image download should succeed")

        var result1: AFIResult<Image>?
        var result2: AFIResult<Image>?

        // When
        let requestReceipt1 = downloader.download(.image(.jpeg), filter: filter, completion: { closureResponse in
            result1 = closureResponse.result
            expectation1.fulfill()
        })

        waitForExpectations(timeout: timeout)

        let expectation2 = expectation(description: "image download should succeed")

        let requestReceipt2 = downloader.download(.image(.jpeg), filter: filter, completion: { closureResponse in
            result2 = closureResponse.result
            expectation2.fulfill()
        })

        waitForExpectations(timeout: timeout)

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
        let endpoint = Endpoint.image(.jpeg)
        let request = downloader.session.request(endpoint)

        // When
        let activeRequestCountBefore = downloader.activeRequestCount
        downloader.start(request)
        let activeRequestCountAfter = downloader.activeRequestCount

        request.cancel()

        // Then
        XCTAssertEqual(activeRequestCountBefore, 0, "active request count before should be 0")
        XCTAssertEqual(activeRequestCountAfter, 1, "active request count after should be 1")
    }

    func testThatEnqueueRequestInsertsRequestAtTheBackOfTheQueueWithFIFODownloadPrioritization() {
        // Given
        let downloader = ImageDownloader()

        let request1 = downloader.session.request(.image(.jpeg))
        let request2 = downloader.session.request(.image(.png))

        // When
        downloader.enqueue(request1)
        downloader.enqueue(request2)

        let queuedRequests = downloader.queuedRequests

        // Then
        XCTAssertEqual(queuedRequests.count, 2, "queued requests count should be 1")
        XCTAssertEqual(queuedRequests[0].task, request1.task, "first queued request should be request 1")
        XCTAssertEqual(queuedRequests[1].task, request2.task, "second queued request should be request 2")
    }

    func testThatEnqueueRequestInsertsRequestAtTheFrontOfTheQueueWithLIFODownloadPrioritization() {
        // Given
        let downloader = ImageDownloader(downloadPrioritization: .lifo)

        let request1 = downloader.session.request(.image(.jpeg))
        let request2 = downloader.session.request(.image(.png))

        // When
        downloader.enqueue(request1)
        downloader.enqueue(request2)

        let queuedRequests = downloader.queuedRequests

        // Then
        XCTAssertEqual(queuedRequests.count, 2, "queued requests count should be 1")
        XCTAssertEqual(queuedRequests[0].task, request2.task, "first queued request should be request 2")
        XCTAssertEqual(queuedRequests[1].task, request1.task, "second queued request should be request 1")
    }

    func testThatDequeueRequestAlwaysRemovesRequestFromTheFrontOfTheQueue() {
        // Given
        let downloader = ImageDownloader(downloadPrioritization: .fifo)

        let request1 = downloader.session.request(.image(.jpeg))
        let request2 = downloader.session.request(.image(.png))

        // When
        downloader.enqueue(request1)
        downloader.enqueue(request2)
        downloader.dequeue()

        let queuedRequests = downloader.queuedRequests

        // Then
        XCTAssertEqual(queuedRequests.count, 1, "queued requests count should be 1")
        XCTAssertEqual(queuedRequests[0].task, request2.task, "queued request should be request 2")
    }
}
