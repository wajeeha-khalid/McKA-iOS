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
        XCTAssertTrue(contentDownloadNotificationTypes.contains(NSNotification.Name.OEXDownloadProgressChanged.rawValue))
    }
    
    /// Test either OEXDownloadEndedNotification observer added or not.
    func testOEXDownloadEndedNotificationKey() {
        let contentDownloadNotificationTypes = OEXCoursewareViewController.getContentDownloadNotificationTypes()
        XCTAssertTrue(contentDownloadNotificationTypes.contains(NSNotification.Name.OEXDownloadEnded.rawValue))
    }

    /// Test either OEXDownloadProgressChangedNotification fired or not.
    func testOEXDownloadProgressChangedNotificationFired() {
        let isNotificationFired = MutableBox<Bool>(false)
        let removable = NotificationCenter.default.oex_addObserver(self, name: NSNotification.Name.OEXDownloadProgressChanged.rawValue) { (notification, observer, removable) in
            isNotificationFired.value = true
        }
        XCTAssertFalse(isNotificationFired.value)
        NotificationCenter.default.post(name: NSNotification.Name.OEXDownloadProgressChanged, object: nil)
        XCTAssertTrue(isNotificationFired.value)
        removable.remove()
    }
    
    /// Test either OEXDownloadEndedNotification fired or not.
    func testOEXDownloadEndedNotificationFired() {
        let isNotificationFired = MutableBox<Bool>(false)
        let removable = NotificationCenter.default.oex_addObserver(self, name: NSNotification.Name.OEXDownloadEnded.rawValue) { (notification, observer, removable) in
            isNotificationFired.value = true
        }
        XCTAssertFalse(isNotificationFired.value)
        NotificationCenter.default.post(name: NSNotification.Name.OEXDownloadEnded, object: nil)
        XCTAssertTrue(isNotificationFired.value)
        removable.remove()
    }
}
