//
//  DiscussionResponsesDataController.swift
//  edX
//
//  Created by Saeed Bashir on 2/24/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

class DiscussionResponsesDataController: NSObject {
 
    var responses: [DiscussionComment] = []
    var endorsedResponses: [DiscussionComment] = []
    
    /// "Given a new comment, looks through responses and increments the childCount of the parent of that comment."
    func addedChildComment(_ comment: DiscussionComment) {
        for i in 0 ..< responses.count {
            if responses[i].commentID == comment.parentID {
                responses[i].childCount += 1
                break
            }
        }
        
        for i in 0..<endorsedResponses.count {
            if endorsedResponses[i].commentID == comment.parentID {
                endorsedResponses[i].childCount += 1
                break
            }
        }
    }

    /// "Given a new comment, looks through responses and update vote information of that comment."
    func updateResponsesWithComment(_ comment : DiscussionComment) {
        for i in 0 ..< responses.count {
            if responses[i].commentID == comment.commentID {
                responses[i] = comment
            }
        }
        
        for i in 0..<endorsedResponses.count {
            
            if endorsedResponses[i].commentID == comment.commentID {
                endorsedResponses[i] = comment
            }
        }
    }
}
