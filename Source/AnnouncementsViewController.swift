//
//  AnnouncementsViewController.swift
//  edX
//
//  Created by Abdul Haseeb on 8/18/17.
//  Copyright © 2017 edX. All rights reserved.
//

//  TODO: In the current senario the app is crashing if there is no announcements or the data is failed to load.

import UIKit

class AnnouncementsViewController: UIViewController {

    public typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & NetworkManagerProvider & OEXRouterProvider & OEXInterfaceProvider & OEXRouterProvider
    
    @IBOutlet weak var noAnnouncementLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var webView: UIWebView!
    
    fileprivate let environment: Environment
    fileprivate let courseId: String?
    
    var stream: edXCore.Stream<[CourseAnnouncement]>?
    var courseAnnouncements: [CourseAnnouncement]?
    
    let loadController: LoadStateViewController
    
    public init(environment: Environment, courseId: String?) {
        self.environment = environment
        self.courseId = courseId
        loadController = LoadStateViewController()
        
        super.init(nibName: nil, bundle: nil)
        stream = environment.dataManager.courseDataManager.streamForCourseAnnouncements(courseId ?? "")
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addListeners()
        setupUI()
    }

    private func setupUI () {
        webView.delegate = self
        self.navigationItem.title = Strings.courseAnnouncements
        loadController.setupInController(self, contentView: self.webView)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func showStreamData() {
        //TODO: adjust the loader view according to states rightnow the app is crashing if data fails to load in web view.
        if (courseAnnouncements != nil) {
            if (courseAnnouncements?.count)! > 0 {
                self.dateLabel.isHidden = false
                self.webView.isHidden = false
                self.dateLabel.text = courseAnnouncements?[0].date
                self.webView.loadHTMLString((courseAnnouncements?[0].content)!, baseURL: nil)
            } else {
                self.dateLabel.isHidden = true
                self.webView.isHidden = true
            }
        }
    }

    private func addListeners() {
        stream?.listen(self, action: { (result) in
            result.ifSuccess({ (courseAnnouncements: [CourseAnnouncement]) -> Void in
                if courseAnnouncements.count > 0 {
                    self.courseAnnouncements = courseAnnouncements
                    self.showStreamData()
                } else {
                    self.dateLabel.isHidden = true
                    self.webView.isHidden = true
                    self.loadController.state = LoadState.failed(NSError())
                }
                
            })
            result.ifFailure({ (error) in
                self.webView.isHidden = true
                self.dateLabel.isHidden = true
                self.loadController.state = LoadState.failed(error as NSError)
            })
        })
    }

}

extension AnnouncementsViewController: UIWebViewDelegate {
    
    func webViewDidStartLoad(_ webView: UIWebView){
        self.webView.isUserInteractionEnabled = false
    }

    func webViewDidFinishLoad(_ webView :UIWebView){
        self.loadController.state = .loaded
        self.webView.isUserInteractionEnabled = true
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        self.loadController.state = .failed()
        self.loadController.state = LoadState.failed(error as NSError)
    }

}
