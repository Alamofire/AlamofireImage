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

import UIKit

// MARK: ImageFilter

public protocol ImageFilter {
    var filter: UIImage -> UIImage { get }
    var identifier: String { get }
}

// MARK: - Single Pass Image Filters

public struct ScaledToSizeFilter: ImageFilter {
    public let size: CGSize

    public init(size: CGSize) {
        self.size = size
    }

    public var filter: UIImage -> UIImage {
        return { image in
            return image.ai_imageScaledToSize(self.size)
        }
    }

    public var identifier: String { return "\(self.self)-\(UInt(self.size.width))x\(UInt(self.size.height))" }
}

public struct AspectScaledToFitSizeFilter: ImageFilter {
    public let size: CGSize

    public init(size: CGSize) {
        self.size = size
    }

    public var filter: UIImage -> UIImage {
        return { image in
            return image.ai_imageAspectScaledToFitSize(self.size)
        }
    }

    public var identifier: String { return "\(self.self)-\(UInt(self.size.width))x\(UInt(self.size.height))" }
}

public struct AspectScaledToFillSizeFilter: ImageFilter {
    public let size: CGSize

    public init(size: CGSize) {
        self.size = size
    }

    public var filter: UIImage -> UIImage {
        return { image in
            return image.ai_imageAspectScaledToFillSize(self.size)
        }
    }

    public var identifier: String { return "\(self.self)-\(UInt(self.size.width))x\(UInt(self.size.height))" }
}

// MARK: - Multi-Pass Image Filters

public struct ScaledToSizeWithRoundedCornersFilter: ImageFilter {
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

    public var identifier: String { return "\(self.self)-\(UInt(self.size.width))x\(UInt(self.size.height))" }
}

public struct AspectScaledToFitSizeWithRoundedCornersFilter: ImageFilter {
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

    public var identifier: String { return "\(self.self)-\(UInt(self.size.width))x\(UInt(self.size.height))" }
}

public struct AspectScaledToFillSizeWithRoundedCornersFilter: ImageFilter {
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

    public var identifier: String { return "\(self.self)-\(UInt(self.size.width))x\(UInt(self.size.height))" }
}
