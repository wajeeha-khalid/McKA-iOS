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

class FTManager: NSObject, FTSubmission {
    let blockID: String
    let courseID: String
    let enviroment: RouterEnvironment
    var stream: edXCore.Stream<FTResponseData>?
    
    public init(blockID: String, courseID: String, environment: RouterEnvironment) {
        self.blockID = blockID
        self.courseID = courseID
        self.enviroment = environment
    }
    
    func submitFT(questionId: String, answer: String, completion: @escaping (Bool) -> Void) {
        stream = ftResponseStream(questionId: questionId, answer: answer, courseId: courseID, blockId: blockID)
        //        self.stream?.listen(self, action: { (result) in
        //            result.ifSuccess({ (mrqResponse: MRQResponse) -> Void in
        //                completion(mrqResponse)
        //            })
        //            result.ifFailure({ (error) in
        //                print(error.localizedDescription)
        //            })
        //        })
        
        //MARK: Mock Data
//        let mrqResponseChoiceStatus = [Option(value: "Test Value1", tip: "Its Tip 1", isSelected: true, isCompleted: true),
//                                       Option(value: "Test Value2", tip: "Its Tip 2", isSelected: false, isCompleted: false),
//                                       Option(value: "Test Value3", tip: "Its Tip 3", isSelected: true, isCompleted: true),
//                                       Option(value: "Test Value4", tip: "Its Tip 4", isSelected: true, isCompleted: true)
//        ]
//        let mrqResponse = MRQResponse(id: "123", completed: false, message: "Its message string", choicesStatus: mrqResponseChoiceStatus)
        
        let ftResponse = FTResponseData(id: "123", value: "This is answer", status: "Correct", completed: true)
        completion(true)
    }
}

extension FTManager {
    func ftResponseStream(questionId: String, answer: String, courseId: String, blockId: String) -> edXCore.Stream<FTResponseData> {
        let request = FTAPI.submitFT(questionId: questionId, answer: answer, courseId: courseId, blockId: blockId)
        return enviroment.networkManager.streamForRequest(request)
    }
}
