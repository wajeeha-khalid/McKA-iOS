//
//  CourseCatalogDetailViewController.swift
//  edX
//
//  Created by Akiva Leffert on 12/3/15.
//  Copyright © 2015 edX. All rights reserved.
//

import WebKit
import UIKit

import edXCore

class CourseCatalogDetailViewController: UIViewController {
    fileprivate let courseID: String
    
    typealias Environment = OEXAnalyticsProvider & DataManagerProvider & NetworkManagerProvider & OEXRouterProvider
    
    fileprivate let environment: Environment
    fileprivate lazy var loadController = LoadStateViewController()
    fileprivate lazy var aboutView : CourseCatalogDetailView = {
        return CourseCatalogDetailView(frame: CGRect.zero, environment: self.environment)
    }()
    fileprivate let courseStream = BackedStream<(OEXCourse, enrolled: Bool)>()
    
    init(environment : Environment, courseID : String) {
        self.courseID = courseID
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
        self.navigationItem.title = Strings.findCourses
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(aboutView)
        aboutView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
        self.view.backgroundColor = OEXStyles.shared.standardBackgroundColor()
        
        self.loadController.setupInController(self, contentView: aboutView)
        
        self.aboutView.setupInController(self)
        
        listen()
        load()
    }
    
    fileprivate func listen() {
        self.courseStream.listen(self,
            success: {[weak self] (course, enrolled) in
                self?.aboutView.applyCourse(course)
                if enrolled {
                    self?.aboutView.actionText = Strings.CourseDetail.viewCourse
                    self?.aboutView.action = {completion in
                        self?.showCourseScreen()
                        completion()
                    }
                }
                else {
                    self?.aboutView.actionText = Strings.CourseDetail.enrollNow
                    
                    self?.aboutView.action = {[weak self] completion in
                        self?.enrollInCourse(completion)
                    }
                }
            }, failure: {[weak self] error in
                self?.loadController.state = LoadState.failed(error)
            }
        )
        self.aboutView.loaded.listen(self) {[weak self] _ in
            self?.loadController.state = .loaded
        }
    }
    
    fileprivate func load() {
        let request = CourseCatalogAPI.getCourse(courseID)
        let courseStream = environment.networkManager.streamForRequest(request)
        let enrolledStream = environment.dataManager.enrollmentManager.streamForCourseWithID(courseID).resultMap {
            return .success($0.isSuccess)
        }
        let stream = joinStreams(courseStream, enrolledStream).map{($0, enrolled: $1) }
        self.courseStream.backWithStream(stream)
    }
    
    fileprivate func showCourseScreen(message: String? = nil) {
        self.environment.router?.showMyCourses(animated: true, pushingCourseWithID:courseID)
        
        if let message = message {
            let after = DispatchTime.now() + Double(Int64(EnrollmentShared.overlayMessageDelay * TimeInterval(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: after) {
                NotificationCenter.default.post(name: Notification.Name(rawValue: EnrollmentShared.successNotification), object: message, userInfo: nil)
            }
        }
    }
    
    fileprivate func enrollInCourse(_ completion : @escaping () -> Void) {
        
        let notEnrolled = environment.dataManager.enrollmentManager.enrolledCourseWithID(self.courseID) == nil
        
        guard notEnrolled else {
            self.showCourseScreen(message: Strings.findCoursesAlreadyEnrolledMessage)
            completion()
            return
        }
        
        let courseID = self.courseID
        let request = CourseCatalogAPI.enroll(courseID)
        environment.networkManager.taskForRequest(request) {[weak self] response in
            if response.response?.httpStatusCode.is2xx ?? false {
                self?.environment.analytics.trackUserEnrolled(inCourse: courseID)
                self?.showCourseScreen(message: Strings.findCoursesEnrollmentSuccessfulMessage)
            }
            else {
                self?.showOverlayMessage(Strings.findCoursesEnrollmentErrorDescription)
            }
            completion()
        }
    }
    
}
// Testing only
extension CourseCatalogDetailViewController {
    
    var t_loaded : edXCore.Stream<()> {
        return self.aboutView.loaded
    }
    
    var t_actionText: String? {
        return self.aboutView.actionText
    }
    
    func t_enrollInCourse(_ completion : @escaping () -> Void) {
        enrollInCourse(completion)
    }
    
}
