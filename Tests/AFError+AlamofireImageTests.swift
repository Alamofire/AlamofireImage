//
//  AFError+AlamofireImageTests.swift
//
//  Copyright (c) 2015-2018 Alamofire Software Foundation (http://alamofire.org/)
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

import Alamofire

extension AFError {

    // ResponseSerializationFailureReason

    var isInputDataNil: Bool {
        if case let .responseSerializationFailed(reason) = self, reason.isInputDataNil { return true }
        return false
    }

    var isInputDataNilOrZeroLength: Bool {
        if case let .responseSerializationFailed(reason) = self, reason.isInputDataNilOrZeroLength { return true }
        return false
    }

    var isInputFileNil: Bool {
        if case let .responseSerializationFailed(reason) = self, reason.isInputFileNil { return true }
        return false
    }

    var isInputFileReadFailed: Bool {
        if case let .responseSerializationFailed(reason) = self, reason.isInputFileReadFailed { return true }
        return false
    }

    // ResponseValidationFailureReason

    var isDataFileNil: Bool {
        if case let .responseValidationFailed(reason) = self, reason.isDataFileNil { return true }
        return false
    }

    var isDataFileReadFailed: Bool {
        if case let .responseValidationFailed(reason) = self, reason.isDataFileReadFailed { return true }
        return false
    }

    var isMissingContentType: Bool {
        if case let .responseValidationFailed(reason) = self, reason.isMissingContentType { return true }
        return false
    }

    var isUnacceptableContentType: Bool {
        if case let .responseValidationFailed(reason) = self, reason.isUnacceptableContentType { return true }
        return false
    }

    var isUnacceptableStatusCode: Bool {
        if case let .responseValidationFailed(reason) = self, reason.isUnacceptableStatusCode { return true }
        return false
    }
}

// MARK: -

extension AFError.ResponseSerializationFailureReason {
    var isInputDataNil: Bool {
        if case .inputDataNil = self { return true }
        return false
    }

    var isInputDataNilOrZeroLength: Bool {
        if case .inputDataNilOrZeroLength = self { return true }
        return false
    }

    var isInputFileNil: Bool {
        if case .inputFileNil = self { return true }
        return false
    }

    var isInputFileReadFailed: Bool {
        if case .inputFileReadFailed = self { return true }
        return false
    }
}

// MARK: -

extension AFError.ResponseValidationFailureReason {
    var isDataFileNil: Bool {
        if case .dataFileNil = self { return true }
        return false
    }

    var isDataFileReadFailed: Bool {
        if case .dataFileReadFailed = self { return true }
        return false
    }

    var isMissingContentType: Bool {
        if case .missingContentType = self { return true }
        return false
    }

    var isUnacceptableContentType: Bool {
        if case .unacceptableContentType = self { return true }
        return false
    }

    var isUnacceptableStatusCode: Bool {
        if case .unacceptableStatusCode = self { return true }
        return false
    }
}
