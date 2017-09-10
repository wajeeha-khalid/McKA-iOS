//
//  WebViewLoadingProtocol.swift
//  edX
//
//  Created by Abdul Haseeb on 9/9/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation

open class WebViewLocalLoadingProtocol: URLProtocol {
    
    static let loadingKey = "https://maxcdn.bootstrapcdn.com"
    
    //This should be an instance property instead of a class property but since we can't either
    //instantiate or access an instance of NSURLProtocol there is no way for us to set this
    //property on instance so as a hack we have to set it on class
    //Setting it on class will share the same instance b/w all the instances of this class
    static var requestLoader: RequestLoader?
    
    func substitutionPaths() -> [String: String]? {
        guard let filePath = Bundle.main.path(forResource: "web-cache", ofType: "plist") else {
            client?.urlProtocol(self,
                                didFailWithError: NSError(domain: "", code: 0, userInfo: nil))
            return nil
        }
        guard let fileContent = NSDictionary(contentsOfFile: filePath) as? [String: String] else {
            return nil
        }
        
        return fileContent
    }
    
    func mimeType(forPath originalPath: String) -> String {
        var contentType: String
        let fileOriginalPath = URL(fileURLWithPath: originalPath)
        if (fileOriginalPath.pathExtension == "js") {
            contentType = "application/javascript"
        }
        else if (fileOriginalPath.pathExtension == "css") {
            contentType = "text/css"
        }
        else if (fileOriginalPath.pathExtension == "png") {
            contentType = "image/png"
        }
        else if (fileOriginalPath.pathExtension == "tff") {
            contentType = "application/x-font-ttf"
        }
        else if (fileOriginalPath.pathExtension == "woff") {
            contentType = "application/font-woff"
        }
        else {
            contentType = "application/octet-stream"
        }
        
        return contentType
    }
    
    override open class func canInit(with request: URLRequest) -> Bool {
        
        //If we are already loading this request then return false. otherwise it will go into an
        // infinite loop
        if URLProtocol.property(forKey: WebViewLoadingProtocol.loadingKey, in: request) != nil {
            return false
        }
        
        if let path = Bundle.main.path(forResource: "web-cache", ofType: "plist") {
            if let dic = NSDictionary(contentsOfFile: path) as? [String: String] {
                var filepath = request.url?.relativeString ?? ""
                filepath = filepath.replacingOccurrences(of: "file://", with: "")
                
                if dic[filepath] != nil {
                    return true
                }
            }
        }
        return false
    }
    
    override open class func canonicalRequest(for request: URLRequest) -> URLRequest {
        //        /*we need to set the policy to ignore cache here because everytime we send the response to
        //         protocol's client the URLSystem tries to cache the response which isn't needed when we return
        //         already cached response. URLCache won't cache data when the policy is set to ignore cache.*/
        
        return request
    }
    
    override open func startLoading() {
        
        let mutableRequest = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        URLProtocol.setProperty("true", forKey: WebViewLoadingProtocol.loadingKey, in: mutableRequest)
        
        let mimeType = self.mimeType(forPath: (mutableRequest.url?.absoluteString) ?? "")
        guard let path = getResoursePath(url: mutableRequest.url) else {
            return
        }
        
        let javaScriptStr = try! Data(contentsOf: URL(fileURLWithPath: path))
        let data = javaScriptStr
        let response = URLResponse(url: request.url!, mimeType: mimeType, expectedContentLength: data.count, textEncodingName: "utf-8")
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self
            , didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    
    open override func stopLoading() {
        
    }
    
    func getResoursePath(url: URL?) -> String? {
        guard let substitutionPath = self.substitutionPaths() else {
            return nil
        }
        
        guard let urlPath = url else{
            return nil
        }
        var urlPathString = urlPath.absoluteString
        urlPathString = urlPathString.replacingOccurrences(of: "file://", with: "")
        guard let resourseFilePath = Bundle.main.path(forResource: substitutionPath[urlPathString], ofType: urlPath.pathExtension) else {
            client?.urlProtocol(self,
                                didFailWithError: NSError(domain: "", code: 0, userInfo: nil))
            return nil
        }
        
        return resourseFilePath
    }
    
}
