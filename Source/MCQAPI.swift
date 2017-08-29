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

struct MCQAPI {
    struct Keys {
        static let completed = "completed"
        static let value = "submission"
        static let tip = "tips"
        static let results = "results"
    }

    static func mcqResponseDeserializer(_ response: HTTPURLResponse, json: JSON) -> Result<Bool> {

        //TODO: Need to implement the mapping of response to MCQResponseData and send the response for MCQResponse
       guard let mcqResponse = json.dictionary else {
            return .failure(NSError())
        }
        
        let isCompleted = mcqResponse[Keys.completed]?.boolValue ?? false
        
        return .success(isCompleted)
    }
    
    static func getMCQResponse(_ questionId: String, value: String, courseId: String, blockId: String) -> NetworkRequest<Bool> {
        let path = "/courses/{course_id}/xblock/{block_id}".oex_format(withParameters: ["course_id": courseId, "block_id": blockId])
        let requestBody = [questionId: ["value": value]]
        return NetworkRequest(method: .GET,
                       path: path,
                       requiresAuth: true,
                       body: .jsonBody(JSON(requestBody)),
                       deserializer: .jsonResponse(mcqResponseDeserializer)
        )
    }
}
