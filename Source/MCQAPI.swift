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
        static let status = "completed"
        static let tip = "tips"
    }

    let id: String
    let value: String
    let status: Bool
    let tip: String
    
    init(id: String, value: String, status: Bool, tip: String) {
        self.id = id
        self.value = value
        self.status = status
        self.tip = tip
    }
    init?(dictionary: [String: Any]) {
        self.id = dictionary[Keys.id] as? String ?? ""
        self.value = dictionary[Keys.value] as? String ?? ""
        self.status = dictionary[Keys.status] as? Bool ?? false
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
    struct Keys {
        static let completed = "completed"
        static let value = "submission"
        static let tip = "tips"
        static let results = "results"
    }

    static func mcqResponseDeserializer(_ response: HTTPURLResponse, json: JSON) -> Result<MCQResponseData> {

        //TODO: Need to implement the mapping of response to MCQResponseData and send the response for MCQResponse
       guard let mcqResponse = json.dictionary else {
            return .failure(NSError())
        }
        
        print(mcqResponse.description)
        
        let isCompleted = mcqResponse[Keys.completed]?.boolValue ?? false
        var id: String = ""
        var value: String = ""
        var tip: String = ""
        
        let results = mcqResponse[Keys.results]?.arrayValue
        if (results?.count ?? 0) >= 2 {
            id = (results?[0].stringValue) ?? ""
            if let optionResult = results?[1].dictionaryValue {
                value = (optionResult[Keys.value]?.stringValue) ?? ""
                tip = (optionResult[Keys.value]?.stringValue) ?? ""
            }
        }
        
        let mcqResponseData = MCQResponseData(id: id, value: value, status: isCompleted, tip: tip)
        return .success(mcqResponseData)
    }
    
    static func getMCQResponse(_ questionId: String, value: String, courseId: String, blockId: String) -> NetworkRequest<MCQResponseData> {
        let path = "/courses/{course_id}/xblock/{block_id}/handler/submit".oex_format(withParameters: ["course_id": courseId, "block_id": blockId])
        let requestBody = [questionId: ["value": value]]
        return NetworkRequest(method: .POST,
                       path: path,
                       requiresAuth: true,
                       body: .jsonBody(JSON(requestBody)),
                       deserializer: .jsonResponse(mcqResponseDeserializer)
        )
    }
}
