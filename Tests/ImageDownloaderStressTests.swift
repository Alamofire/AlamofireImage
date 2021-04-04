//
//  ImageDownloaderStressTests.swift
//
//  Copyright (c) 2019 Alamofire Software Foundation (http://alamofire.org/)
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

final class ImageDownloaderStressTestCase: BaseTestCase {
    let imageCount = 1000
    var cache: Set<String> = []

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()

        cache.removeAll()
    }

    // MARK: - Tests - Common Use Cases

    func testThatItCanDownloadManyImagesInParallel() {
        // Given
        let endpoints = (1...imageCount).map { _ in randomUniversalImageEndpoint() }
        let imageDownloader = ImageDownloader(configuration: .ephemeral)

        let expect = expectation(description: "all requests should complete")
        expect.expectedFulfillmentCount = endpoints.count

        var receipts: [RequestReceipt] = []
        var responses: [AFIDataResponse<Image>] = []

        // When
        for endpoint in endpoints {
            let receipt = imageDownloader.download(endpoint, completion: { response in
                responses.append(response)
                expect.fulfill()
            })

            receipt.flatMap { receipts.append($0) }
        }

        waitForExpectations(timeout: 10, handler: nil)

        // Then
        XCTAssertEqual(receipts.count, imageCount)
        XCTAssertEqual(responses.count, imageCount)
        responses.forEach { XCTAssertTrue($0.result.isSuccess) }
    }

    func testThatItCanDownloadManyImagesInParallelWhileCancellingRequests() {
        // Given
        let cancelledImageCount = 4
        let endpoints = (1...imageCount).map { _ in randomUniversalImageEndpoint() }
        let imageDownloader = ImageDownloader(configuration: .ephemeral)

        let expect = expectation(description: "all requests should complete")
        expect.expectedFulfillmentCount = endpoints.count

        var receipts: [RequestReceipt] = []
        var responses: [AFIDataResponse<Image>] = []

        // When
        for endpoint in endpoints {
            let receipt = imageDownloader.download(endpoint, completion: { response in
                responses.append(response)
                expect.fulfill()
            })

            receipt.flatMap { receipts.append($0) }
        }

        receipts.suffix(cancelledImageCount).forEach { imageDownloader.cancelRequest(with: $0) }

        waitForExpectations(timeout: 10, handler: nil)

        // Then
        XCTAssertEqual(receipts.count, imageCount)
        XCTAssertEqual(responses.count, imageCount)

        let successCount = responses.reduce(0) { count, response in response.result.isSuccess ? count + 1 : count }
        let failureCount = responses.reduce(0) { count, response in response.result.isFailure ? count + 1 : count }

        XCTAssertEqual(successCount, imageCount - cancelledImageCount)
        XCTAssertEqual(failureCount, cancelledImageCount)
    }

    // MARK: - Tests - Uncommon Use Cases (External Abuse)

    func testThatItCanDownloadManyImagesInParallelWhileResumingRequestsExternally() {
        // Given
        let endpoints = (1...imageCount).map { _ in randomUniversalImageEndpoint() }
        let imageDownloader = ImageDownloader(configuration: .ephemeral)

        let expect = expectation(description: "all requests should complete")
        expect.expectedFulfillmentCount = endpoints.count

        var receipts: [RequestReceipt] = []
        var responses: [AFIDataResponse<Image>] = []

        // When
        for endpoint in endpoints {
            let receipt = imageDownloader.download(endpoint, completion: { response in
                responses.append(response)
                expect.fulfill()
            })

            receipt.flatMap { receipts.append($0) }
        }

        receipts.suffix(4).forEach { $0.request.resume() }

        waitForExpectations(timeout: 10, handler: nil)

        // Then
        XCTAssertEqual(receipts.count, imageCount)
        XCTAssertEqual(responses.count, imageCount)
        responses.forEach { XCTAssertTrue($0.result.isSuccess) }
    }

    func testThatItCanDownloadManyImagesInParallelWhileCancellingRequestsExternally() {
        // Given
        let cancelledImageCount = 4
        let endpoints = (1...imageCount).map { _ in randomUniversalImageEndpoint() }
        let imageDownloader = ImageDownloader(configuration: .ephemeral)

        let expect = expectation(description: "all requests should complete")
        expect.expectedFulfillmentCount = endpoints.count

        var receipts: [RequestReceipt] = []
        var responses: [AFIDataResponse<Image>] = []

        // When
        for endpoint in endpoints {
            let receipt = imageDownloader.download(endpoint, completion: { response in
                responses.append(response)
                expect.fulfill()
            })

            receipt.flatMap { receipts.append($0) }
        }

        receipts.suffix(cancelledImageCount).forEach { $0.request.cancel() }

        waitForExpectations(timeout: 10, handler: nil)

        // Then
        XCTAssertEqual(receipts.count, imageCount)
        XCTAssertEqual(responses.count, imageCount)

        let successCount = responses.reduce(0) { count, response in response.result.isSuccess ? count + 1 : count }
        let failureCount = responses.reduce(0) { count, response in response.result.isFailure ? count + 1 : count }

        XCTAssertEqual(successCount, imageCount - cancelledImageCount)
        XCTAssertEqual(failureCount, cancelledImageCount)
    }

    private func randomUniversalImageEndpoint() -> Endpoint {
        let endpoint = Endpoint.image(Endpoint.Image.universalCases.randomElement()!)
            .modifying(\.queryItems, to: [.init(name: "random", value: "\(arc4random())")])

        let urlString = endpoint.url.absoluteString

        if cache.contains(urlString) {
            return randomUniversalImageEndpoint()
        } else {
            cache.insert(urlString)
            return endpoint
        }
    }
}
