//
//  VersionUpgradeInfoController.swift
//  edX
//
//  Created by Saeed Bashir on 6/7/16.
//  Copyright © 2016 edX. All rights reserved.
//

private let AppLatestVersionKey = "EDX-APP-LATEST-VERSION"
private let AppVersionLastSupportedDateKey = "EDX-APP-VERSION-LAST-SUPPORTED-DATE"
let AppNewVersionAvailableNotification = "AppNewVersionAvailableNotification"

class VersionUpgradeInfoController: NSObject {
    
    static let sharedController = VersionUpgradeInfoController()
    fileprivate(set) var latestVersion:String?
    fileprivate(set) var lastSupportedDateString:String?
    
    fileprivate func returnToDefaultState() {
        latestVersion = nil
        lastSupportedDateString = nil
    }
    
    func populateFromHeaders(httpResponseHeaders headers: [AnyHashable: Any]?) {
        
        guard let responseHeaders = headers else {
            if let _ = latestVersion {
                // if server stop sending header information in response and version upgrade header is showing then hide it
                returnToDefaultState()
                postVersionUpgradeNotification()
            }
            return
        }
        
        var postNotification:Bool = false
        
        if let appLatestVersion = responseHeaders[AppLatestVersionKey] as? String {
            postNotification = latestVersion != appLatestVersion
            latestVersion = appLatestVersion
        }
        else {
            // In case if server stop sending version upgrade info in headers
            if let _ = latestVersion {
                returnToDefaultState()
                postNotification = true
            }
        }
        
        if let versionLastSupportedDate = responseHeaders[AppVersionLastSupportedDateKey] as? String {
            lastSupportedDateString = versionLastSupportedDate
        }
        
        if postNotification {
            postVersionUpgradeNotification()
        }
    }
    
    fileprivate func postVersionUpgradeNotification() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name(rawValue: AppNewVersionAvailableNotification), object: self)
        }
    }
}
