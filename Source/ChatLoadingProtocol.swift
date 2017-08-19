//
//  ChatLoadingProtocol.swift
//  edX
//
//  Created by Salman Jamil on 6/6/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

// checks if a request is coming from a WebView
func isWebViewRequest(_ request: URLRequest) -> Bool {
    guard let path = request.url?.path else {
        return false
    }
    
    let referer = request.allHTTPHeaderFields?["Referer"]
    
    if  (path.contains("type@html") ||
        path.contains("type@chat") ||
        path.range(of: "i4x://.*/chat/", options: .regularExpression) != nil ||
        path.range(of: "i4x://.*/html/", options: .regularExpression) != nil ||
        referer?.contains("type@html") == true ||
        referer?.contains("type@chat") == true ||
        referer?.range(of: "i4x://.*/chat/", options: .regularExpression) != nil ||
        referer?.range(of: "i4x://.*/html/", options: .regularExpression) != nil) {
        return true
    }
    
    return false
}

@objc protocol RequestCache {
    func cachedResponseForRequest(_ request: URLRequest) -> CachedURLResponse?
    func storeCachedResponse(_ response: CachedURLResponse, forRequest: URLRequest)
}

@objc protocol RequestLoader {
    func loadRequest(_ request: URLRequest, completionHandler:@escaping ( Data?, URLResponse?, Error?) -> Void)
    func cancel()
}

/**
 Loads a request from the network using a URLSession instance...
 */
class NetworkRequestLoader: NSObject, RequestLoader {
    let session: URLSession
    var task: URLSessionDataTask?
    init(session: URLSession) {
        self.session = session
    }
    
    func loadRequest(_ request: URLRequest, completionHandler: @escaping ( Data?, URLResponse?, Error?) -> Void) {
        task = session.dataTask(with: request, completionHandler: completionHandler)
        task?.resume()
    }
    
    func cancel() {
        task?.cancel()
    }
}

extension URLCache : RequestCache {
}

/**
 Caching Decorator around any loader. tries to fetch the response from provided cache before asking the decoarated loader to fetch it.
 */
class CachedRequestLoader: NSObject, RequestLoader {
    let cache: RequestCache
    let loader: RequestLoader
    
    init(cache: RequestCache, loader: RequestLoader) {
        self.cache = cache
        self.loader = loader
    }
    
    func loadRequest(_ request: URLRequest, completionHandler:@escaping (Data?, URLResponse?, Error?) -> Void) {
        var cachableRequest = request
        cachableRequest.cachePolicy = .returnCacheDataElseLoad
        if let cachedResponse = cache.cachedResponseForRequest(cachableRequest as URLRequest) {
            completionHandler(cachedResponse.data, cachedResponse.response, nil)
        } else {
            loader.loadRequest(request) { (data, response, error) in
                if let data = data, let response = response {
                    let cachedResponse = CachedURLResponse(response: response, data: data)
                    // don't cache POST, PUT, DELETE etc..
                    if request.httpMethod == "GET" {
                        self.cache.storeCachedResponse(cachedResponse, forRequest: cachableRequest as URLRequest)
                    }
                }
                completionHandler(data, response, error)
            }
        }
    }
    
    func cancel() {
        loader.cancel()
    }
}

/*
 There are two reasons for implementing custom protocol for loading WebView requests
 1.) UIWebView returns error when device is not connected to internet. so we intercept the requests to return cached response
 2.) Files greater than 500Kb are not cached by WebView so we are downloading the resources ourselves so that we can cache them irrespective of size..
 */
open class WebViewLoadingProtocol: URLProtocol {
    
    static let loadingKey = "com.Pique.requestLoading"
    
    //This should be an instance property instead of a class property but since we can't either 
    //instantiate or access an instance of NSURLProtocol there is no way for us to set this
    //property on instance so as a hack we have to set it on class
    //Setting it on class will share the same instance b/w all the instances of this class
    static var requestLoader: RequestLoader?
    
    override open class func canInit(with request: URLRequest) -> Bool {
        
        //If we are already loading this request then return false. otherwise it will go into an 
        // infinite loop
        if URLProtocol.property(forKey: WebViewLoadingProtocol.loadingKey, in: request) != nil {
            return false
        }
        
        if isWebViewRequest(request) {
            return true
        }
        
        return false
    }
    
    override open class func canonicalRequest(for request: URLRequest) -> URLRequest {
        var mutableRequest = request
        /*we need to set the policy to ignore cache here because everytime we send the response to 
         protocol's client the URLSystem tries to cache the response which isn't needed when we return 
         already cached response. URLCache won't cache data when the policy is set to ignore cache.*/
        mutableRequest.cachePolicy = .reloadIgnoringLocalCacheData
        return mutableRequest
    }
    
    override open func startLoading() {
        guard let loader = WebViewLoadingProtocol.requestLoader else {
            fatalError("No loader found for loading request")
        }
        
        let mutableRequest = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        //Tag the request with this property value so that if we receive this request again
        // we can know that we already in process of loading it
        URLProtocol.setProperty("true", forKey: WebViewLoadingProtocol.loadingKey, in: mutableRequest)
        loader.loadRequest(mutableRequest as URLRequest) { (data, response, error) in
            if let response = response {
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let error = error {
                self.client?.urlProtocol(self, didFailWithError: error)
            } else if let data = data {
                self.client?.urlProtocol(self, didLoad: data)
            }
            self.client?.urlProtocolDidFinishLoading(self)
        }
    }
    
    override open func stopLoading() {
        guard let loader = WebViewLoadingProtocol.requestLoader else {
            fatalError("No loader found for loading request")
        }
        
        loader.cancel()
    }
}

