// Request+AlamofireImage.swift
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

import Alamofire
import Foundation

#if os(iOS)
import UIKit
#elseif os(OSX)
import Cocoa
#endif

public extension Request {
    public typealias CompletionHandler = (NSURLRequest?, NSHTTPURLResponse?, Result<Image>) -> Void

    // MARK: - iOS Methods

#if os(iOS)

    /**
        Creates a response serializer that returns an image initialized from the response data using the specified
        image options.

        - parameter imageScale: The scale factor used when interpreting the image data to construct `responseImage`.
            Specifying a scale factor of 1.0 results in an image whose size matches the pixel-based dimensions of the
            image. Applying a different scale factor changes the size of the image as reported by the size property.
            `UIScreen.mainScreen().scale` by default.
        - parameter automaticallyInflateResponseImage: Whether to automatically inflate response image data for
            compressed formats (such as PNG or JPEG). Enabling this can significantly improve drawing performance as it
            allows a bitmap representation to be constructed in the background rather than on the main thread. `true`
            by default.

        - returns: An image response serializer.
    */
    public class func imageResponseSerializer(
        imageScale imageScale: CGFloat = UIScreen.mainScreen().scale,
        automaticallyInflateResponseImage: Bool = true)
        -> GenericResponseSerializer<UIImage>
    {
        return GenericResponseSerializer { request, response, data in
            guard let validData = data else {
                return .Failure(data, Request.imageDataError())
            }

            guard Request.validateResponse(response) else {
                return .Failure(data, Request.contentTypeValidationError())
            }

            do {
                var image = try Request.imageFromResponseData(validData, imageScale: imageScale)

                if automaticallyInflateResponseImage, let inflatedImage = Request.inflateImage(image) {
                    image = inflatedImage
                }

                return .Success(image)
            } catch {
                return .Failure(data, error)
            }
        }
    }

    /**
        Adds a handler to be called once the request has finished.

        - parameter imageScale: The scale factor used when interpreting the image data to construct `responseImage`.
            Specifying a scale factor of 1.0 results in an image whose size matches the pixel-based dimensions of the
            image. Applying a different scale factor changes the size of the image as reported by the size property.
            This is set to the value of scale of the main screen by default, which automatically scales images for
            retina displays, for instance. `UIScreen.mainScreen().scale` by default.
        - parameter automaticallyInflateResponseImage: Whether to automatically inflate response image data for
            compressed formats (such as PNG or JPEG). Enabling this can significantly improve drawing performance as it
            allows a bitmap representation to be constructed in the background rather than on the main thread. `true`
            by default.
        - parameter completionHandler: A closure to be executed once the request has finished. The closure takes 4
            arguments: the URL request, the URL response, if one was received, the image, if one could be created from
            the URL response and data, and any error produced while creating the image.

        - returns: The request.
    */
    public func responseImage(
        imageScale: CGFloat = UIScreen.mainScreen().scale,
        automaticallyInflateResponseImage: Bool = true,
        completionHandler: CompletionHandler)
        -> Self
    {
        return response(
            responseSerializer: Request.imageResponseSerializer(
                imageScale: imageScale,
                automaticallyInflateResponseImage: automaticallyInflateResponseImage
            ),
            completionHandler: completionHandler
        )
    }

    private class func imageFromResponseData(data: NSData, imageScale: CGFloat) throws -> UIImage {
        // TODO: Figure out why we need this extra step here...
        if let image = UIImage(data: data) {
            return UIImage(CGImage: image.CGImage!, scale: imageScale, orientation: image.imageOrientation)
        }

        throw imageDataError()
    }

    private class func inflateImage(compressedImage: UIImage) -> UIImage? {
        // Do not attempt to inflate animated images
        guard compressedImage.images == nil else { return nil }

        let imageRef = CGImageCreateCopy(compressedImage.CGImage)

        let width = CGImageGetWidth(imageRef)
        let height = CGImageGetHeight(imageRef)
        let bitsPerComponent = CGImageGetBitsPerComponent(imageRef)

        // Do not inflate images that are too large or have more than 8-bit components
        if width * height > 1024 * 1024 || bitsPerComponent > 8 {
            return compressedImage
        }

        let bytesPerRow: Int = 0
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var bitmapInfo = CGImageGetBitmapInfo(imageRef)

        // Fix alpha channel issues if necessary
        let alpha = (bitmapInfo.rawValue & CGBitmapInfo.AlphaInfoMask.rawValue)

        if alpha == CGImageAlphaInfo.None.rawValue {
            bitmapInfo.remove(.AlphaInfoMask)
            bitmapInfo = CGBitmapInfo(rawValue: bitmapInfo.rawValue | CGImageAlphaInfo.NoneSkipFirst.rawValue)
        } else if !(alpha == CGImageAlphaInfo.NoneSkipFirst.rawValue) || !(alpha == CGImageAlphaInfo.NoneSkipLast.rawValue) {
            bitmapInfo.remove(.AlphaInfoMask)
            bitmapInfo = CGBitmapInfo(rawValue: bitmapInfo.rawValue | CGImageAlphaInfo.PremultipliedFirst.rawValue)
        }

        let context = CGBitmapContextCreate(nil, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo.rawValue)
        CGContextDrawImage(context, CGRectMake(0.0, 0.0, CGFloat(width), CGFloat(height)), imageRef)

        guard let inflatedImageRef = CGBitmapContextCreateImage(context) else { return nil }

        return UIImage(
            CGImage: inflatedImageRef,
            scale: compressedImage.scale,
            orientation: compressedImage.imageOrientation
        )
    }

#elseif os(OSX)

    // MARK: - OSX Methods

    /**
        Creates a response serializer that returns an image initialized from the response data.

        - returns: An image response serializer.
    */
    public class func imageResponseSerializer() -> GenericResponseSerializer<NSImage> {
        return GenericResponseSerializer { request, response, data in
            guard let validData = data else {
                return .Failure(data, Request.imageDataError())
            }

            guard Request.validateResponse(response) else {
                return .Failure(data, Request.contentTypeValidationError())
            }

            guard let bitmapImage = NSBitmapImageRep(data: validData) else {
                return .Failure(data, Request.imageDataError())
            }

            let image = NSImage(size: NSSize(width: bitmapImage.pixelsWide, height: bitmapImage.pixelsHigh))
            image.addRepresentation(bitmapImage)

            return .Success(image)
        }
    }

    /**
        Adds a handler to be called once the request has finished.

        - parameter completionHandler: A closure to be executed once the request has finished. The closure takes 4
            arguments: the URL request, the URL response, if one was received, the image, if one could be created from
            the URL response and data, and any error produced while creating the image.

        - returns: The request.
    */
    public func responseImage(completionHandler: CompletionHandler) -> Self {
        return response(
            responseSerializer: Request.imageResponseSerializer(),
            completionHandler: completionHandler
        )
    }

#endif

    // MARK: - Private - Shared Helper Methods

    private class func validateResponse(response: NSHTTPURLResponse?) -> Bool {
        let acceptableContentTypes: Set<String> = [
            "image/tiff",
            "image/jpeg",
            "image/gif",
            "image/png",
            "image/ico",
            "image/x-icon",
            "image/bmp",
            "image/x-bmp",
            "image/x-xbitmap",
            "image/x-win-bitmap"
        ]

        if let mimeType = response?.MIMEType where acceptableContentTypes.contains(mimeType) {
            return true
        }

        return false
    }

    private class func contentTypeValidationError() -> NSError {
        let failureReason = "Failed to validate response due to unacceptable content type"
        return Error.errorWithCode(NSURLErrorCannotDecodeContentData, failureReason: failureReason)
    }

    private class func imageDataError() -> NSError {
        let failureReason = "Failed to create a valid Image from the response data"
        return Error.errorWithCode(NSURLErrorCannotDecodeContentData, failureReason: failureReason)
    }
}
