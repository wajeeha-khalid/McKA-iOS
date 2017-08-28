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

class MCQManager: ResultMatchingMCQ {
    let blockID: String
    let courseID: String
    let enviroment: RouterEnvironment
    var stream: edXCore.Stream<MCQResponse>?

    public init(blockID: String, courseID: String, environment: RouterEnvironment) {
        self.blockID = blockID
        self.courseID = courseID
        self.enviroment = environment 
    }
    
    func matchMCQ(value: String, completion: @escaping (MCQResponse) -> Void) {
        // TODO: call the method to get the stream on the basis of questionID and value of the option
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.50, execute: {
            //completion(true, nil)
            let mcqResponse = MCQResponse(success: true, tip: "TestingResponseTip", value: value)//(success: Bool, tip: String, value: String)
            completion(mcqResponse)
        })
    }
}

extension MCQManager {

    func mcqResponseStream(questionId: String, value: String, courseId: String, blockId: String) -> edXCore.Stream<MCQResponseData> {
        let request = MCQAPI.getMCQResponse(questionId, value: value, courseId: courseId, blockId: blockId)
        return enviroment.networkManager.streamForRequest(request)
    }

}

class MockMCQMatcher: ResultMatchingMCQ {
    func matchMCQ(value: String, completion: @escaping (MCQResponse) -> Void) {
        
    }
}

/*
 func freshFeedWithUsername(_ userID: Int, organizationCode: String?) -> Feed<[UserCourseEnrollment]> {
 let request = CoursesAPI.getUserEnrollments(userID, organizationCode: organizationCode)
 return Feed(request: request, manager: networkManager, persistResponse: true)
 }
 */
