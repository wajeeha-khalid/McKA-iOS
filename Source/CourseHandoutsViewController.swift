//
//  CourseHandoutsViewController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 26/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
open class CourseHandoutsViewController: OfflineSupportViewController, UIWebViewDelegate {
    
    public typealias Environment = DataManagerProvider & NetworkManagerProvider & ReachabilityProvider & OEXAnalyticsProvider & OEXSessionProvider

    let courseID : String
    let environment : Environment
    let webView : UIWebView
    let loadController : LoadStateViewController
    let handouts : BackedStream<String> = BackedStream()
    
    init(environment : Environment, courseID : String) {
        self.environment = environment
        self.courseID = courseID
        self.webView = UIWebView()
        self.loadController = LoadStateViewController()
        
        super.init(env: environment)
        
        addListener()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        loadController.setupInController(self, contentView: webView)
        addSubviews()
        setConstraints()
        setStyles()
        webView.delegate = self
        loadHandouts()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        environment.analytics.trackScreen(withName: OEXAnalyticsScreenHandouts, courseID: courseID, value: nil)
    }
    
    override func reloadViewData() {
        loadHandouts()
    }
    
    fileprivate func addSubviews() {
        view.addSubview(webView)
    }
    
    fileprivate func setConstraints() {
        webView.snp.makeConstraints { (make) -> Void in
            make.edges.equalTo(self.view)
        }
    }
    
    fileprivate func setStyles() {
        self.view.backgroundColor = OEXStyles.shared.standardBackgroundColor()
        self.navigationItem.title = Strings.courseHandouts
    }
    
    fileprivate func streamForCourse(_ course : OEXCourse) -> edXCore.Stream<String>? {
        if let access = course.courseware_access, !access.has_access {
            return edXCore.Stream<String>(error: OEXCoursewareAccessError(coursewareAccess: access, displayInfo: course.start_display_info))
        }
        else {
            let request = CourseInfoAPI.getHandoutsForCourseWithID(courseID, overrideURL: course.course_handouts)
            let loader = self.environment.networkManager.streamForRequest(request, persistResponse: true)
            return loader
        }
    }

    fileprivate func loadHandouts() {
        if !handouts.active {
            loadController.state = .initial
            let courseStream = self.environment.dataManager.enrollmentManager.streamForCourseWithID(courseID)
            let handoutStream = courseStream.transform {[weak self] enrollment in
                return self?.streamForCourse(enrollment.course) ?? edXCore.Stream<String>(error : NSError.oex_courseContentLoadError())
            }
            self.handouts.backWithStream(handoutStream)
        }
    }
    
    fileprivate func addListener() {
        handouts.listen(self, success: { [weak self] courseHandouts in
            if let
                displayHTML = OEXStyles.shared.styleHTMLContent(courseHandouts, stylesheet: "handouts-announcements"),
                let apiHostUrl = OEXConfig.shared().apiHostURL()
            {
                self?.webView.loadHTMLString(displayHTML, baseURL: apiHostUrl)
                self?.loadController.state = .loaded
            }
            else {
                self?.loadController.state = LoadState.failed()
            }
            
            }, failure: {[weak self] error in
                self?.loadController.state = LoadState.failed(error)
        } )
    }
    
    override open func updateViewConstraints() {
        loadController.insets = UIEdgeInsets(top: self.topLayoutGuide.length, left: 0, bottom: self.bottomLayoutGuide.length, right: 0)
        super.updateViewConstraints()
    }
    
    //MARK: UIWebView delegate

    open func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if (navigationType != UIWebViewNavigationType.other) {
            if let URL = request.url {
                 UIApplication.shared.openURL(URL)
                return false
            }
        }
        return true
    }
    
}
