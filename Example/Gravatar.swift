//
//  Gravatar.swift
//  iOS Example
//
//  Created by Kevin Harwood on 8/25/15.
//  Copyright © 2015 Alamofire. All rights reserved.
//

import Foundation
import UIKit

private extension String  {
    var md5_hash: String {
        let trimmedString = lowercaseString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        let utf8String = trimmedString.cStringUsingEncoding(NSUTF8StringEncoding)!
        let stringLength = CC_LONG(trimmedString.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        let digestLength = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLength)

        CC_MD5(utf8String, stringLength, result)

        var hash = ""

        for i in 0..<digestLength {
            hash += String(format: "%02x", result[i])
        }

        result.dealloc(digestLength)

        return String(format: hash)
    }
}

// MARK: - QueryItemConvertible

private protocol QueryItemConvertible {
    var queryItem: NSURLQueryItem {get}
}

// MARK: -

public struct Gravatar {
    public enum DefaultImage: String, QueryItemConvertible {
        case HTTP404 = "404"
        case MysteryMan = "mm"
        case Identicon = "identicon"
        case MonsterID = "monsterid"
        case Wavatar = "wavatar"
        case Retro = "retro"
        case Blank = "blank"

        var queryItem: NSURLQueryItem {
            return NSURLQueryItem(name: "d", value: rawValue)
        }
    }

    public enum Rating: String, QueryItemConvertible {
        case G = "g"
        case PG = "pg"
        case R = "r"
        case X = "x"

        var queryItem: NSURLQueryItem {
            return NSURLQueryItem(name: "r", value: rawValue)
        }
    }

    public let email: String
    public let forceDefault: Bool
    public let defaultImage: DefaultImage
    public let rating: Rating

    private static let baseURL = NSURL(string: "https://secure.gravatar.com/avatar")!

    public init(
        emailAddress: String,
        defaultImage: DefaultImage = .MysteryMan,
        forceDefault: Bool = false,
        rating: Rating = .PG)
    {
        self.email = emailAddress
        self.defaultImage = defaultImage
        self.forceDefault = forceDefault
        self.rating = rating
    }

    public func URL(size size: CGFloat, scale: CGFloat = UIScreen.mainScreen().scale) -> NSURL {
        let URL = Gravatar.baseURL.URLByAppendingPathComponent(email.md5_hash)
        let components = NSURLComponents(URL: URL, resolvingAgainstBaseURL: false)!

        var queryItems = [defaultImage.queryItem, rating.queryItem]
        queryItems.append(NSURLQueryItem(name: "f", value: forceDefault ? "y" : "n"))
        queryItems.append(NSURLQueryItem(name: "s", value: String(format: "%.0f",size * scale)))

        components.queryItems = queryItems

        return components.URL!
    }
}
