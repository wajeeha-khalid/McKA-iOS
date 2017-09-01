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
    let enviroment: RouterEnvironment
    var stream: edXCore.Stream<MCQResponseData>?

    public init(blockID: String, courseID: String, environment: RouterEnvironment) {
        self.blockID = blockID
        self.courseID = courseID
        self.enviroment = environment
    }
    
    public func matchMCQ(selectedValue: String, for questionId: String, completion: @escaping (Bool) -> Swift.Void) {
        self.stream = mcqResponseStream(questionId: questionId, value: selectedValue, courseId: self.courseID, blockId: self.blockID)
        self.stream?.listen(self, action: { (result) in
            
        result.ifSuccess({ (mcqResponseData: MCQResponseData) -> Void in
                completion(mcqResponseData.status)
            
            })
        
            result.ifFailure({ (error) in
                print(error.localizedDescription)
            })
        
        })
    }
}

extension MCQManager {

    func mcqResponseStream(questionId: String, value: String, courseId: String, blockId: String) -> edXCore.Stream<MCQResponseData> {
        let request = MCQAPI.getMCQResponse(questionId, value: value, courseId: courseId, blockId: blockId)
        return enviroment.networkManager.streamForRequest(request)
    }

}
