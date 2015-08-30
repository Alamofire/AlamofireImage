// UIImage+AlamofireImage.swift
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

import CoreGraphics
import CoreImage
import Foundation
import UIKit

// MARK: Inflation

extension UIImage {
    private struct AssociatedKeys {
        static var InflatedKey = "af_UIImage.Inflated"
    }

    public var af_inflated: Bool {
        get {
            if let inflated = objc_getAssociatedObject(self, &AssociatedKeys.InflatedKey) as? Bool {
                return inflated
            } else {
                return false
            }
        }
        set(inflated) {
            objc_setAssociatedObject(self, &AssociatedKeys.InflatedKey, inflated, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    public func af_inflatedImage() -> UIImage? {
        // Do not re-inflate if already inflated
        guard !af_inflated else { return self }

        // Do not attempt to inflate animated images
        guard images == nil else { return nil }

        // Do not attempt to inflate if not backed by a CGImage
        guard let imageRef = CGImageCreateCopy(CGImage) else { return nil }

        let width = CGImageGetWidth(imageRef)
        let height = CGImageGetHeight(imageRef)
        let bitsPerComponent = CGImageGetBitsPerComponent(imageRef)

        // Do not attempt to inflate if too large or has more than 8-bit components
        guard width * height <= 4096 * 4096 && bitsPerComponent <= 8 else { return nil }

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

        // Render the image
        let context = CGBitmapContextCreate(nil, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo.rawValue)
        CGContextDrawImage(context, CGRectMake(0.0, 0.0, CGFloat(width), CGFloat(height)), imageRef)

        // Make sure the inflation was successful
        guard let inflatedImageRef = CGBitmapContextCreateImage(context) else { return nil }

        let inflatedImage = UIImage(CGImage: inflatedImageRef, scale: scale, orientation: imageOrientation)
        inflatedImage.af_inflated = true

        return inflatedImage
    }
}

// MARK: - Scaling

extension UIImage {
    public func af_imageScaledToSize(size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        drawInRect(CGRect(origin: CGPointZero, size: size))

        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return scaledImage
    }

    public func af_imageAspectScaledToFitSize(size: CGSize) -> UIImage {
        let imageAspectRatio = self.size.width / self.size.height
        let canvasAspectRatio = size.width / size.height

        var resizeFactor: CGFloat

        if imageAspectRatio > canvasAspectRatio {
            resizeFactor = size.width / self.size.width
        } else {
            resizeFactor = size.height / self.size.height
        }

        let scaledSize = CGSize(width: self.size.width * resizeFactor, height: self.size.height * resizeFactor)
        let origin = CGPoint(x: (size.width - scaledSize.width) / 2.0, y: (size.height - scaledSize.height) / 2.0)

        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        drawInRect(CGRect(origin: origin, size: scaledSize))

        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return scaledImage
    }

    public func af_imageAspectScaledToFillSize(size: CGSize) -> UIImage {
        let imageAspectRatio = self.size.width / self.size.height
        let canvasAspectRatio = size.width / size.height

        var resizeFactor: CGFloat

        if imageAspectRatio > canvasAspectRatio {
            resizeFactor = size.height / self.size.height
        } else {
            resizeFactor = size.width / self.size.width
        }

        let scaledSize = CGSize(width: self.size.width * resizeFactor, height: self.size.height * resizeFactor)
        let origin = CGPoint(x: (size.width - scaledSize.width) / 2.0, y: (size.height - scaledSize.height) / 2.0)

        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        drawInRect(CGRect(origin: origin, size: scaledSize))

        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return scaledImage
    }
}

// MARK: - Rounded Corners

extension UIImage {
    public func af_imageWithRoundedCornerRadius(radius: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, 0.0)

        let clippingPath = UIBezierPath(roundedRect: CGRect(origin: CGPointZero, size: self.size), cornerRadius: radius)
        clippingPath.addClip()

        drawInRect(CGRect(origin: CGPointZero, size: self.size))

        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return roundedImage
    }

    public func af_imageRoundedIntoCircle() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)

        let radius = min(size.width, size.height) / 2.0
        var squareImage = self

        if size.width != size.height {
            let squareDimension = min(size.width, size.height) / 2.0
            let squareSize = CGSize(width: squareDimension, height: squareDimension)
            squareImage = af_imageAspectScaledToFillSize(squareSize)
        }

        let clippingPath = UIBezierPath(
            roundedRect: CGRect(origin: CGPointZero, size: squareImage.size),
            cornerRadius: radius
        )

        clippingPath.addClip()

        drawInRect(CGRect(origin: CGPointZero, size: squareImage.size))

        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return roundedImage
    }
}

// MARK: - Core Image Filters

extension UIImage {
    public func af_imageWithAppliedCoreImageFilter(
        filterName: String,
        filterParameters: [String: AnyObject]? = nil) -> UIImage?
    {
        var image: CoreImage.CIImage? = CIImage

        if image == nil, let CGImage = self.CGImage {
            image = CoreImage.CIImage(CGImage: CGImage)
        }

        guard let coreImage = image else { return nil }

        let context = CIContext(options: [kCIContextPriorityRequestLow: true])

        var parameters: [String: AnyObject] = filterParameters ?? [:]
        parameters[kCIInputImageKey] = coreImage

        guard let filter = CIFilter(name: filterName, withInputParameters: parameters) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        let cgImageRef = context.createCGImage(outputImage, fromRect: coreImage.extent)

        return UIImage(CGImage: cgImageRef, scale: scale, orientation: imageOrientation)
    }
}
