//
//  CourseContentCompletionTests.swift
//  edX
//
//  Created by Shafqat Muneer on 6/1/17.
//  Copyright © 2017 edX. All rights reserved.
//

import XCTest
@testable import edX

/// The class to Test Media (Video, Audio etc) Completion status.
class CourseContentCompletionTests: XCTestCase {
    
    let totalDuration:Double = 120.0
    var currentPlaybackTime:Double = 0.0
    
    /// Test media content marked as completed.
    func testMediaContentMarkedAsCompleted() {
        currentPlaybackTime = totalDuration * 0.51
        let shouldMarkComplete:Bool = MediaPlaybackDecision.shouldMediaPlaybackCompleted(currentPlaybackTime, totalDuration: totalDuration)
        XCTAssertTrue(shouldMarkComplete)
    }
    
    /// Test media content marked as incomplete.
    func testMediaContentMarkedAsIncomplete() {
        currentPlaybackTime = totalDuration * 0.49
        let shouldMarkComplete = MediaPlaybackDecision.shouldMediaPlaybackCompleted(currentPlaybackTime, totalDuration: totalDuration)
        XCTAssertFalse(shouldMarkComplete)
    }
}
