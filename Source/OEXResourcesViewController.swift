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
    
    @IBOutlet weak var farwardBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var backBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var refreshBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var toolbar: UIToolbar!
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var webView: UIWebView!
    
    fileprivate let environment: Environment
    fileprivate let courseId: String?
    fileprivate var htmlLoadingString: String?
    var stream: edXCore.Stream<[CourseContent]>?
    var courseContents: [CourseContent]?
    var resourseContent: CourseContent?
    let loadController : LoadStateViewController

    private func setWebviewSettings() {
        webView.allowsInlineMediaPlayback = true
    }
    
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
        setWebviewSettings()
        setBarButtonItemActions()
    }

    private func setupUI () {
        self.progressView.isHidden = true
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
        
        guard let resourcesContent = resourseContent else {
            self.webView.isHidden = true
            self.toolbar.isHidden = true
            self.loadController.state = LoadState.loaded
            return
        }
        
        self.webView.loadHTMLString(resourcesContent.content!, baseURL: nil)
        
        let htmlFile = Bundle.main.path(forResource: "template", ofType: "html")
        let htmlString = try? String(contentsOfFile: htmlFile!, encoding: String.Encoding.utf8)
        htmlLoadingString = htmlString?.replacingOccurrences(of: "MCKINSEY_PLACEHOLDER",
                                                             with: resourseContent?.content ?? "")
        htmlLoadingString = htmlLoadingString?.replacingOccurrences(of: "//player.ooyala.co", with: "https://player.ooyala.co")
        webView.loadRequest(URLRequest(url: URL(string: "about:blank")!))
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
       
        setBarButtonItemStatus()
        progressView.isHidden = false
        progressView.setProgress(0.0, animated: false)
        progressView.setProgress(0.3, animated: true)
    }
    
    func webViewDidFinishLoad(_ webView :UIWebView){
        self.loadController.state = .loaded
        setBarButtonItemStatus()
        checkIfLoadingFirstTime()
        progressView.setProgress(1.0, animated: true)
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        setBarButtonItemStatus()
        progressView.setProgress(1.0, animated: true)
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        return true
    }
    
}


extension OEXResourcesViewController {
    
    func setBarButtonItemActions() {
        farwardBarButtonItem.action = #selector(OEXResourcesViewController.farwardBarButtonItemAction)
        backBarButtonItem.action = #selector(OEXResourcesViewController.backBarButtonItemAction)
        refreshBarButtonItem.action = #selector(OEXResourcesViewController.refreshBarButtonItemAction)
    }
    
    func backBarButtonItemAction() {
        webView.goBack()
    }
    
    func farwardBarButtonItemAction() {
        webView.goForward()
    }
    
    func refreshBarButtonItemAction() {
        webView.reload()
    }
        
    func setBarButtonItemStatus() {
        if webView.isLoading {
            refreshBarButtonItem.isEnabled = false
        } else {
            refreshBarButtonItem.isEnabled = true
        }
        
        if webView.canGoBack {
            backBarButtonItem.isEnabled = true
        } else {
            backBarButtonItem.isEnabled = false
            refreshBarButtonItem.isEnabled = false
        }
        
        if webView.canGoForward {
            farwardBarButtonItem.isEnabled = true
        } else {
            farwardBarButtonItem.isEnabled = false
        }
    }
    
    func checkIfLoadingFirstTime() {
        if (webView.request?.url?.absoluteString == "about:blank") && !webView.canGoBack {
            let baseURL = URL.init(string: "https://courses.qa.mckinsey.edx.org")
            webView.loadHTMLString(htmlLoadingString ?? "", baseURL: baseURL)
        }
    }
}
