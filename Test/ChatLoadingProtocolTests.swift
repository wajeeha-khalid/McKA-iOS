//
//  ChatLoadingProtocolTests.swift
//  edX
//
//  Created by Salman Jamil on 6/12/17.
//  Copyright © 2017 edX. All rights reserved.
//

import XCTest
@testable import edX

private final class TestLoader: NSObject, RequestLoader {
    let error: NSError?
    let data: Data?
    let response: URLResponse?
    
    init(response: URLResponse?, data: Data?, error: NSError?) {
        self.response = response
        self.data = data
        self.error = error
    }
    
    func loadRequest(_ request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let delayTime = DispatchTime.now() + Double(Int64(1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            completionHandler(self.data, self.response, self.error)
        }
    }
    
    @objc fileprivate func cancel() {
        
    }
}

private final class TestURLClient: NSObject, URLProtocolClient {
    var receivedError: NSError?
    var receivedData: Data?
    var receivedResponse: URLResponse?
    var finishedLoading = false
     @objc fileprivate func urlProtocol(_ protocol: URLProtocol, wasRedirectedTo request: URLRequest, redirectResponse: URLResponse) {
        fatalError()
    }
    
    @objc fileprivate func urlProtocol(_ protocol: URLProtocol, cachedResponseIsValid cachedResponse: CachedURLResponse) {
        fatalError()
    }
    
    @objc fileprivate func urlProtocol(_ protocol: URLProtocol, didReceive response: URLResponse, cacheStoragePolicy policy: URLCache.StoragePolicy) {
        receivedResponse = response
    }
    
    @objc fileprivate func urlProtocol(_ protocol: URLProtocol, didLoad data: Data) {
        receivedData = data
    }
    
    @objc fileprivate func urlProtocolDidFinishLoading(_ protocol: URLProtocol) {
        finishedLoading = true
    }
    
    @objc fileprivate func urlProtocol(_ protocol: URLProtocol, didFailWithError error: Error) {
        receivedError = error as NSError
    }
    
    @objc fileprivate func urlProtocol(_ protocol: URLProtocol, didReceive challenge: URLAuthenticationChallenge) {
        
    }
    
    @objc fileprivate func urlProtocol(_ protocol: URLProtocol, didCancel challenge: URLAuthenticationChallenge) {
        
    }
}

class ChatLoadingProtocolTests: XCTestCase {
    
    
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testThatProtocolInterceptsChatRequests() {
        let requestURL = URL(string: "http://insignificantHost.com/xblock/block-v1:Majid_Al_Futtaim+PMM01+2017_T2+type@chat+block@444ed0f29613445fb1f41bd6c572f496")
        let request = URLRequest(url: requestURL!)
        XCTAssertTrue(WebViewLoadingProtocol.canInit(with: request))
    }
    
    func testThatProtocolInterceptChatRequestsUsingRefereField() {
        let refererURL = "http://insignificantHost.com/xblock/block-v1:Majid_Al_Futtaim+PMM01+2017_T2+type@chat+block@444ed0f29613445fb1f41bd6c572f496"
        let requestURL = URL(string: "http://insginificantHost.com/static/assets/test.js")
        var request = URLRequest(url: requestURL!)
        request.setValue(refererURL, forHTTPHeaderField: "Referer")
        XCTAssertTrue(WebViewLoadingProtocol.canInit(with: request))
    }
    
    func testThatProtocolDoesnotInterceptNonHTMLRequests() {
        let requestURL = URL(string: "https://insignificantHost.com/xblock")!
        let referer = "https://apple.com/"
        var request = URLRequest(url: requestURL)
        request.setValue(referer, forHTTPHeaderField: "Referer")
        XCTAssertFalse(WebViewLoadingProtocol.canInit(with: request))
    }
    
    func testThatProtocolForwardsErrorToClient() {
        //setup
        let errorDomain = "com.pique.test"
        let errorCode = 455
        let error = NSError(domain: errorDomain, code: errorCode, userInfo: nil)
        let testLoader = TestLoader(response: nil, data: nil, error: error)
        WebViewLoadingProtocol.requestLoader = testLoader
        let client = TestURLClient()
        let request = URLRequest(url: URL(string:"https://www.google.com")!)
        let subject = WebViewLoadingProtocol(request: request, cachedResponse: nil, client: client)
        
        //execution
        let expectation = self.expectation(description: "Should forward error to the client")
        subject.startLoading()
        delay(1.5) { 
            XCTAssertEqual(errorCode, client.receivedError?.code)
            XCTAssertEqual(errorDomain, client.receivedError?.domain)
            XCTAssertNil(client.receivedData)
            XCTAssertTrue(client.finishedLoading)
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testThatProtocolForwardsDataToClient() {
        //setup
        let url = URL(string: "https://www.google.com")!
        let response = HTTPURLResponse(url: url, mimeType: "application/json", expectedContentLength: 320, textEncodingName: nil)
        let data = "This is test data".data(using: String.Encoding.utf8)
        let testLoader = TestLoader(response: response, data: data, error: nil)
        WebViewLoadingProtocol.requestLoader = testLoader
        let client = TestURLClient()
        let request = URLRequest(url: url)
        let subject = WebViewLoadingProtocol(request: request, cachedResponse: nil, client: client)
        
        //execution
        let expectation = self.expectation(description: "Should forward error to the client")
        subject.startLoading()
        delay(1.5) {
            XCTAssertEqual(data, client.receivedData)
            XCTAssertEqual(response.statusCode, (client.receivedResponse as! HTTPURLResponse).statusCode)
            XCTAssertNil(client.receivedError)
            XCTAssertTrue(client.finishedLoading)
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 3.0, handler: nil)
    }
}

func delay(_ seconds: Double, queue: DispatchQueue = DispatchQueue.main, block: @escaping () -> ()) {
    let delayTime = DispatchTime.now() + Double(Int64(seconds * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
    queue.asyncAfter(deadline: delayTime, execute: block)
}
