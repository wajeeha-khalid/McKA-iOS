//
//  MCQManager.swift
//  edX
//
//  Created by Shafqat Muneer on 8/26/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation
import MckinseyXBlocks

class MCQManager: ResultMatchingMCQ {
    let blockID: String
    let courseID: String
    
    public init(blockID: String, courseID: String) {
        self.blockID = blockID
        self.courseID = courseID
    }
    
    func matchMCQ(value: String, completion: @escaping (MCQResponse) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.50, execute: {
            //completion(true, nil)
            let mcqResponse = MCQResponse(success: true, tip: "TestingResponseTip", value: value)//(success: Bool, tip: String, value: String)
            completion(mcqResponse)
        })

    }
    
}
