//
//  ContentCompletionPolicyTests.swift
//  edX
//
//  Created by Salman Jamil on 6/19/17.
//  Copyright © 2017 edX. All rights reserved.
//

import XCTest
@testable import edX

final class OEXTestInterface: OEXInterface {
    
    var videoStateMap: [String : OEXPlayedState] = [:]
    var audioStateMap: [String : OEXPlayedState] = [:]
    
    func set(state: OEXPlayedState, forVideoID videoID: CourseBlockID) {
        videoStateMap[videoID] = state
    }
    
    func set(state: OEXPlayedState, forAudioID audioID: CourseBlockID) {
        audioStateMap[audioID] = state
    }
    
    override func watchedStateForVideoWithID(videoID: String?) -> OEXPlayedState {
        guard let videoID = videoID else {
            fatalError("video id cannot be nil for test implementation")
        }
        if let state = videoStateMap[videoID] {
            return state
        } else {
            fatalError("No state registered for video id")
        }
    }
    
    override func watchedStateForAudioWithID(audioID: String?) -> OEXPlayedState {
        guard let audioID = audioID else {
            fatalError("audio id cannot be nil for test implementation")
        }
        if let state = audioStateMap[audioID] {
            return state
        } else {
            fatalError("No state registered for given audio id")
        }
    }
    
    
    
}

class ContentCompletionPolicyTests: XCTestCase {
    
    func testThatAVideoUnitIsCompleteWhenStateIsWatched() {
        //setup
        let unitID = "35201"
        let testInterface = OEXTestInterface()
        testInterface.set(.Watched, forVideoID: unitID)
        
        XCTAssertTrue(
            videoUnitCompleted(unitID, testInterface)
        )
        
    }
    
    func testThatAVideoUnitIsInCompleteWhenStateIsPartiallyWatched() {
        //setup
        let unitID = "35201"
        let testInterface = OEXTestInterface()
        testInterface.set(.PartiallyWatched, forVideoID: unitID)
        
        XCTAssertFalse(
            videoUnitCompleted(unitID, testInterface)
        )
    }
    
    func testThatAVideoUnitIsIncompleteWhenStateIsUnwatched() {
        //setup
        let unitID = "35201"
        let testInterface = OEXTestInterface()
        testInterface.set(.Unwatched, forVideoID: unitID)
        
        XCTAssertFalse(
            videoUnitCompleted(unitID, testInterface)
        )
    }
    
    func testThatAnAudiUnitIsCompleteWhenStateIsWatched() {
        //setup
        let unitID = "35201"
        let testInterface = OEXTestInterface()
        testInterface.set(.Watched, forAudioID: unitID)
        
        XCTAssertTrue(
            audioUnitCompleted(unitID, testInterface)
        )
    }
    
    func testThatAudioUnitIsIncompleteWhenStateIsParitallyWatched() {
        //setup
        let unitID = "35201"
        let testInterface = OEXTestInterface()
        testInterface.set(.PartiallyWatched, forAudioID: unitID)
        
        XCTAssertFalse(
            audioUnitCompleted(unitID, testInterface)
        )
    }
    
    func testThatAudioUnitIsIncompleteWhenStateIsUnwatched() {
        //setup
        let unitID = "35201"
        let testInterface = OEXTestInterface()
        testInterface.set(.Unwatched, forAudioID: unitID)
        
        XCTAssertFalse(
            audioUnitCompleted(unitID, testInterface)
        )
    }
}
