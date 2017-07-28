//
//  UserPreferenceManager.swift
//  edX
//
//  Created by Kevin Kim on 7/28/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

open class UserPreferenceManager : NSObject {
    
    fileprivate let networkManager : NetworkManager
    fileprivate let preferencesFeed = BackedFeed<UserPreference?>()
    
    public init(networkManager : NetworkManager) {
        self.networkManager = networkManager
        
        super.init()
        
        addObservers()
    }
    
    open var feed: BackedFeed<UserPreference?> {
        return preferencesFeed
    }
    
    fileprivate func addObservers() {
  
        NotificationCenter.default.oex_addObserver(self, name: NSNotification.Name.OEXSessionEnded.rawValue) { (_, observer, _) in
            observer.clearFeed()
        }
        
        NotificationCenter.default.oex_addObserver(self, name: NSNotification.Name.OEXSessionStarted.rawValue) { (notification, observer, _) -> Void in
            if let userDetails = notification.userInfo?[OEXSessionStartedUserDetailsKey] as? OEXUserDetails {
                observer.setupFeedWithUserDetails(userDetails)
            }
        }
    }
    
    fileprivate func clearFeed() {
        let feed = Feed<UserPreference?> { stream in
            stream.removeAllBackings()
            stream.send(Success(nil))
        }
        
        preferencesFeed.backWithFeed(feed)
        preferencesFeed.refresh()
    }
    
    fileprivate func setupFeedWithUserDetails(_ userDetails: OEXUserDetails) {
        guard let username = userDetails.username else { return }
        let feed = freshFeedWithUsername(username)
        preferencesFeed.backWithFeed(feed.map{x in x})
        preferencesFeed.refresh()
    }
    
    fileprivate func freshFeedWithUsername(_ username: String) -> Feed<UserPreference> {
        let request = UserPreferenceAPI.preferenceRequest(username)
        return Feed(request: request, manager: networkManager, persistResponse: true)
    }
    
}
