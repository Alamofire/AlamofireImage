//
//  Request+AlamofireImage.swift
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

import Alamofire
import Foundation

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(watchOS)
import UIKit
import WatchKit
#elseif os(macOS)
import Cocoa
#endif

public final class ImageResponseSerializer: ResponseSerializer {
    // MARK: Properties

    public static var deviceScreenScale: CGFloat { return DataRequest.imageScale }

    public let imageScale: CGFloat
    public let inflateResponseImage: Bool
    public let emptyResponseCodes: Set<Int>
    public let emptyRequestMethods: Set<HTTPMethod>

    static var acceptableImageContentTypes: Set<String> = ["application/octet-stream",
                                                           "image/tiff",
                                                           "image/jpeg",
                                                           "image/gif",
                                                           "image/png",
                                                           "image/ico",
                                                           "image/x-icon",
                                                           "image/bmp",
                                                           "image/x-bmp",
                                                           "image/x-xbitmap",
                                                           "image/x-ms-bmp",
                                                           "image/x-win-bitmap"]

    static let streamImageInitialBytePattern = Data([255, 216]) // 0xffd8

    // MARK: Initialization

    public init(imageScale: CGFloat = ImageResponseSerializer.deviceScreenScale,
                inflateResponseImage: Bool = true,
                emptyResponseCodes: Set<Int> = ImageResponseSerializer.defaultEmptyResponseCodes,
                emptyRequestMethods: Set<HTTPMethod> = ImageResponseSerializer.defaultEmptyRequestMethods) {
        self.imageScale = imageScale
        self.inflateResponseImage = inflateResponseImage
        self.emptyResponseCodes = emptyResponseCodes
        self.emptyRequestMethods = emptyRequestMethods
    }

    // MARK: Serialization

    public func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> Image {
        guard error == nil else { throw error! }

        guard let data = data, !data.isEmpty else {
            guard emptyResponseAllowed(forRequest: request, response: response) else {
                throw AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)
            }

            print("Returning empty image!")
            return Image()
        }

        try validateContentType(for: request, response: response)
        let image = try serializeImage(from: data)

        return image
    }

    public func serializeImage(from data: Data) throws -> Image {
        guard !data.isEmpty else {
            throw AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)
        }

        #if os(iOS) || os(tvOS) || os(watchOS)
        guard let image = UIImage.af.threadSafeImage(with: data, scale: imageScale) else {
            throw AFIError.imageSerializationFailed
        }

        if inflateResponseImage { image.af.inflate() }
        #elseif os(macOS)
        guard let bitmapImage = NSBitmapImageRep(data: data) else {
            throw AFIError.imageSerializationFailed
        }

        let image = NSImage(size: NSSize(width: bitmapImage.pixelsWide, height: bitmapImage.pixelsHigh))
        image.addRepresentation(bitmapImage)
        #endif

        return image
    }

    // MARK: Content Type Validation

    /// Adds the content types specified to the list of acceptable images content types for validation.
    ///
    /// - parameter contentTypes: The additional content types.
    public class func addAcceptableImageContentTypes(_ contentTypes: Set<String>) {
        ImageResponseSerializer.acceptableImageContentTypes.formUnion(contentTypes)
    }

    public func validateContentType(for request: URLRequest?, response: HTTPURLResponse?) throws {
        if let url = request?.url, url.isFileURL { return }

        guard let mimeType = response?.mimeType else {
            let contentTypes = Array(ImageResponseSerializer.acceptableImageContentTypes)
            throw AFError.responseValidationFailed(reason: .missingContentType(acceptableContentTypes: contentTypes))
        }

        guard ImageResponseSerializer.acceptableImageContentTypes.contains(mimeType) else {
            let contentTypes = Array(ImageResponseSerializer.acceptableImageContentTypes)

            throw AFError.responseValidationFailed(
                reason: .unacceptableContentType(acceptableContentTypes: contentTypes, responseContentType: mimeType)
            )
        }
    }
}

// MARK: - Image Scale

extension DataRequest {
    public class var imageScale: CGFloat {
        #if os(iOS) || os(tvOS)
        return UIScreen.main.scale
        #elseif os(watchOS)
        return WKInterfaceDevice.current().screenScale
        #elseif os(macOS)
        return 1.0
        #endif
    }
}

// MARK: - iOS, tvOS, and watchOS

#if os(iOS) || os(tvOS) || os(watchOS)

extension DataRequest {
    /// Adds a response handler to be called once the request has finished.
    ///
    /// - parameter imageScale:           The scale factor used when interpreting the image data to construct
    ///                                   `responseImage`. Specifying a scale factor of 1.0 results in an image whose
    ///                                   size matches the pixel-based dimensions of the image. Applying a different
    ///                                   scale factor changes the size of the image as reported by the size property.
    ///                                   This is set to the value of scale of the main screen by default, which
    ///                                   automatically scales images for retina displays, for instance.
    ///                                   `Screen.scale` by default.
    /// - parameter inflateResponseImage: Whether to automatically inflate response image data for compressed formats
    ///                                   (such as PNG or JPEG). Enabling this can significantly improve drawing
    ///                                   performance as it allows a bitmap representation to be constructed in the
    ///                                   background rather than on the main thread. `true` by default.
    /// - parameter queue:                The queue on which the completion handler is dispatched. `.main` by default.
    /// - parameter completionHandler:    A closure to be executed once the request has finished. The closure takes 4
    ///                                   arguments: the URL request, the URL response, if one was received, the image,
    ///                                   if one could be created from the URL response and data, and any error produced
    ///                                   while creating the image.
    ///
    /// - returns: The request.
    @discardableResult
    public func responseImage(imageScale: CGFloat = DataRequest.imageScale,
                              inflateResponseImage: Bool = true,
                              queue: DispatchQueue = .main,
                              completionHandler: @escaping (AFDataResponse<Image>) -> Void)
        -> Self {
        return response(queue: queue,
                        responseSerializer: ImageResponseSerializer(imageScale: imageScale,
                                                                    inflateResponseImage: inflateResponseImage),
                        completionHandler: completionHandler)
    }
}

// MARK: - macOS

#elseif os(macOS)

extension DataRequest {
    /// Adds a response handler to be called once the request has finished.
    ///
    /// - Parameters:
    ///   - queue:             The queue on which the completion handler is dispatched. `.main` by default.
    ///   - completionHandler: A closure to be executed once the request has finished. The closure takes 4 arguments:
    ///                        the URL request, the URL response, if one was received, the image, if one could be
    ///                        created from the URL response and data, and any error produced while creating the image.
    ///
    /// - returns: The request.
    @discardableResult
    public func responseImage(queue: DispatchQueue = .main,
                              completionHandler: @escaping (AFDataResponse<Image>) -> Void)
        -> Self {
        return response(queue: queue,
                        responseSerializer: ImageResponseSerializer(inflateResponseImage: false),
                        completionHandler: completionHandler)
    }
}

#endif
