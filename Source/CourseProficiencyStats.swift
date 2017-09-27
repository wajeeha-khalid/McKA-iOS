//
//  CourseProficiencyStats.swift
//  edX
//
//  Created by Talha Babar on 9/23/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit
import edXCore
import SwiftyJSON

public struct CourseProficiencyStats {
    struct Fields {
        static let username = "username"
        static let cohortAvgGrade = "cohort_average_grade"
        static let courseId = "course_key"
        static let courseGrade = "course_grade"
    }
    
    let username: String
    let cohortAvgGrade: Int
    let courseId: String
    let courseGrade: Int
    
    init(username: String, cohortAvgGrade: Int, courseId: String, courseGrade: Int) {
        self.username = username
        self.cohortAvgGrade = cohortAvgGrade
        self.courseId = courseId
        self.courseGrade = courseGrade
    }
    
    init?(dictionary: [String: Any]) {
        self.courseGrade = dictionary[Fields.courseGrade] as? Int ?? 0
        self.courseId = dictionary[Fields.courseId] as? String ?? ""
        self.cohortAvgGrade = dictionary[Fields.cohortAvgGrade] as? Int ?? 0
        self.username = dictionary[Fields.username] as? String ?? ""
    }
    
    init?(json: JSON) {
        var proficiencyDic: [String:Any] = [:]
        proficiencyDic[Fields.courseGrade] = json[Fields.courseGrade].intValue
        proficiencyDic[Fields.courseId] = json[Fields.courseId].stringValue
        proficiencyDic[Fields.cohortAvgGrade] = json[Fields.cohortAvgGrade].intValue
        proficiencyDic[Fields.username] = json[Fields.username].intValue
        self.init(dictionary: proficiencyDic)
    }
}

struct CourseProficiencyAPI {
    struct Fields {
        static let username = "username"
        static let cohortAvgGrade = "cohort_average_grade"
        static let courseId = "course_key"
        static let courseGrade = "course_grade"
    }
    
    static func courseProficiencyResponseDeserializer(_ response: HTTPURLResponse, json: JSON) -> Result<CourseProficiencyStats> {
        if let courseProficiency = CourseProficiencyStats(json: json) {
            return .success(courseProficiency)
        } else {
            return .failure(NSError())
        }
        
    }
    
    static func getProficiencyFor(username: String, courseId: String) -> NetworkRequest<CourseProficiencyStats> {
        let path = "api/server/mobile/v1/users/courses/grades?course_id={course_id}&username={username}".oex_format(withParameters: ["course_id": courseId, "username": username])
        return NetworkRequest(method: .GET,
                              path: path,
                              requiresAuth: true,
                              deserializer: .jsonResponse(courseProficiencyResponseDeserializer)
        )
    }
}
