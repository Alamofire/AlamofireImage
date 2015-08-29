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
import UIKit

// MARK: ImageFilter

public protocol ImageFilter {
    var filter: UIImage -> UIImage { get }
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

        return "\(self.dynamicType)-\(width)x\(height)"
    }
}

// MARK: - Roundable

public protocol Roundable {
    var radius: CGFloat { get }
}

extension ImageFilter where Self: Sizable, Self: Roundable {
    public var identifier: String {
        let width = Int64(round(size.width))
        let height = Int64(round(size.height))
        let radius = Int64(round(self.radius))

        return "\(self.dynamicType)-\(width)x\(height)x\(radius)"
    }
}

// MARK: - Single Pass Image Filters -

public struct ScaledToSizeFilter: ImageFilter, Sizable {
    public let size: CGSize

    public init(size: CGSize) {
        self.size = size
    }

    public var filter: UIImage -> UIImage {
        return { image in
            return image.ai_imageScaledToSize(self.size)
        }
    }
}

// MARK: -

public struct AspectScaledToFitSizeFilter: ImageFilter, Sizable {
    public let size: CGSize

    public init(size: CGSize) {
        self.size = size
    }

    public var filter: UIImage -> UIImage {
        return { image in
            return image.ai_imageAspectScaledToFitSize(self.size)
        }
    }
}

// MARK: -

public struct AspectScaledToFillSizeFilter: ImageFilter, Sizable {
    public let size: CGSize

    public init(size: CGSize) {
        self.size = size
    }

    public var filter: UIImage -> UIImage {
        return { image in
            return image.ai_imageAspectScaledToFillSize(self.size)
        }
    }
}

// MARK: - Multi-Pass Image Filters -

public struct ScaledToSizeWithRoundedCornersFilter: ImageFilter, Sizable, Roundable {
    public let size: CGSize
    public let radius: CGFloat

    public init(size: CGSize, radius: CGFloat) {
        self.size = size
        self.radius = radius
    }

    public var filter: UIImage -> UIImage {
        return { image in
            let scaledImage = image.ai_imageScaledToSize(self.size)
            let roundedAndScaledImage = scaledImage.ai_imageWithRoundedCornerRadius(self.radius)

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

    public var filter: UIImage -> UIImage {
        return { image in
            let scaledImage = image.ai_imageAspectScaledToFitSize(self.size)
            let roundedAndScaledImage = scaledImage.ai_imageWithRoundedCornerRadius(self.radius)

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

    public var filter: UIImage -> UIImage {
        return { image in
            let scaledImage = image.ai_imageAspectScaledToFillSize(self.size)
            let roundedAndScaledImage = scaledImage.ai_imageWithRoundedCornerRadius(self.radius)

            return roundedAndScaledImage
        }
    }
}
