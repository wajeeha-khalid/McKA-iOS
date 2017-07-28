//
//  EnrollmentManager.swift
//  edX
//
//  Created by Akiva Leffert on 12/26/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

open class EnrollmentManager : NSObject {
    fileprivate let interface: OEXInterface?
    fileprivate let networkManager : NetworkManager
    fileprivate let enrollmentFeed = BackedFeed<[UserCourseEnrollment]?>()
    fileprivate let config: OEXConfig
    
    public init(interface: OEXInterface?, networkManager: NetworkManager, config: OEXConfig) {
        self.interface = interface
        self.networkManager = networkManager
        self.config = config
        
        super.init()
        
        NotificationCenter.default.oex_addObserver( self, name: NSNotification.Name.OEXSessionEnded.rawValue) { (_, observer, _) in
            observer.clearFeed()
        }
        
        NotificationCenter.default.oex_addObserver( self, name: NSNotification.Name.OEXSessionStarted.rawValue) { (notification, observer, _) -> Void in
            
            if let userDetails = notification.userInfo?[OEXSessionStartedUserDetailsKey] as? OEXUserDetails {
                observer.setupFeedWithUserDetails(userDetails)
            }
        }
        
        // Eventutally we should remove responsibility for knowing about the course list
        // from OEXInterface and remove these
        feed.output.listen(self) {[weak self] enrollments in
            enrollments.ifSuccess {
                let courses = $0?.flatMap { $0.course } ?? []
                self?.interface?.setRegisteredCourses(courses)
                self?.interface?.deleteUnregisteredItems()
                self?.interface?.courses = $0 ?? []
            }
        }
    }
    
    open var feed: Feed<[UserCourseEnrollment]?> {
        return enrollmentFeed
    }
    
    open func enrolledCourseWithID(_ courseID: String) -> UserCourseEnrollment? {
        return self.streamForCourseWithID(courseID).value
    }
    
    open func streamForCourseWithID(_ courseID: String) -> edXCore.Stream<UserCourseEnrollment> {
        let hasCourse = enrollmentFeed.output.value??.contains {
            $0.course.course_id == courseID
            } ?? false
        
        if !hasCourse {
            enrollmentFeed.refresh()
        }
        
        let courseStream = feed.output.flatMap(fireIfAlreadyLoaded: hasCourse || !enrollmentFeed.output.active) { enrollments in
            return enrollments.toResult().flatMap { enrollments -> Result<UserCourseEnrollment> in
                let courseEnrollment = enrollments.firstObjectMatching {
                    return $0.course.course_id == courseID
                }
                return courseEnrollment.toResult()
            }
        }
        
        return courseStream
    }
    
    fileprivate func clearFeed() {
        let feed = Feed<[UserCourseEnrollment]?> { stream in
            stream.removeAllBackings()
            stream.send(Success(nil))
        }
        self.enrollmentFeed.backWithFeed(feed)
        
        self.enrollmentFeed.refresh()
    }
    
    fileprivate func setupFeedWithUserDetails(_ userDetails: OEXUserDetails) {
        guard let userId = userDetails.userId?.intValue else {
                return
        }
        let organizationCode = self.config.organizationCode()
        let feed = freshFeedWithUsername(userId, organizationCode: organizationCode)
        enrollmentFeed.backWithFeed(feed.map {x in x})
        enrollmentFeed.refresh()
    }
    
    func freshFeedWithUsername(_ userID: Int, organizationCode: String?) -> Feed<[UserCourseEnrollment]> {
        let request = CoursesAPI.getUserEnrollments(userID, organizationCode: organizationCode)
        return Feed(request: request, manager: networkManager, persistResponse: true)
    }
}
