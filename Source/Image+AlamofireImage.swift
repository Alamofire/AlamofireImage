//
//  ImageCache.swift
//
//  Copyright (c) 2015 Alamofire Software Foundation (http://alamofire.org/)
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

import Foundation
import SwiftUI

// MARK: URLImageMaster

@available(iOS 13.0, macOS 10.15, tvOS 13, watchOS 6, *)
public final class LazyImageDownloader {
    var placeholder: SwiftUI.Image
    private var imageLoader: ImageDownloader

    public func image(url: URL,
               callback: @escaping (SwiftUI.Image?,  AFIError?) -> Void,
               filter: ImageFilter? = nil,
               progressQueue: DispatchQueue = DispatchQueue.global(qos: .userInteractive)) {
        let urlRequest = URLRequest(url: url)
        imageLoader.download(urlRequest,
                             filter: filter,
                             progressQueue: progressQueue,
                             completion:  { response in
            if case .success(let image) = response.result {
                callback(self.toSwitUIImage(uiImage: image), nil)
            } else {
                callback(nil, response.error)
            }
        })
    }
    
    private func toSwitUIImage(uiImage: UIImage) -> SwiftUI.Image {
        SwiftUI.Image(uiImage: uiImage)
    }
    
    public init() {
        imageLoader = ImageDownloader(configuration: .default,
                                                  downloadPrioritization: .fifo,
                                                  maximumActiveDownloads: 4,
                                                  imageCache:AutoPurgingImageCache())
        self.placeholder = SwiftUI.Image(systemName: "cloud")
    }
    
    public init(downloader:ImageDownloader, placeholder: SwiftUI.Image?=nil){
        if placeholder == nil {
            self.placeholder = SwiftUI.Image(systemName: "cloud")
        } else {
            self.placeholder = placeholder!
        }
        imageLoader = downloader
    }
    
    public static var `default`:LazyImageDownloader {
        LazyImageDownloader()
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13, watchOS 6, *)
public struct LazyImage: View {
    enum URLImageState {
        case finished
        case loading
        case error
    }
    private let loader: LazyImageDownloader
    private let url: URL;
    private var onLoad: (SwiftUI.Image?, AFIError?) -> Void;
    
    @State private var loadedImage: SwiftUI.Image? = nil
    @State private var error: AFIError? = nil
    @State private var loaded: URLImageState = .loading
    
    public init(url: URL,
         loader: LazyImageDownloader = LazyImageDownloader.default,
         onLoad:((SwiftUI.Image?, AFIError?) -> Void)? = nil) {
        self.loader = loader
        self.url = url
        self.onLoad = onLoad ?? {_,_ in}
    }
    
    public var body: some View {
        Group {
            switch loaded {
            case .loading:
                loader.placeholder
            case .finished:
                loadedImage!
            case .error:
                Text(loadedImage.debugDescription)
            }
        }.onAppear(perform: {
            loader.image(url: url){ image, error in
                if let imageSuccess = image {
                    self.loadedImage = imageSuccess
                    loaded = .finished
                } else {
                    self.error = error
                    loaded = .error
                }
                self.onLoad(image, error)
            }
        })
    }
}

