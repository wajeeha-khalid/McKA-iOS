//
//  MediaPlaybackDecision.swift
//  edX
//
//  Created by Shafqat Muneer on 6/5/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

/// The class to make Media (Video, Audio etc) Playback decision.

@objc public class MediaPlaybackDecision: NSObject {
    
    /**
     Should playing media mark as completed or not.
     
     - Parameter currentPlaybackTime:   How much current media is played.
     - Parameter totalDuration: Total duration of media.
     
     - Returns: If yes, mark media as completed otherwise incomplete.
     */
    class public func shouldMediaPlaybackCompleted(currentPlaybackTime: Double, totalDuration: Double) -> Bool {
        return (currentPlaybackTime > (totalDuration * MEDIA_COMPLETION_PERCENTAGE) && totalDuration > 0)
    }
}
