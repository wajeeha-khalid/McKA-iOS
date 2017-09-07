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

class FTManager: NSObject, FreeTextAPIProtocol {
    let blockID: String
    let courseID: String
    let enviroment: RouterEnvironment
    var submissionStream: edXCore.Stream<FreeTextSubmissionResponseData>?
    var completionStream: edXCore.Stream<FreeTextCompletedAnswerResponseData>?
    
    public init(blockID: String, courseID: String, environment: RouterEnvironment) {
        self.blockID = blockID
        self.courseID = courseID
        self.enviroment = environment
    }

    public func submitFT(answer: String, forQuestion: String, completion: @escaping (Bool) -> Void) {
        self.submissionStream = ftSubmitResponseStream(questionId: forQuestion, answer: answer, courseId: courseID, blockId: blockID)
        self.submissionStream?.listen(self, action: { (result) in
            
            result.ifSuccess({ (ftResponseData) in
                completion(ftResponseData.completed)
            })
            
            result.ifFailure({ (error) in
                print(error.localizedDescription)
            })
        })
    }
    
    public func getCompletedAnswerFT(completion: @escaping (FTCompletedAnswer?, Bool) -> Void) {
        self.completionStream = ftGetCompletedAnswerStream(courseId: courseID, blockId: blockID)
        self.completionStream?.listen(self, action: { (result) in
            
            result.ifSuccess({ (ftCompletedAnswerResponseData) in
                let completedAnswer = FTCompletedAnswer(attempted: ftCompletedAnswerResponseData.attempted, completed: ftCompletedAnswerResponseData.completed, answer: ftCompletedAnswerResponseData.answer)
                completion(completedAnswer, ftCompletedAnswerResponseData.completed)
            })
            
            result.ifFailure({ (error) in
                print(error.localizedDescription)
            })
        })
    }
}

extension FTManager {
    func ftSubmitResponseStream(questionId: String, answer: String, courseId: String, blockId: String) -> edXCore.Stream<FreeTextSubmissionResponseData> {
        let request = FTAPI.submitFT(questionId: questionId, answer: answer, courseId: courseId, blockId: blockId)
        return enviroment.networkManager.streamForRequest(request)
    }
    
    func ftGetCompletedAnswerStream(courseId: String, blockId: String) -> edXCore.Stream<FreeTextCompletedAnswerResponseData> {
        let request = FTAPI.getCompletedAnswer(courseId: courseId, blockId: blockId)
        return enviroment.networkManager.streamForRequest(request)
    }
}
