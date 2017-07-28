//
//  JSON+Formatting.swift
//  edX
//
//  Created by Akiva Leffert on 3/31/16.
//  Copyright © 2016 edX. All rights reserved.
//

import SwiftyJSON

extension JSON {
    var serverDate : NSDate? {
        return string.map { OEXDateFormatting.date(withServerString: $0) as NSDate }
    }
}
