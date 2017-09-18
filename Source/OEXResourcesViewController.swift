//
//  OEXResourcesViewController.swift
//  edX
//
//  Created by Abdul Haseeb on 8/10/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

class OEXResourcesViewController: UIViewController {
    struct Keys {
        static let baseUrl = OEXConfig.shared().apiHostURL()?.absoluteString ?? ""
        static let mckinseyPlaceholder = "MCKINSEY_PLACEHOLDER"
        static let ooyalaPlayerWithoutHttpHeader = "//player.ooyala.co"
        static let ooyalaPlayerWithHttpHeader = "https://player.ooyala.co"
    }
    public typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & NetworkManagerProvider & OEXRouterProvider & OEXInterfaceProvider & OEXRouterProvider
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var webView: UIWebView!
    
    fileprivate let environment: Environment
    fileprivate let courseId: String?
    fileprivate var htmlLoadingString: String?
    var stream: edXCore.Stream<[CourseContent]>?
    var courseContents: [CourseContent]?
    var resourseContent: CourseContent?
    let loadController : LoadStateViewController
    var loadedFirstTime = true
    
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
        
        guard resourseContent != nil else {
            self.webView.isHidden = true
            self.loadController.state = LoadState.loaded
            return
        }
        
        
        let htmlFile = Bundle.main.path(forResource: "template", ofType: "html")
        let htmlString = try? String(contentsOfFile: htmlFile!, encoding: String.Encoding.utf8)
        htmlLoadingString = htmlString?.replacingOccurrences(of: Keys.mckinseyPlaceholder,
                                                             with: resourseContent?.content ?? "")
        htmlLoadingString = htmlLoadingString?.replacingOccurrences(of: Keys.ooyalaPlayerWithoutHttpHeader,
                                                                    with: Keys.ooyalaPlayerWithHttpHeader)
        let baseURL = URL.init(string: Keys.baseUrl)
        webView.loadHTMLString(htmlLoadingString ?? "", baseURL: baseURL)
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
        progressView.isHidden = false
        progressView.setProgress(0.0, animated: false)
        progressView.setProgress(0.3, animated: true)
    }
    
    func webViewDidFinishLoad(_ webView :UIWebView){
        self.loadController.state = .loaded
        progressView.setProgress(1.0, animated: true)
        loadedFirstTime = false
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        progressView.setProgress(1.0, animated: true)
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if checkIfLoadingFirstTime(request: request)  {
            return true
        } else {
            loadRequest(request: request, navigationType:  navigationType)
        }
        return loadedFirstTime
    }
    
}

extension OEXResourcesViewController {
    
    func loadRequest(request: URLRequest, navigationType: UIWebViewNavigationType) {
        if !loadedFirstTime && navigationType == .linkClicked {
            showWebNavigationViewController(request: request)
        }
    }
    
    
    func showWebNavigationViewController(request: URLRequest) {
        let webNavigationViewController = WebNavigationViewController(request: request,
                                                                      title: Strings.resources)
        let navigationController = UINavigationController(rootViewController: webNavigationViewController)
        self.present(navigationController, animated: false, completion: nil)
    }
    
    func checkIfLoadingFirstTime(request: URLRequest) -> Bool {
        return request.url?.absoluteString.contains(Keys.baseUrl) ?? false &&
            request.url?.absoluteString.contains("#") ?? false
    }
    
}
