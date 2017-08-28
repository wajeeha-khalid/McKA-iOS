//
//  MRQManager.swift
//  edX
//
//  Created by Shafqat Muneer on 8/26/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation
import MckinseyXBlocks

class MRQManager: ResultMatching {
    func matchMRQ(selectedValues: [String], for questionID: String, completion: @escaping (MRQResponse) -> Void) {
        
    }

    let blockID: String
    let courseID: String
    
    public init(blockID: String, courseID: String) {
        self.blockID = blockID
        self.courseID = courseID
    }
    
//    public func match(selectedOptions: [String], for question: String, completion: @escaping (Bool, Error?) -> Swift.Void) {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.50, execute: {
//            completion(true, nil)
////            let mcqResponse = MCQResponse(success: true, tip: "TestingResponseTip", value: value)//(success: Bool, tip: String, value: String)
//        })
//    }
}
    
