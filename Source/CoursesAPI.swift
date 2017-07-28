//
//  CoursesAPI.swift
//  edX
//
//  Created by Akiva Leffert on 12/21/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation
import edXCore

struct CoursesAPI {
    
    static func enrollmentsDeserializer(response: NSHTTPURLResponse, json: JSON) -> Result<[UserCourseEnrollment]> {
        
        let enrollments = json.arrayValue.flatMap { enrollmentJSON -> UserCourseEnrollment? in
            let courseJSON = enrollmentJSON["course"]
            let progress = enrollmentJSON["progress"].double
            let course = courseJSON.dictionaryObject.map {
                OEXCourse(JSON: $0, progress: progress)
            }
            return course.map {
                UserCourseEnrollment(course: $0, created: enrollmentJSON["created"].string, isActive: enrollmentJSON["is_active"].boolValue)
            }
        }
        return .Success(enrollments)
    }
    
    static func getUserEnrollments(userID: Int, organizationCode: String?) -> NetworkRequest<[UserCourseEnrollment]> {
        let path = "/api/server/users/{user_id}/courses/progress?mobile_only=true".oex_formatWithParameters(["user_id": userID])
        return NetworkRequest(
            method: .GET,
            path: path,
            requiresAuth: true,
            deserializer: .JSONResponse(enrollmentsDeserializer)
        )
    }
}
