//
//  OEXWebViewController.swift
//  edX
//
//  Created by Naveen Katari on 16/01/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

class OEXWebViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var errorView: UIView!
    
    var requestToLoad : URLRequest = URLRequest(url: NSURL() as URL)
    var navigationControllerTitle : String = String()
    fileprivate let loadController : LoadStateViewController = LoadStateViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadController.setupInController(self, contentView: self.webView)
        
        webView.loadRequest(self.requestToLoad)
        navigationItem.title = self.navigationControllerTitle
        
        self.webView.scrollView.bounces = false
        
        self.webView.isUserInteractionEnabled = false
    }
    
    override func updateViewConstraints() {
        loadController.insets = UIEdgeInsets(top: self.topLayoutGuide.length, left: 0, bottom: self.bottomLayoutGuide.length, right : 0)
        super.updateViewConstraints()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
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
    
    @IBAction func reloadPage(_ sender: UIButton) {
            webView.reload()
    }
    
}
