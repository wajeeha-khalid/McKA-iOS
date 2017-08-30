//
//  FTAPI.swift
//  edX
//
//  Created by Talha Babar on 8/29/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation
import edXCore
import SwiftyJSON
import MckinseyXBlocks

class FTResponseData: NSObject {
    struct Keys {
        static let id = "id"
        static let value = "student_input"
        static let completed = "completed"
        static let status = "status"
    }
    
    let id: String
    let value: String
    let status: String
    let completed: Bool
    
    init(id: String, value: String, status: String, completed: Bool) {
        self.id = id
        self.value = value
        self.status = status
        self.completed = completed
    }
    init?(dictionary: [String: Any]) {
        self.id = dictionary[Keys.id] as? String ?? ""
        self.value = dictionary[Keys.value] as? String ?? ""
        self.status = dictionary[Keys.status] as? String ?? ""
        self.completed = dictionary[Keys.completed] as? Bool ?? false
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

struct FTAPI {
    enum Fields: String, RawStringExtractable {
        case completed = "completed"
//        case message = "message"
        case results = "results"
        case value = "student_input"
        case status = "status"
    }
    
    static func ftSubmitResponseDeserializer(_ response: HTTPURLResponse, json: JSON) -> Result<FTResponseData> {
        guard let ftResponseDic = json.dictionary else {
            return .failure(NSError())
        }
        
        var id = ""
        let completed = ftResponseDic[Fields.completed]?.bool ?? false
        var status = ""
        var value = ""
//        let message = mrqResponseDic[Fields.message]?.string ?? ""
        
        let results = ftResponseDic[Fields.results]?.arrayValue
        if (results?.count ?? 0) >= 2 {
            id = (results?[0].stringValue) ?? ""
            
            if let ftResult = results?[1].dictionaryValue {
                status = ftResult[Fields.status]?.stringValue ?? ""
                value = ftResult[Fields.value]?.stringValue ?? ""
            }
        }
        
        let ftResponse = FTResponseData(id: id, value: value, status: status, completed: completed)
        return .success(ftResponse)
    }
    
    static func submitFT(questionId: String, answer: String, courseId: String, blockId: String) -> NetworkRequest<FTResponseData> {
        let path = "/courses/{course_id}/xblock/{block_id}".oex_format(withParameters: ["course_id": courseId, "block_id": blockId])
        let answerDic = ["value": answer]
        let requestBody = [questionId: answerDic]
        return NetworkRequest(method: .POST,
                              path: path,
                              requiresAuth: true,
                              body: .jsonBody(JSON(requestBody)),
                              deserializer: .jsonResponse(ftSubmitResponseDeserializer)
        )
    }
}



