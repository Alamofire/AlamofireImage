//
//  CombineTests.swift
//  AlamofireImage
//
//  Created by Jon Shier on 9/7/20.
//  Copyright © 2020 Alamofire. All rights reserved.
//

#if canImport(Combine)

import Alamofire
import AlamofireImage
import Combine
import XCTest

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
final class ImageRequestCombineTests: CombineTestCase {
    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func testImageRequestCanBePublished() {
        // Given
        let responseReceived = expectation(description: "response should be received")
        let completionReceived = expectation(description: "stream should complete")
        var response: DataResponse<Image, AFError>?

        // When
        store {
            AF.request("https://httpbin.org/image/png")
                .publishImage()
                .sink(receiveCompletion: { _ in completionReceived.fulfill() },
                      receiveValue: { response = $0; responseReceived.fulfill() })
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(response?.result.isSuccess == true)
    }

    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func testThatNonAutomaticImageRequestCanBePublished() {
        // Given
        let responseReceived = expectation(description: "response should be received")
        let completionReceived = expectation(description: "stream should complete")
        let session = Session(startRequestsImmediately: false)
        var response: DataResponse<Image, AFError>?

        // When
        store {
            session.request("https://httpbin.org/image/png")
                .publishImage()
                .sink(receiveCompletion: { _ in completionReceived.fulfill() },
                      receiveValue: { response = $0; responseReceived.fulfill() })
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(response?.result.isSuccess == true)
    }

    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func testThatImageRequestCanBePublishedWithMultipleHandlers() {
        // Given
        let handlerResponseReceived = expectation(description: "handler response should be received")
        let publishedResponseReceived = expectation(description: "published response should be received")
        let completionReceived = expectation(description: "stream should complete")
        var handlerResponse: DataResponse<Image, AFError>?
        var publishedResponse: DataResponse<Image, AFError>?

        // When
        store {
            AF.request("https://httpbin.org/image/png")
                .responseImage { handlerResponse = $0; handlerResponseReceived.fulfill() }
                .publishImage()
                .sink(receiveCompletion: { _ in completionReceived.fulfill() },
                      receiveValue: { publishedResponse = $0; publishedResponseReceived.fulfill() })
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(handlerResponse?.result.isSuccess == true)
        XCTAssertTrue(publishedResponse?.result.isSuccess == true)
    }

    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func testThatImageRequestCanPublishResult() {
        // Given
        let responseReceived = expectation(description: "response should be received")
        let completionReceived = expectation(description: "stream should complete")
        var result: Result<Image, AFError>?

        // When
        store {
            AF.request("https://httpbin.org/image/png")
                .publishImage()
                .result()
                .sink(receiveCompletion: { _ in completionReceived.fulfill() },
                      receiveValue: { result = $0; responseReceived.fulfill() })
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(result?.isSuccess == true)
    }

    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func testThatDataRequestCanPublishValue() {
        // Given
        let responseReceived = expectation(description: "response should be received")
        let completionReceived = expectation(description: "stream should complete")
        var value: Image?

        // When
        store {
            AF.request("https://httpbin.org/image/png")
                .publishImage()
                .value()
                .sink(receiveCompletion: { _ in completionReceived.fulfill() },
                      receiveValue: { value = $0; responseReceived.fulfill() })
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(value)
    }
}

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
final class ImageStreamCombineTests: CombineTestCase {
    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func testImageStreamCanBePublished() {
        // Given
        let responsesReceived = expectation(description: "responses should be received")
        responsesReceived.expectedFulfillmentCount = 2
        let completionReceived = expectation(description: "stream should complete")
        var responses: [DataStreamRequest.Stream<Image, AFError>] = []
        
        // When
        store {
            AF.streamRequest("https://httpbin.org/image/png")
                .publishImage()
                .sink(receiveCompletion: { _ in completionReceived.fulfill() },
                      receiveValue: { responses.append($0); responsesReceived.fulfill() })
        }
        
        waitForExpectations(timeout: timeout)
        
        // Then
        XCTAssertTrue(responses[0].result?.isSuccess == true)
    }
    
    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func testThatNonAutomaticImageRequestCanBePublished() {
        // Given
        let responsesReceived = expectation(description: "responses should be received")
        responsesReceived.expectedFulfillmentCount = 2
        let completionReceived = expectation(description: "stream should complete")
        let session = Session(startRequestsImmediately: false)
        var responses: [DataStreamRequest.Stream<Image, AFError>] = []
        
        // When
        store {
            session.streamRequest("https://httpbin.org/image/png")
                .publishImage()
                .sink(receiveCompletion: { _ in completionReceived.fulfill() },
                      receiveValue: { responses.append($0); responsesReceived.fulfill() })
        }
        
        waitForExpectations(timeout: timeout)
        
        // Then
        XCTAssertTrue(responses[0].result?.isSuccess == true)
    }
    
//    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
//    func testThatImageRequestCanBePublishedWithMultipleHandlers() {
//        // Given
//        let handlerResponseReceived = expectation(description: "handler response should be received")
//        let publishedResponseReceived = expectation(description: "published response should be received")
//        let completionReceived = expectation(description: "stream should complete")
//        var handlerResponse: DataResponse<Image, AFError>?
//        var publishedResponse: DataResponse<Image, AFError>?
//
//        // When
//        store {
//            AF.request("https://httpbin.org/image/png")
//                .responseImage { handlerResponse = $0; handlerResponseReceived.fulfill() }
//                .publishImage()
//                .sink(receiveCompletion: { _ in completionReceived.fulfill() },
//                      receiveValue: { publishedResponse = $0; publishedResponseReceived.fulfill() })
//        }
//
//        waitForExpectations(timeout: timeout)
//
//        // Then
//        XCTAssertTrue(handlerResponse?.result.isSuccess == true)
//        XCTAssertTrue(publishedResponse?.result.isSuccess == true)
//    }
//
//    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
//    func testThatImageRequestCanPublishResult() {
//        // Given
//        let responseReceived = expectation(description: "response should be received")
//        let completionReceived = expectation(description: "stream should complete")
//        var result: Result<Image, AFError>?
//
//        // When
//        store {
//            AF.request("https://httpbin.org/image/png")
//                .publishImage()
//                .result()
//                .sink(receiveCompletion: { _ in completionReceived.fulfill() },
//                      receiveValue: { result = $0; responseReceived.fulfill() })
//        }
//
//        waitForExpectations(timeout: timeout)
//
//        // Then
//        XCTAssertTrue(result?.isSuccess == true)
//    }
//
//    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
//    func testThatDataRequestCanPublishValue() {
//        // Given
//        let responseReceived = expectation(description: "response should be received")
//        let completionReceived = expectation(description: "stream should complete")
//        var value: Image?
//
//        // When
//        store {
//            AF.request("https://httpbin.org/image/png")
//                .publishImage()
//                .value()
//                .sink(receiveCompletion: { _ in completionReceived.fulfill() },
//                      receiveValue: { value = $0; responseReceived.fulfill() })
//        }
//
//        waitForExpectations(timeout: timeout)
//
//        // Then
//        XCTAssertNotNil(value)
//    }
}

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
final class ImageDownloadCombineTests: CombineTestCase {
    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func testImageRequestCanBePublished() {
        // Given
        let responseReceived = expectation(description: "response should be received")
        let completionReceived = expectation(description: "stream should complete")
        var response: DownloadResponse<Image, AFError>?

        // When
        store {
            AF.download("https://httpbin.org/image/png")
                .publishImage()
                .sink(receiveCompletion: { _ in completionReceived.fulfill() },
                      receiveValue: { response = $0; responseReceived.fulfill() })
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(response?.result.isSuccess == true)
    }

    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func testThatNonAutomaticImageRequestCanBePublished() {
        // Given
        let responseReceived = expectation(description: "response should be received")
        let completionReceived = expectation(description: "stream should complete")
        let session = Session(startRequestsImmediately: false)
        var response: DownloadResponse<Image, AFError>?

        // When
        store {
            session.download("https://httpbin.org/image/png")
                .publishImage()
                .sink(receiveCompletion: { _ in completionReceived.fulfill() },
                      receiveValue: { response = $0; responseReceived.fulfill() })
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(response?.result.isSuccess == true)
    }

    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func testThatImageRequestCanPublishResult() {
        // Given
        let responseReceived = expectation(description: "response should be received")
        let completionReceived = expectation(description: "stream should complete")
        var result: Result<Image, AFError>?

        // When
        store {
            AF.download("https://httpbin.org/image/png")
                .publishImage()
                .result()
                .sink(receiveCompletion: { _ in completionReceived.fulfill() },
                      receiveValue: { result = $0; responseReceived.fulfill() })
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(result?.isSuccess == true)
    }

    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func testThatDataRequestCanPublishValue() {
        // Given
        let responseReceived = expectation(description: "response should be received")
        let completionReceived = expectation(description: "stream should complete")
        var value: Image?

        // When
        store {
            AF.download("https://httpbin.org/image/png")
                .publishImage()
                .value()
                .sink(receiveCompletion: { _ in completionReceived.fulfill() },
                      receiveValue: { value = $0; responseReceived.fulfill() })
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(value)
    }
}

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
class CombineTestCase: BaseTestCase {
    var storage: Set<AnyCancellable> = []

    override func tearDown() {
        storage = []

        super.tearDown()
    }

    func store(_ toStore: () -> AnyCancellable) {
        storage.insert(toStore())
    }
}

#endif
