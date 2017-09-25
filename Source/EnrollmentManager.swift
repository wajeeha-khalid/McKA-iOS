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
    fileprivate let enrollmentFeed = BackedFeed<[(UserCourseEnrollment, ProgressStats)]?>()
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
        
        let output = feed.output
        output.listen(self) { result in
            result.ifSuccess {
                if let enrollmentsWithProgress = $0 {
                    let courses = enrollmentsWithProgress.flatMap { (enrollment, _) in enrollment.course }
                    self.interface?.setRegisteredCourses(courses)
                    self.interface?.deleteUnregisteredItems()
                    self.interface?.courses = enrollmentsWithProgress.flatMap {(enrollment, _) in enrollment }
                }
            }
        }
    }
    
    open var feed: Feed<[(UserCourseEnrollment, ProgressStats)]?> {
        return enrollmentFeed
    }
    
    open func enrolledCourseWithID(_ courseID: String) -> UserCourseEnrollment? {
        return self.streamForCourseWithID(courseID).value
    }
    
    open func streamForCourseWithID(_ courseID: String) -> edXCore.Stream<UserCourseEnrollment> {
        let hasCourse = enrollmentFeed.output.value??.contains { (enrollment, progress) in
            enrollment.course.course_id == courseID
            } ?? false
        
        if !hasCourse {
            enrollmentFeed.refresh()
        }
        
    
        let courseStream = feed.output.flatMap(fireIfAlreadyLoaded: hasCourse || !enrollmentFeed.output.active) { optionalEnrollmentsWithProgress  in
            return optionalEnrollmentsWithProgress.toResult().flatMap({ enrollmentsWithProgress -> Result<UserCourseEnrollment>  in
                if let (enrollment, _) = enrollmentsWithProgress.firstObjectMatching({ (enrollment, courseProgress)  in
                    return enrollment.course.course_id == courseID
                }) {
                    return .success(enrollment)
                } else {
                    return .failure(NSError.oex_unknownError())
                }
            })
        }
        return courseStream
    }
    
    fileprivate func clearFeed() {
        let feed = Feed<[(UserCourseEnrollment, ProgressStats)]?> { stream in
            stream.removeAllBackings()
            stream.send(Success(nil))
        }
        self.enrollmentFeed.backWithFeed(feed)
        
        self.enrollmentFeed.refresh()
    }
    
    fileprivate func setupFeedWithUserDetails(_ userDetails: OEXUserDetails) {
        guard let username = userDetails.username else {
                return
        }
        let organizationCode = self.config.organizationCode()
        let feed = freshFeedWithUsername(username, organizationCode: organizationCode)
        enrollmentFeed.backWithFeed(feed.map {x in x})
        enrollmentFeed.refresh()
    }
    
    func freshFeedWithUsername(_ username: String, organizationCode: String?) -> Feed<[(UserCourseEnrollment,ProgressStats)]> {
        
        
        
        let request = CoursesAPI.getUserEnrollments(username, organizationCode: organizationCode)
        let enrollmentStream = networkManager.streamForRequest(request, persistResponse: true)
        let progressStream = networkManager.streamForRequest(CourseProgressAPI.getAllCoursesProgress(), persistResponse: true)
        
        
        let combinedStream: edXCore.Stream<[(UserCourseEnrollment, ProgressStats)]> = joinStreams(enrollmentStream, progressStream).map { (enrollements, progress) in
            
            //Done because of in-consistent number of elements returned in CourseEnrollments & CourseProgress from API
            return enrollements.flatMap { enrollment -> (UserCourseEnrollment, ProgressStats)? in
                guard let courseProgress = progress.index(where: {
                    $0.courseID == enrollment.course.course_id
                })
                .map ({
                    progress[$0]
                }) else {
                        return nil
                }
                return (enrollment, courseProgress)
            }
        }
        return Feed { backing in
            backing.backWithStream(combinedStream)
        }
    }
}
