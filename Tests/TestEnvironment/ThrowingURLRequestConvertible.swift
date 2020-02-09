//
//  ThrowingURLRequestConvertible.swift
//  AlamofireImage iOS
//
//  Created by Marina Gornostaeva on 10/02/2020.
//  Copyright © 2020 Alamofire. All rights reserved.
//

import Foundation
import Alamofire

struct ThrowingURLRequestConvertible: URLRequestConvertible {
    
    enum Error: Swift.Error {
        case testError
    }
    
    func asURLRequest() throws -> URLRequest {
        throw Error.testError
    }
}
