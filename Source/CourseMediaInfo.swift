//
//  CourseMediaInfo.swift
//  edX
//
//  Created by Akiva Leffert on 12/7/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

open class CourseMediaInfo: NSObject {
    let name: String?
    let uri: String?
    
    public init(name : String?, uri : String?) {
        self.name = name
        self.uri = uri
    }
    
    public init(dict : [AnyHashable: Any]?) {
        self.name = dict?["name"] as? String
        self.uri = dict?["uri"] as? String
        super.init()
    }
    
    open var dictionary : [String:AnyObject] {
        return stripNullsFrom(["name" : name as AnyObject, "uri" : uri as AnyObject])
    }
}
