//
//  CourseLessonsViewControllerTests.swift
//  edX
//
//  Created by Abdul Haseeb on 8/15/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit
import XCTest
@testable import edX

class CourseLessonsViewControllerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testFilterDiscussion() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let courseoutline = CourseOutlineTestDataFactory.freshCourseOutline("1")
        let courseOutLineQuerier = CourseOutlineQuerier(courseID: "1", outline: courseoutline)
        let lessonModelViewDataSource = LessonViewModelDataSourceImplementation(querier: courseOutLineQuerier, interface: OEXInterface.shared())
        let testExpectation = self.expectation(description: "")
        
        lessonModelViewDataSource.lessons.listen(self) { (result) in
            switch result {
            case .success(let value):
                XCTAssert(value.count == 4)
                testExpectation.fulfill()
            case .failure:
                break
            }
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testDiscussionContainment() {
        let courseoutline = CourseOutlineTestDataFactory.freshCourseOutline("1")
        let courseOutLineQuerier = CourseOutlineQuerier(courseID: "1", outline: courseoutline)
        let lessonModelViewDataSource = LessonViewModelDataSourceImplementation(querier: courseOutLineQuerier, interface: OEXInterface.shared())
        let testExpectation = self.expectation(description: "")
        lessonModelViewDataSource.lessons.listen(self) { (result) in
            switch result {
            case .success(let value):
                XCTAssertFalse(
                    value.contains(where: {$0.title.contains("discussion_course")})
                )
                testExpectation.fulfill()
            case .failure:
                break
            }
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }

}
