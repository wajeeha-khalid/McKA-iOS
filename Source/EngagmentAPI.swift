//
//  EngagmentAPI.swift
//  edX
//
//  Created by Talha Babar on 9/23/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit
import edXCore
import SwiftyJSON

public struct CourseEngagmentStats {
    struct Fields {
        static let score = "score"
        static let courseAvg = "course_avg"
    }
    
    let score: Int
    let courseAvg: Int
    
    init(score: Int, courseAvg: Int) {
        self.score = score
        self.courseAvg = courseAvg
    }
    
    init?(dictionary: [String: Int]) {
        self.score = dictionary[Fields.score] ?? 0
        self.courseAvg = dictionary[Fields.courseAvg] ?? 0
    }
    
    init?(json: JSON) {
        var engagmentDic: [String:Int] = [:]
        engagmentDic[Fields.score] = json[Fields.score].intValue
        engagmentDic[Fields.courseAvg] = json[Fields.courseAvg].intValue
        self.init(dictionary: engagmentDic)
    }
}

struct CourseEngagmentAPI {
    struct Fields {
        static let score = "score"
        static let courseAvg = "course_avg"
    }
    
    static func courseEngagementResponseDeserializer(_ response: HTTPURLResponse, json: JSON) -> Result<CourseEngagmentStats> {
        if let courseEngagment = CourseEngagmentStats(json: json) {
            return .success(courseEngagment)
        } else {
            return .failure(NSError())
        }
        
    }
    
    static func getEngagementFor(username: String, courseId: String) -> NetworkRequest<CourseEngagmentStats> {
        let path = "/api/server/mobile/v1/users/discussion_metrics/?username={username}&course_id={course_id}".oex_format(withParameters: ["username": username, "course_id": courseId])
        return NetworkRequest(method: .GET,
                              path: path,
                              requiresAuth: true,
                              deserializer: .jsonResponse(courseEngagementResponseDeserializer)
        )
    }
}
