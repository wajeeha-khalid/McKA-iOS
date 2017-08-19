//
//  OEXResourcesViewController.swift
//  edX
//
//  Created by Abdul Haseeb on 8/10/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

class OEXResourcesViewController: UIViewController {

    public typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & NetworkManagerProvider & OEXRouterProvider & OEXInterfaceProvider & OEXRouterProvider
    
    @IBOutlet weak var webView: UIWebView!
    fileprivate let environment: Environment
    fileprivate let courseId: String?
    var stream: edXCore.Stream<[CourseContent]>?
    var courseContents: [CourseContent]?
    var resourseContent: CourseContent?
    let loadController : LoadStateViewController

    public init(environment: Environment, courseId: String) {
        self.environment = environment
        self.courseId = courseId
        loadController = LoadStateViewController()
        
        super.init(nibName: nil, bundle: nil)
        stream = environment.dataManager.courseDataManager.streamForCourseContent(courseId)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        addListeners()
    }

    private func setupUI () {
        self.navigationItem.title = Strings.resources
        loadController.setupInController(self, contentView: self.webView)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func showCourseContent() {
        courseContents?.forEach{ (courseContent: CourseContent) -> Void in
            if courseContent.name == "Resources" {
                resourseContent = courseContent
            }
        }
        if (resourseContent != nil) {
            self.webView.loadHTMLString((resourseContent?.content)!, baseURL: nil)
        }
    }

    private func addListeners() {
        stream?.listen(self, action: { (result) in
            result.ifSuccess({ (courseContents:[CourseContent]) -> Void in
                self.courseContents = courseContents
                self.showCourseContent()
            })
            
            result.ifFailure({ (error) in
                self.loadController.state = LoadState.failed(error as NSError)
            })
        })
    }
}

extension OEXResourcesViewController: UIWebViewDelegate {
    
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
