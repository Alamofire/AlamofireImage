//
//  ImageFilter.swift
//  AlamofireImage
//
//  Created by Christian Noon on 3/14/15.
//  Copyright (c) 2015 Alamofire. All rights reserved.
//

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
