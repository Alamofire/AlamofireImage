//
//  TestEnvironment.swift
//  AlamofireImage
//
//  Created by Marina Gornostaeva on 12/02/2020.
//  Copyright © 2020 Alamofire. All rights reserved.
//

import Foundation

enum TestEnvironment {
    
    enum URL {
        static let pngImage = "https://httpbin.org/image/png"
        static let jpegImage = "https://httpbin.org/image/jpeg"
        static let pngImageWithRedirect = "https://httpbin.org/redirect-to?url=\(URL.pngImage)"
        static let webpImage = "https://httpbin.org/image/webp"
        
        static let zeroBytes = "https://httpbin.org/bytes/0"
        static let randomBytes = "https://httpbin.org/bytes/\(4 * 1024 * 1024)"
        static let json = "https://httpbin.org/get"
        
        static let gravatarImages: [String] = [
            "https://secure.gravatar.com/avatar/5a105e8b9d40e1329780d62ea2265d8a?d=identicon",
            "https://secure.gravatar.com/avatar/6a105e8b9d40e1329780d62ea2265d8a?d=identicon",
            "https://secure.gravatar.com/avatar/7a105e8b9d40e1329780d62ea2265d8a?d=identicon",
            "https://secure.gravatar.com/avatar/8a105e8b9d40e1329780d62ea2265d8a?d=identicon",
            "https://secure.gravatar.com/avatar/9a105e8b9d40e1329780d62ea2265d8a?d=identicon"
        ]
        
        static var randomJPEGImage: String {
            "https://httpbin.org/image/jpeg?random=\(arc4random())"
        }
        
        static var kittenImageOfRandomSize: String {
            let width = Int.random(in: 100...400)
            let height = Int.random(in: 100...400)
            
            let urlString = "https://placekitten.com/\(width)/\(height)"
            return urlString
        }
        
        static let nonExistent = "https://invalid.for.sure"
    }
}
