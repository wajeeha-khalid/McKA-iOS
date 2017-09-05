//
//  FTManager.swift
//  edX
//
//  Created by Talha Babar on 8/29/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation
import edXCore
import MckinseyXBlocks

class FTManager: NSObject, FreeTextSubmissionProtocol {
    let blockID: String
    let courseID: String
    let enviroment: RouterEnvironment
    var stream: edXCore.Stream<FTResponseData>?
    
    public init(blockID: String, courseID: String, environment: RouterEnvironment) {
        self.blockID = blockID
        self.courseID = courseID
        self.enviroment = environment
    }

    public func submitFT(answer: String, forQuestion: String, completion: @escaping (Bool) -> Void) {
        self.stream = ftResponseStream(questionId: forQuestion, answer: answer, courseId: courseID, blockId: blockID)
        self.stream?.listen(self, action: { (result) in
            
            result.ifSuccess({ (ftResponseData) in
                completion(ftResponseData.completed)
            })
            
            result.ifFailure({ (error) in
                print(error.localizedDescription)
            })
        })
    }
}

extension FTManager {
    func ftResponseStream(questionId: String, answer: String, courseId: String, blockId: String) -> edXCore.Stream<FTResponseData> {
        let request = FTAPI.submitFT(questionId: questionId, answer: answer, courseId: courseId, blockId: blockId)
        return enviroment.networkManager.streamForRequest(request)
    }
}
