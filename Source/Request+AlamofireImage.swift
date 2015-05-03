// Request+AlamofireImage.swift
//
// Copyright (c) 2014–2015 Alamofire (http://alamofire.org)
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

import Foundation
import Alamofire

#if os(iOS)
import UIKit
#elseif os(OSX)
import Cocoa
#endif

public extension Request {

    public typealias CompletionHandler = (NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void
    
    // MARK: - iOS Methods
    
#if os(iOS)
    
    /**
        Creates a response serializer that returns an image initialized from the response data using the specified
        image options.
    
        :param: imageScale The scale factor used when interpreting the image data to construct `responseImage`. 
            Specifying a scale factor of 1.0 results in an image whose size matches the pixel-based dimensions of 
            the image. Applying a different scale factor changes the size of the image as reported by the size 
            property. `UIScreen.mainScreen().scale` by default.
        :param: automaticallyInflateResponseImage Whether to automatically inflate response image data for compressed 
            formats (such as PNG or JPEG). Enabling this can significantly improve drawing performance as it allows a 
            bitmap representation to be constructed in the background rather than on the main thread. `true` by default.
    
        :returns: An image response serializer.
    */
    public class func imageResponseSerializer(
        imageScale: CGFloat = UIScreen.mainScreen().scale,
        automaticallyInflateResponseImage: Bool = true)
        -> Serializer
    {
        return { request, response, data in
            if data == nil {
                return (nil, Request.imageDataError())
            }
            
            if !Request.validateResponse(response) {
                return (nil, Request.contentTypeValidationError())
            }
            
            var image: UIImage?
            var error: NSError?
            
            (image, error) = Request.imageFromResponseData(data!, imageScale: imageScale)
            
            if var image = image {
                if automaticallyInflateResponseImage {
                    if let inflatedImage = Request.inflateImage(image) {
                        image = inflatedImage
                    }
                }
            }
            
            return (image, error)
        }
    }
    
    /**
        Adds a handler to be called once the request has finished.
    
        :param: imageScale The scale factor used when interpreting the image data to construct `responseImage`. 
            Specifying a scale factor of 1.0 results in an image whose size matches the pixel-based dimensions of 
            the image. Applying a different scale factor changes the size of the image as reported by the size 
            property. This is set to the value of scale of the main screen by default, which automatically scales 
            images for retina displays, for instance. `UIScreen.mainScreen().scale` by default.
        :param: automaticallyInflateResponseImage Whether to automatically inflate response image data for compressed 
            formats (such as PNG or JPEG). Enabling this can significantly improve drawing performance as it allows a 
            bitmap representation to be constructed in the background rather than on the main thread. `true` by default.
        :param: completionHandler A closure to be executed once the request has finished. The closure takes 4 
            arguments: the URL request, the URL response, if one was received, the image, if one could be created from 
            the URL response and data, and any error produced while creating the image.
    
        :returns: The request.
    */
    public func responseImage(
        imageScale: CGFloat = UIScreen.mainScreen().scale,
        automaticallyInflateResponseImage: Bool = true,
        completionHandler: CompletionHandler) -> Self
    {
        return response(
            serializer: Request.imageResponseSerializer(
                imageScale: imageScale,
                automaticallyInflateResponseImage: automaticallyInflateResponseImage
            ),
            completionHandler: { request, response, data, error in
                completionHandler(request, response, data, error)
            }
        )
    }
    
    private class func imageFromResponseData(data: NSData, imageScale: CGFloat) -> (UIImage?, NSError?) {
        var resultImage: UIImage? = nil
        var error: NSError? = nil
        
        if var image = UIImage(data: data) {
            let adjustedImage = UIImage(
                CGImage: image.CGImage,
                scale: imageScale,
                orientation: image.imageOrientation
            )
            
            if let adjustedImage = adjustedImage {
                resultImage = adjustedImage
            }
        }
        
        if let resultImage = resultImage {
            return (resultImage, nil)
        } else {
            return (nil, imageDataError())
        }
    }
    
    private class func inflateImage(compressedImage: UIImage) -> UIImage? {
        
        // Do not attempt to inflate animated images
        if let images = compressedImage.images {
            return nil
        }
        
        let imageRef = CGImageCreateCopy(compressedImage.CGImage)
        
        let width = CGImageGetWidth(imageRef)
        let height = CGImageGetHeight(imageRef)
        let bitsPerComponent = CGImageGetBitsPerComponent(imageRef)
        
        // Do not inflate images that are too large or have more than 8-bit components
        if width * height > 1024 * 1024 || bitsPerComponent > 8 {
            return compressedImage
        }
        
        var bytesPerRow: Int = 0
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colorSpaceModel = CGColorSpaceGetModel(colorSpace)
        var bitmapInfo = CGImageGetBitmapInfo(imageRef)
        
        // Fix alpha channel issues if necessary
        if colorSpaceModel.value == kCGColorSpaceModelRGB.value {
            let alpha: UInt32 = (bitmapInfo.rawValue & CGBitmapInfo.AlphaInfoMask.rawValue)
            
            if alpha == CGImageAlphaInfo.None.rawValue {
                bitmapInfo &= ~CGBitmapInfo.AlphaInfoMask
                bitmapInfo = CGBitmapInfo(bitmapInfo.rawValue | CGImageAlphaInfo.NoneSkipFirst.rawValue)
            } else if !(alpha == CGImageAlphaInfo.NoneSkipFirst.rawValue || alpha == CGImageAlphaInfo.NoneSkipLast.rawValue) {
                bitmapInfo &= ~CGBitmapInfo.AlphaInfoMask
                bitmapInfo = CGBitmapInfo(bitmapInfo.rawValue | CGImageAlphaInfo.PremultipliedFirst.rawValue)
            }
        }
        
        let context = CGBitmapContextCreate(nil, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo)
        
        // Return the original image if the context creation failed
        if context == nil {
            return nil
        }
        
        CGContextDrawImage(context, CGRectMake(0.0, 0.0, CGFloat(width), CGFloat(height)), imageRef)
        let inflatedImageRef = CGBitmapContextCreateImage(context)
        
        if let inflatedImage = UIImage(
            CGImage: inflatedImageRef,
            scale: compressedImage.scale,
            orientation: compressedImage.imageOrientation)
        {
            return inflatedImage
        }
        
        return nil
    }
    
#elseif os(OSX)
    
    // MARK: - OSX Methods
    
    /**
        Creates a response serializer that returns an image initialized from the response data.
    
        :returns: An image response serializer.
    */
    public class func imageResponseSerializer() -> Serializer {
        return { request, response, data in
            if data == nil {
                return (nil, Request.imageDataError())
            }
        
            if !Request.validateResponse(response) {
                return (nil, Request.contentTypeValidationError())
            }
            
            var image: NSImage?
            var error: NSError?
            
            if let bitmapImage = NSBitmapImageRep(data: data!) {
                image = NSImage(size: NSSize(width: bitmapImage.pixelsWide, height: bitmapImage.pixelsHigh))
                image!.addRepresentation(bitmapImage)
            } else {
                error = Request.imageDataError()
            }
            
            return (image, error)
        }
    }
    
    /**
        Adds a handler to be called once the request has finished.
    
        :param: completionHandler A closure to be executed once the request has finished. The closure takes 4 
            arguments: the URL request, the URL response, if one was received, the image, if one could be created 
            from the URL response and data, and any error produced while creating the image.
    
        :returns: The request.
    */
    public func responseImage(completionHandler: CompletionHandler) -> Self {
        return response(
            serializer: Request.imageResponseSerializer(),
            completionHandler: { request, response, data, error in
                completionHandler(request, response, data, error)
            }
        )
    }
    
#endif
    
    // MARK: - Private - Shared Helper Methods
    
    private class func validateResponse(response: NSHTTPURLResponse?) -> Bool {
        let acceptableContentTypes = NSSet(objects:
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
        )
        
        if let mimeType = response?.MIMEType {
            if acceptableContentTypes.containsObject(mimeType) {
                return true
            }
        }
        
        return false
    }
    
    private class func contentTypeValidationError() -> NSError {
        let failureReason = "Failed to validate response due to unacceptable content type"
        let userInfo = [NSLocalizedFailureReasonErrorKey: failureReason]
        
        return NSError(domain: AlamofireErrorDomain, code: NSURLErrorCannotDecodeContentData, userInfo: userInfo)
    }
    
    private class func imageDataError() -> NSError {
        let failureReason = "Failed to create a valid UIImage from the response data"
        let userInfo = [NSLocalizedFailureReasonErrorKey: failureReason]
        
        return NSError(domain: AlamofireErrorDomain, code: NSURLErrorCannotDecodeContentData, userInfo: userInfo)
    }
}
