//
//  ChatLoadingProtocol.swift
//  edX
//
//  Created by Salman Jamil on 6/6/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

// checks if a request is coming from a WebView
func isWebViewRequest(request: NSURLRequest) -> Bool {
    guard let path = request.URL?.path else {
        return false
    }
    
    let referer = request.allHTTPHeaderFields?["Referer"]
    
    if  (path.containsString("type@html") ||
        path.containsString("type@chat") ||
        path.rangeOfString("i4x://.*/chat/", options: .RegularExpressionSearch) != nil ||
        path.rangeOfString("i4x://.*/html/", options: .RegularExpressionSearch) != nil ||
        referer?.containsString("type@html") == true ||
        referer?.containsString("type@chat") == true ||
        referer?.rangeOfString("i4x://.*/chat/", options: .RegularExpressionSearch) != nil ||
        referer?.rangeOfString("i4x://.*/html/", options: .RegularExpressionSearch) != nil) {
        return true
    }
    
    return false
}

@objc protocol RequestCache {
    func cachedResponseForRequest(request: NSURLRequest) -> NSCachedURLResponse?
    func storeCachedResponse(response: NSCachedURLResponse, forRequest: NSURLRequest)
}

@objc protocol RequestLoader {
    func loadRequest(request: NSURLRequest, completionHandler: ( NSData?, NSURLResponse?, NSError?) -> Void)
    func cancel()
}

/**
 Loads a request from the network using a URLSession instance...
 */
class NetworkRequestLoader: NSObject, RequestLoader {
    let session: NSURLSession
    var task: NSURLSessionDataTask?
    init(session: NSURLSession) {
        self.session = session
    }
    
    func loadRequest(request: NSURLRequest, completionHandler: ( NSData?, NSURLResponse?, NSError?) -> Void) {
        task = session.dataTaskWithRequest(request, completionHandler: completionHandler)
        task?.resume()
    }
    
    func cancel() {
        task?.cancel()
    }
}

extension NSURLCache : RequestCache {
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
    
    func loadRequest(request: NSURLRequest, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) {
        let cachableRequest = request.mutableCopy() as! NSMutableURLRequest
        cachableRequest.cachePolicy = .ReturnCacheDataElseLoad
        if let cachedResponse = cache.cachedResponseForRequest(cachableRequest) {
            completionHandler(cachedResponse.data, cachedResponse.response, nil)
        } else {
            loader.loadRequest(request) { (data, response, error) in
                if let data = data, response = response {
                    let cachedResponse = NSCachedURLResponse(response: response, data: data)
                    // don't cache POST, PUT, DELETE etc..
                    if request.HTTPMethod == "GET" {
                        self.cache.storeCachedResponse(cachedResponse, forRequest: cachableRequest)
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
public class WebViewLoadingProtocol: NSURLProtocol {
    
    static let loadingKey = "com.Pique.requestLoading"
    
    //This should be an instance property instead of a class property but since we can't either 
    //instantiate or access an instance of NSURLProtocol there is no way for us to set this
    //property on instance so as a hack we have to set it on class
    //Setting it on class will share the same instance b/w all the instances of this class
    static var requestLoader: RequestLoader?
    
    override public class func canInitWithRequest(request: NSURLRequest) -> Bool {
        
        //If we are already loading this request then return false. otherwise it will go into an 
        // infinite loop
        if NSURLProtocol.propertyForKey(WebViewLoadingProtocol.loadingKey, inRequest: request) != nil {
            return false
        }
        
        if isWebViewRequest(request) {
            return true
        }
        
        return false
    }
    
    override public class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
        let mutableRequest = request.mutableCopy() as! NSMutableURLRequest
        /*we need to set the policy to ignore cache here because everytime we send the response to 
         protocol's client the URLSystem tries to cache the response which isn't needed when we return 
         already cached response. URLCache won't cache data when the policy is set to ignore cache.*/
        mutableRequest.cachePolicy = .ReloadIgnoringLocalCacheData
        return mutableRequest
    }
    
    override public func startLoading() {
        guard let loader = WebViewLoadingProtocol.requestLoader else {
            fatalError("No loader found for loading request")
        }
        
        let mutableRequest = request.mutableCopy() as! NSMutableURLRequest
        //Tag the request with this property value so that if we receive this request again
        // we can know that we already in process of loading it
        NSURLProtocol.setProperty("true", forKey: WebViewLoadingProtocol.loadingKey, inRequest: mutableRequest)
        loader.loadRequest(mutableRequest) { (data, response, error) in
            if let response = response {
                self.client?.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .NotAllowed)
            }
            if let error = error {
                self.client?.URLProtocol(self, didFailWithError: error)
            } else if let data = data {
                self.client?.URLProtocol(self, didLoadData: data)
            }
            self.client?.URLProtocolDidFinishLoading(self)
        }
    }
    
    override public func stopLoading() {
        guard let loader = WebViewLoadingProtocol.requestLoader else {
            fatalError("No loader found for loading request")
        }
        
        loader.cancel()
    }
}

