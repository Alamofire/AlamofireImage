//
//  Combine.swift
//
//  Copyright (c) 2020 Alamofire Software Foundation (http://alamofire.org/)
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

#if canImport(Combine)

import Alamofire
import CoreGraphics

extension DataRequest {
    #if os(macOS)
    
    /// Creates a `DownloadResponsePublisher<Image>` for this instance using the given parameters.
    ///
    /// - Parameters:
    ///   - queue:               `DispatchQueue` on which to serialize the response `Image`.
    ///   - emptyResponseCodes:  `Set<Int>` of HTTP status codes for which empty responses are allowed. `[204, 205]` by
    ///                          default.
    ///   - emptyRequestMethods: `Set<HTTPMethod>` of `HTTPMethod`s for which empty responses are allowed, regardless of
    ///                          status code. `[.head]` by default.
    ///
    /// - Returns: The `DataResponsePublisher`.
    @available(macOS 10.15, *)
    public func publishImage(queue: DispatchQueue = .main,
                             emptyResponseCodes: Set<Int> = ImageResponseSerializer.defaultEmptyResponseCodes,
                             emptyRequestMethods: Set<HTTPMethod> = ImageResponseSerializer.defaultEmptyRequestMethods
    ) -> DataResponsePublisher<Image> {
        publishResponse(using: ImageResponseSerializer(inflateResponseImage: false,
                                                       emptyResponseCodes: emptyResponseCodes,
                                                       emptyRequestMethods: emptyRequestMethods),
                        on: queue)
    }
    
    #else
    
    /// Creates a `DownloadResponsePublisher<Image>` for this instance using the given parameters.
    ///
    /// - Parameters:
    ///   - queue:                `DispatchQueue` on which to serialize the response `Image`.
    ///   - imageScale:           Scale at which the response `Image` is interpreted. Device scale by default.
    ///   - inflateResponseImage: Whether or not the response `Image` should be decompressed before being returned. Can
    ///                           cause crashes if images are especially large. `true` by default.
    ///   - emptyResponseCodes:   `Set<Int>` of HTTP status codes for which empty responses are allowed. `[204, 205]` by
    ///                           default.
    ///   - emptyRequestMethods:  `Set<HTTPMethod>` of `HTTPMethod`s for which empty responses are allowed, regardless of
    ///                           status code. `[.head]` by default.
    ///
    /// - Returns: The `DataResponsePublisher`.
    @available(iOS 13, watchOS 6, tvOS 13, *)
    public func publishImage(queue: DispatchQueue = .main,
                             imageScale: CGFloat = ImageResponseSerializer.deviceScreenScale,
                             inflateResponseImage: Bool = true,
                             emptyResponseCodes: Set<Int> = ImageResponseSerializer.defaultEmptyResponseCodes,
                             emptyRequestMethods: Set<HTTPMethod> = ImageResponseSerializer.defaultEmptyRequestMethods
    ) -> DataResponsePublisher<Image> {
        publishResponse(using: ImageResponseSerializer(imageScale: imageScale,
                                                       inflateResponseImage: inflateResponseImage,
                                                       emptyResponseCodes: emptyResponseCodes,
                                                       emptyRequestMethods: emptyRequestMethods),
                        on: queue)
    }
    
    #endif
}

extension DownloadRequest {
    #if os(macOS)
    
    /// Creates a `DownloadResponsePublisher<Image>` for this instance using the given parameters.
    ///
    /// - Parameters:
    ///   - queue:               `DispatchQueue` on which to serialize the response `Image`.
    ///   - emptyResponseCodes:  `Set<Int>` of HTTP status codes for which empty responses are allowed. `[204, 205]` by
    ///                          default.
    ///   - emptyRequestMethods: `Set<HTTPMethod>` of `HTTPMethod`s for which empty responses are allowed, regardless of
    ///                          status code. `[.head]` by default.
    ///
    /// - Returns: The `DownloadResponsePublisher`.
    @available(macOS 10.15, *)
    public func publishImage(queue: DispatchQueue = .main,
                             emptyResponseCodes: Set<Int> = ImageResponseSerializer.defaultEmptyResponseCodes,
                             emptyRequestMethods: Set<HTTPMethod> = ImageResponseSerializer.defaultEmptyRequestMethods
    ) -> DownloadResponsePublisher<Image> {
        publishResponse(using: ImageResponseSerializer(inflateResponseImage: false,
                                                       emptyResponseCodes: emptyResponseCodes,
                                                       emptyRequestMethods: emptyRequestMethods),
                        on: queue)
    }
    
    #else
    
    /// Creates a `DownloadResponsePublisher<Image>` for this instance using the given parameters.
    ///
    /// - Parameters:
    ///   - queue:                `DispatchQueue` on which to serialize the response `Image`.
    ///   - imageScale:           Scale at which the response `Image` is interpreted. Device scale by default.
    ///   - inflateResponseImage: Whether or not the response `Image` should be decompressed before being returned. Can
    ///                           cause crashes if images are especially large. `true` by default.
    ///   - emptyResponseCodes:   `Set<Int>` of HTTP status codes for which empty responses are allowed. `[204, 205]` by
    ///                           default.
    ///   - emptyRequestMethods:  `Set<HTTPMethod>` of `HTTPMethod`s for which empty responses are allowed, regardless of
    ///                           status code. `[.head]` by default.
    ///
    /// - Returns: The `DownloadResponsePublisher`.
    @available(iOS 13, watchOS 6, tvOS 13, *)
    public func publishImage(queue: DispatchQueue = .main,
                             imageScale: CGFloat = ImageResponseSerializer.deviceScreenScale,
                             inflateResponseImage: Bool = true,
                             emptyResponseCodes: Set<Int> = ImageResponseSerializer.defaultEmptyResponseCodes,
                             emptyRequestMethods: Set<HTTPMethod> = ImageResponseSerializer.defaultEmptyRequestMethods
    ) -> DownloadResponsePublisher<Image> {
        publishResponse(using: ImageResponseSerializer(imageScale: imageScale,
                                                       inflateResponseImage: inflateResponseImage,
                                                       emptyResponseCodes: emptyResponseCodes,
                                                       emptyRequestMethods: emptyRequestMethods),
                        on: queue)
    }
    
    #endif
}

#endif
