//
//  OEXConfig+AppFeatures.swift
//  edX
//
//  Created by Akiva Leffert on 3/9/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

extension OEXConfig {
    var pushNotificationsEnabled : Bool {
        return bool(forKey: "PUSH_NOTIFICATIONS")
    }

    var discussionsEnabled : Bool {
        return bool(forKey: "DISCUSSIONS_ENABLED")
    }

    var certificatesEnabled : Bool {
        return bool(forKey: "CERTIFICATES_ENABLED")
    }

    var profilesEnabled : Bool {
        return bool(forKey: "USER_PROFILES_ENABLED")
    }

    var courseSharingEnabled : Bool {
        return bool(forKey: "COURSE_SHARING_ENABLED")
    }

    var badgesEnabled : Bool {
        return bool(forKey: "BADGES_ENABLED")
    }
    
    var newLogistrationFlowEnabled: Bool {
        return bool(forKey: "NEW_LOGISTRATION_ENABLED")
    }
    
    var discussionsEnabledProfilePictureParam: Bool {
        return bool(forKey: "DISCUSSIONS_ENABLE_PROFILE_PICTURE_PARAM")
    }
    
    var isRegistrationEnabled: Bool {
        // By default registration is enabled
        if let _ = properties["REGISTRATION_ENABLED"] {
            return bool(forKey: "REGISTRATION_ENABLED")
        }
        return true
    }
    
}
