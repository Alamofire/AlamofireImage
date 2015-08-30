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

public protocol ImageFilter {
    var filter: Image -> Image { get }
    var identifier: String { get }
}

extension ImageFilter {
    public var identifier: String { return "\(self.dynamicType)" }
}

// MARK: - Sizable

public protocol Sizable {
    var size: CGSize { get }
}

extension ImageFilter where Self: Sizable {
    public var identifier: String {
        let width = Int64(round(size.width))
        let height = Int64(round(size.height))

        return "\(self.dynamicType)-size:(\(width)x\(height))"
    }
}

// MARK: - Roundable

public protocol Roundable {
    var radius: CGFloat { get }
}

extension ImageFilter where Self: Roundable {
    public var identifier: String {
        let radius = Int64(round(self.radius))
        return "\(self.dynamicType)-radius:(\(radius))"
    }
}

extension ImageFilter where Self: Sizable, Self: Roundable {
    public var identifier: String {
        let width = Int64(round(size.width))
        let height = Int64(round(size.height))
        let radius = Int64(round(self.radius))

        return "\(self.dynamicType)-size:(\(width)x\(height))-radius:(\(radius))"
    }
}

#if os(iOS)

// MARK: - Single Pass Image Filters (iOS and watchOS only) -

public struct ScaledToSizeFilter: ImageFilter, Sizable {
    public let size: CGSize

    public init(size: CGSize) {
        self.size = size
    }

    public var filter: Image -> Image {
        return { image in
            return image.af_imageScaledToSize(self.size)
        }
    }
}

// MARK: -

public struct AspectScaledToFitSizeFilter: ImageFilter, Sizable {
    public let size: CGSize

    public init(size: CGSize) {
        self.size = size
    }

    public var filter: Image -> Image {
        return { image in
            return image.af_imageAspectScaledToFitSize(self.size)
        }
    }
}

// MARK: -

public struct AspectScaledToFillSizeFilter: ImageFilter, Sizable {
    public let size: CGSize

    public init(size: CGSize) {
        self.size = size
    }

    public var filter: Image -> Image {
        return { image in
            return image.af_imageAspectScaledToFillSize(self.size)
        }
    }
}

// MARK: -

public struct RoundedCornersFilter: ImageFilter, Roundable {
    public let radius: CGFloat

    public init(radius: CGFloat) {
        self.radius = radius
    }

    public var filter: Image -> Image {
        return { image in
            return image.af_imageWithRoundedCornerRadius(self.radius)
        }
    }
}

// MARK: -

public struct CircleFilter: ImageFilter {
    public init() {}

    public var filter: Image -> Image {
        return { image in
            return image.af_imageRoundedIntoCircle()
        }
    }
}

// MARK: -

public struct BlurFilter: ImageFilter {
    let blurRadius: UInt

    public init(blurRadius: UInt = 10) {
        self.blurRadius = blurRadius
    }

    public var filter: Image -> Image {
        return { image in
            let parameters = ["inputRadius": self.blurRadius]
            return image.af_imageWithAppliedCoreImageFilter("CIGaussianBlur", filterParameters: parameters) ?? image
        }
    }
}

// MARK: - Multi-Pass Image Filters (iOS and watchOS only) -

public struct ScaledToSizeWithRoundedCornersFilter: ImageFilter, Sizable, Roundable {
    public let size: CGSize
    public let radius: CGFloat

    public init(size: CGSize, radius: CGFloat) {
        self.size = size
        self.radius = radius
    }

    public var filter: Image -> Image {
        return { image in
            let scaledImage = image.af_imageScaledToSize(self.size)
            let roundedAndScaledImage = scaledImage.af_imageWithRoundedCornerRadius(self.radius)

            return roundedAndScaledImage
        }
    }
}

// MARK: -

public struct AspectScaledToFitSizeWithRoundedCornersFilter: ImageFilter, Sizable, Roundable {
    public let size: CGSize
    public let radius: CGFloat

    public init(size: CGSize, radius: CGFloat) {
        self.size = size
        self.radius = radius
    }

    public var filter: Image -> Image {
        return { image in
            let scaledImage = image.af_imageAspectScaledToFitSize(self.size)
            let roundedAndScaledImage = scaledImage.af_imageWithRoundedCornerRadius(self.radius)

            return roundedAndScaledImage
        }
    }
}

// MARK: -

public struct AspectScaledToFillSizeWithRoundedCornersFilter: ImageFilter, Sizable, Roundable {
    public let size: CGSize
    public let radius: CGFloat

    public init(size: CGSize, radius: CGFloat) {
        self.size = size
        self.radius = radius
    }

    public var filter: Image -> Image {
        return { image in
            let scaledImage = image.af_imageAspectScaledToFillSize(self.size)
            let roundedAndScaledImage = scaledImage.af_imageWithRoundedCornerRadius(self.radius)

            return roundedAndScaledImage
        }
    }
}

// MARK: -

public struct ScaledToSizeCircleFilter: ImageFilter, Sizable, Roundable {
    public let size: CGSize
    public let radius: CGFloat

    public init(size: CGSize, radius: CGFloat) {
        self.size = size
        self.radius = min(size.width, size.height) / 2.0
    }

    public var filter: Image -> Image {
        return { image in
            let scaledImage = image.af_imageScaledToSize(self.size)
            let scaledCircleImage = scaledImage.af_imageRoundedIntoCircle()
            
            return scaledCircleImage
        }
    }
}

// MARK: -

public struct AspectScaledToFitSizeCircleFilter: ImageFilter, Sizable, Roundable {
    public let size: CGSize
    public let radius: CGFloat

    public init(size: CGSize, radius: CGFloat) {
        self.size = size
        self.radius = min(size.width, size.height) / 2.0
    }

    public var filter: Image -> Image {
        return { image in
            let scaledImage = image.af_imageAspectScaledToFitSize(self.size)
            let scaledCircleImage = scaledImage.af_imageRoundedIntoCircle()

            return scaledCircleImage
        }
    }
}

// MARK: -

public struct AspectScaledToFillSizeCircleFilter: ImageFilter, Sizable, Roundable {
    public let size: CGSize
    public let radius: CGFloat

    public init(size: CGSize, radius: CGFloat) {
        self.size = size
        self.radius = min(size.width, size.height) / 2.0
    }

    public var filter: Image -> Image {
        return { image in
            let scaledImage = image.af_imageAspectScaledToFillSize(self.size)
            let scaledCircleImage = scaledImage.af_imageRoundedIntoCircle()
            
            return scaledCircleImage
        }
    }
}

#endif
