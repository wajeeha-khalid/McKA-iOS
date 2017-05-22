//
//  ProgressAPI.swift
//  edX
//
//  Created by Naveen Katari on 01/03/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

struct ProgressAPI {
    
    static func progressResponseDeserializer(response: NSHTTPURLResponse, json: JSON) -> Result<[UserCourseEnrollment]> {
        return (json.array?.flatMap { UserCourseEnrollment(json: $0) }).toResult()
    }
    
    static func setProgressForCourse(username: String, componentIDs: String) -> NetworkRequest<[UserCourseEnrollment]> {
       //let componetIDs = "block-v1:edX+DemoX+Demo_Course+type@problem+block@ex_practice_limited_checks,block-v1:edX+DemoX+Demo_Course+type@problem+block@logic_gate_problem"
        return NetworkRequest(
            method: .POST,
            path: "/api/progress_tracker/recordView/",
            body: .JSONBody(JSON([
                "userName" : username,
                "componentIds": componentIDs
                ])),
            deserializer: .JSONResponse(progressResponseDeserializer)
        )
    }
}
