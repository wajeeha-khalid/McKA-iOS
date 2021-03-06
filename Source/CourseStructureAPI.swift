//
//  ServerAPI.swift
//  edX
//
//  Created by Akiva Leffert on 5/20/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
import edXCore
import SwiftyJSON
public struct CourseOutlineAPI {
    struct Parameters {
        let courseID: String
        let username : String?
        let fields : [String]
        let blockCount : [String]
        let studentViewData : [String]
        
        var query : [String:JSON] {
            var result =
            [
                "requested_fields" : JSON(fields.joined(separator: ",")),
                "block_counts" : JSON(blockCount.joined(separator: ",")),
                "student_view_data" : JSON(studentViewData.joined(separator: ",")),
                "depth": "all",
                "nav_depth": 3,
                "course_id": JSON(courseID)
            ]
            
            if let username = username {
                result["username"] = JSON(username)
            }
            
            return result
            
        }
    }
    
    static func deserializer(_ response : HTTPURLResponse, json : JSON) -> Result<CourseOutline> {
        return CourseOutline(json: json).toResult(NSError.oex_courseContentLoadError())
    }
    
    public static func requestWithCourseID(_ courseID : String, username : String?) -> NetworkRequest<CourseOutline> {
        let parameters = Parameters(
            courseID: courseID,
            username: username,
            fields : ["graded", "student_view_multi_device", "format"],
            blockCount : [CourseBlock.Category.Video.rawValue],
            studentViewData : ["video", "discussion", "ooyala"]
        )
        return NetworkRequest(
            method : .GET,
            path : "/api/courses/v1/blocks/",
            requiresAuth : true,
            query : parameters.query,
            deserializer : .jsonResponse(deserializer)
        )
    }
}
