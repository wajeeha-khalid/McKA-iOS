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
    let networkManager: NetworkManager
    var stream: edXCore.Stream<MRQResponse>?
    
    public init(blockID: String, courseID: String, networkManager: NetworkManager) {
        self.blockID = blockID
        self.courseID = courseID
        self.networkManager = networkManager
    }
    
    func matchMRQ(selectedValues: [String], for questionID: String, completion: @escaping (MRQResponse) -> Void) {
        stream = mrqResponseStream(questionId: questionID, selectedValues: selectedValues, courseId: courseID, blockId: blockID)
        stream?.listen(self, action: { (result) in
            result.ifSuccess({ (mrqResponse: MRQResponse) -> Void in
                completion(mrqResponse)
            })
            result.ifFailure({ (error) in
                Logger.logInfo("MRQ", error.localizedDescription)
            })
        })
    }
}

extension MRQManager {
    func mrqResponseStream(questionId: String, selectedValues: [String], courseId: String, blockId: String) -> edXCore.Stream<MRQResponse> {
        let request = MRQAPI.submitMRQ(questionId: questionId, values: selectedValues, courseId: courseId, blockId: blockId)
        return self.networkManager.streamForRequest(request)
    }
}

