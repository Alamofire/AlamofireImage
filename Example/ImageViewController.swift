//
//  ImageViewController.swift
//
//  Copyright (c) 2015-2017 Alamofire Software Foundation (http://alamofire.org/)
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

import AlamofireImage
import Foundation
import UIKit

class ImageViewController : UIViewController {
    var gravatar: Gravatar!
    var imageView: UIImageView!

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpInstanceProperties()
        setUpImageView()
    }

    // MARK: - Private - Setup Methods

    private func setUpInstanceProperties() {
        title = gravatar.email
        edgesForExtendedLayout = UIRectEdge()
        view.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
    }

    private func setUpImageView() {
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit

        let URL = gravatar.url(size: view.bounds.size.width)

        imageView.af_setImage(
            withURL: URL,
            placeholderImage: nil,
            filter: CircleFilter(),
            imageTransition: .flipFromBottom(0.5)
        )

        view.addSubview(imageView)

        imageView.frame = view.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
}
