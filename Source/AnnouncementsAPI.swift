//
//  AnnouncementsAPI.swift
//  edX
//
//  Created by Abdul Haseeb on 8/18/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation
import SwiftyJSON

class CourseAnnouncementContent {
    struct Keys {
        static let content = "content"
    }
    
    let content: String?
    
    init(dictionary: [String: Any]) {
        self.content = dictionary[Keys.content] as? String
        print(self.content ?? "")
    }
    
    convenience init?(json: JSON) {
        guard let dict = json.dictionaryObject else {
            self.init(dictionary:[:])
            return nil
        }
        self.init(dictionary: dict)
    }
    
    init(content: String) {
        self.content = content
    }
}

struct AnnouncementsAPI {
    
    static func courseContentDeserializer(_ response: HTTPURLResponse, json: JSON) -> Result<CourseAnnouncementContent> {
        let courseAnnouncementContent = CourseAnnouncementContent(content: json["content"].stringValue)
        return .success(courseAnnouncementContent)
    }
    
    static func getAnnouncementsContent(_ courseId: String) -> NetworkRequest<CourseAnnouncementContent> {
        let path = "/api/server/courses/{course_id}/updates".oex_format(withParameters: ["course_id": courseId])
        return NetworkRequest(
            method: .GET,
            path: path,
            requiresAuth: true,
            deserializer: .jsonResponse(courseContentDeserializer)
        )
    }
    
}
