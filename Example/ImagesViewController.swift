// ImagesViewController.swift
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

import Alamofire
import AlamofireImage
import Foundation
import UIKit

class ImagesViewController: UIViewController {
    lazy var gravatars: [Gravatar] = []

    lazy var placeholderImage: UIImage = {
        let image = UIImage(named: "Placeholder Image")!
        return image
    }()

    var collectionView: UICollectionView!

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpInstanceProperties()
        setUpCollectionView()
    }

    // MARK: Private - Setup

    private func setUpInstanceProperties() {
        title = "Random Images"

        for _ in 1...1_000 {
            let gravatar = Gravatar(
                emailAddress: NSUUID().UUIDString,
                defaultImage: Gravatar.DefaultImage.Identicon,
                forceDefault: true
            )

            gravatars.append(gravatar)
        }
    }

    private func setUpCollectionView() {
        collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.backgroundColor = UIColor.whiteColor()

        collectionView.delegate = self
        collectionView.dataSource = self

        collectionView.registerClass(ImageCell.self, forCellWithReuseIdentifier: ImageCell.ReuseIdentifier)

        view.addSubview(self.collectionView)

        collectionView.frame = self.view.bounds
        collectionView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
    }

    private func sizeForCollectionViewItem() -> CGSize {
        let viewWidth = view.bounds.size.width

        var cellWidth = (viewWidth - 4 * 8) / 3.0

        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            cellWidth = (viewWidth - 7 * 8) / 6.0
        }

        return CGSize(width: cellWidth, height: cellWidth)
    }
}

// MARK: - UICollectionViewDataSource

extension ImagesViewController : UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gravatars.count
    }

    func collectionView(
        collectionView: UICollectionView,
        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ImageCell.ReuseIdentifier, forIndexPath: indexPath) as! ImageCell
        let gravatar = gravatars[indexPath.row]
        cell.configureCellWithURLString(gravatar.URL(size: sizeForCollectionViewItem().width).URLString, placeholderImage: placeholderImage)

        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension ImagesViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(
        collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        return sizeForCollectionViewItem()
    }

    func collectionView(
        collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAtIndex section: Int) -> UIEdgeInsets
    {
        return UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }

    func collectionView(
        collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat
    {
        return 8.0
    }

    func collectionView(
        collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat
    {
        return 8.0
    }
}

// MARK: - UICollectionViewDelegate

extension ImagesViewController : UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let gravatar = self.gravatars[indexPath.row]

        let imageViewController = ImageViewController()
        imageViewController.gravatar = gravatar

        self.navigationController?.pushViewController(imageViewController, animated: true)
    }
}
