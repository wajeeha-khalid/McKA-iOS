//
//  CourseAnnouncementsViewController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 07/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
import edXCore
import SwiftyJSON

private let notificationLabelLeadingOffset = 20.0
private let notificationLabelTrailingOffset = -10.0
private let notificationBarHeight = 50.0

@objc protocol CourseAnnouncementsViewControllerEnvironment : OEXConfigProvider, DataManagerProvider, NetworkManagerProvider, ReachabilityProvider, OEXRouterProvider, OEXAnalyticsProvider, OEXSessionProvider {}

extension RouterEnvironment : CourseAnnouncementsViewControllerEnvironment {}


private func announcementsDeserializer(_ response: HTTPURLResponse, json: JSON) -> Result<[OEXAnnouncement]> {
    return json.array.toResult().map {
        return $0.map {
            return OEXAnnouncement(dictionary: $0.dictionaryObject ?? [:])
        }
    }
}


class CourseAnnouncementsViewController: OfflineSupportViewController, UIWebViewDelegate {
    fileprivate let environment: CourseAnnouncementsViewControllerEnvironment
    
    let courseID: String
    
    fileprivate let loadController = LoadStateViewController()
    fileprivate let announcementsLoader = BackedStream<[OEXAnnouncement]>()
    
    fileprivate let webView: UIWebView
    fileprivate let notificationBar : UIView
    fileprivate let notificationLabel : UILabel
    fileprivate let notificationSwitch : UISwitch
    
    fileprivate let fontStyle = OEXTextStyle(weight : .normal, size: .base, color: OEXStyles.shared.neutralBlack())
    fileprivate let switchStyle = OEXStyles.shared.standardSwitchStyle()
    
    init(environment: CourseAnnouncementsViewControllerEnvironment, courseID: String) {
        self.courseID = courseID
        self.environment = environment
        self.webView = UIWebView()
        self.notificationBar = UIView(frame: CGRect.zero)
        self.notificationBar.clipsToBounds = true
        self.notificationLabel = UILabel(frame: CGRect.zero)
        self.notificationSwitch = UISwitch(frame: CGRect.zero)
        super.init(env: environment)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        addSubviews()
        setConstraints()
        setStyles()
        
        self.view.backgroundColor = OEXStyles.shared.standardBackgroundColor()
        webView.backgroundColor = OEXStyles.shared.standardBackgroundColor()
        webView.isOpaque = false
        
        loadController.setupInController(self, contentView: self.webView)
        
        notificationSwitch.oex_addAction({[weak self] _ in
            if let owner = self {
                owner.environment.dataManager.pushSettings.setPushDisabled(!owner.notificationSwitch.isOn, forCourseID: owner.courseID)
            }}, for: UIControlEvents.valueChanged)
        
        self.webView.delegate = self
        
        announcementsLoader.listen(self) {[weak self] in
            switch $0 {
            case let .success(announcements):
                self?.useAnnouncements(announcements)
            case let .failure(error):
                if !(self?.announcementsLoader.active ?? false) {
                    self?.loadController.state = LoadState.failed(error)
                }
            }
        }
    }
    
    fileprivate static func requestForCourse(_ course: OEXCourse) -> NetworkRequest<[OEXAnnouncement]> {
        let announcementsURL = course.course_updates ?? "".oex_format(withParameters: [:])
        return NetworkRequest(method: .GET,
            path: announcementsURL,
            requiresAuth: true,
            deserializer: .jsonResponse(announcementsDeserializer)
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.loadContent()
        environment.analytics.trackScreen(withName: OEXAnalyticsScreenAnnouncements, courseID: courseID, value: nil)
    }
    
    override func reloadViewData() {
        loadContent()
    }
    
    fileprivate func loadContent() {
        if !announcementsLoader.active {
            let networkManager = environment.networkManager
            announcementsLoader.backWithStream(
                environment.dataManager.enrollmentManager.streamForCourseWithID(courseID).transform {
                    let request = CourseAnnouncementsViewController.requestForCourse($0.course)
                    return networkManager.streamForRequest(request, persistResponse: true)
                }
            )
        }
    }
    
    //MARK: - Setup UI
    fileprivate func addSubviews() {
        self.view.addSubview(webView)
        self.view.addSubview(notificationBar)
        notificationBar.addSubview(notificationLabel)
        notificationBar.addSubview(notificationSwitch)
    }
    
    fileprivate func setConstraints() {
        notificationLabel.snp.makeConstraints { (make) -> Void in
            make.leading.equalTo(notificationBar.snp.leading).offset(notificationLabelLeadingOffset)
            make.centerY.equalTo(notificationBar)
            make.trailing.equalTo(notificationSwitch)
        }
        
        notificationSwitch.snp.makeConstraints { (make) -> Void in
            make.centerY.equalTo(notificationBar)
            make.trailing.equalTo(notificationBar).offset(notificationLabelTrailingOffset)
        }
        
        notificationBar.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view)
            make.leading.equalTo(self.view)
            make.trailing.equalTo(self.view)
            if environment.config.pushNotificationsEnabled {
                make.height.equalTo(notificationBarHeight)
            }
            else {
                make.height.equalTo(0)
            }
        }
        
        webView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(notificationBar.snp.bottom)
            make.leading.equalTo(self.view)
            make.trailing.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
    }
    
    fileprivate func setStyles() {
        self.navigationItem.title = Strings.courseAnnouncements
        notificationBar.backgroundColor = OEXStyles.shared.standardBackgroundColor()
        switchStyle.apply(to: notificationSwitch)
        notificationLabel.attributedText = fontStyle.attributedString(withText: Strings.notificationsEnabled)
        notificationSwitch.isOn = !environment.dataManager.pushSettings.isPushDisabledForCourse(withID: courseID)
    }
    //MARK: - Presenter
    
    fileprivate func useAnnouncements(_ announcements: [OEXAnnouncement]) {
        guard announcements.count > 0 else {
            self.loadController.state = LoadState.empty(icon: nil, message: Strings.announcementUnavailable)
            return
        }
        
        var html:String = String()
        
        for (index,announcement) in announcements.enumerated() {
                html += "<div class=\"announcement-header\">\(announcement.heading ?? "")</div>"
                html += "<hr class=\"announcement\"/>"
                html += announcement.content ?? ""
                if(index + 1 < announcements.count)
                {
                    html += "<div class=\"announcement-separator\"/></div>"
                }
        }
        let displayHTML = OEXStyles.shared.styleHTMLContent(html, stylesheet: "handouts-announcements") ?? ""
        let baseURL = self.environment.config.apiHostURL()
        self.webView.loadHTMLString(displayHTML, baseURL: baseURL)
    }
    
    //MARK: - UIWebViewDeleagte
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if (navigationType != UIWebViewNavigationType.other) {
            if let URL = request.url {
                UIApplication.shared.openURL(URL)
                return false
            }
        }
        return true
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        self.loadController.state = .loaded
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        self.loadController.state = LoadState.failed(error as NSError)
    }
}

// Testing only
extension CourseAnnouncementsViewController {
    var t_showingNotificationBar : Bool {
        return self.notificationBar.bounds.size.height > 0
    }
}
