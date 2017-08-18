//
//  AnnouncementsViewController.swift
//  edX
//
//  Created by Abdul Haseeb on 8/18/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

class AnnouncementsViewController: UIViewController {

    public typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & NetworkManagerProvider & OEXRouterProvider & OEXInterfaceProvider & OEXRouterProvider
    
    @IBOutlet weak var webView: UIWebView!
    fileprivate let environment: Environment
    fileprivate let courseId: String?
    
    var stream: edXCore.Stream<CourseAnnouncementContent>?
    var courseAnnouncementContent: CourseAnnouncementContent?
    
    let loadController : LoadStateViewController
    
    public init(environment: Environment, courseId: String?) {
        self.environment = environment
        self.courseId = courseId
        loadController = LoadStateViewController()
        
        super.init(nibName: nil, bundle: nil)

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addListeners()
        setupUI()
//        loadController.setupInController(self, contentView : self.view)
        
        // Do any additional setup after loading the view.
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
        print("courseContent: \(String(describing: courseAnnouncementContent?.content))")
        if (courseAnnouncementContent != nil) {
            self.webView.loadHTMLString((courseAnnouncementContent?.content)!, baseURL: nil)
        }
    }

    private func addListeners() {
        stream = environment.dataManager.courseDataManager.streamForCourseAnnouncements(courseId ?? "")
        stream?.listen(self, action: { (result) in
            result.ifSuccess({ (courseAnnouncementContent: CourseAnnouncementContent) -> Void in
                self.courseAnnouncementContent = courseAnnouncementContent
                self.showStreamData()
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
        self.loadController.state = LoadState.failed(error as NSError)
    }

}
