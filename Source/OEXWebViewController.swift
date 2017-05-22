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
    
    var requestToLoad : NSURLRequest = NSURLRequest()
    var navigationControllerTitle : String = String()
    private let loadController : LoadStateViewController = LoadStateViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadController.setupInController(self, contentView: self.webView)
        
        webView.loadRequest(self.requestToLoad)
        navigationItem.title = self.navigationControllerTitle
        
        self.webView.scrollView.bounces = false
        
        self.webView.userInteractionEnabled = false
    }
    
    override func updateViewConstraints() {
        loadController.insets = UIEdgeInsets(top: self.topLayoutGuide.length, left: 0, bottom: self.bottomLayoutGuide.length, right : 0)
        super.updateViewConstraints()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func webViewDidStartLoad(webView: UIWebView){
        
        self.webView.userInteractionEnabled = false
    }
    func webViewDidFinishLoad(webView :UIWebView){
        
        self.loadController.state = .Loaded
        self.webView.userInteractionEnabled = true
    }
    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        self.loadController.state = LoadState.failed(error)
    }
    
    @IBAction func reloadPage(sender: UIButton) {
            webView.reload()
    }
    
}
