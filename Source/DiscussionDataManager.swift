//
//  DiscussionDataManager.swift
//  edX
//
//  Created by Akiva Leffert on 7/29/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

open class DiscussionDataManager : NSObject {
    fileprivate let topicStream = BackedStream<[DiscussionTopic]>()
    fileprivate let courseID : String
    fileprivate let networkManager : NetworkManager?
    
    public init(courseID : String, networkManager : NetworkManager?) {
        self.courseID = courseID
        self.networkManager = networkManager
    }
    
    public init(courseID : String, topics : [DiscussionTopic]) {
        self.courseID = courseID
        self.networkManager = nil
        self.topicStream.backWithStream(edXCore.Stream(value: topics))
    }
    
    open var topics : edXCore.Stream<[DiscussionTopic]> {
        if topicStream.value == nil && !topicStream.active {
            let request = DiscussionAPI.getCourseTopics(courseID)
            if let stream = networkManager?.streamForRequest(request, persistResponse: true, autoCancel: false) {
                topicStream.backWithStream(stream)
            }
        }
        return topicStream
    }
    
    /// This signals changes when a response is added
    open let commentAddedStream = Sink<(threadID : String, comment : DiscussionComment)>()
    
    /// This signals changes when a post is read
    open let postReadStream = Sink<(postID : String, read : Bool)>()
    
}
