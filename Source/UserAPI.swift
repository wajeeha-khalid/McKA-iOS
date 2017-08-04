//
//  UserAPI.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 11/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
import edXCore
import SwiftyJSON

public struct UserAPI {
    public struct UserStatusParameters {
        let courseVisitedModuleId : String
        let modificationDate = OEXDateFormatting.serverString(with: Date())
        var query : [String:String] {
            return [
                "last_visited_module_id" : courseVisitedModuleId,
                "modification_date" : modificationDate ?? ""
            ]
        }
        
        var jsonBody : JSON {
            return JSON(query)
        }
}

    static func lastAccessedDeserializer(_ response : HTTPURLResponse, json : JSON) -> Result<CourseLastAccessed> {
        return CourseLastAccessed(json: json).toResult()
    }
    
    public static func requestLastVisitedModuleForCourseID(_ courseID: String) -> NetworkRequest<CourseLastAccessed> {

        return NetworkRequest(
            method: HTTPMethod.GET,
            path : "/api/mobile/v0.5/users/{username}/course_status_info/{course_id}".oex_format(withParameters: ["course_id" : courseID, "username":OEXSession.shared()?.currentUser?.username ?? ""]),
            requiresAuth : true,
            deserializer: .jsonResponse(lastAccessedDeserializer))
    }
    
    public static func setLastVisitedModuleForBlockID(_ blockID:String, module_id:String) -> NetworkRequest<CourseLastAccessed> {
        let requestParams = UserStatusParameters(courseVisitedModuleId: module_id)
        
        return NetworkRequest(
            method: HTTPMethod.PATCH,
            path : "/api/mobile/v0.5/users/{username}/course_status_info/{course_id}".oex_format(withParameters: ["course_id" : blockID, "username":OEXSession.shared()?.currentUser?.username ?? ""]),
            requiresAuth : true,
            body : RequestBody.jsonBody(requestParams.jsonBody),
            deserializer: .jsonResponse(lastAccessedDeserializer))
    }
    



}
