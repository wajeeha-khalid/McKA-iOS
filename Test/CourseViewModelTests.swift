//
//  CourseViewModelTests.swift
//  edX
//
//  Created by Abdul Haseeb on 8/11/17.
//  Copyright © 2017 edX. All rights reserved.
//

import XCTest
@testable import edX

class CourseViewModelTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testFormattedLessonCountTextWhenCountIsNil() {
        let course = OEXCourse(dictionary: [:])
        let courseModel = CourseViewModel(lessonCount: nil, persistImage: false, course: course)
        XCTAssertEqual(courseModel.formattedLessonCount, "fetching lesson count...")
    }
 
    func testFormattedLessonCountTextWhenCountIsMoreThanOne()  {
        let course = OEXCourse(dictionary: [:])
        let courseModel = CourseViewModel(lessonCount: 2, persistImage: false, course: course)
        XCTAssertEqual(courseModel.formattedLessonCount, "2 Lessons")
    }
    
    func testFormattedLessonCountWhenCountIsOne() {
        let course = OEXCourse(dictionary: [:])
        let courseModel = CourseViewModel(lessonCount: 1, persistImage: false, course: course)
        XCTAssertEqual(courseModel.formattedLessonCount, "1 Lesson")
    }
}
