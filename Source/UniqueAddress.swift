//
//  UniqueAddress.swift
//  AlamofireImage
//
//  Created by Andrew Benson on 8/1/23.
//  Copyright © 2023 Alamofire. All rights reserved.
//

import Foundation

/// From:
/// https://github.com/atrick/swift-evolution/blob/diagnose-implicit-raw-bitwise/proposals/nnnn-implicit-raw-bitwise-conversion.md#workarounds-for-common-cases

@propertyWrapper
public struct UniqueAddress {
    private var _placeholder: Int8 = 0

    public var wrappedValue: UnsafeRawPointer {
        mutating get {
            // This is "ok" only as long as the wrapped property appears
            // inside of something with a stable address (a global/static
            // variable or class property) and the pointer is never read or
            // written through, only used for its unique value
            return withUnsafeBytes(of: &self) {
                return $0.baseAddress.unsafelyUnwrapped
            }
        }
    }

    private init(_placeholder: Int8) {
        self._placeholder = _placeholder
    }

    public init() { }
}
