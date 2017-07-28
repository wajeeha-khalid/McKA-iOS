//
//  CoursesAPI.swift
//  edX
//
//  Created by Akiva Leffert on 12/21/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation
import edXCore
import SwiftyJSON

struct CoursesAPI {
    
    static func enrollmentsDeserializer(_ response: HTTPURLResponse, json: JSON) -> Result<[UserCourseEnrollment]> {
        
        let enrollments = json.arrayValue.flatMap { enrollmentJSON -> UserCourseEnrollment? in
            let courseJSON = enrollmentJSON["course"]
            let progress = enrollmentJSON["progress"].double
            let course = courseJSON.dictionaryObject.map {
                OEXCourse(json: $0, progress: progress.map {NSNumber(value: $0)})
            }
            return course.map {
                UserCourseEnrollment(course: $0, created: enrollmentJSON["created"].string, isActive: enrollmentJSON["is_active"].boolValue)
            }
        }
        return .success(enrollments)
    }
    
    static func getUserEnrollments(_ userID: Int, organizationCode: String?) -> NetworkRequest<[UserCourseEnrollment]> {
        let path = "/api/server/users/{user_id}/courses/progress?mobile_only=true".oex_format(withParameters: ["user_id": userID])
        return NetworkRequest(
            method: .GET,
            path: path,
            requiresAuth: true,
            deserializer: .jsonResponse(enrollmentsDeserializer)
        )
    }
}
