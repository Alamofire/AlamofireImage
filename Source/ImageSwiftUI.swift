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

/// `LazyImageDownloader` is used for `LazyImage` to avoid abundant `ImageDownloader`creations and placeholder passings
@available(iOS 13.0, macOS 10.15, tvOS 13, watchOS 6, *)
public final class LazyImageDownloader {
    /// SwiftUI view displayed while image is downloading
    var placeholder: AnyView = AnyView(EmptyView())
    
    /// `ImageDownloader` instance used to download images
    private var imageLoader: ImageDownloader
    
    /// `ImageFilter` applied to images downloaded using this `LazyImageDownloader`
    private var filter: ImageFilter? = nil
    
    /// Creates image download request
    ///
    /// - parameter url - image URL
    /// - parameter callback - callback called after the completion
    /// - parameter progressQueue - DispatchQueue to be used in AlomofireImage
    public func image(url: URL,
                      callback: @escaping (SwiftUI.Image?,  AFIError?) -> Void,
                      progressQueue: DispatchQueue = DispatchQueue.main) {
        let urlRequest = URLRequest(url: url)
        imageLoader.download(urlRequest,
                             filter: filter,
                             progressQueue: progressQueue,
                             completion:  { response in
                                if case .success(let image) = response.result {
                                    callback(SwiftUI.Image(uiImage: image), nil)
                                } else {
                                    callback(nil, response.error)
                                }
                             })
    }
    
    /// Basic init for most cases
    public init() {
        imageLoader = ImageDownloader(configuration: .default,
                                      downloadPrioritization: .fifo,
                                      maximumActiveDownloads: 4,
                                      imageCache:AutoPurgingImageCache())
    }
    
    /// Specify `ImageDownloader` and placeholder
    public init(downloader:ImageDownloader = .default, placeholder: AnyView=AnyView(EmptyView())){
        self.placeholder = placeholder
        imageLoader = downloader
    }
    
    /// Quick access to basic initialisation
    public static var `default`:LazyImageDownloader {
        LazyImageDownloader()
    }
}

// MARK: LazyImage

/// `LazyImage` is a regular SwiftUI view that displays Image by asynchronously downloading it.
@available(iOS 13.0, macOS 10.15, tvOS 13, watchOS 6, *)
public struct LazyImage: View {
    
    /// Used to select internal image loading state
    enum URLImageState {
        case finished
        case loading
        case error
    }
    
    /// `LazyImageDownloader` used for this image
    private let loader: LazyImageDownloader
    
    /// Image URL
    private let url: URL;
    
    /// User-specified action to perform on load completion
    private var onLoad: (SwiftUI.Image?, AFIError?) -> Void;
    
    /// Loaded image will be placed here
    @State private var loadedImage: SwiftUI.Image? = nil
    
    /// In case an error occurs, `AFIError` will be placed here
    @State private var error: AFIError? = nil
    
    /// Loading state
    @State private var loaded: URLImageState = .loading
    
    /// Init `LazyImage`
    /// - parameter url - image url
    /// - parameter loader - `LazyImageDownloader` to be used
    /// - parameter onLoad - closure to be called on load completion
    public init(url: URL,
                loader: LazyImageDownloader = LazyImageDownloader.default,
                onLoad:((SwiftUI.Image?, AFIError?) -> Void)? = nil) {
        self.loader = loader
        self.url = url
        self.onLoad = onLoad ?? {_,_ in}
    }
    
    /// Body to be displayed. Load action is fired through SwiftUI `.onAppear()` functionality
    public var body: some View {
        Group {
            switch loaded {
            case .loading:
                loader.placeholder
            case .finished:
                loadedImage
            case .error:
                Text(error?.errorDescription ?? "Unknown error")
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

