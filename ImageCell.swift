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

import Foundation
import UIKit
import Alamofire
import AlamofireImage

class ImageCell : UICollectionViewCell {

    // MARK: - Properties
    
    let imageView: UIImageView
    
    // MARK: - Initialization Methods
    
    override init(frame: CGRect) {
        self.imageView = UIImageView(frame: frame)
        self.imageView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        self.imageView.contentMode = .ScaleAspectFill
        self.imageView.clipsToBounds = true
        
        super.init(frame: frame)
        
        self.contentView.addSubview(self.imageView)
        
        self.imageView.frame = self.contentView.bounds
        
        self.contentView.backgroundColor = UIColor.darkGrayColor()
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
        self.imageView.setImage(URL: NSURL(string: URLString)!, placeHolderImage: placeholderImage)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.imageView.cancelImageRequest()
        self.imageView.image = nil
    }
}
