//
//  PrefillCacheController.swift
//  edX
//
//  Created by Konstantinos Angistalis on 07/03/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit


/// Allows preactive filling of the cache with course content that requires authentication.
class PrefillCacheController: NSObject, UIWebViewDelegate {
    
    private var state = WebControllerState.CreatingSession
    
    private var webController: UIWebViewContentController?
    
    private var urlQueue = [NSURL]()
    private var isLoading = false
    
    // MARK: Initializers

    static let sharedController = PrefillCacheController()
    
    private override init() {
        //This prevents others from using the default '()' initializer for this class.
        super.init()
        
        state = .CreatingSession
    }

	func reset() {
		state = .CreatingSession
	}
    
    
    // MARK: Requests Loading
    
    private func loadOAuthRefreshRequest() {
        
        if let hostURL = OEXConfig.sharedConfig().apiHostURL(), let authorizationHeaders = OEXSession.sharedSession()?.authorizationHeaders {
            
            guard let URL = hostURL.URLByAppendingPathComponent(OAuthExchangePath) else { return }
            let exchangeRequest = NSMutableURLRequest(URL: URL)
            exchangeRequest.HTTPMethod = HTTPMethod.POST.rawValue
            
            for (key, value) in authorizationHeaders {
                exchangeRequest.addValue(value, forHTTPHeaderField: key)
            }
            
            loadRequest(exchangeRequest)
        }
    }
    
    
    // MARK: Public Methods
    
    func cacheWebContent(urls : [NSURL]) {
        
        guard urls.count > 0 else {
            return
        }
        
        debugPrint("cacheWebContent: \(urls)")
        
        // Do not allow duplicates
        urls.forEach { (incomingURL) in
            if urlQueue.contains(incomingURL) == false {
                urlQueue.append(incomingURL)
            }
        }
        
        guard isLoading == false else {
            return
        }
        
        if let url = urlQueue.first {
            
            let request = NSURLRequest(URL: url)
            
            if state == .CreatingSession && EVURLCache.storagePathForRequest(request) == nil {
                loadOAuthRefreshRequest()
            }
            else {
                debugPrint("Loading Request: \(request.URLString)")

                state = .LoadingContent
                loadRequest(request)
            }
        }
    }
    
    func stateOfWebContent(urls : [NSURL]) -> [DownloadState] {
        
        var resultStates = [DownloadState]()
        
        urls.forEach { (url) in
            
            if self.urlQueue.first == url {
                // Currently downloading
                resultStates.append(DownloadState(state: .Active, progress: 50.0))
                
            } else if self.urlQueue.contains(url) {
                // In the download queue
                resultStates.append(DownloadState(state: .Active, progress: 0.0))
                
            } else if (EVURLCache.sharedURLCache().cachedResponseForRequest(NSURLRequest(URL: url)) != nil) {
                // On the disk
                resultStates.append(DownloadState(state: .Complete, progress: 100.0))
                
            } else {
                // Not cached
                resultStates.append(DownloadState(state: .Available, progress: 0.0))
            }        
        }
        
        return resultStates
    }
    
    func cancelDownload(urls : [NSURL]) {
        
        debugPrint("Canceling URLs: \(urls)")
        
        urls.forEach { (incomingURL) in
            
            if state == .LoadingContent && incomingURL == urlQueue.first {
                // Stop loading of the curret URL
                isLoading = false
                webController?.webView.stopLoading()
                
                urlQueue.removeFirst()
                
            } else {
                if let index = urlQueue.indexOf(incomingURL) {
                    urlQueue.removeAtIndex(index)
                }
            }
        }
        
        debugPrint("Remaining queue <\(isLoading)> after cancel: \(urlQueue)")
        
        //Resume loading if stoped
        if isLoading == false {
            
            if let url = urlQueue.first {
                
                let request = NSURLRequest(URL: url)
                loadRequest(request)
                
            } else {
                cleanWebViewIfNeeded()
            }
        }
        
        postUpdateNotification()
    }
    
    
    // MARK: UIWebView delegate
    
    @objc internal func webViewDidFinishLoad(webView: UIWebView) {
        
        switch state {
        case .CreatingSession:
            if let url = urlQueue.first {
                state = .LoadingContent
                loadRequest(NSURLRequest(URL: url))
            }
            else {
                cleanWebViewIfNeeded()
                postUpdateNotification()
            }
            
        case .LoadingContent:
            // Call the progress block
            debugPrint("Finished caching: \(urlQueue.first)")
            
            // Move to the next request
            if urlQueue.isEmpty == false {
                urlQueue.removeFirst()
            }
            
            if let url = urlQueue.first {
                loadRequest(NSURLRequest(URL: url))
            } else {
                cleanWebViewIfNeeded()
            }
            
            postUpdateNotification()
            
        case .NeedingSession:
            state = .CreatingSession
            loadOAuthRefreshRequest()
        }
    }
    
    @objc internal func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        // Call the completion block with error
        
        if state == .CreatingSession {
            debugPrint("Failed caching authentication: \(error)")
            
            urlQueue.removeAll()
            
            cleanWebViewIfNeeded()
            postUpdateNotification()
            
            return
        }
        
        debugPrint("Failed caching: \(urlQueue.first)")
        
        // Move to the next request
        if urlQueue.isEmpty == false {
            urlQueue.removeFirst()
        }
        
        if let url = urlQueue.first {
            loadRequest(NSURLRequest(URL: url))
        } else {
            cleanWebViewIfNeeded()
        }

        postUpdateNotification()
    }
    
    
    //MARK:- Helper Methods
    
    private func loadRequest(request: NSURLRequest) {
        
        if let webController = webController {
            
            isLoading = true
            webController.loadURLRequest(request)
            
        } else {
            
            let controller = UIWebViewContentController()
            controller.webView.delegate = self
            
            isLoading = true
            controller.loadURLRequest(request)
            
            webController = controller
        }
    }

    
    ///Post download update notification
    private func postUpdateNotification() {
        
        dispatch_async(dispatch_get_main_queue(), {
            NSNotificationCenter.defaultCenter().postNotificationName(OEXDownloadEndedNotification, object: nil)
        })
    }
    
    private func cleanWebViewIfNeeded() {
        isLoading = false
        webController?.clearDelegate()
        webController = nil
    }
}
