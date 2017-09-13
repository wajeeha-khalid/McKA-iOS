//
//  AnnouncementsAPI.swift
//  edX
//
//  Created by Abdul Haseeb on 8/18/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation
import SwiftyJSON

class CourseAnnouncement {
    struct Keys {
        static let date = "date"
        static let id = "id"
        static let content = "content"
    }
    
    let content: String?
    let id: String?
    let date: String?
    
    init(dictionary: [String: Any]) {
        self.content = dictionary[Keys.content] as? String
        self.id = dictionary[Keys.id] as? String
        self.date = dictionary[Keys.date] as? String
    }
    
    convenience init?(json: JSON) {
        guard let dict = json.dictionaryObject else {
            self.init(dictionary:[:])
            return nil
        }
        self.init(dictionary: dict)
    }
    
    init(id: String, date: String,content: String) {
        self.id = id
        self.date = date
        self.content = content
    }
}

struct AnnouncementsAPI {
    
    static func courseContentDeserializer(_ response: HTTPURLResponse, json: JSON) -> Result<[CourseAnnouncement]> {
        let courseContentUpdates = json.arrayValue.filter{ courseUpdateContent in
            courseUpdateContent["status"].stringValue == "visible"
        }
        let courseUpdates = courseContentUpdates.flatMap{ courseUpdate -> CourseAnnouncement? in
            let id = courseUpdate["id"].stringValue
            let date = courseUpdate["date"].stringValue
            let content = courseUpdate["content"].stringValue
            let courseAnnouncement = CourseAnnouncement(id: id, date: date, content: content)
            return courseAnnouncement
        }
        return .success(courseUpdates)
    }
    
    static func getAnnouncementsContent(_ courseId: String) -> NetworkRequest<[CourseAnnouncement]> {
        let path = "/api/mobile/v0.5/course_info/{course_id}/updates".oex_format(withParameters: ["course_id": courseId])
        return NetworkRequest(
            method: .GET,
            path: path,
            requiresAuth: true,
            deserializer: .jsonResponse(courseContentDeserializer)
        )
    }
    
}
