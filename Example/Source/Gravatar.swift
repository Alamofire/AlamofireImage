//
//  Gravatar.swift
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
import UIKit

extension String {
    fileprivate var md5Hash: String {
        let trimmedString = lowercased().trimmingCharacters(in: .whitespaces)
        let utf8String = trimmedString.cString(using: .utf8)!
        let stringLength = CC_LONG(trimmedString.lengthOfBytes(using: .utf8))
        let digestLength = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLength)

        CC_MD5(utf8String, stringLength, result)

        var hash = ""

        for i in 0..<digestLength {
            hash += String(format: "%02x", result[i])
        }

        result.deallocate()

        return String(format: hash)
    }
}

// MARK: - QueryItemConvertible

private protocol QueryItemConvertible {
    var queryItem: URLQueryItem { get }
}

// MARK: -

public struct Gravatar {
    public enum DefaultImage: String, QueryItemConvertible {
        case http404 = "404"
        case mysteryMan = "mm"
        case identicon
        case monsterID = "monsterid"
        case wavatar
        case retro
        case blank

        var queryItem: URLQueryItem {
            URLQueryItem(name: "d", value: rawValue)
        }
    }

    public enum Rating: String, QueryItemConvertible {
        case g
        case pg
        case r
        case x

        var queryItem: URLQueryItem {
            URLQueryItem(name: "r", value: rawValue)
        }
    }

    public let email: String
    public let forceDefault: Bool
    public let defaultImage: DefaultImage
    public let rating: Rating

    private static let baseURL = URL(string: "https://secure.gravatar.com/avatar")!

    public init(emailAddress: String,
                defaultImage: DefaultImage = .mysteryMan,
                forceDefault: Bool = false,
                rating: Rating = .pg) {
        email = emailAddress
        self.defaultImage = defaultImage
        self.forceDefault = forceDefault
        self.rating = rating
    }

    public func url(size: CGFloat, scale: CGFloat = UIScreen.main.scale) -> URL {
        let url = Gravatar.baseURL.appendingPathComponent(email.md5Hash)
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!

        var queryItems = [defaultImage.queryItem, rating.queryItem]
        if forceDefault {
            queryItems.append(URLQueryItem(name: "f", value: "y"))
        }
        queryItems.append(URLQueryItem(name: "s", value: String(format: "%.0f", size * scale)))

        components.queryItems = queryItems

        return components.url!
    }
}
