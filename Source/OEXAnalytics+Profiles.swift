//
//  OEXAnalytics+Profiles.swift
//  edX
//
//  Created by Michael Katz on 10/26/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

enum AnaylticsPhotoSource {
    case camera
    case photoLibrary
    
    var value : String {
        switch self {
            case .camera: return OEXAnalyticsValuePhotoSourceCamera
            case .photoLibrary: return OEXAnalyticsValuePhotoSourceLibrary
        }
    }
}

extension OEXAnalytics {
    
    func trackProfileViewed(_ username : String) {
        let event = OEXAnalyticsEvent()
        event.name = OEXAnalyticsEventProfileViewed
        event.displayName = "Viewed a profile"
        event.category = OEXAnalyticsCategoryProfile
        event.label = username
        
        self.trackEvent(event, forComponent: nil, withInfo: nil)
    }
    
    func trackSetProfilePhoto(_ photoSource: AnaylticsPhotoSource) {
        let event = OEXAnalyticsEvent()
        event.name = OEXAnalyticsEventPictureSet
        event.displayName = "Set a profile picture"
        event.category = OEXAnalyticsCategoryProfile
        event.label = photoSource.value
        
        self.trackEvent(event, forComponent: nil, withInfo: nil)
    }
}
