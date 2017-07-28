//
//  ContentNavigationPolicy.swift
//  edX
//
//  Created by Salman Jamil on 6/19/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation

// A function that given a course block and an interface decides whether a unit has been
// completed or not
typealias UnitCompletionPolicy = (CourseBlockID, OEXInterface) -> Bool

// factory function to return policy based on viewController and itemId
// the chat completed flag is only used by chat completion policy
func unitCompletionPolicy(for controller: UIViewController, itemId: CourseBlockID, chatCompleted: Bool) -> UnitCompletionPolicy?  {
    switch controller {
    case is VideoBlockViewController:
        return videoUnitCompleted(_: _:)
    case is AudioBlockViewController:
        return audioUnitCompleted(_: _:)
    case is HTMLBlockViewController where itemId.containsString("type@chat"):
        return { itemId, interface in
            return chatUnitCompleted(itemId, interface, chatCompleted: chatCompleted)
        }
    default:
        return nil
    }
}

// given a video id and an interface decides whether the video is completed
func videoUnitCompleted(itemID: CourseBlockID, _ interface: OEXInterface) -> Bool {
    let state = interface.watchedStateForVideoWithID(itemID)
    return state == .Watched
}

// given a audio id and an interface decides whether the audio is completed
func audioUnitCompleted(itemID: CourseBlockID, _ interface: OEXInterface) -> Bool {
    let state = interface.watchedStateForAudioWithID(itemID)
    return state == .Watched
}

// given a chat id decides whether the chat has been completed
func chatUnitCompleted(itemID: CourseBlockID, _ interface: OEXInterface, chatCompleted: Bool) -> Bool {
    
    if let data = interface.storage?.getComponentDataForComponentID(itemID) where data.isViewed.boolValue {
        return true
    } else if chatCompleted {
        return true
    }
    return false
}
