//
//  WebNavigationViewController.swift
//  edX
//
//  Created by Abdul Haseeb on 9/12/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

class WebNavigationViewController: UIViewController {

    @IBOutlet weak var webView: UIWebView!
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var backBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var farwardBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var refreshBarButtonItem: UIBarButtonItem!
    let loadController: LoadStateViewController
    let loadingRequest: URLRequest
    let navigationBarTitle: String?
    
    public init(request: URLRequest, title: String) {
        loadController = LoadStateViewController()
        loadingRequest = request
        navigationBarTitle = title
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.loadRequest(loadingRequest)
        setBarButtonItemActions()
        setBarButtonItemStatus()
        addRightBarButtonsItems()
        uiSetup()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension WebNavigationViewController: UIWebViewDelegate {
    
    func webViewDidStartLoad(_ webView: UIWebView){
        
        self.webView.isUserInteractionEnabled = false
        setBarButtonItemStatus()
        progressView.isHidden = false
        progressView.setProgress(0.0, animated: false)
        progressView.setProgress(0.3, animated: true)
        self.loadController.state = .initial
    }
    
    func webViewDidFinishLoad(_ webView :UIWebView){
        self.loadController.state = .loaded
        progressView.setProgress(1.0, animated: true)
        self.webView.isUserInteractionEnabled = true
        setBarButtonItemStatus()
        self.loadController.state = .loaded
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        setBarButtonItemStatus()
        progressView.setProgress(1.0, animated: true)
        progressView.isHidden = true
        self.loadController.state = LoadState.failed(error as NSError)
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        return true
    }
    
}

extension WebNavigationViewController {
    
    func setBarButtonItemActions() {
        farwardBarButtonItem.action = #selector(farwardBarButtonItemAction)
        backBarButtonItem.action = #selector(backBarButtonItemAction)
        refreshBarButtonItem.action = #selector(refreshBarButtonItemAction)
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
            progressView.isHidden = true
        }
        
        if webView.canGoBack {
            backBarButtonItem.isEnabled = true
        } else {
            backBarButtonItem.isEnabled = false
        }
        
        if webView.canGoForward {
            farwardBarButtonItem.isEnabled = true
        } else {
            farwardBarButtonItem.isEnabled = false
        }
    }

}

extension WebNavigationViewController {
    fileprivate func addRightBarButtonsItems() {
        let doneButtonItem = UIBarButtonItem(title: Strings.done,
                                             style: .plain, target: self,
                                             action: #selector(self.done))

        self.navigationItem.leftBarButtonItems = [doneButtonItem]
    }
    
    @objc fileprivate func done()  {
        self.navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
    }
}

extension WebNavigationViewController {
    fileprivate func uiSetup() {
        loadController.setupInController(self, contentView: self.webView)
        navigationItem.title = navigationBarTitle
        progressView.isHidden = true
        webView.scalesPageToFit = true
    }
}
