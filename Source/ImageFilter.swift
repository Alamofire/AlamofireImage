// ImageFilter.swift
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

import Foundation

#if os(iOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import Cocoa
#endif

// MARK: ImageFilter

/// The `ImageFilter` protocol defines properties for filtering an image as well as identification of the filter.
public protocol ImageFilter {
    /// A closure used to create an alternative representation of the given image.
    var filter: Image -> Image { get }

    /// The string used to uniquely identify the filter operation.
    var identifier: String { get }
}

extension ImageFilter {
    /// The unique identifier for any `ImageFilter` type.
    public var identifier: String { return "\(self.dynamicType)" }
}

// MARK: - Sizable

/// The `Sizable` protocol defines a size property intended for use with `ImageFilter` types.
public protocol Sizable {
    /// The size of the type.
    var size: CGSize { get }
}

extension ImageFilter where Self: Sizable {
    /// The unique idenitifier for an `ImageFilter` conforming to the `Sizable` protocol.
    public var identifier: String {
        let width = Int64(round(size.width))
        let height = Int64(round(size.height))

        return "\(self.dynamicType)-size:(\(width)x\(height))"
    }
}

// MARK: - Roundable

/// The `Roundable` protocol defines a radius property intended for use with `ImageFilter` types.
public protocol Roundable {
    /// The radius of the type.
    var radius: CGFloat { get }
}

extension ImageFilter where Self: Roundable {
    /// The unique idenitifier for an `ImageFilter` conforming to the `Roundable` protocol.
    public var identifier: String {
        let radius = Int64(round(self.radius))
        return "\(self.dynamicType)-radius:(\(radius))"
    }
}

// MARK: - DynamicImageFilter

/// The `DynamicImageFilter` class simplifies custom image filter creation by using a trailing closure initializer.
public struct DynamicImageFilter: ImageFilter {
    /// The string used to uniquely identify the image filter operation.
    public let identifier: String

    /// A closure used to create an alternative representation of the given image.
    public let filter: Image -> Image

    /**
        Initializes the `DynamicImageFilter` instance with the specified identifier and filter closure.

        - parameter identifier: The unique identifier of the filter.
        - parameter filter:     A closure used to create an alternative representation of the given image.

        - returns: The new `DynamicImageFilter` instance.
    */
    public init(_ identifier: String, filter: Image -> Image) {
        self.identifier = identifier
        self.filter = filter
    }
}

// MARK: - CompositeImageFilter

/// The `CompositeImageFilter` protocol defines an additional `filters` property to support multiple composite filters.
public protocol CompositeImageFilter: ImageFilter {
    /// The image filters to apply to the image in sequential order.
    var filters: [ImageFilter] { get }
}

public extension CompositeImageFilter {
    /// The unique idenitifier for any `CompositeImageFilter` type.
    var identifier: String {
        return filters.map { $0.identifier }.joinWithSeparator("_")
    }

    /// The filter closure for any `CompositeImageFilter` type.
    var filter: Image -> Image {
        return { image in
            return self.filters.reduce(image) { $1.filter($0) }
        }
    }
}

// MARK: - DynamicCompositeImageFilter

/// The `DynamicCompositeImageFilter` class is a composite image filter based on a specified array of filters.
public struct DynamicCompositeImageFilter: CompositeImageFilter {
    /// The image filters to apply to the image in sequential order.
    public let filters: [ImageFilter]

    /**
        Initializes the `DynamicCompositeImageFilter` instance with the given filters.

        - parameter filters: The filters taking part in the composite image filter.

        - returns: The new `DynamicCompositeImageFilter` instance.
    */
    public init(_ filters: [ImageFilter]) {
        self.filters = filters
    }

    /**
        Initializes the `DynamicCompositeImageFilter` instance with the given filters.

        - parameter filters: The filters taking part in the composite image filter.

        - returns: The new `DynamicCompositeImageFilter` instance.
    */
    public init(_ filters: ImageFilter...) {
        self.init(filters)
    }
}

#if os(iOS) || os(watchOS)

// MARK: - Single Pass Image Filters (iOS and watchOS only) -

/// Scales an image to a specified size.
public struct ScaledToSizeFilter: ImageFilter, Sizable {
    /// The size of the filter.
    public let size: CGSize

    /**
        Initializes the `ScaledToSizeFilter` instance with the given size.

        - parameter size: The size.

        - returns: The new `ScaledToSizeFilter` instance.
    */
    public init(size: CGSize) {
        self.size = size
    }

    /// The filter closure used to create the modified representation of the given image.
    public var filter: Image -> Image {
        return { image in
            return image.af_imageScaledToSize(self.size)
        }
    }
}

// MARK: -

/// Scales an image from the center while maintaining the aspect ratio to fit within a specified size.
public struct AspectScaledToFitSizeFilter: ImageFilter, Sizable {
    /// The size of the filter.
    public let size: CGSize

    /**
        Initializes the `AspectScaledToFitSizeFilter` instance with the given size.

        - parameter size: The size.

        - returns: The new `AspectScaledToFitSizeFilter` instance.
    */
    public init(size: CGSize) {
        self.size = size
    }

    /// The filter closure used to create the modified representation of the given image.
    public var filter: Image -> Image {
        return { image in
            return image.af_imageAspectScaledToFitSize(self.size)
        }
    }
}

// MARK: -

/// Scales an image from the center while maintaining the aspect ratio to fill a specified size. Any pixels that fall
/// outside the specified size are clipped.
public struct AspectScaledToFillSizeFilter: ImageFilter, Sizable {
    /// The size of the filter.
    public let size: CGSize

    /**
        Initializes the `AspectScaledToFillSizeFilter` instance with the given size.

        - parameter size: The size.

        - returns: The new `AspectScaledToFillSizeFilter` instance.
    */
    public init(size: CGSize) {
        self.size = size
    }

    /// The filter closure used to create the modified representation of the given image.
    public var filter: Image -> Image {
        return { image in
            return image.af_imageAspectScaledToFillSize(self.size)
        }
    }
}

// MARK: -

/// Rounds the corners of an image to the specified radius.
public struct RoundedCornersFilter: ImageFilter, Roundable {
    /// The radius of the filter.
    public let radius: CGFloat

    /// Whether to divide the radius by the image scale.
    public let divideRadiusByImageScale: Bool

    /**
        Initializes the `RoundedCornersFilter` instance with the given radius.

        - parameter radius:                   The radius.
        - parameter divideRadiusByImageScale: Whether to divide the radius by the image scale. Set to `true` when the
                                              image has the same resolution for all screen scales such as @1x, @2x and
                                              @3x (i.e. single image from web server). Set to `false` for images loaded
                                              from an asset catalog with varying resolutions for each screen scale.
                                              `false` by default.

        - returns: The new `RoundedCornersFilter` instance.
    */
    public init(radius: CGFloat, divideRadiusByImageScale: Bool = false) {
        self.radius = radius
        self.divideRadiusByImageScale = divideRadiusByImageScale
    }

    /// The filter closure used to create the modified representation of the given image.
    public var filter: Image -> Image {
        return { image in
            return image.af_imageWithRoundedCornerRadius(
                self.radius,
                divideRadiusByImageScale: self.divideRadiusByImageScale
            )
        }
    }

    /// The unique idenitifier for an `ImageFilter` conforming to the `Roundable` protocol.
    public var identifier: String {
        let radius = Int64(round(self.radius))
        return "\(self.dynamicType)-radius:(\(radius))-divided:(\(divideRadiusByImageScale))"
    }
}

// MARK: -

/// Rounds the corners of an image into a circle.
public struct CircleFilter: ImageFilter {
    /**
        Initializes the `CircleFilter` instance.

        - returns: The new `CircleFilter` instance.
    */
    public init() {}

    /// The filter closure used to create the modified representation of the given image.
    public var filter: Image -> Image {
        return { image in
            return image.af_imageRoundedIntoCircle()
        }
    }
}

// MARK: -

#if os(iOS)

/// Blurs an image using a `CIGaussianBlur` filter with the specified blur radius.
public struct BlurFilter: ImageFilter {
    /// The blur radius of the filter.
    let blurRadius: UInt

    /**
        Initializes the `BlurFilter` instance with the given blur radius.

        - parameter blurRadius: The blur radius.

        - returns: The new `BlurFilter` instance.
    */
    public init(blurRadius: UInt = 10) {
        self.blurRadius = blurRadius
    }

    /// The filter closure used to create the modified representation of the given image.
    public var filter: Image -> Image {
        return { image in
            let parameters = ["inputRadius": self.blurRadius]
            return image.af_imageWithAppliedCoreImageFilter("CIGaussianBlur", filterParameters: parameters) ?? image
        }
    }
}

#endif

// MARK: - Composite Image Filters (iOS and watchOS only) -

/// Scales an image to a specified size, then rounds the corners to the specified radius.
public struct ScaledToSizeWithRoundedCornersFilter: CompositeImageFilter {
    /**
        Initializes the `ScaledToSizeWithRoundedCornersFilter` instance with the given size and radius.

        - parameter size:                     The size.
        - parameter radius:                   The radius.
        - parameter divideRadiusByImageScale: Whether to divide the radius by the image scale. Set to `true` when the
                                              image has the same resolution for all screen scales such as @1x, @2x and
                                              @3x (i.e. single image from web server). Set to `false` for images loaded
                                              from an asset catalog with varying resolutions for each screen scale.
                                              `false` by default.

        - returns: The new `ScaledToSizeWithRoundedCornersFilter` instance.
    */
    public init(size: CGSize, radius: CGFloat, divideRadiusByImageScale: Bool = false) {
        self.filters = [
            ScaledToSizeFilter(size: size),
            RoundedCornersFilter(radius: radius, divideRadiusByImageScale: divideRadiusByImageScale)
        ]
    }

    /// The image filters to apply to the image in sequential order.
    public let filters: [ImageFilter]
}

// MARK: -

/// Scales an image from the center while maintaining the aspect ratio to fit within a specified size, then rounds the 
/// corners to the specified radius.
public struct AspectScaledToFillSizeWithRoundedCornersFilter: CompositeImageFilter {
    /**
        Initializes the `AspectScaledToFillSizeWithRoundedCornersFilter` instance with the given size and radius.

        - parameter size:                     The size.
        - parameter radius:                   The radius.
        - parameter divideRadiusByImageScale: Whether to divide the radius by the image scale. Set to `true` when the
                                              image has the same resolution for all screen scales such as @1x, @2x and
                                              @3x (i.e. single image from web server). Set to `false` for images loaded
                                              from an asset catalog with varying resolutions for each screen scale.
                                              `false` by default.

        - returns: The new `AspectScaledToFillSizeWithRoundedCornersFilter` instance.
    */
    public init(size: CGSize, radius: CGFloat, divideRadiusByImageScale: Bool = false) {
        self.filters = [
            AspectScaledToFillSizeFilter(size: size),
            RoundedCornersFilter(radius: radius, divideRadiusByImageScale: divideRadiusByImageScale)
        ]
    }

    /// The image filters to apply to the image in sequential order.
    public let filters: [ImageFilter]
}

// MARK: -

/// Scales an image to a specified size, then rounds the corners into a circle.
public struct ScaledToSizeCircleFilter: CompositeImageFilter {
    /**
        Initializes the `ScaledToSizeCircleFilter` instance with the given size.

        - parameter size: The size.

        - returns: The new `ScaledToSizeCircleFilter` instance.
    */
    public init(size: CGSize) {
        self.filters = [ScaledToSizeFilter(size: size), CircleFilter()]
    }

    /// The image filters to apply to the image in sequential order.
    public let filters: [ImageFilter]
}

// MARK: -

/// Scales an image from the center while maintaining the aspect ratio to fit within a specified size, then rounds the
/// corners into a circle.
public struct AspectScaledToFillSizeCircleFilter: CompositeImageFilter {
    /**
        Initializes the `AspectScaledToFillSizeCircleFilter` instance with the given size.

        - parameter size: The size.

        - returns: The new `AspectScaledToFillSizeCircleFilter` instance.
    */
    public init(size: CGSize) {
        self.filters = [AspectScaledToFillSizeFilter(size: size), CircleFilter()]
    }

    /// The image filters to apply to the image in sequential order.
    public let filters: [ImageFilter]
}

#endif
