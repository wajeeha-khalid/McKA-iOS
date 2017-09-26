//
//  CourseOutline.swift
//  edX
//
//  Created by Jake Lim on 5/09/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//


import Foundation
import SwiftyJSON
import Alamofire

public enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

public enum RequestBody {
    case jsonBody(JSON)
    case formEncoded([String:String])
    case dataBody(data : Data, contentType: String)
    case emptyBody
}

private enum DeserializationResult<Out> {
    case deserializedResult(value : Result<Out>, original : Data?)
    case reauthenticationRequest(AuthenticateRequestCreator, original: Data?)
}

public typealias AuthenticateRequestCreator = (_ _networkManager: NetworkManager, _ _completion: @escaping (_ _success : Bool) -> Void) -> Void
public typealias ServiceResponse = (Bool?) -> Void

public enum AuthenticationAction {
    case proceed
    case authenticate(AuthenticateRequestCreator)
    
    public var isProceed : Bool {
        switch self {
        case .proceed(_): return true
        case .authenticate(_): return false
        }
    }
    
    public var isAuthenticate : Bool {
        switch self {
        case .proceed(_): return false
        case .authenticate(_): return true
        }
    }
}

public enum ResponseDeserializer<Out> {
    case jsonResponse((HTTPURLResponse, JSON) -> Result<Out>)
    case dataResponse((HTTPURLResponse, Data) -> Result<Out>)
    case noContent((HTTPURLResponse) -> Result<Out>)
    
    func map<A>(_ f: @escaping (Out) -> A) -> ResponseDeserializer<A> {
        switch self {
        case let .jsonResponse(d): return .jsonResponse({(request, json) in d(request, json).map(f)})
        case let .dataResponse(d): return .dataResponse({(request, data) in d(request, data).map(f)})
        case let .noContent(d): return .noContent({args in d(args).map(f)})
        }
    }
}

public protocol ResponseInterceptor {
    func handleResponse<Out>(_ result: NetworkResult<Out>) -> Result<Out>
}

public struct NetworkRequest<Out> {
    public let method : HTTPMethod
    public let path : String // Absolute URL or URL relative to the API base
    public let requiresAuth : Bool
    public let body : RequestBody
    public let query: [String:JSON]
    public let deserializer : ResponseDeserializer<Out>
    public let additionalHeaders: [String: String]?
    
    public init(method : HTTPMethod,
                path : String,
                requiresAuth : Bool = false,
                body : RequestBody = .emptyBody,
                query : [String:JSON] = [:],
                headers: [String: String]? = nil,
                deserializer : ResponseDeserializer<Out>) {
        self.method = method
        self.path = path
        self.requiresAuth = requiresAuth
        self.body = body
        self.query = query
        self.deserializer = deserializer
        self.additionalHeaders = headers
    }
    
    public func map<A>(_ f : @escaping (Out) -> A) -> NetworkRequest<A> {
        return NetworkRequest<A>(method: method, path: path, requiresAuth: requiresAuth, body: body, query: query, headers: additionalHeaders, deserializer: deserializer.map(f))
        
    }
}

extension NetworkRequest: CustomDebugStringConvertible {
    public var debugDescription: String { return "\(type(of: self)) {\(method):\(path)}" }
}


public struct NetworkResult<Out> {
    public let request: URLRequest?
    public let response: HTTPURLResponse?
    public let data: Out?
    public let baseData : Data?
    public let error: NSError?
    
    public init(request : URLRequest?, response : HTTPURLResponse?, data : Out?, baseData : Data?, error : NSError?) {
        self.request = request
        self.response = response
        self.data = data
        self.error = error
        self.baseData = baseData
    }
}

open class NetworkTask : Removable {
    let request : Request
    fileprivate init(request : Request) {
        self.request = request
    }
    
    open func remove() {
        request.cancel()
    }
}

@objc public protocol AuthorizationHeaderProvider {
    var authorizationHeaders : [String:String] { get }
}

@objc public protocol URLCredentialProvider {
    func URLCredentialForHost(_ host : String) -> URLCredential?
}


@objc public protocol NetworkManagerProvider {
    var networkManager : NetworkManager { get }
}

extension NSError {
    
    public static func oex_unknownNetworkError() -> NSError {
        return NSError(domain: NetworkManager.errorDomain, code: NetworkManager.Error.unknownError.rawValue, userInfo: nil)
    }
    
    static func oex_HTTPError(_ statusCode : Int, userInfo: [AnyHashable: Any]) -> NSError {
        return NSError(domain: NetworkManager.errorDomain, code: statusCode, userInfo: userInfo)
    }
    
    public static func oex_outdatedVersionError() -> NSError {
        return NSError(domain: NetworkManager.errorDomain, code: NetworkManager.Error.outdatedVersionError.rawValue, userInfo: nil)
    }
    
    public var oex_isNoInternetConnectionError : Bool {
        return self.domain == NSURLErrorDomain && (self.code == NSURLErrorNotConnectedToInternet || self.code == NSURLErrorNetworkConnectionLost)
    }
    
    public func errorIsThisType(_ error: NSError) -> Bool {
        return error.domain == NetworkManager.errorDomain && error.code == self.code
    }
}

open class NetworkManager : NSObject {
    fileprivate static let errorDomain = "com.edx.NetworkManager"
    enum Error : Int {
        case unknownError = -1
        case outdatedVersionError = -2
    }
    
    open static let NETWORK = "NETWORK" // Logger key
    
    public typealias JSONInterceptor = (_ _response : HTTPURLResponse, _ _json : JSON) -> Result<JSON>
    public typealias Authenticator = (_ _response: HTTPURLResponse?, _ _data: Data) -> AuthenticationAction
    
    open let baseURL : URL
    
    fileprivate let authorizationHeaderProvider: AuthorizationHeaderProvider?
    fileprivate let credentialProvider : URLCredentialProvider?
    fileprivate let cache : ResponseCache
    fileprivate var jsonInterceptors : [JSONInterceptor] = []
    fileprivate var responseInterceptors: [ResponseInterceptor] = []
    open var authenticator : Authenticator?
    
    public init(authorizationHeaderProvider: AuthorizationHeaderProvider? = nil, credentialProvider : URLCredentialProvider? = nil, baseURL : URL, cache : ResponseCache) {
        self.authorizationHeaderProvider = authorizationHeaderProvider
        self.credentialProvider = credentialProvider
        self.baseURL = baseURL
        self.cache = cache
        super.init()
        SessionManager.default.adapter = self
    }
    
    open static var unknownError : NSError { return NSError.oex_unknownNetworkError() }
    
    /// Allows you to add a processing pass to any JSON response.
    /// Typically used to check for errors that can be sent by any request
    open func addJSONInterceptor(_ interceptor : @escaping (HTTPURLResponse,JSON) -> Result<JSON>) {
        jsonInterceptors.append(interceptor)
    }
    
    open func addResponseInterceptors(_ interceptor: ResponseInterceptor) {
        responseInterceptors.append(interceptor)
    }
    
    open func URLRequestWithRequest<Out>(_ request : NetworkRequest<Out>) -> Result<URLRequest> {
        return URL(string: request.path, relativeTo: baseURL).toResult(NetworkManager.unknownError).flatMap { url -> Result<Foundation.URLRequest> in
            
            let URLRequest = Foundation.URLRequest(url: url)
            if request.query.count == 0 {
                return .success(URLRequest)
            }
            
            var queryParams : [String:String] = [:]
            for (key, value) in request.query {
                if let stringValue = value.rawString(options : JSONSerialization.WritingOptions()) {
                    queryParams[key] = stringValue
                }
            }
            
            // Alamofire has a kind of contorted API where you can encode parameters over URLs
            // or through the POST body, but you can't do both at the same time.
            //
            // So first we encode the get parameters
            do {
                let encoded = try URLEncoding.default.encode(URLRequest, with: queryParams)
                return .success(encoded)
            } catch (let error) {
                return .failure(error as NSError)
            }
            }
            .flatMap { URLRequest in
                var mutableURLRequest = URLRequest
                if request.requiresAuth {
                    for (key, value) in self.authorizationHeaderProvider?.authorizationHeaders ?? [:] {
                        print ("key value is \(key), \(value)")
                        mutableURLRequest.setValue(value, forHTTPHeaderField: key)
                    }
                }
                mutableURLRequest.httpMethod = request.method.rawValue
                if let additionalHeaders = request.additionalHeaders {
                    for (header, value) in additionalHeaders {
                        mutableURLRequest.setValue(value, forHTTPHeaderField: header)
                    }
                }
                
                
                // Now we encode the body
                switch request.body {
                case .emptyBody:
                    return .success(mutableURLRequest)
                case let .dataBody(data: data, contentType: contentType):
                    mutableURLRequest.httpBody = data
                    mutableURLRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
                    return .success(mutableURLRequest)
                case let .formEncoded(dict):
                    do {
                        let encoded = try URLEncoding.default.encode(mutableURLRequest, with: dict)
                        return .success(encoded)
                    } catch (let error) {
                        return .failure(error as NSError)
                    }
                case let .jsonBody(json):
                    
                    do {
                        var encoded = try JSONEncoding.default.encode(mutableURLRequest, with: json.dictionaryObject ?? [:])
                        if let additionalHeaders = request.additionalHeaders {
                            for (header, value) in additionalHeaders {
                                encoded.setValue(value, forHTTPHeaderField: header)
                            }
                        }
                        return .success(encoded)
                    } catch (let error) {
                        return .failure(error as NSError)
                    }
                    
                }
                
        }
    }
    
    fileprivate static func deserialize<Out>(_ deserializer : ResponseDeserializer<Out>, interceptors : [JSONInterceptor], response : HTTPURLResponse?, data : Data?, error: NSError) -> Result<Out> {
        if let response = response {
            switch deserializer {
            case let .jsonResponse(f):
                if let data = data,
                    let raw : AnyObject = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions()) as AnyObject
                {
                    let json = JSON(raw)
                   //Logger.log(...)
                    let result = interceptors.reduce(.success(json), { (acc: Result<JSON>, interceptor)  in
                        return acc.flatMap {
                            interceptor(response, $0)
                        }
                    })
                    return result.flatMap {
                        return f(response, $0)
                    }
                }
                else {
                    return .failure(error)
                }
            case let .dataResponse(f):
                return data.toResult(error).flatMap { f(response, $0) }
            case let .noContent(f):
                if response.hasErrorResponseCode() { // server error
                    guard let data = data,
                        let raw : AnyObject = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions()) as AnyObject else {
                            return .failure(error)
                    }
                    let userInfo = JSON(raw).object as? [AnyHashable: Any]
                    return .failure(NSError.oex_HTTPError(response.statusCode, userInfo: userInfo ?? [:]))
                }
                
                return f(response)
            }
        }
        else {
            return .failure(error)
        }
    }
    
    @discardableResult open func taskForRequest<Out>(_ networkRequest : NetworkRequest<Out>, handler: @escaping (NetworkResult<Out>) -> Void) -> Removable {
        let URLRequest = URLRequestWithRequest(networkRequest)
        let authenticator = self.authenticator
        let interceptors = jsonInterceptors

        let task = URLRequest.map {URLRequest -> NetworkTask in
            Logger.logInfo(NetworkManager.NETWORK, "Request is \(URLRequest)")
            let task: DataRequest = request(URLRequest)
            
            let dataResponseSerializer: DataResponseSerializer<DeserializationResult<Out>> = DataResponseSerializer(serializeResponse: { (request, response, data, error)  in
               
                switch authenticator?(response, data!) ?? .proceed {
                case .proceed:
                    let result = NetworkManager.deserialize(networkRequest.deserializer, interceptors: interceptors, response: response, data: data, error: NetworkManager.unknownError)
                    return .success(DeserializationResult.deserializedResult(value : result, original : data))
                case .authenticate(let authenticateRequest):
                    return .success(DeserializationResult.reauthenticationRequest(authenticateRequest, original: data))
                }
            })
            task.response(responseSerializer: dataResponseSerializer, completionHandler: { obj in
                switch obj.result {
                case let .success(.deserializedResult(value, original)):
                    let result = NetworkResult<Out>(request: obj.request, response: obj.response, data: value.value, baseData: original, error: obj.error as NSError?)
                    Logger.logInfo(NetworkManager.NETWORK, "Response is \(String(describing: obj.response))")
                    handler(result)
                case let .success(.reauthenticationRequest(authHandler, originalData)):
                    authHandler(self, {success in
                        if success {
                            // Logger.logInfo(NetworkManager.NETWORK, "Reauthentication, reattempting original request")
                            _ = self.taskForRequest(networkRequest, handler: handler)
                        }
                        else {
                            // Logger.logInfo(NetworkManager.NETWORK, "Reauthentication unsuccessful")
                            handler(NetworkResult<Out>(request: obj.request, response: obj.response, data: nil, baseData: originalData, error: obj.error as NSError?))
                        }
                    })
                case .failure:
                    assert(false, "Deserialization failed in an unexpected way")
                    handler(NetworkResult<Out>(request:obj.request, response:obj.response, data: nil, baseData: nil, error: obj.error as NSError?))
                }
                })
            
            if let
                host = URLRequest.url?.host,
                let credential = self.credentialProvider?.URLCredentialForHost(host)
            {
                task.authenticate(usingCredential: credential)
            }
            task.resume()
            return NetworkTask(request: task)
        }
        
        switch task {
        case let .success(t): return t
        case let .failure(error):
            DispatchQueue.main.async {
                handler(NetworkResult(request: nil, response: nil, data: nil, baseData : nil, error: error))
            }
            return BlockRemovable {}
        }
    }
    
    fileprivate func combineWithPersistentCacheFetch<Out>(_ stream : edXCore.Stream<Out>, request : NetworkRequest<Out>) -> edXCore.Stream<Out> {
        if let URLRequest = URLRequestWithRequest(request).value {
            let cacheStream = Sink<Out>()
            let interceptors = jsonInterceptors
            cache.fetchCacheEntryWithRequest(URLRequest, completion: {(entry : ResponseCacheEntry?) -> Void in
                
                if let entry = entry {
                    DispatchQueue.global(qos: .default).async(execute: {[weak cacheStream] in
                        let result = NetworkManager.deserialize(request.deserializer, interceptors: interceptors, response: entry.response, data: entry.data, error: NetworkManager.unknownError)
                        DispatchQueue.main.async {[weak cacheStream] in
                            cacheStream?.close()
                            cacheStream?.send(result)
                        }
                    })
                }
                else {
                    cacheStream.close()
                    if let error = stream.error, error.oex_isNoInternetConnectionError {
                        cacheStream.send(error)
                    }
                }
            })
            return stream.cachedByStream(cacheStream)
        }
        else {
            return stream
        }
    }
    
    open func streamForRequest<Out>(_ request : NetworkRequest<Out>, persistResponse : Bool = false, autoCancel : Bool = true) -> edXCore.Stream<Out> {
        let stream = Sink<NetworkResult<Out>>()
        let task = self.taskForRequest(request) {[weak stream, weak self] result in
            if let response = result.response, let request = result.request, let data = result.baseData, (persistResponse && data.count > 0) {
                self?.cache.setCacheResponse(response, withData: data, forRequest: request, completion: nil)
            }
            stream?.close()
            stream?.send(result)
        }
        var result : edXCore.Stream<Out> = stream.flatMap {(result : NetworkResult<Out>) -> Result<Out> in
            return self.handleResponse(result)
        }
        
        if persistResponse {
            result = combineWithPersistentCacheFetch(result, request: request)
        }
        
        if autoCancel {
            result = result.autoCancel(task)
        }
        
        return result
    }
    
    fileprivate func handleResponse<Out>(_ networkResult: NetworkResult<Out>) -> Result<Out> {
        var result:Result<Out>?
        for responseInterceptor in self.responseInterceptors {
            result = responseInterceptor.handleResponse(networkResult)
            if case .none = result {
                break
            }
        }
        
        return result ?? networkResult.data.toResult(NetworkManager.unknownError)
    }
    
    
    //MARK : API call to update progress
    open func updateCourseProgress(_ userName:String, componentIDs:String, onCompletion: @escaping ServiceResponse) -> Void {
        var request = URLRequest(url: URL(string:"\(self.baseURL)/"+"api/progress_tracker/recordView/")!)
        let requestBody = ["userName": userName, "componentIds": componentIDs]
        request.httpMethod = HTTPMethod.POST.rawValue
        do{
        let requestData  = try JSONSerialization.data(withJSONObject: requestBody, options: JSONSerialization.WritingOptions.prettyPrinted)
        request.httpBody = requestData
        }
        catch {}
        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            guard error == nil && data != nil else {                                                          // check for networking errors
                Logger.logError("Courses", error!.localizedDescription)
                return
            }
            
            
    
            let responseString = String(data: data!, encoding: String.Encoding.utf8)
            Logger.logInfo("Courses", responseString ?? "")
            onCompletion(true)
        }) 
        task.resume()
}
}

extension NetworkManager: RequestAdapter {
    public func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        guard urlRequest.url?.pathComponents.contains("submit") == true ||
             urlRequest.url?.pathComponents.contains("student_view_user_state") == true ||
            urlRequest.url?.pathComponents.contains("try_again") == true  else {
                return urlRequest
        }
        
        var requestWithoutCookies = urlRequest
        requestWithoutCookies.httpShouldHandleCookies = false
        return requestWithoutCookies
    }
}
