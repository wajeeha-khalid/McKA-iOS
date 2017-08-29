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
    var stream: edXCore.Stream<Bool>?

    public init(blockID: String, courseID: String, environment: RouterEnvironment) {
        self.blockID = blockID
        self.courseID = courseID
        self.enviroment = environment
    }
    
    public func matchMCQ(questionId: String, value: String, completion: @escaping (Bool) -> Swift.Void) {
        // TODO: call the method to get the stream on the basis of questionID and value of the option
//        self.stream = mcqResponseStream(questionId: questionId, value: value, courseId: self.courseID, blockId: self.blockID)
//        self.stream?.listen(self, action: { (result) in
//        result.ifSuccess({ (success: Bool) -> Void in
//                completion(success)
//            })
//        
//            result.ifFailure({ (error) in
//                print(error.localizedDescription)
//            })
//        })
        completion(false)
    }
}

extension MCQManager {

    func mcqResponseStream(questionId: String, value: String, courseId: String, blockId: String) -> edXCore.Stream<Bool> {
        let request = MCQAPI.getMCQResponse(questionId, value: value, courseId: courseId, blockId: blockId)
        return enviroment.networkManager.streamForRequest(request)
    }

}

class MockMCQMatcher: MCQResultMatching {
    public func matchMCQ(questionId: String, value: String, completion: @escaping (Bool) -> Swift.Void) {
        
    }
}

/*
 func freshFeedWithUsername(_ userID: Int, organizationCode: String?) -> Feed<[UserCourseEnrollment]> {
 let request = CoursesAPI.getUserEnrollments(userID, organizationCode: organizationCode)
 return Feed(request: request, manager: networkManager, persistResponse: true)
 }
 */
