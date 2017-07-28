//
//  TableCellStyle.swift
//  edX
//
//  Created by Akiva Leffert on 10/1/15.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit

enum TableCellStyle {
    case normal
    case highlighted
}

extension UITableViewCell {
    func applyStyle(_ style : TableCellStyle) {
        switch style {
        case .normal: self.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        case .highlighted: self.backgroundColor = OEXStyles.shared().primaryXLightColor()
        }
    }
}
