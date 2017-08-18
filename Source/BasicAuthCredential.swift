//
//  BasicAuthCredential.swift
//  edX
//
//  Created by Akiva Leffert on 11/6/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

class BasicAuthCredential: NSObject {
    let host: URL
    fileprivate let username: String
    fileprivate let password: String
    
    init(host : URL, username : String, password : String) {
        self.host = host
        self.username = username
        self.password = password
    }
    
    init?(dictionary : [String:AnyObject]) {
        guard let
            host = dictionary["HOST"] as? String,
            let hostURL = URL(string:host),
            let username = dictionary["USERNAME"] as? String,
            let password = dictionary["PASSWORD"] as? String else
        {
            self.host = NSURL() as URL
            self.username = ""
            self.password = ""
            super.init()
            return nil
        }
        self.host = hostURL
        self.username = username
        self.password = password
        super.init()
    }
    
    var URLCredential : Foundation.URLCredential {
        // Return .ForSession since credentials may change between runs
        return Foundation.URLCredential(user: username, password: password, persistence: .forSession)
    }
}

private let authCredentialKey = "BASIC_AUTH_CREDENTIALS"

extension OEXConfig {
    var basicAuthCredentials : [BasicAuthCredential] {
        return (self[authCredentialKey] as? [[String:AnyObject]] ?? []).mapSkippingNils { item in
            return BasicAuthCredential(dictionary: item)
        }
    }
}

