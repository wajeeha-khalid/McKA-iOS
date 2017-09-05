//
//  MCQManager.swift
//  edX
//
//  Created by Shafqat Muneer on 8/26/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation
import edXCore
import MckinseyXBlocks

class MCQManager: NSObject, MCQResultMatching {
    let blockID: String
    let courseID: String
    let networkManager: NetworkManager
    var stream: edXCore.Stream<MCQResponse>?

    public init(blockID: String, courseID: String, networkManager: NetworkManager) {
        self.blockID = blockID
        self.courseID = courseID
        self.networkManager = networkManager
    }
    
    public func matchMCQ(selectedValue: String, for questionId: String, completion: @escaping (Bool) -> Swift.Void) {
        stream = mcqResponseStream(questionId: questionId, value: selectedValue, courseId: self.courseID, blockId: self.blockID)
        stream?.listen(self, action: { (result) in
            
        result.ifSuccess({ (mcqResponseData: MCQResponse) -> Void in
                completion(mcqResponseData.status)
            })
            result.ifFailure({ (error) in
                Logger.logInfo("MCQ", error.localizedDescription)
            })
        })
    }
}

extension MCQManager {

    func mcqResponseStream(questionId: String, value: String, courseId: String, blockId: String) -> edXCore.Stream<MCQResponse> {
        let request = MCQAPI.getMCQResponse(questionId, value: value, courseId: courseId, blockId: blockId)
        return self.networkManager.streamForRequest(request)
    }

}
