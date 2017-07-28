//
//  UserProfileManager.swift
//  edX
//
//  Created by Akiva Leffert on 10/28/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation


open class UserProfileManager : NSObject {
    
    fileprivate let networkManager : NetworkManager
    fileprivate let session: OEXSession
    fileprivate let currentUserFeed = BackedFeed<UserProfile>()
    fileprivate let currentUserUpdateStream = Sink<UserProfile>()
    fileprivate let cache = LiveObjectCache<Feed<UserProfile>>()
    
    public init(networkManager : NetworkManager, session : OEXSession) {
        self.networkManager = networkManager
        self.session = session
        
        super.init()
        
        self.currentUserFeed.backingStream.addBackingStream(currentUserUpdateStream)
        
        NotificationCenter.default.oex_addObserver(self, name: NSNotification.Name.OEXSessionEnded.rawValue) { (_, owner, _) -> Void in
            owner.sessionChanged()
        }
        NotificationCenter.default.oex_addObserver(self, name: NSNotification.Name.OEXSessionStarted.rawValue) { (_, owner, _) -> Void in
            owner.sessionChanged()
        }
        self.sessionChanged()
    }
    
    open func feedForUser(_ username : String) -> Feed<UserProfile> {
        return self.cache.objectForKey(username) {
            let request = ProfileAPI.profileRequest(username)
            return Feed(request: request, manager: self.networkManager)
        }
    }
    
    fileprivate func sessionChanged() {
        if let username = self.session.currentUser?.username {
            self.currentUserFeed.backWithFeed(self.feedForUser(username))
        }
        else {
            self.currentUserFeed.removeBacking()
            // clear the stream
            self.currentUserUpdateStream.send(NSError.oex_unknownError())
        }
        if self.session.currentUser == nil {
            self.cache.empty()
        }
    }
    
    // Feed that updates if the current user changes
    open func feedForCurrentUser() -> Feed<UserProfile> {
        return currentUserFeed
    }
    
    open func updateCurrentUserProfile(_ profile : UserProfile, handler : @escaping (Result<UserProfile>) -> Void) {
        let request = ProfileAPI.profileUpdateRequest(profile)
        self.networkManager.taskForRequest(request) { result -> Void in
            if let data = result.data {
                self.currentUserUpdateStream.send(Success(data))
            }
            handler(result.data.toResult(result.error))
        }
    }
}
