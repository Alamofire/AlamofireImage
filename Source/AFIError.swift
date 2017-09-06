//
//  AFIError.swift
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

import Foundation

/// `AFIError` is the error type returned by AlamofireImage.
///
/// - requestCancelled:         The request was explicitly cancelled.
/// - imageSerializationFailed: Response data could not be serialized into an image.
public enum AFIError: Error {
    case requestCancelled
    case imageSerializationFailed
}

// MARK: - Error Booleans

extension AFIError {
    /// Returns `true` if the `AFIError` is a request cancellation error, `false` otherwise.
    public var isRequestCancelledError: Bool {
        if case .requestCancelled = self { return true }
        return false
    }

    /// Returns `true` if the `AFIError` is an image serialization error, `false` otherwise.
    public var isImageSerializationFailedError: Bool {
        if case .imageSerializationFailed = self { return true }
        return false
    }
}

// MARK: - Error Descriptions

extension AFIError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .requestCancelled:
            return "The request was explicitly cancelled."
        case .imageSerializationFailed:
            return "Response data could not be serialized into an image."
        }
    }
}
