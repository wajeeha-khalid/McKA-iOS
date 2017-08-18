//
//  OEXCourseTests.swift
//  edX
//
//  Created by Akiva Leffert on 8/12/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
import XCTest
import edX

class OEXCourseTests: XCTestCase {

    func testStartOld() {
        let date = Date().addingTimeInterval(-1000)
        let course = OEXDateFormatting.serverString(with: date).map {
            OEXCourse(dictionary: ["start" : $0])
        }
        XCTAssertNotNil(course)
        XCTAssertTrue(course!.isStartDateOld)
    }
    
    func testStartNotOld() {
        let date = Date().addingTimeInterval(1000)
        let course = OEXDateFormatting.serverString(with: date).map {
            OEXCourse(dictionary: ["start" : $0])
        }
        XCTAssertNotNil(course)
        XCTAssertFalse(course!.isStartDateOld)
    }
    
    func testEndOld() {
        let date = Date().addingTimeInterval(-1000)
        let course = OEXDateFormatting.serverString(with: date).map {
            OEXCourse(dictionary: ["end" : $0])
        }
        XCTAssertNotNil(course)
        XCTAssertTrue(course!.isEndDateOld)
    }
    
    func testEndNotOld() {
        let date = Date().addingTimeInterval(1000)
        let course = OEXDateFormatting.serverString(with: date).map {
            OEXCourse(dictionary: ["end" : $0])
        }
        XCTAssertNotNil(course)
        XCTAssertFalse(course!.isEndDateOld)
    }
    
}
