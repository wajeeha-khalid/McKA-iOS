//
//  MCQAPI.swift
//  edX
//
//  Created by Shafqat Muneer on 8/26/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation
import edXCore
import SwiftyJSON

class MCQResponseData: NSObject {
    struct Keys {
        static let id = "id"
        static let value = "submission"
        static let status = "status"
        static let tip = "tips"
    }

    let id: String
    let value: String
    let status: String
    let tip: String
    
    init(id: String, value: String, status: String, tip: String) {
        self.id = id
        self.value = value
        self.status = status
        self.tip = tip
    }
    init?(dictionary: [String: Any]) {
        self.id = dictionary[Keys.id] as? String ?? ""
        self.value = dictionary[Keys.value] as? String ?? ""
        self.status = dictionary[Keys.status] as? String ?? ""
        self.tip = dictionary[Keys.tip] as? String ?? ""
        
        super.init()
    }
    
    convenience init?(json: JSON) {
        let array = json.arrayValue
        if array.count >= 2 {
            let id = array[0].stringValue
            guard var dictionary = json.dictionaryObject else {
                self.init(dictionary:[:])
                return nil
            }
            dictionary["id"] = id
            self.init(dictionary: dictionary)
        } else {
            self.init(dictionary:[:])
            return nil
        }
    }
}

struct MCQAPI {
    static func mcqResponseDeserializer(_ response: HTTPURLResponse, json: JSON) -> Result<MCQResponseData> {

        //TODO: Need to implement the mapping of response to MCQResponseData and send the response for MCQResponse
        
//        let enrollments = json.arrayValue.flatMap { enrollmentJSON -> UserCourseEnrollment? in
//            let courseJSON = enrollmentJSON["course"]
//            let progress = enrollmentJSON["progress"].double
//            let course = courseJSON.dictionaryObject.map {
//                OEXCourse(json: $0, progress: progress.map {NSNumber(value: $0)})
//            }
//            return course.map {
//                UserCourseEnrollment(course: $0, created: enrollmentJSON["created"].string, isActive: enrollmentJSON["is_active"].boolValue)
//            }
//        }
//        return .success(enrollments)
        let mcqResponseData = MCQResponseData(id: "TestId", value: "TestValue", status: "TestStatus", tip: "TestTip")
        return .success(mcqResponseData)
    }
    
    static func getMCQResponse(_ questionId: String, value: String, courseId: String, blockId: String) -> NetworkRequest<MCQResponseData> {
        let path = "/courses/{course_id}/xblock/{block_id}".oex_format(withParameters: ["user_id": courseId, "block_id": blockId])
        let requestBody = [questionId: ["value": value]]
        return NetworkRequest(method: .GET,
                       path: path,
                       requiresAuth: true,
                       body: .jsonBody(JSON(requestBody)),
                       deserializer: .jsonResponse(mcqResponseDeserializer)
        )
    }
}
