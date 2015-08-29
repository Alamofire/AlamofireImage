// ImageCell.swift
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

import Alamofire
import AlamofireImage
import UIKit

class ImageCell : UICollectionViewCell {

    // MARK: - Properties

    let imageView: UIImageView

    // MARK: - Initialization Methods

    override init(frame: CGRect) {
        self.imageView = UIImageView(frame: frame)
        self.imageView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.imageView.contentMode = .Center
        self.imageView.clipsToBounds = true

        super.init(frame: frame)

        self.contentView.addSubview(self.imageView)

        self.imageView.frame = self.contentView.bounds
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Identification Methods

    class func identifier() -> String {
        return "ImageCellIdentifier"
    }

    // MARK: - Cell Lifecycle Methods

    func configureCellWithURLString(URLString: String, placeholderImage: UIImage) {
        let size = self.imageView.frame.size

        self.imageView.ai_setImage(
            URLString: URLString,
            placeholderImage: placeholderImage,
            filter: AspectScaledToFillSizeWithRoundedCornersFilter(size: size, radius: 20.0),
            imageTransition: .CrossDissolve(0.2)
        )
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.imageView.ai_cancelImageRequest()
        self.imageView.layer.removeAllAnimations()
        self.imageView.image = nil
    }
}
