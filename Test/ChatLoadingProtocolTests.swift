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
    let data: NSData?
    let response: NSURLResponse?
    
    init(response: NSURLResponse?, data: NSData?, error: NSError?) {
        self.response = response
        self.data = data
        self.error = error
    }
    
    @objc private func loadRequest(request: NSURLRequest, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) {
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            completionHandler(self.data, self.response, self.error)
        }
    }
    
    @objc private func cancel() {
        
    }
}

private final class TestURLClient: NSObject, NSURLProtocolClient {
    var receivedError: NSError?
    var receivedData: NSData?
    var receivedResponse: NSURLResponse?
    var finishedLoading = false
     @objc private func URLProtocol(protocol: NSURLProtocol, wasRedirectedToRequest request: NSURLRequest, redirectResponse: NSURLResponse) {
        fatalError()
    }
    
    @objc private func URLProtocol(protocol: NSURLProtocol, cachedResponseIsValid cachedResponse: NSCachedURLResponse) {
        fatalError()
    }
    
    @objc private func URLProtocol(protocol: NSURLProtocol, didReceiveResponse response: NSURLResponse, cacheStoragePolicy policy: NSURLCacheStoragePolicy) {
        receivedResponse = response
    }
    
    @objc private func URLProtocol(protocol: NSURLProtocol, didLoadData data: NSData) {
        receivedData = data
    }
    
    @objc private func URLProtocolDidFinishLoading(protocol: NSURLProtocol) {
        finishedLoading = true
    }
    
    @objc private func URLProtocol(protocol: NSURLProtocol, didFailWithError error: NSError) {
        receivedError = error
    }
    
    @objc private func URLProtocol(protocol: NSURLProtocol, didReceiveAuthenticationChallenge challenge: NSURLAuthenticationChallenge) {
        
    }
    
    @objc private func URLProtocol(protocol: NSURLProtocol, didCancelAuthenticationChallenge challenge: NSURLAuthenticationChallenge) {
        
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
        let requestURL = NSURL(string: "http://insignificantHost.com/xblock/block-v1:Majid_Al_Futtaim+PMM01+2017_T2+type@chat+block@444ed0f29613445fb1f41bd6c572f496")
        let request = NSURLRequest(URL: requestURL!)
        XCTAssertTrue(WebViewLoadingProtocol.canInitWithRequest(request))
    }
    
    func testThatProtocolInterceptChatRequestsUsingRefereField() {
        let refererURL = "http://insignificantHost.com/xblock/block-v1:Majid_Al_Futtaim+PMM01+2017_T2+type@chat+block@444ed0f29613445fb1f41bd6c572f496"
        let requestURL = NSURL(string: "http://insginificantHost.com/static/assets/test.js")
        let request = NSMutableURLRequest(URL: requestURL!)
        request.setValue(refererURL, forHTTPHeaderField: "Referer")
        XCTAssertTrue(WebViewLoadingProtocol.canInitWithRequest(request))
    }
    
    func testThatProtocolDoesnotInterceptNonHTMLRequests() {
        let requestURL = NSURL(string: "https://insignificantHost.com/xblock")!
        let referer = "https://apple.com/"
        let request = NSMutableURLRequest(URL: requestURL)
        request.setValue(referer, forHTTPHeaderField: "Referer")
        XCTAssertFalse(WebViewLoadingProtocol.canInitWithRequest(request))
    }
    
    func testThatProtocolForwardsErrorToClient() {
        //setup
        let errorDomain = "com.pique.test"
        let errorCode = 455
        let error = NSError(domain: errorDomain, code: errorCode, userInfo: nil)
        let testLoader = TestLoader(response: nil, data: nil, error: error)
        WebViewLoadingProtocol.requestLoader = testLoader
        let client = TestURLClient()
        let request = NSURLRequest(URL: NSURL(string:"https://www.google.com")!)
        let subject = WebViewLoadingProtocol(request: request, cachedResponse: nil, client: client)
        
        //execution
        let expectation = self.expectationWithDescription("Should forward error to the client")
        subject.startLoading()
        delay(1.5) { 
            XCTAssertEqual(errorCode, client.receivedError?.code)
            XCTAssertEqual(errorDomain, client.receivedError?.domain)
            XCTAssertNil(client.receivedData)
            XCTAssertTrue(client.finishedLoading)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(3.0, handler: nil)
    }
    
    func testThatProtocolForwardsDataToClient() {
        //setup
        let url = NSURL(string: "https://www.google.com")!
        let response = NSHTTPURLResponse(URL: url, MIMEType: "application/json", expectedContentLength: 320, textEncodingName: nil)
        let data = "This is test data".dataUsingEncoding(NSUTF8StringEncoding)
        let testLoader = TestLoader(response: response, data: data, error: nil)
        WebViewLoadingProtocol.requestLoader = testLoader
        let client = TestURLClient()
        let request = NSURLRequest(URL: url)
        let subject = WebViewLoadingProtocol(request: request, cachedResponse: nil, client: client)
        
        //execution
        let expectation = self.expectationWithDescription("Should forward error to the client")
        subject.startLoading()
        delay(1.5) {
            XCTAssertEqual(data, client.receivedData)
            XCTAssertEqual(response.statusCode, (client.receivedResponse as! NSHTTPURLResponse).statusCode)
            XCTAssertNil(client.receivedError)
            XCTAssertTrue(client.finishedLoading)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(3.0, handler: nil)
    }
}

func delay(seconds: Double, queue: dispatch_queue_t = dispatch_get_main_queue(), block: () -> ()) {
    let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * Double(NSEC_PER_SEC)))
    dispatch_after(delayTime, queue, block)
}
