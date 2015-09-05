// UIImage+AlamofireImageTests.swift
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

extension UIImage {
    func af_isEqualToImage(image: UIImage, withinTolerance tolerance: UInt8 = 0) -> Bool {
        guard CGSizeEqualToSize(size, image.size) else { return false }

        let inflated1 = copy() as! UIImage
        let inflated2 = image

        inflated1.af_inflate()
        inflated2.af_inflate()

        let pixelData1 = CGDataProviderCopyData(CGImageGetDataProvider(inflated1.CGImage))
        let pixelData2 = CGDataProviderCopyData(CGImageGetDataProvider(inflated2.CGImage))

        guard let validPixelData1 = pixelData1, let validPixelData2 = pixelData2 else { return false }

        let data1: UnsafePointer<UInt8> = CFDataGetBytePtr(validPixelData1)
        let data2: UnsafePointer<UInt8> = CFDataGetBytePtr(validPixelData2)

        let length1: Int = CFDataGetLength(validPixelData1)
        let length2: Int = CFDataGetLength(validPixelData2)

        guard length1 == length2 else { return false }

        for index in 0..<length1 {
            let byte1 = data1[index]
            let byte2 = data2[index]
            let delta = UInt8(abs(Int(byte1) - Int(byte2)))

            guard delta <= tolerance else { return false }
        }

        return true
    }

    /**
        Modifies the underlying UIImage data to use a PNG representation.

        This is important in verifying pixel data between two images. If one has been exported out with PNG
        compression and another has not, the image data between the two images will never be equal. This helper
        method helps ensure comparisons will be valid.

        - returns: The PNG representation image.
    */
    func af_imageWithPNGRepresentation() -> UIImage {
        let data = UIImagePNGRepresentation(self)!
        let image = UIImage(data: data, scale: UIScreen.mainScreen().scale)!

        return image
    }
}
