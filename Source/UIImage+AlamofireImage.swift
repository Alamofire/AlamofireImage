//
//  UIImage+AlamofireImage.swift
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

#if os(iOS) || os(tvOS) || os(watchOS)

import Alamofire
import CoreGraphics
import Foundation
import UIKit

// MARK: Initialization

private let lock = NSLock()

extension UIImage: AlamofireExtended {}
extension AlamofireExtension where ExtendedType: UIImage {
    /// Initializes and returns the image object with the specified data in a thread-safe manner.
    ///
    /// It has been reported that there are thread-safety issues when initializing large amounts of images
    /// simultaneously. In the event of these issues occurring, this method can be used in place of
    /// the `init?(data:)` method.
    ///
    /// - parameter data: The data object containing the image data.
    ///
    /// - returns: An initialized `UIImage` object, or `nil` if the method failed.
    public static func threadSafeImage(with data: Data) -> UIImage? {
        lock.lock()
        let image = UIImage(data: data)
        lock.unlock()

        return image
    }

    /// Initializes and returns the image object with the specified data and scale in a thread-safe manner.
    ///
    /// It has been reported that there are thread-safety issues when initializing large amounts of images
    /// simultaneously. In the event of these issues occurring, this method can be used in place of
    /// the `init?(data:scale:)` method.
    ///
    /// - parameter data:  The data object containing the image data.
    /// - parameter scale: The scale factor to assume when interpreting the image data. Applying a scale factor of 1.0
    ///                    results in an image whose size matches the pixel-based dimensions of the image. Applying a
    ///                    different scale factor changes the size of the image as reported by the size property.
    ///
    /// - returns: An initialized `UIImage` object, or `nil` if the method failed.
    public static func threadSafeImage(with data: Data, scale: CGFloat) -> UIImage? {
        lock.lock()
        let image = UIImage(data: data, scale: scale)
        lock.unlock()

        return image
    }
}

extension UIImage {
    @available(*, deprecated, message: "Replaced by `UIImage.af.threadSafeImage(with:)`")
    public static func af_threadSafeImage(with data: Data) -> UIImage? {
        af.threadSafeImage(with: data)
    }

    @available(*, deprecated, message: "Replaced by `UIImage.af.threadSafeImage(with:scale:)`")
    public static func af_threadSafeImage(with data: Data, scale: CGFloat) -> UIImage? {
        af.threadSafeImage(with: data, scale: scale)
    }
}

// MARK: - Inflation

extension AlamofireExtension where ExtendedType: UIImage {
    /// Returns whether the image is inflated.
    public var isInflated: Bool {
        get {
            if let isInflated = objc_getAssociatedObject(type, &AssociatedKeys.isInflated) as? Bool {
                return isInflated
            } else {
                return false
            }
        }
        nonmutating set {
            objc_setAssociatedObject(type, &AssociatedKeys.isInflated, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// Inflates the underlying compressed image data to be backed by an uncompressed bitmap representation.
    ///
    /// Inflating compressed image formats (such as PNG or JPEG) can significantly improve drawing performance as it
    /// allows a bitmap representation to be constructed in the background rather than on the main thread.
    public func inflate() {
        guard !isInflated else { return }

        isInflated = true
        _ = type.cgImage?.dataProvider?.data
    }
}

extension UIImage {
    @available(*, deprecated, message: "Replaced by `image.af.isInflated`")
    public var af_inflated: Bool {
        af.isInflated
    }

    @available(*, deprecated, message: "Replaced by `image.af.inflate()`")
    public func af_inflate() {
        af.inflate()
    }
}

// MARK: - Alpha

extension AlamofireExtension where ExtendedType: UIImage {
    /// Returns whether the image contains an alpha component.
    public var containsAlphaComponent: Bool {
        let alphaInfo = type.cgImage?.alphaInfo

        return (
            alphaInfo == .first ||
                alphaInfo == .last ||
                alphaInfo == .premultipliedFirst ||
                alphaInfo == .premultipliedLast
        )
    }

    /// Returns whether the image is opaque.
    public var isOpaque: Bool { !containsAlphaComponent }
}

extension UIImage {
    @available(*, deprecated, message: "Replaced by `image.af.containsAlphaComponent`")
    public var af_containsAlphaComponent: Bool { af.containsAlphaComponent }

    @available(*, deprecated, message: "Replaced by `image.af.isOpaque`")
    public var af_isOpaque: Bool { af.isOpaque }
}

// MARK: - Scaling

extension AlamofireExtension where ExtendedType: UIImage {
    /// Returns a new version of the image scaled to the specified size.
    ///
    /// - Parameters:
    ///   - size: The size to use when scaling the new image.
    ///   - scale: The scale to set for the new image. Defaults to `nil` which will maintain the current image scale.
    ///
    /// - Returns: The new image object.
    public func imageScaled(to size: CGSize, scale: CGFloat? = nil) -> UIImage {
        assert(size.width > 0 && size.height > 0, "You cannot safely scale an image to a zero width or height")

        UIGraphicsBeginImageContextWithOptions(size, isOpaque, scale ?? type.scale)
        type.draw(in: CGRect(origin: .zero, size: size))

        let scaledImage = UIGraphicsGetImageFromCurrentImageContext() ?? type
        UIGraphicsEndImageContext()

        return scaledImage
    }

    /// Returns a new version of the image scaled from the center while maintaining the aspect ratio to fit within
    /// a specified size.
    ///
    /// The resulting image contains an alpha component used to pad the width or height with the necessary transparent
    /// pixels to fit the specified size. In high performance critical situations, this may not be the optimal approach.
    /// To maintain an opaque image, you could compute the `scaledSize` manually, then use the `af.imageScaledToSize`
    /// method in conjunction with a `.Center` content mode to achieve the same visual result.
    ///
    /// - Parameters:
    ///   - size: The size to use when scaling the new image.
    ///   - scale: The scale to set for the new image. Defaults to `nil` which will maintain the current image scale.
    ///
    /// - Returns: A new image object.
    public func imageAspectScaled(toFit size: CGSize, scale: CGFloat? = nil) -> UIImage {
        assert(size.width > 0 && size.height > 0, "You cannot safely scale an image to a zero width or height")

        let imageAspectRatio = type.size.width / type.size.height
        let canvasAspectRatio = size.width / size.height

        var resizeFactor: CGFloat

        if imageAspectRatio > canvasAspectRatio {
            resizeFactor = size.width / type.size.width
        } else {
            resizeFactor = size.height / type.size.height
        }

        let scaledSize = CGSize(width: type.size.width * resizeFactor, height: type.size.height * resizeFactor)
        let origin = CGPoint(x: (size.width - scaledSize.width) / 2.0, y: (size.height - scaledSize.height) / 2.0)

        UIGraphicsBeginImageContextWithOptions(size, false, scale ?? type.scale)
        type.draw(in: CGRect(origin: origin, size: scaledSize))

        let scaledImage = UIGraphicsGetImageFromCurrentImageContext() ?? type
        UIGraphicsEndImageContext()

        return scaledImage
    }

    /// Returns a new version of the image scaled from the center while maintaining the aspect ratio to fill a
    /// specified size. Any pixels that fall outside the specified size are clipped.
    ///
    /// - Parameters:
    ///   - size: The size to use when scaling the new image.
    ///   - scale: The scale to set for the new image. Defaults to `nil` which will maintain the current image scale.
    ///
    /// - Returns: A new image object.
    public func imageAspectScaled(toFill size: CGSize, scale: CGFloat? = nil) -> UIImage {
        assert(size.width > 0 && size.height > 0, "You cannot safely scale an image to a zero width or height")

        let imageAspectRatio = type.size.width / type.size.height
        let canvasAspectRatio = size.width / size.height

        var resizeFactor: CGFloat

        if imageAspectRatio > canvasAspectRatio {
            resizeFactor = size.height / type.size.height
        } else {
            resizeFactor = size.width / type.size.width
        }

        let scaledSize = CGSize(width: type.size.width * resizeFactor, height: type.size.height * resizeFactor)
        let origin = CGPoint(x: (size.width - scaledSize.width) / 2.0, y: (size.height - scaledSize.height) / 2.0)

        UIGraphicsBeginImageContextWithOptions(size, isOpaque, scale ?? type.scale)
        type.draw(in: CGRect(origin: origin, size: scaledSize))

        let scaledImage = UIGraphicsGetImageFromCurrentImageContext() ?? type
        UIGraphicsEndImageContext()

        return scaledImage
    }
}

extension UIImage {
    @available(*, deprecated, message: "Replaced by `image.af.imageScale(to:scale:)`")
    public func af_imageScaled(to size: CGSize, scale: CGFloat? = nil) -> UIImage {
        af.imageScaled(to: size, scale: scale)
    }

    @available(*, deprecated, message: "Replaced by `image.af.imageAspectScale(toFit:scale:)`")
    public func af_imageAspectScaled(toFit size: CGSize, scale: CGFloat? = nil) -> UIImage {
        af.imageAspectScaled(toFit: size, scale: scale)
    }

    @available(*, deprecated, message: "Replaced by `image.af.imageAspectScale(toFill:scale:)`")
    public func af_imageAspectScaled(toFill size: CGSize, scale: CGFloat? = nil) -> UIImage {
        af.imageAspectScaled(toFill: size, scale: scale)
    }
}

// MARK: - Rounded Corners

extension AlamofireExtension where ExtendedType: UIImage {
    /// Returns a new version of the image with the corners rounded to the specified radius.
    ///
    /// - Parameters:
    ///   - radius:                   The radius to use when rounding the new image.
    ///   - divideRadiusByImageScale: Whether to divide the radius by the image scale. Set to `true` when the image has
    ///                               the same resolution for all screen scales such as @1x, @2x and @3x (i.e. single
    ///                               image from web server). Set to `false` for images loaded from an asset catalog
    ///                               with varying resolutions for each screen scale. `false` by default.
    ///
    /// - Returns: A new image object.
    public func imageRounded(withCornerRadius radius: CGFloat, divideRadiusByImageScale: Bool = false) -> UIImage {
        let size = type.size
        let scale = type.scale

        UIGraphicsBeginImageContextWithOptions(size, false, scale)

        let scaledRadius = divideRadiusByImageScale ? radius / scale : radius

        let clippingPath = UIBezierPath(roundedRect: CGRect(origin: CGPoint.zero, size: size), cornerRadius: scaledRadius)
        clippingPath.addClip()

        type.draw(in: CGRect(origin: CGPoint.zero, size: size))

        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return roundedImage
    }

    /// Returns a new version of the image rounded into a circle.
    ///
    /// - Returns: A new image object.
    public func imageRoundedIntoCircle() -> UIImage {
        let size = type.size
        let radius = min(size.width, size.height) / 2.0
        var squareImage: UIImage = type

        if size.width != size.height {
            let squareDimension = min(size.width, size.height)
            let squareSize = CGSize(width: squareDimension, height: squareDimension)
            squareImage = imageAspectScaled(toFill: squareSize)
        }

        UIGraphicsBeginImageContextWithOptions(squareImage.size, false, type.scale)

        let clippingPath = UIBezierPath(roundedRect: CGRect(origin: CGPoint.zero, size: squareImage.size),
                                        cornerRadius: radius)

        clippingPath.addClip()

        squareImage.draw(in: CGRect(origin: CGPoint.zero, size: squareImage.size))

        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return roundedImage
    }
}

extension UIImage {
    @available(*, deprecated, message: "Replaced by `image.af.imageRounded(withCornerRadius:divideRadiusByImageScale:)`")
    public func af_imageRounded(withCornerRadius radius: CGFloat, divideRadiusByImageScale: Bool = false) -> UIImage {
        af.imageRounded(withCornerRadius: radius, divideRadiusByImageScale: divideRadiusByImageScale)
    }

    @available(*, deprecated, message: "Replaced by `image.af.imageRoundedIntoCircle()`")
    public func af_imageRoundedIntoCircle() -> UIImage {
        af.imageRoundedIntoCircle()
    }
}

#endif

#if os(iOS) || os(tvOS)

import CoreImage

// MARK: - Core Image Filters

extension AlamofireExtension where ExtendedType: UIImage {
    /// Returns a new version of the image using a CoreImage filter with the specified name and parameters.
    ///
    /// - Parameters:
    ///   - name:       The name of the CoreImage filter to use on the new image.
    ///   - parameters: The parameters to apply to the CoreImage filter.
    ///
    /// - Returns: A new image object, or `nil` if the filter failed for any reason.
    public func imageFiltered(withCoreImageFilter name: String, parameters: [String: Any]? = nil) -> UIImage? {
        var image: CoreImage.CIImage? = type.ciImage

        if image == nil, let CGImage = type.cgImage {
            image = CoreImage.CIImage(cgImage: CGImage)
        }

        guard let coreImage = image else { return nil }

        let context = CIContext(options: [.priorityRequestLow: true])

        var parameters: [String: Any] = parameters ?? [:]
        parameters[kCIInputImageKey] = coreImage

        guard let filter = CIFilter(name: name, parameters: parameters) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        let cgImageRef = context.createCGImage(outputImage, from: outputImage.extent)

        return UIImage(cgImage: cgImageRef!, scale: type.scale, orientation: type.imageOrientation)
    }
}

extension UIImage {
    @available(*, deprecated, message: "Replaced by `image.af.imageFiltered(withCoreImageFilter:parameters:)`")
    public func af_imageFiltered(withCoreImageFilter name: String, parameters: [String: Any]? = nil) -> UIImage? {
        af.imageFiltered(withCoreImageFilter: name, parameters: parameters)
    }
}

#endif

// MARK: -

private enum AssociatedKeys {
    static var isInflated = "UIImage.af.isInflated"
}
