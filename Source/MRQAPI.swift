//
//  MRQAPI.swift
//  edX
//
//  Created by Shafqat Muneer on 8/26/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation
import edXCore
import SwiftyJSON
import MckinseyXBlocks

struct MRQAPI {
    enum Fields: String, RawStringExtractable {
        case completed = "completed"
        case message = "message"
        case results = "results"
        case choices = "choices"
        case selected = "selected"
        case tip = "tips"
        case value = "value"
        case status = "status"
    }
    
    static func deserializerResponse(_ response: HTTPURLResponse, json: JSON) -> Result<MRQResponse> {
        guard let mrqResponseDic = json.dictionary else {
            return .failure(NSError())
        }
        
        Logger.logInfo("MRQ", mrqResponseDic.description)

        var id = ""
        var questionCorrectStatus = false
        let message = mrqResponseDic[Fields.message]?.stringValue
        
        guard let result = mrqResponseDic[Fields.results]?.arrayValue.first?.arrayValue,
            result.count >= 2  else {
                let mrqResponse = MRQResponse(id: id, completed: questionCorrectStatus, message: message!, choicesStatus: [])
                return .success(mrqResponse)
        }
        id = result[0].stringValue
        let optionResult = result[1].dictionaryValue
        questionCorrectStatus = optionResult[Fields.status]?.stringValue == "correct"
        let choicesArray = (optionResult[Fields.choices]?.arrayValue)
        let choices: [Option] = choicesArray.map { (array: [JSON]) in
            array.map { choiceDic in
                let completed = choiceDic[Fields.completed].boolValue
                let selected = choiceDic[Fields.selected].boolValue
                let tip = choiceDic[Fields.tip].stringValue
                let value = choiceDic[Fields.value].stringValue
                
                return Option(value: value, tip: tip, isSelected: selected, isCompleted: completed)

            }
        } ?? []
        
        let mrqResponse = MRQResponse(id: id, completed: questionCorrectStatus, message: message!, choicesStatus: choices)
        return .success(mrqResponse)
    }
    
    static func submitMRQ(questionId: String, values: [String], courseId: String, blockId: String) -> NetworkRequest<MRQResponse> {
        let path = "/courses/{course_id}/xblock/{block_id}/handler/submit".oex_format(withParameters: ["course_id": courseId, "block_id": blockId])
        let requestBody = [questionId: values]
        return NetworkRequest(method: .POST,
                              path: path,
                              requiresAuth: true,
                              body: .jsonBody(JSON(requestBody)),
                              deserializer: .jsonResponse(deserializerResponse)
        )
    }
}
