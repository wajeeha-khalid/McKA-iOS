//
//  CachedWebViewController.swift
//  edX
//
//  Created by Konstantinos Angistalis on 20/02/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit


public typealias Environment = protocol<OEXConfigProvider, OEXSessionProvider>


class UIWebViewContentController : WebContentController {
    
    let webView = UIWebView(frame: CGRectZero)
    
    var view : UIView {
        return webView
    }
    
    var scrollView : UIScrollView {
        return webView.scrollView
    }
    
    func clearDelegate() {
        return webView.delegate = nil
    }
    
    func loadURLRequest(request: NSURLRequest) {
        webView.loadRequest(request)
    }
    
    func resetState() {
        webView.stopLoading()
        webView.loadHTMLString("", baseURL: nil)
    }
    
    var alwaysRequiresOAuthUpdate : Bool {
        return true
    }
    
    var initialContentState : WebControllerState {
        return WebControllerState.CreatingSession
    }
    
    deinit {
        debugPrint("UIWebViewContentController deinit!")
    }
}


// Allows access to cached course content that requires authentication.
// Forwarding our oauth token to the server so we can get a web based cookie
public class CachedWebViewController: UIViewController, UIWebViewDelegate {

    public let blockID: CourseBlockID?

    internal let environment : Environment
    private let loadController : LoadStateViewController
    private let insetsController : ContentInsetsController
    private let headerInsets : HeaderViewInsets
    
    private lazy var webController : WebContentController = {
        let controller = UIWebViewContentController()
        controller.webView.delegate = self
        return controller
    }()
    
    private var state = WebControllerState.CreatingSession
    
    private var contentRequest : NSURLRequest? = nil
    var currentUrl: NSURL? {
        return contentRequest?.URL
    }
    
    public init(environment : Environment, blockID: CourseBlockID?) {
        self.environment = environment
        self.blockID = blockID
        
        loadController = LoadStateViewController()
        insetsController = ContentInsetsController()
        headerInsets = HeaderViewInsets()
        insetsController.addSource(headerInsets)
        
        super.init(nibName: nil, bundle: nil)
        
        automaticallyAdjustsScrollViewInsets = false
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        // Prevent crash due to stale back pointer, since WKWebView's UIScrollView apparently doesn't
        // use weak for its delegate
        webController.scrollView.delegate = nil
        webController.clearDelegate()
    }
    
    override public func viewDidLoad() {
        
        self.state = webController.initialContentState
        self.view.addSubview(webController.view)
        webController.view.snp_makeConstraints {make in
            make.edges.equalTo(self.view)
        }
        self.loadController.setupInController(self, contentView: webController.view)
        webController.view.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        webController.scrollView.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        
        self.insetsController.setupInController(self, scrollView: webController.scrollView)
        
        
        if let request = self.contentRequest {
            loadRequest(request)
        }
    }
    
    private func resetState() {
        loadController.state = .Initial
        state = .CreatingSession
    }
    
    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        if view.window == nil {
            webController.resetState()
        }
        resetState()
    }
    
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        insetsController.updateInsets()
    }
    
    public func showError(error : NSError?, icon : Icon? = nil, message : String? = nil) {
        loadController.state = LoadState.failed(error, icon : icon, message : message)
    }
    
    // MARK: Header View
    
    var headerView : UIView? {
        get {
            return headerInsets.view
        }
        set {
            headerInsets.view?.removeFromSuperview()
            headerInsets.view = newValue
            if let headerView = newValue {
                webController.view.addSubview(headerView)
                headerView.snp_makeConstraints {make in
                    if #available(iOS 9.0, *) {
                        make.top.equalTo(self.topLayoutGuide.bottomAnchor)
                    }
                    else {
                        make.top.equalTo(self.snp_topLayoutGuideBottom)
                    }
                    make.leading.equalTo(webController.view)
                    make.trailing.equalTo(webController.view)
                }
                webController.view.setNeedsLayout()
                webController.view.layoutIfNeeded()
            }
        }
    }
    
    private func loadOAuthRefreshRequest() {
        if let hostURL = environment.config.apiHostURL() {
            guard let URL = hostURL.URLByAppendingPathComponent(OAuthExchangePath) else { return }
            let exchangeRequest = NSMutableURLRequest(URL: URL)
            exchangeRequest.HTTPMethod = HTTPMethod.POST.rawValue
            
            for (key, value) in self.environment.session.authorizationHeaders {
                exchangeRequest.addValue(value, forHTTPHeaderField: key)
            }
            self.webController.loadURLRequest(exchangeRequest)
        }
    }
    
    // MARK: Request Loading
    
    public func loadRequest(request : NSURLRequest) {
        contentRequest = request
        loadController.state = .Initial
        state = webController.initialContentState
        
        if webController.alwaysRequiresOAuthUpdate && EVURLCache.storagePathForRequest(request) == nil {
            loadOAuthRefreshRequest()
        }
        else {
            state = .LoadingContent
            debugPrint("Loading Request: \(request.URLString)")
            webController.loadURLRequest(request)
        }
    }
    
    // MARK: UIWebView delegate
    
    public func webViewDidFinishLoad(webView: UIWebView) {
        
        switch state {
        case .CreatingSession:
            if let request = contentRequest {
                state = .LoadingContent
                webController.loadURLRequest(request)
            }
            else {
                loadController.state = LoadState.failed()
            }
        case .LoadingContent:
            loadController.state = .Loaded

            if let url = contentRequest?.URL?.absoluteString, let source = webView.stringByEvaluatingJavaScriptFromString("document.documentElement.outerHTML") where url.containsString("type@chat") {

                if source.containsString(">COMPLETE<") || source.containsString(">Complete<") {
                    print("Is completed!")

                    NSNotificationCenter.defaultCenter().postNotificationName("ChatCompletedNotification", object: nil, userInfo: ["blockId": self.blockID ?? ""])
                }
            }

            let jsString = "localStorage.getItem('current_step');"
            let currentStep = webView.stringByEvaluatingJavaScriptFromString(jsString)

            if let controller = webController as? UIWebViewContentController {
                let currentStep = controller.webView.stringByEvaluatingJavaScriptFromString(jsString)
                print("currentStep: \(currentStep)")
            }
            print("currentStep: \(currentStep)")
        case .NeedingSession:
            state = .CreatingSession
            loadOAuthRefreshRequest()
        }
    }
    
    public func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        if (error.code != -999) {
            showError(error)
        }
    }
}
