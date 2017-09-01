//
//  MRQManager.swift
//  edX
//
//  Created by Shafqat Muneer on 8/26/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation
import edXCore
import MckinseyXBlocks

class MRQManager: NSObject, MRQResultMatching {
    let blockID: String
    let courseID: String
    let enviroment: RouterEnvironment
    var stream: edXCore.Stream<MRQResponse>?
    
    public init(blockID: String, courseID: String, environment: RouterEnvironment) {
        self.blockID = blockID
        self.courseID = courseID
        self.enviroment = environment
    }
    
    func matchMRQ(selectedValues: [String], for questionID: String, completion: @escaping (MRQResponse) -> Void) {
        // TODO: call the method to get the stream on the basis of questionID and values of the options
        self.stream = mrqResponseStream(questionId: questionID, selectedValues: selectedValues, courseId: courseID, blockId: blockID)
        self.stream?.listen(self, action: { (result) in
            result.ifSuccess({ (mrqResponse: MRQResponse) -> Void in
                completion(mrqResponse)
            })
            result.ifFailure({ (error) in
                print(error.localizedDescription)
            })
        })
        
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
//            //MARK: Mock Data
//            let mrqResponseChoiceStatus = [Option(value: "Test Value1", tip: "Its Tip 1", isSelected: true, isCompleted: true),
//                                           Option(value: "Test Value2", tip: "Its Tip 2", isSelected: false, isCompleted: false),
//                                           Option(value: "Test Value3", tip: "Its Tip 3", isSelected: true, isCompleted: true),
//                                           Option(value: "Test Value4", tip: "Its Tip 4", isSelected: true, isCompleted: true)
//            ]
//            let mrqResponse = MRQResponse(id: "123", completed: false, message: "<p><b>Click each green check mark or red ! to read feedback.</b></p> <p>An ! shows that you were not right, either incorrectly selecting an item or incorrectly excluding it.</p> <p><i>Click <b>Next Question </b>to advance or click<b> Review final grade</b> to return to your results summary.</i></p>", choicesStatus: mrqResponseChoiceStatus)
//            
//            completion(mrqResponse)
//        })
    }
}

extension MRQManager {
    func mrqResponseStream(questionId: String, selectedValues: [String], courseId: String, blockId: String) -> edXCore.Stream<MRQResponse> {
        let request = MRQAPI.submitMRQ(questionId: questionId, values: selectedValues, courseId: courseId, blockId: blockId)
        return enviroment.networkManager.streamForRequest(request)
    }
}

