// ImagesViewController.swift
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

import UIKit
import Alamofire
import AlamofireImage

class ImagesViewController: UIViewController {
    
    // MARK: Properties
    
    lazy var imageURLStrings = [String]()
    var collectionView: UICollectionView!
    
    // MARK: View Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpInstanceProperties()
        setUpCollectionView()
    }

    // MARK: Private - Set Up Methods
    
    private func setUpInstanceProperties() {
        self.title = "Random Images"
        
        let imdbBase = "http://ia.media-imdb.com/images/M/"
        let appleBase = "https://developer.apple.com/library/prerelease/ios/documentation/UserExperience/Conceptual/"
        
        self.imageURLStrings = [
            "\(imdbBase)MV5BMjExMjkwNTQ0Nl5BMl5BanBnXkFtZTcwNTY0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMjIyNjk1OTgzNV5BMl5BanBnXkFtZTcwOTU0OTk1Mw@@._V1__SX1457_SY1141_.jpg",
            "\(imdbBase)MV5BNjMxNjI1Mjc1OV5BMl5BanBnXkFtZTcwMDY0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTk1NDM4MDMwMF5BMl5BanBnXkFtZTcwMjY0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTY3MzMzMDgyMF5BMl5BanBnXkFtZTcwMzY0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTMxNDExNzM4MV5BMl5BanBnXkFtZTcwNDY0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTgxNjg2OTc2M15BMl5BanBnXkFtZTcwNzY0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTAyNjQ2NTIyMzBeQTJeQWpwZ15BbWU3MDY3NDk5NTM@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTAzNTQwMDQ4ODReQTJeQWpwZ15BbWU3MDczNDk5NTM@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTM5MjMyMTgxNl5BMl5BanBnXkFtZTcwOTM0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTgzODU4NTY1N15BMl5BanBnXkFtZTcwMTQ0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BNDExNDYxODc1MF5BMl5BanBnXkFtZTcwNDQ0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTQ3NTU4MjA2Ml5BMl5BanBnXkFtZTcwNjQ0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTI3ODA1ODkwN15BMl5BanBnXkFtZTcwODQ0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTU3NTIyOTQyOV5BMl5BanBnXkFtZTcwMTU0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BNTQ5NzI5ODUyOV5BMl5BanBnXkFtZTcwMzU0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTMxODk0MTAzNl5BMl5BanBnXkFtZTcwNDU0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTU2MTc4NDk0MV5BMl5BanBnXkFtZTcwNjU0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTA3NDIwNTc0MDZeQTJeQWpwZ15BbWU3MDYzNDk5NTM@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMjIwNDE4ODc1NV5BMl5BanBnXkFtZTcwODM0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BNDMwMTM2NjEyNF5BMl5BanBnXkFtZTcwMDQ0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTMxODMxMTMzNl5BMl5BanBnXkFtZTcwMzQ0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTA2MDA2NjIxMzJeQTJeQWpwZ15BbWU3MDU0NDk5NTM@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTY0NDEwMzMwMl5BMl5BanBnXkFtZTcwNzQ0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTk1NjIzMjMwNF5BMl5BanBnXkFtZTcwOTQ0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTU1MzY2NTIzNV5BMl5BanBnXkFtZTcwMDM0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BNjk2MTMzNTA4MF5BMl5BanBnXkFtZTcwMTM0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTk0MzQ3MjEwMF5BMl5BanBnXkFtZTcwMjM0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTUxNjYzMTIyM15BMl5BanBnXkFtZTcwMzM0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTQxNTM4MDA1MF5BMl5BanBnXkFtZTcwNDM0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BOTQzNTEyMzE3N15BMl5BanBnXkFtZTcwNTM0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTI3ODgyMDc2Nl5BMl5BanBnXkFtZTcwODY0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTU0MzQxMDY0MV5BMl5BanBnXkFtZTcwOTY0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTMwMDY5Mjc0OV5BMl5BanBnXkFtZTcwMDc0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BOTc0NTkwMTYyNV5BMl5BanBnXkFtZTcwMTc0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTM1MzA2ODIxOV5BMl5BanBnXkFtZTcwMjc0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTY1Nzk4ODUwMF5BMl5BanBnXkFtZTcwMzc0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTMzMDEyMzg0NF5BMl5BanBnXkFtZTcwNDc0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTU4MDk3MjUzNF5BMl5BanBnXkFtZTcwNTc0OTk1Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTUxMjI3Njk4OF5BMl5BanBnXkFtZTcwNzI2NjQ0Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTk1MzExMjM5Nl5BMl5BanBnXkFtZTcwNjI2NjQ0Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMjAxOTM4MzQ5Ml5BMl5BanBnXkFtZTcwODMwNzQxMw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMjEzNzg0Mjk0Ml5BMl5BanBnXkFtZTcwMjI1ODkwMw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTU0NTMwNzMxNl5BMl5BanBnXkFtZTcwODQyODU2Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMjE4OTQwNDU5OV5BMl5BanBnXkFtZTcwMjkyODU2Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMjE0MzY2OTI3MF5BMl5BanBnXkFtZTcwNDkyODU2Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTM3Nzg3NTM5OV5BMl5BanBnXkFtZTcwODkyODU2Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTkwMTc4MTU4MV5BMl5BanBnXkFtZTcwMDAzODU2Mw@@._V1__SX1610_SY1303_.jpg",
            "\(imdbBase)MV5BMTcxNTgxNzgyNl5BMl5BanBnXkFtZTcwMTEzODU2Mw@@._V1__SX1610_SY1303_.jpg",
            "\(appleBase)WatchHumanInterfaceGuidelines/Art/HomeScreen_2x.png",
            "\(appleBase)WatchHumanInterfaceGuidelines/Art/personal_digitaltouch_2x.png",
            "\(appleBase)WatchHumanInterfaceGuidelines/Art/lightweight_weatherglance_2x.png",
            "\(appleBase)WatchHumanInterfaceGuidelines/Art/fullwidth_settings_2x.png",
            "\(appleBase)WatchHumanInterfaceGuidelines/Art/menu_stopwatch_2x.png",
            "\(appleBase)WatchHumanInterfaceGuidelines/Art/typography_mail_2x.png",
            "\(appleBase)WatchHumanInterfaceGuidelines/Art/text_styles_2x.png",
            "\(appleBase)WatchHumanInterfaceGuidelines/Art/images_worldclock_2x.png",
            "\(appleBase)WatchHumanInterfaceGuidelines/Art/table_list_2x.png",
            "\(appleBase)WatchHumanInterfaceGuidelines/Art/sliders_settings_brightness_2x.png"
        ]
    }
    
    private func setUpCollectionView() {
        self.collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: UICollectionViewFlowLayout())
        self.collectionView.backgroundColor = UIColor.whiteColor()
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        self.collectionView.registerClass(ImageCell.classForCoder(), forCellWithReuseIdentifier: ImageCell.identifier())
        
        self.view.addSubview(self.collectionView)
        
        self.collectionView.frame = self.view.bounds
        self.collectionView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
    }
}

// MARK: - UICollectionViewDataSource

extension ImagesViewController : UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.imageURLStrings.count
    }
    
    func collectionView(
        collectionView: UICollectionView,
        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ImageCell.identifier(), forIndexPath: indexPath) as ImageCell
        cell.configureCellWithURLString(self.imageURLStrings[indexPath.row])
        
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
        let viewWidth = self.view.bounds.size.width
        let cellWidth = (viewWidth - 4 * 8) / 3.0
        
        return CGSize(width: cellWidth, height: cellWidth)
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
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as ImageCell
        let image = cell.imageView.image!
        
        let imageViewController = ImageViewController(image: image)
        
        self.navigationController?.pushViewController(imageViewController, animated: true)
    }
}
