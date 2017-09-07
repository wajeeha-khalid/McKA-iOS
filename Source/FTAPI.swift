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

class FreeTextSubmissionResponseData: NSObject {
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

class FreeTextCompletedAnswerResponseData: NSObject {
    struct Keys {
        static let attempted = "attempted"
        static let answer = "student_input"
        static let completed = "completed"
    }
    
    let attempted: Bool
    let answer: String
    let completed: Bool
    
    init(attempted: Bool, answer: String, completed: Bool) {
        self.attempted = attempted
        self.answer = answer
        self.completed = completed
    }
    
    init?(dictionary: [String: Any]) {
        self.attempted = dictionary[Keys.attempted] as? Bool ?? false
        self.answer = dictionary[Keys.answer] as? String ?? ""
        self.completed = dictionary[Keys.completed] as? Bool ?? false
        super.init()
    }
    
    convenience init?(json: JSON) {
        let responseDic = json.dictionary
        var answerDic: [String:Any] = [:]
        answerDic[Keys.attempted] = responseDic?[Keys.attempted]?.boolValue
        answerDic[Keys.attempted] = responseDic?[Keys.completed]?.boolValue
        
        guard let components = responseDic?["components"]?.dictionary else {
            self.init(dictionary: answerDic)
            return nil
        }
        
        guard components.count > 0 else {
            self.init(dictionary: answerDic)
            return nil
        }
        
        guard let xBlockDic = components[components.keys.first!]?.dictionary else {
            self.init(dictionary: answerDic)
            return nil
        }
        
        
        guard let answerDataDic = xBlockDic["answer_data"]?.dictionary else {
            self.init(dictionary: answerDic)
            return nil
        }
        
        answerDic[Keys.answer] = answerDataDic[Keys.answer]?.string ?? ""
        self.init(dictionary: answerDic)
    }
}

struct FTAPI {
    enum Fields: String, RawStringExtractable {
        case completed = "completed"
        case results = "results"
        case value = "student_input"
        case status = "status"
        case components = "components"
        case answerData = "answer_data"
        case attempted = "attempted"
    }
    
    static func ftSubmitResponseDeserializer(_ response: HTTPURLResponse, json: JSON) -> Result<FreeTextSubmissionResponseData> {
        guard let freeTextResponseDic = json.dictionary else {
            return .failure(NSError())
        }
        
        var id = ""
        let completed = freeTextResponseDic[Fields.completed]?.bool ?? false
        var status = ""
        var value = ""
        
        let results = freeTextResponseDic[Fields.results]?.arrayValue.first?.arrayValue
        if (results?.count ?? 0) >= 2 {
            id = (results?[0].stringValue) ?? ""
            
            if let freeTextResult = results?[1].dictionaryValue {
                status = freeTextResult[Fields.status]?.stringValue ?? ""
                value = freeTextResult[Fields.value]?.stringValue ?? ""
            }
        } else {
            return .failure(NSError())
        }
        
        let ftResponse = FreeTextSubmissionResponseData(id: id, value: value, status: status, completed: completed)
        return .success(ftResponse)
    }
    
    static func submitFT(questionId: String, answer: String, courseId: String, blockId: String) -> NetworkRequest<FreeTextSubmissionResponseData> {
        let path = "/courses/{course_id}/xblock/{block_id}/handler/submit".oex_format(withParameters: ["course_id": courseId, "block_id": blockId])
        let requestBody = [questionId: ["value": answer]]
        return NetworkRequest(method: .POST,
                              path: path,
                              requiresAuth: true,
                              body: .jsonBody(JSON(requestBody)),
                              deserializer: .jsonResponse(ftSubmitResponseDeserializer)
        )
    }
    
    static func ftCompletedAnswerResponseDeserializer(_ response: HTTPURLResponse, json: JSON) -> Result<FreeTextCompletedAnswerResponseData> {
        guard let freeTextResponseDic = json.dictionary else {
            return .failure(NSError())
        }
        
        let attempted = freeTextResponseDic[Fields.attempted]?.boolValue
        let completed = freeTextResponseDic[Fields.completed]?.boolValue
        var answer = ""
        
        guard let components = freeTextResponseDic[Fields.components]?.dictionary else {
            return .failure(NSError())
        }
        
        guard components.count > 0 else {
            return .failure(NSError())
        }
        
        guard let xBlockDic = components[components.keys.first!]?.dictionary else {
            return .failure(NSError())
        }
        
        
        guard let answerDataDic = xBlockDic[Fields.answerData]?.dictionary else {
            return .failure(NSError())
        }
        
        answer = answerDataDic[Fields.value]?.string ?? ""
        let ftResponse = FreeTextCompletedAnswerResponseData(attempted: attempted!, answer: answer, completed: completed!)
        return .success(ftResponse)
    }
    
    static func getCompletedAnswer(courseId: String, blockId: String) -> NetworkRequest<FreeTextCompletedAnswerResponseData> {
        let path = "courses/{course_id}/xblock/{block_id}/handler/student_view_user_state".oex_format(withParameters: ["course_id": courseId, "block_id": blockId])
        return NetworkRequest(method: .GET,
                              path: path,
                              requiresAuth: true,
                              deserializer: .jsonResponse(ftCompletedAnswerResponseDeserializer)
        )
    }
}



