//
//  CourseDataManager.swift
//  edX
//
//  Created by Akiva Leffert on 5/6/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

open class CourseDataManager: NSObject {
    
    fileprivate let analytics : OEXAnalytics
    fileprivate let interface : OEXInterface?
    fileprivate let enrollmentManager: EnrollmentManager
    fileprivate let session : OEXSession
    fileprivate let networkManager : NetworkManager
    fileprivate let outlineQueriers = LiveObjectCache<CourseOutlineQuerier>()
    fileprivate let discussionDataManagers = LiveObjectCache<DiscussionDataManager>()
    
    public init(analytics: OEXAnalytics, enrollmentManager: EnrollmentManager, interface : OEXInterface?, networkManager : NetworkManager, session : OEXSession) {
        self.analytics = analytics
        self.enrollmentManager = enrollmentManager
        self.interface = interface
        self.networkManager = networkManager
        self.session = session
        
        super.init()
        
        NotificationCenter.default.oex_addObserver(self, name: NSNotification.Name.OEXSessionEnded.rawValue) { (_, observer, _) -> Void in
            observer.outlineQueriers.empty()
            observer.discussionDataManagers.empty()
        }
    }
    
    open func querierForCourseWithID(_ courseID : String) -> CourseOutlineQuerier {
        return outlineQueriers.objectForKey(courseID) {
            let querier = CourseOutlineQuerier(courseID: courseID, interface : interface, enrollmentManager: enrollmentManager, networkManager : networkManager, session : session)
            return querier
        }
    }
    
    open func discussionManagerForCourseWithID(_ courseID : String) -> DiscussionDataManager {
        return discussionDataManagers.objectForKey(courseID) {
            let manager = DiscussionDataManager(courseID: courseID, networkManager: self.networkManager)
            return manager
        }
    }
    
    func streamForCourseContent(_ courseID: String) -> edXCore.Stream<[CourseContent]> {
        let request = ResourseAPI.getCourseContent(courseID, username: session.currentUser?.username ?? "")
        return networkManager.streamForRequest(request)
    }
    
    func streamForCourseAnnouncements(_ courseID: String) -> edXCore.Stream<[CourseAnnouncement]> {
        let request = AnnouncementsAPI.getAnnouncementsContent(courseID)
        return networkManager.streamForRequest(request)
    }
    
}
