//
//  CachedWebViewController.swift
//  edX
//
//  Created by Konstantinos Angistalis on 20/02/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit
import SnapKit

public typealias Environment = OEXConfigProvider & OEXSessionProvider


class UIWebViewContentController : WebContentController {
    
    let webView = UIWebView(frame: CGRect.zero)
    
    var view : UIView {
        return webView
    }
    
    var scrollView : UIScrollView {
        return webView.scrollView
    }
    
    func clearDelegate() {
        return webView.delegate = nil
    }
    
    func loadURLRequest(_ request: URLRequest) {
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
        return WebControllerState.creatingSession
    }
    
    deinit {
        debugPrint("UIWebViewContentController deinit!")
    }
}


// Allows access to cached course content that requires authentication.
// Forwarding our oauth token to the server so we can get a web based cookie
open class CachedWebViewController: UIViewController, UIWebViewDelegate {

    open let blockID: CourseBlockID?

    internal let environment : Environment
    fileprivate let loadController : LoadStateViewController
    fileprivate let insetsController : ContentInsetsController
    fileprivate let headerInsets : HeaderViewInsets
    
    fileprivate lazy var webController : WebContentController = {
        let controller = UIWebViewContentController()
        controller.webView.delegate = self
        return controller
    }()
    
    fileprivate var state = WebControllerState.creatingSession
    
    fileprivate var contentRequest : URLRequest? = nil
    var currentUrl: URL? {
        return contentRequest?.url
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
    
    override open func viewDidLoad() {
        
        self.state = webController.initialContentState
        self.view.addSubview(webController.view)
        webController.view.snp.makeConstraints {make in
            make.edges.equalTo(self.view)
        }
        self.loadController.setupInController(self, contentView: webController.view)
        webController.view.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        webController.scrollView.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        
        self.insetsController.setupInController(self, scrollView: webController.scrollView)
        
        
        if let request = self.contentRequest {
            loadRequest(request)
        }
    }
    
    fileprivate func resetState() {
        loadController.state = .initial
        state = .creatingSession
    }
    
    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        if view.window == nil {
            webController.resetState()
        }
        resetState()
    }
    
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        insetsController.updateInsets()
    }
    
    open func showError(_ error : NSError?, icon : Icon? = nil, message : String? = nil) {
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
                headerView.snp.makeConstraints {make in
                    //TODO: Verify this replacement
                   /* if #available(iOS 9.0, *) {
                        make.top.equalTo(self.topLayoutGuide.bottomAnchor)
                    }
                    else {
                        make.top.equalTo(self.snp_topLayoutGuideBottom)
                    } */
                    make.top.equalTo(topLayoutGuide.snp.bottom)
                    make.leading.equalTo(webController.view)
                    make.trailing.equalTo(webController.view)
                }
                webController.view.setNeedsLayout()
                webController.view.layoutIfNeeded()
            }
        }
    }
    
    fileprivate func loadOAuthRefreshRequest() {
        if let hostURL = environment.config.apiHostURL() {
            
            let URL = hostURL.appendingPathComponent(OAuthExchangePath)
            let exchangeRequest = NSMutableURLRequest(url: URL)
            exchangeRequest.httpMethod = HTTPMethod.POST.rawValue
            
            for (key, value) in self.environment.session.authorizationHeaders {
                exchangeRequest.addValue(value, forHTTPHeaderField: key)
            }
            self.webController.loadURLRequest(exchangeRequest as URLRequest)
        }
    }
    
    // MARK: Request Loading
    
    open func loadRequest(_ request : URLRequest) {
        contentRequest = request
        loadController.state = .initial
        state = webController.initialContentState
        
        if webController.alwaysRequiresOAuthUpdate && EVURLCache.storagePathForRequest(request) == nil {
            loadOAuthRefreshRequest()
        }
        else {
            state = .loadingContent
            debugPrint("Loading Request: \(request.url!.absoluteString)")
            webController.loadURLRequest(request)
        }
    }
    
    // MARK: UIWebView delegate
    
    open func webViewDidFinishLoad(_ webView: UIWebView) {
        
        switch state {
        case .creatingSession:
            if let request = contentRequest {
                state = .loadingContent
                webController.loadURLRequest(request)
            }
            else {
                loadController.state = LoadState.failed()
            }
        case .loadingContent:
            loadController.state = .loaded

            if let url = contentRequest?.url?.absoluteString, let source = webView.stringByEvaluatingJavaScript(from: "document.documentElement.outerHTML"), (url.contains("type@chat") || url.range(of: "i4x://.*/chat/", options: .regularExpression) != nil) {

                if source.contains(">COMPLETE<") || source.contains(">Complete<") {
                    print("Is completed!")

                    NotificationCenter.default.post(name: Notification.Name(rawValue: "ChatCompletedNotification"), object: nil, userInfo: ["blockId": self.blockID ?? ""])
                }
            }

            let jsString = "localStorage.getItem('current_step');"
            _ = webView.stringByEvaluatingJavaScript(from: jsString)

            if let controller = webController as? UIWebViewContentController {
                _ = controller.webView.stringByEvaluatingJavaScript(from: jsString)
            }
        case .needingSession:
            state = .creatingSession
            loadOAuthRefreshRequest()
        }
    }
    
    open func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        if ((error as NSError).code != -999) {
            showError(error as NSError)
        }
    }
}
