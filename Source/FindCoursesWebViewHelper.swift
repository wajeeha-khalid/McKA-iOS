//
//  FindCoursesWebViewHelper.swift
//  edX
//
//  Created by Akiva Leffert on 11/9/15.
//  Copyright © 2015-2016 edX. All rights reserved.
//

import UIKit
import WebKit
import SnapKit

@objc protocol FindCoursesWebViewHelperDelegate : class {
    func webViewHelper(_ helper : FindCoursesWebViewHelper, shouldLoadLinkWithRequest request: URLRequest) -> Bool
    func containingControllerForWebViewHelper(_ helper : FindCoursesWebViewHelper) -> UIViewController
}

class FindCoursesWebViewHelper: NSObject, WKNavigationDelegate {
    let config : OEXConfig?
    weak var delegate : FindCoursesWebViewHelperDelegate?
    
    let webView : WKWebView = WKWebView()
    let searchBar = UISearchBar()
    fileprivate var loadController = LoadStateViewController()
    
    fileprivate var request : URLRequest? = nil
    var searchBaseURL: URL?

    let bottomBar: UIView?
    
    init(config : OEXConfig?, delegate : FindCoursesWebViewHelperDelegate?, bottomBar: UIView?, showSearch: Bool) {
        self.config = config
        self.delegate = delegate
        self.bottomBar = bottomBar
        
        super.init()
        
        webView.navigationDelegate = self
        webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal
        webView.accessibilityIdentifier = "find-courses-webview"

        if let container = delegate?.containingControllerForWebViewHelper(self) {
            loadController.setupInController(container, contentView: webView)

            let searchbarEnabled = (config?.courseEnrollmentConfig.webviewConfig.nativeSearchbarEnabled ?? false) && showSearch

            let webviewTop: ConstraintItem
            if searchbarEnabled {
                searchBar.delegate = self

                container.view.insertSubview(searchBar, at: 0)

                searchBar.snp.makeConstraints{ make in
                    make.leading.equalTo(container.view)
                    make.trailing.equalTo(container.view)
                    make.top.equalTo(container.view)
                }
                webviewTop = searchBar.snp.bottom
            } else {
                webviewTop = container.view.snp.top
            }


            container.view.insertSubview(webView, at: 0)

            webView.snp.makeConstraints { make in
                make.leading.equalTo(container.view)
                make.trailing.equalTo(container.view)
                make.bottom.equalTo(container.view)
                make.top.equalTo(webviewTop)
            }

            if let bar = bottomBar {
                container.view.insertSubview(bar, at: 0)
                bar.snp.makeConstraints({ (make) in
                    make.height.equalTo(50)
                    make.leading.equalTo(container.view)
                    make.trailing.equalTo(container.view)
                    make.bottom.equalTo(container.view)
                })
            }
        }
    }


    fileprivate var courseInfoTemplate : String {
        return config?.courseEnrollmentConfig.webviewConfig.courseInfoURLTemplate ?? ""
    }
    
    var isWebViewLoaded : Bool {
        return self.loadController.state.isLoaded
    }
    
    func loadRequestWithURL(_ url : URL) {
        let request = URLRequest(url: url)
        self.webView.load(request)
        self.request = request
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let request = navigationAction.request
        let capturedLink = navigationAction.navigationType == .linkActivated && (self.delegate?.webViewHelper(self, shouldLoadLinkWithRequest: request) ?? true)

        let outsideLink = (request.mainDocumentURL?.host != self.request?.url?.host)
        if let URL = request.url, outsideLink || capturedLink {
            UIApplication.shared.openURL(URL)
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.loadController.state = .loaded
        
        //Setting webView accessibilityValue for testing
        webView.evaluateJavaScript("document.getElementsByClassName('course-card')[0].innerText",
                                   completionHandler: { (result: AnyObject?, error: NSError?) in
                                    
                                    if (error == nil) {
                                        self.webView.accessibilityValue = "findCoursesLoaded"
                                    }
        } as? (Any?, Error?) -> Void)
        if let bar = bottomBar {
            bar.superview?.bringSubview(toFront: bar)
        }
    }
    
    func showError(_ error : NSError) {
        let buttonInfo = MessageButtonInfo(title: Strings.retry) {[weak self] _ in
            if let request = self?.request {
                self?.webView.load(request)
                self?.loadController.state = .initial
            }
        }
        self.loadController.state = LoadState.failed(error, buttonInfo: buttonInfo)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showError(error as NSError)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showError(error as NSError)
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let credential = config?.URLCredentialForHost(challenge.protectionSpace.host) {
            completionHandler(.useCredential, credential)
        }
        else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

}

extension FindCoursesWebViewHelper: UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()

        guard let searchTerms = searchBar.text, let searchURL = searchBaseURL else { return }
        if let URL = FindCoursesWebViewHelper.buildQuery(searchURL.absoluteString, toolbarString: searchTerms) {
            loadRequestWithURL(URL)
        }
    }

    @objc static func buildQuery(_ baseURL: String, toolbarString: String) -> URL? {
        let items = toolbarString.components(separatedBy: " ")
        let escapedItems = items.flatMap { $0.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) }
        let searchTerm = "search_query=" + escapedItems.joined(separator: "+")
        let newQuery: String
        if baseURL.contains("?") {
            newQuery = baseURL + "&" + searchTerm
        } else {
            newQuery = baseURL + "?" + searchTerm

        }
        return URL(string: newQuery)
    }
}
