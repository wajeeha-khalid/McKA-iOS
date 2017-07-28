//
//  SessionUsernameProvider.swift
//  edX
//
//  Created by Akiva Leffert on 3/9/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
import edXCore

@objc open class SessionUsernameProvider : NSObject, PathProvider {
    fileprivate let session : OEXSession
    public init(session : OEXSession) {
        self.session = session
    }

    fileprivate var currentUsername : String? {
        return self.session.currentUser?.username
    }

    open func pathForRequestKey(_ key: String?) -> URL? {
        return OEXFileUtility.filePath(forRequestKey: key, username: self.currentUsername).flatMap {URL(fileURLWithPath: $0)}
    }
}
