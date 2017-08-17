//
//  UserPreferenceManagerTests.swift
//  edX
//
//  Created by Kevin Kim on 8/8/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
@testable import edX

class UserPreferenceManagerTests : XCTestCase {
    
    func testUserPreferencesLoginLogout() {
        let userPrefernces = UserPreference(json: ["time_zone": "Asia/Tokyo"])
        
        XCTAssertNotNil(userPrefernces)
        
        let preferences = userPrefernces!
        
        let environment = TestRouterEnvironment()
        environment.mockNetworkManager.interceptWhenMatching({_ in true }) {
            return (nil, preferences)
        }
        
        let manager = UserPreferenceManager(networkManager: environment.networkManager)
        let feed = manager.feed
        // starts empty
        // flatten the value since the type of `feed.output.value` is `UserPreference??`
        // and the compiler gives a warning when we pass an Optional<Optional<UserPreference>>
        // to XCAssetNil
        let flattenedValue = feed.output.value?.flatMap {$0}
        XCTAssertNil(flattenedValue)
        
        // Log in. Preferences should load
        environment.logInTestUser()
        feed.refresh()
        
        stepRunLoop()
        
        waitForStream(feed.output)
        XCTAssertEqual(feed.output.value??.timeZone, preferences.timeZone)
        
        // Log out. Now preferences should be cleared
        environment.session.closeAndClear()
        XCTAssertNil(feed.output.value!)
    }
    
}
