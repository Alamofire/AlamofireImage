//
//  Error.swift
//  AlamofireImage
//
//  Created by Anthony Miller on 5/30/16.
//  Copyright © 2016 Alamofire. All rights reserved.
//

import Foundation

/// The `Error` struct provides a convenience for creating custom AlamofireImage NSErrors.
public struct Error {
    /// The domain used for creating all Alamofire errors.
    public static let Domain = "com.alamofire-image.error"
    
    /// The custom error codes generated by Alamofire.
    public enum Code: Int {
        case ContentTypeValidationFailed     = -9000
        case ImageDataSerializationFailed    = -9001
    }
    
    /**
     Creates an `NSError` with the given error code and failure reason.
     
     - parameter code:          The error code.
     - parameter failureReason: The failure reason.
     
     - returns: An `NSError` with the given error code and failure reason.
     */
    static func errorWithCode(code: Code, failureReason: String) -> NSError {
        let userInfo = [NSLocalizedFailureReasonErrorKey: failureReason]
        return NSError(domain: Domain, code: code.rawValue, userInfo: userInfo)
    }
    
}