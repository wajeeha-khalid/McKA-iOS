//
//  DownloadProgressTests.swift
//  edX
//
//  Created by Shafqat Muneer on 6/19/17.
//  Copyright © 2017 edX. All rights reserved.
//

import XCTest
@testable import edX

class DownloadProgressTests: XCTestCase {
    
    /// Test either OEXDownloadProgressChangedNotification observer added or not.
    func testOEXDownloadProgressChangedNotificationKey() {
        let contentDownloadNotificationTypes = OEXCoursewareViewController.getContentDownloadNotificationTypes()
        XCTAssertTrue(contentDownloadNotificationTypes.contains(OEXDownloadProgressChangedNotification))
    }
    
    /// Test either OEXDownloadEndedNotification observer added or not.
    func testOEXDownloadEndedNotificationKey() {
        let contentDownloadNotificationTypes = OEXCoursewareViewController.getContentDownloadNotificationTypes()
        XCTAssertTrue(contentDownloadNotificationTypes.contains(OEXDownloadEndedNotification))
    }

    /// Test either OEXDownloadProgressChangedNotification fired or not.
    func testOEXDownloadProgressChangedNotificationFired() {
        let isNotificationFired = MutableBox<Bool>(false)
        let removable = NSNotificationCenter.defaultCenter().oex_addObserver(self, name: OEXDownloadProgressChangedNotification) { (notification, observer, removable) in
            isNotificationFired.value = true
        }
        XCTAssertFalse(isNotificationFired.value)
        NSNotificationCenter.defaultCenter().postNotificationName(OEXDownloadProgressChangedNotification, object: nil)
        XCTAssertTrue(isNotificationFired.value)
        removable.remove()
    }
    
    /// Test either OEXDownloadEndedNotification fired or not.
    func testOEXDownloadEndedNotificationFired() {
        let isNotificationFired = MutableBox<Bool>(false)
        let removable = NSNotificationCenter.defaultCenter().oex_addObserver(self, name: OEXDownloadEndedNotification) { (notification, observer, removable) in
            isNotificationFired.value = true
        }
        XCTAssertFalse(isNotificationFired.value)
        NSNotificationCenter.defaultCenter().postNotificationName(OEXDownloadEndedNotification, object: nil)
        XCTAssertTrue(isNotificationFired.value)
        removable.remove()
    }
}
