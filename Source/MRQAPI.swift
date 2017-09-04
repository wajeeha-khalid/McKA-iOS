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
    
    static func mrqSubmitResponseDeserializer(_ response: HTTPURLResponse, json: JSON) -> Result<MRQResponse> {
        guard let mrqResponseDic = json.dictionary else {
            return .failure(NSError())
        }
        
        print(mrqResponseDic.description)

        var id = ""
        var questionCorrectStatus = false
        let message = mrqResponseDic[Fields.message]?.string ?? ""
        var choices : [Option] = []
        
        var results = mrqResponseDic[Fields.results]?.arrayValue
        results = results?[0].arrayValue
        if (results?.count ?? 0) >= 2 {
            id = (results?[0].stringValue) ?? ""
            
            if let optionResult = results?[1].dictionaryValue {
                if optionResult[Fields.status]?.stringValue == "correct" {
                    //correct
                    questionCorrectStatus = true
                }
                else {
                    //incorrect or partial
                    questionCorrectStatus = false
                }
                
                let choicesArray = (optionResult[Fields.choices]?.arrayValue)
                for choiceDic in choicesArray! {
                    let completed = choiceDic[Fields.completed].bool ?? false
                    let selected = choiceDic[Fields.selected].bool ?? false
                    let tip = choiceDic[Fields.tip].string ?? ""
                    let value = choiceDic[Fields.value].string ?? ""
                    
                    let option = Option(value: value, tip: tip, isSelected: selected, isCompleted: completed)
                    choices.append(option)
                }
            }
        }
        
        let mrqResponse = MRQResponse(id: id, completed: questionCorrectStatus, message: message, choicesStatus: choices)
        return .success(mrqResponse)
    }
    
    static func submitMRQ(questionId: String, values: [String], courseId: String, blockId: String) -> NetworkRequest<MRQResponse> {
        let path = "/courses/{course_id}/xblock/{block_id}/handler/submit".oex_format(withParameters: ["course_id": courseId, "block_id": blockId])
        let requestBody = [questionId: values]
        return NetworkRequest(method: .POST,
                              path: path,
                              requiresAuth: true,
                              body: .jsonBody(JSON(requestBody)),
                              deserializer: .jsonResponse(mrqSubmitResponseDeserializer)
        )
    }
}
