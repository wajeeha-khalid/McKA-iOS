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
    
    @IBOutlet weak var backBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var farwardBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var refreshBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var stopBarButtonItem: UIBarButtonItem!
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
    }
    
    func webViewDidFinishLoad(_ webView :UIWebView){
        self.loadController.state = .loaded
        self.webView.isUserInteractionEnabled = true
        setBarButtonItemStatus()
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        setBarButtonItemStatus()
        
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        return true
    }
    
}

extension WebNavigationViewController {
    
    func setBarButtonItemActions() {
        farwardBarButtonItem.action = #selector(OEXResourcesViewController.farwardBarButtonItemAction)
        backBarButtonItem.action = #selector(OEXResourcesViewController.backBarButtonItemAction)
        refreshBarButtonItem.action = #selector(OEXResourcesViewController.refreshBarButtonItemAction)
        stopBarButtonItem.action = #selector(OEXResourcesViewController.stopLoadingBarButtonItemAction)
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
    
    func stopLoadingBarButtonItemAction() {
        webView.stopLoading()
    }
    
    func setBarButtonItemStatus() {
        if webView.isLoading {
            stopBarButtonItem.isEnabled = true
        } else {
            stopBarButtonItem.isEnabled = false
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
        navigationItem.title = navigationBarTitle
    }
}
