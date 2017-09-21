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

struct MCQResponse {
    struct Keys {
        static let id = "id"
        static let value = "submission"
        static let status = "completed"
        static let tip = "tips"
        static let message = "message"
    }

    let id: String
    let value: String
    let status: Bool
    let tip: String
    let message: String?
    
    init(id: String, value: String, status: Bool, tip: String, message: String) {
        self.id = id
        self.value = value
        self.status = status
        self.tip = tip
        self.message = message
    }
    init?(dictionary: [String: Any]) {
        guard let id = dictionary[Keys.id] as? String,
        let value = dictionary[Keys.value] as? String,
        let status = dictionary[Keys.status] as? Bool,
        let tip = dictionary[Keys.tip] as? String else {
            return nil
        }
        let message = dictionary[Keys.message] as? String ?? ""
        
        self.id = id
        self.value = value
        self.status = status
        self.tip = tip
        self.message = message
    }
    
    init?(json: JSON) {
        let array = json.arrayValue
        
        guard array.count >= 2, var dictionary = json.dictionaryObject else {
            return nil
        }
        let id = array[0].stringValue
        dictionary[Keys.id] = id
        self.init(dictionary: dictionary)
    }
}

struct MCQAPI {
    struct Keys {
        static let completed = "completed"
        static let value = "submission"
        static let tip = "tips"
        static let results = "results"
        static let status = "status"
        static let message = "message"
    }

    static func deserializerResponse(_ response: HTTPURLResponse, json: JSON) -> Result<MCQResponse> {
       guard let mcqResponse = json.dictionary else {
            return .failure(NSError())
        }
        
        Logger.logInfo("MCQ", mcqResponse.description)
        
        var questionCorrectStatus = false
        var id: String = ""
        var value: String = ""
        var tip: String = ""
        let message = json[Keys.message].stringValue
        guard let result = mcqResponse[Keys.results]?.arrayValue.first?.arrayValue,
            result.count >= 2  else {
                let mcqResponseData = MCQResponse(id: id, value: value, status: questionCorrectStatus, tip: tip, message: message)
                return .success(mcqResponseData)
        }
        id = result[0].stringValue
        let optionResult = result[1].dictionaryValue
        questionCorrectStatus = optionResult[Keys.status]?.stringValue == "correct"
        value = (optionResult[Keys.value]?.stringValue) ?? ""
        tip = (optionResult[Keys.value]?.stringValue) ?? ""
        
        let mcqResponseData = MCQResponse(id: id, value: value, status: questionCorrectStatus, tip: tip, message: message)
        return .success(mcqResponseData)
    }
    
    static func getMCQResponse(_ questionId: String, value: String, courseId: String, blockId: String) -> NetworkRequest<MCQResponse> {
        let path = "/courses/{course_id}/xblock/{block_id}/handler/submit".oex_format(withParameters: ["course_id": courseId, "block_id": blockId])
        let requestBody = [questionId: ["value": value]]
        return NetworkRequest(method: .POST,
                       path: path,
                       requiresAuth: true,
                       body: .jsonBody(JSON(requestBody)),
                       deserializer: .jsonResponse(deserializerResponse)
        )
    }
}
