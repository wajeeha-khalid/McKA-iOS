//
//  UserPreferenceAPI.swift
//  edX
//
//  Created by Kevin Kim on 7/28/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
import edXCore
import SwiftyJSON

open class UserPreferenceAPI: NSObject {
    
    fileprivate static func preferenceDeserializer(_ response : HTTPURLResponse, json : JSON) -> Result<UserPreference> {
        return UserPreference(json: json).toResult()
    }
    
    fileprivate class func path(_ username:String) -> String {
        return "/api/user/v1/preferences/{username}".oex_format(withParameters: ["username": username])
    }
    
    class func preferenceRequest(_ username: String) -> NetworkRequest<UserPreference> {
        return NetworkRequest(
            method: HTTPMethod.GET,
            path : path(username),
            requiresAuth : true,
            deserializer: .jsonResponse(preferenceDeserializer))
    }
    
}
