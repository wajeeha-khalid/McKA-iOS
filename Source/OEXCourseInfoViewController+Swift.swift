//
//  OEXCourseInfoViewController+Swift.swift
//  edX
//
//  Created by Saeed Bashir on 8/25/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

extension OEXCourseInfoViewController {
 
    func enrollInCourse(_ courseID: String, emailOpt: Bool) {
        guard let _ = OEXSession.shared()?.currentUser else {
            OEXRouter.shared().showSignUpScreen(from: self, completion: {
                self.enrollInCourse(courseID, emailOpt: emailOpt)
            })
            return;
        }
        
        let environment = OEXRouter.shared().environment;
        
        if let _ = environment.dataManager.enrollmentManager.enrolledCourseWithID(courseID) {
            showMainScreen(withMessage: Strings.findCoursesAlreadyEnrolledMessage, courseID: courseID)
            return
        }
        
        let request = CourseCatalogAPI.enroll(courseID)
        environment.networkManager.taskForRequest(request) {[weak self] response in
            if response.response?.httpStatusCode.is2xx ?? false {
                environment.analytics.trackUserEnrolled(inCourse: courseID)
                self?.showMainScreen(withMessage: Strings.findCoursesEnrollmentSuccessfulMessage, courseID: courseID)
            }
            else {
                self?.showOverlayMessage(Strings.findCoursesEnrollmentErrorDescription)
            }
        }
    }
}
