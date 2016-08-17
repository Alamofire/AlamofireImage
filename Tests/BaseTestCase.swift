//
//  BaseTestCase.swift
//
//  Copyright (c) 2015-2016 Alamofire Software Foundation (http://alamofire.org/)
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
import AlamofireImage
import Foundation
import XCTest

class BaseTestCase : XCTestCase {
    let timeout = 5.0
    var manager: SessionManager!

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()

        manager = {
            let configuration: URLSessionConfiguration = {
                let configuration = URLSessionConfiguration.ephemeral

                let defaultHeaders = SessionManager.sharedInstance.session.configuration.httpAdditionalHeaders
                configuration.httpAdditionalHeaders = defaultHeaders

                return configuration
            }()

            return SessionManager(configuration: configuration)
        }()
    }

    override func tearDown() {
        super.tearDown()

        manager.session.finishTasksAndInvalidate()
        manager = nil
    }

    // MARK: - Resources

    func URLForResource(_ fileName: String, withExtension: String) -> URL {
        let bundle = Bundle(for: BaseTestCase.self)
        return bundle.url(forResource: fileName, withExtension: withExtension)!
    }

    func imageForResource(_ fileName: String, withExtension ext: String) -> Image {
        let resourceURL = URLForResource(fileName, withExtension: ext)
        let data = try! Data(contentsOf: resourceURL)
        #if os(iOS) || os(tvOS)
            let image = Image.af_threadSafeImageWithData(data, scale: UIScreen.main.scale)!
        #elseif os(OSX)
            let image = Image(data: data)!
        #endif

        return image
    }
}
