//
//  NetworkManager+ResponseInterceptors.swift
//  edX
//
//  Created by Saeed Bashir on 6/30/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

extension NetworkManager {
    public func addResponseInterceptors() {
        addResponseInterceptors(Code426Interceptor())
    }
}

open class Code426Interceptor : ResponseInterceptor {
    open func handleResponse<Out>(_ result: NetworkResult<Out>) -> Result<Out> {
        if let response = result.response {
            let statusCode = OEXHTTPStatusCode(rawValue: response.statusCode)
            if statusCode == .code426UpgradeRequired {
                return result.data.toResult(NSError.oex_outdatedVersionError())
            }
        }
        return result.data.toResult(result.error ?? NetworkManager.unknownError)
    }
}
