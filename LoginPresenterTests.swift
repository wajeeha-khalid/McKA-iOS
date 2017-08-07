//
//  LoginPresenterTests.swift
//  edX
//
//  Created by Salman Jamil on 8/15/17.
//  Copyright © 2017 edX. All rights reserved.
//

import XCTest
@testable import edX
@testable import edXCore

final class MockAuthenticator: Authenticator {
    func resetPassword(withEmailID emailID: String) -> edXCore.Stream<()> {
        fatalError()
    }
    
    func authenticateUserWith(username: String, password: String) -> edXCore.Stream<()> {
        fatalError()
    }
}

final class MockView: LoginView {
    
    var presentedMessage: Message?
    
    func present(message: Message) {
        presentedMessage = message
    }
    
    func showActivityIndicator() {
        
    }
    
    func hideActivityIndicator() {
        
    }
    
    func loginSuccessfull() {
        
    }
}

class LoginPresenterTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testThatErrorIsShownWhileResetPassWhenNoInternetIsAvailable() {
        let mockView = MockView()
        let mockReachability = MockReachability()
        mockReachability.networkStatus = (wifi: false, wwan: false)
        let subject = LoginPresenter(authenticator: MockAuthenticator(), view: mockView, reachability: mockReachability)
        subject.forgotPassword(withEmailID: "salman.jamil@arbisoft.com")
        XCTAssertTrue(mockView.presentedMessage != nil)
    }
}
