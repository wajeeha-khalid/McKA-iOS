//
//  AuthenticatedWebViewController.swift
//  edX
//
//  Created by Akiva Leffert on 5/26/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
import WebKit
import Alamofire
import SnapKit

class HeaderViewInsets : ContentInsetsSource {
    weak var insetsDelegate : ContentInsetsSourceDelegate?
    
    var view : UIView?
    
    var currentInsets : UIEdgeInsets {
        return UIEdgeInsets(top : view?.frame.size.height ?? 0, left : 0, bottom : 0, right : 0)
    }
    
    var affectsScrollIndicators : Bool {
        return true
    }
}

public enum WebControllerState {
    case creatingSession
    case loadingContent
    case needingSession
}

public protocol WebContentController {
    var view : UIView {get}
    var scrollView : UIScrollView {get}
    
    var alwaysRequiresOAuthUpdate : Bool { get}
    
    var initialContentState : WebControllerState { get }
    
    func loadURLRequest(_ request : URLRequest)
    
    func clearDelegate()
    func resetState()
}

private class WKWebViewContentController : WebContentController {
    fileprivate let webView = WKWebView(frame: CGRect.zero)
    
    var view : UIView {
        return webView
    }
    
    var scrollView : UIScrollView {
        return webView.scrollView
    }
    
    func clearDelegate() {
        return webView.navigationDelegate = nil
    }
    
    func loadURLRequest(_ request: URLRequest) {
        webView.load(request)
    }
    
    func resetState() {
        webView.stopLoading()
        webView.loadHTMLString("", baseURL: nil)
    }
    
    var alwaysRequiresOAuthUpdate : Bool {
        return false
    }
    
    var initialContentState : WebControllerState {
        return WebControllerState.loadingContent
    }
}

public let OAuthExchangePath = "/oauth2/login/"

// Allows access to course content that requires authentication.
// Forwarding our oauth token to the server so we can get a web based cookie
open class AuthenticatedWebViewController: UIViewController, WKNavigationDelegate {

    public typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & OEXSessionProvider
    
    internal let environment : Environment
    fileprivate let loadController : LoadStateViewController
    fileprivate let insetsController : ContentInsetsController
    fileprivate let headerInsets : HeaderViewInsets
    
    fileprivate lazy var webController : WebContentController = {
        let controller = WKWebViewContentController()
        controller.webView.navigationDelegate = self
        return controller
    
    }()
    
    fileprivate var state = WebControllerState.creatingSession
    
    fileprivate var contentRequest : URLRequest? = nil
    var currentUrl: URL? {
        return contentRequest?.url
    }
    
    public init(environment : Environment) {
        self.environment = environment
        
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
                    //TODO: snp verify
                    /*
                    if #available(iOS 9.0, *) {
                        make.top.equalTo(self.topLayoutGuide.bottomAnchor)
                    }
                    else {
                        make.top.equalTo(self.snp_topLayoutGuideBottom)
                    }*/
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
        
        if webController.alwaysRequiresOAuthUpdate {
            loadOAuthRefreshRequest()
        }
        else {
            debugPrint("Request: \(request.url!.absoluteString)")
            webController.loadURLRequest(request)
        }
    }
    
    // MARK: WKWebView delegate

    open func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        switch navigationAction.navigationType {
        case .linkActivated, .formSubmitted, .formResubmitted:
            if let URL = navigationAction.request.url {
                UIApplication.shared.openURL(URL)
            }
            decisionHandler(.cancel)
        default:
            decisionHandler(.allow)
        }
    }
    
    open func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        
        if let
        httpResponse = navigationResponse.response as? HTTPURLResponse,
        let statusCode = OEXHTTPStatusCode(rawValue: httpResponse.statusCode),
        let errorGroup = statusCode.errorGroup, state == .loadingContent
        {
            switch errorGroup {
            case .http4xx:
                self.state = .needingSession
            case .http5xx:
                self.loadController.state = LoadState.failed()
                decisionHandler(.cancel)
            }
        }
        decisionHandler(.allow)
        
    }
    
    open func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
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
        case .needingSession:
            state = .creatingSession
            loadOAuthRefreshRequest()
        }
    }
    
    open func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showError(error as NSError)
    }
    
    open func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showError(error as NSError)
    }
    
    open func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Don't use basic auth on exchange endpoint. That is explicitly non protected
        // and it screws up the authorization headers
        if let URL = webView.url, URL.absoluteString.hasSuffix(OAuthExchangePath) {
            completionHandler(.performDefaultHandling, nil)
        }
        else if let credential = environment.config.URLCredentialForHost(challenge.protectionSpace.host as NSString)  {
            completionHandler(.useCredential, credential)
        }
        else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

}

