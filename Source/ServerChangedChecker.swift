//
//  ServerChangedChecker.swift
//  edX
//
//  Created by Akiva Leffert on 2/26/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation


@objc class ServerChangedChecker : NSObject {
    fileprivate let defaultsKey = "OEXLastUsedAPIHostURL"

    fileprivate var lastUsedAPIHostURL : URL? {
        get {
            return UserDefaults.standard.url(forKey: defaultsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: defaultsKey)
        }
    }

    func logoutIfServerChanged(config: OEXConfig, logoutAction : (Void) -> Void) {
        if let lastURL = lastUsedAPIHostURL, let currentURL = config.apiHostURL(), lastURL != currentURL {
            logoutAction()
            OEXFileUtility.nukeUserData()
        }
        lastUsedAPIHostURL = config.apiHostURL()
    }

    func logoutIfServerChanged() {
        logoutIfServerChanged(config: OEXConfig(appBundleData: ())) {
            OEXSession().closeAndClear()
        }
    }
}
