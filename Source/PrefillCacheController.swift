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
    
    fileprivate var state = WebControllerState.creatingSession
    
    fileprivate var webController: UIWebViewContentController?
    
    fileprivate var urlQueue = [URL]()
    fileprivate var isLoading = false
    
    // MARK: Initializers

    static let sharedController = PrefillCacheController()
    
    fileprivate override init() {
        //This prevents others from using the default '()' initializer for this class.
        super.init()
        
        state = .creatingSession
    }

	func reset() {
		state = .creatingSession
	}
    
    
    // MARK: Requests Loading
    
    fileprivate func loadOAuthRefreshRequest() {
        
        if let hostURL = OEXConfig.shared().apiHostURL(), let authorizationHeaders = OEXSession.shared()?.authorizationHeaders {
            
            let URL = hostURL.appendingPathComponent(OAuthExchangePath) 
            var exchangeRequest = URLRequest(url: URL)
            exchangeRequest.httpMethod = HTTPMethod.POST.rawValue
            
            for (key, value) in authorizationHeaders {
                exchangeRequest.addValue(value, forHTTPHeaderField: key)
            }
            
            loadRequest(exchangeRequest)
        }
    }
    
    
    // MARK: Public Methods
    
    func cacheWebContent(_ urls : [URL]) {
        
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
            
            let request = URLRequest(url: url)
            
            if state == .creatingSession && EVURLCache.storagePathForRequest(request) == nil {
                loadOAuthRefreshRequest()
            }
            else {
                debugPrint("Loading Request: \(request.url!.absoluteString)")

                state = .loadingContent
                loadRequest(request)
            }
        }
    }
    
    func stateOfWebContent(_ urls : [URL]) -> [DownloadState] {
        
        var resultStates = [DownloadState]()
        
        urls.forEach { (url) in
            
            if self.urlQueue.first == url {
                // Currently downloading
                resultStates.append(DownloadState(state: .active, progress: 50.0))
                
            } else if self.urlQueue.contains(url) {
                // In the download queue
                resultStates.append(DownloadState(state: .active, progress: 0.0))
                
            } else if (EVURLCache.shared.cachedResponse(for: URLRequest(url: url)) != nil) {
                // On the disk
                resultStates.append(DownloadState(state: .complete, progress: 100.0))
                
            } else {
                // Not cached
                resultStates.append(DownloadState(state: .available, progress: 0.0))
            }        
        }
        
        return resultStates
    }
    
    func cancelDownload(_ urls : [URL]) {
        
        debugPrint("Canceling URLs: \(urls)")
        
        urls.forEach { (incomingURL) in
            
            if state == .loadingContent && incomingURL == urlQueue.first {
                // Stop loading of the curret URL
                isLoading = false
                webController?.webView.stopLoading()
                
                urlQueue.removeFirst()
                
            } else {
                if let index = urlQueue.index(of: incomingURL) {
                    urlQueue.remove(at: index)
                }
            }
        }
        
        debugPrint("Remaining queue <\(isLoading)> after cancel: \(urlQueue)")
        
        //Resume loading if stoped
        if isLoading == false {
            
            if let url = urlQueue.first {
                
                let request = URLRequest(url: url)
                loadRequest(request)
                
            } else {
                cleanWebViewIfNeeded()
            }
        }
        
        postUpdateNotification()
    }
    
    
    // MARK: UIWebView delegate
    
    @objc internal func webViewDidFinishLoad(_ webView: UIWebView) {
        
        switch state {
        case .creatingSession:
            if let url = urlQueue.first {
                state = .loadingContent
                loadRequest(URLRequest(url: url))
            }
            else {
                cleanWebViewIfNeeded()
                postUpdateNotification()
            }
            
        case .loadingContent:
            // Call the progress block
    
            // Move to the next request
            if urlQueue.isEmpty == false {
                urlQueue.removeFirst()
            }
            
            if let url = urlQueue.first {
                loadRequest(URLRequest(url: url))
            } else {
                cleanWebViewIfNeeded()
            }
            
            postUpdateNotification()
            
        case .needingSession:
            state = .creatingSession
            loadOAuthRefreshRequest()
        }
    }
    
    @objc internal func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        // Call the completion block with error
        
        if state == .creatingSession {
            debugPrint("Failed caching authentication: \(error)")
            
            urlQueue.removeAll()
            
            cleanWebViewIfNeeded()
            postUpdateNotification()
            
            return
        }
        
        // Move to the next request
        if urlQueue.isEmpty == false {
            urlQueue.removeFirst()
        }
        
        if let url = urlQueue.first {
            loadRequest(URLRequest(url: url))
        } else {
            cleanWebViewIfNeeded()
        }

        postUpdateNotification()
    }
    
    
    //MARK:- Helper Methods
    
    fileprivate func loadRequest(_ request: URLRequest) {
        
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
    fileprivate func postUpdateNotification() {
        
        DispatchQueue.main.async(execute: {
            NotificationCenter.default.post(name: NSNotification.Name.OEXDownloadEnded, object: nil)
        })
    }
    
    fileprivate func cleanWebViewIfNeeded() {
        isLoading = false
        webController?.clearDelegate()
        webController = nil
    }
}
