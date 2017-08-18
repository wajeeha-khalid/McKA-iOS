//
//  ResourseAPI.swift
//  edX
//
//  Created by Abdul Haseeb on 8/17/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation
import SwiftyJSON

class CourseContent {
    struct Keys {
        static let id = "id"
        static let name = "name"
        static let content = "content"
    }
    
    let id: String?
    let name: String?
    let content: String?
    
    init(dictionary: [String: Any]) {
        id = dictionary[Keys.id] as? String
        name = dictionary[Keys.name] as? String
        content = dictionary[Keys.content] as? String
    }
    
    convenience init?(json: JSON) {
        guard let dict = json.dictionaryObject else {
            self.init(dictionary:[:])
            return nil
        }
        self.init(dictionary: dict)
    }
    
    init(id: String, name: String, content: String) {
        self.id = id
        self.name = name
        self.content = content
    }
}

struct ResourseAPI {
    
    static func courseContentDeserializer(_ response: HTTPURLResponse, json: JSON) -> Result<[CourseContent]> {
        let courseContents = json["tabs"].arrayValue.flatMap{ courseContentDictionary -> CourseContent? in
            let id = courseContentDictionary["id"].stringValue
            let name = courseContentDictionary["name"].stringValue
            let content = courseContentDictionary["content"].stringValue
            
            let courseContent = CourseContent(id: id, name: name, content: content)
            return courseContent
        }
        return .success(courseContents)
    }

    static func getCourseContent(_ courseId: String) -> NetworkRequest<[CourseContent]> {
        let path = "/api/server/courses/{course_id}/static_tabs?detail=true".oex_format(withParameters: ["course_id": courseId])
        return NetworkRequest(
            method: .GET,
            path: path,
            requiresAuth: true,
            deserializer: .jsonResponse(courseContentDeserializer)
        )
    }
    
}
