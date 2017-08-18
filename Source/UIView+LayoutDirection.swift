//
//  UIView+LayoutDirection.swift
//  edX
//
//  Created by Akiva Leffert on 7/20/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

extension UIView {
    var isRightToLeft : Bool {
        
        if #available(iOS 9.0, *) {
            let direction = UIView.userInterfaceLayoutDirection(for: self.semanticContentAttribute)
            switch direction {
            case .leftToRight: return false
            case .rightToLeft: return true
            }
        } else {
            return UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
        }
    }
}

enum LocalizedHorizontalContentAlignment {
    case leading
    case center
    case trailing
    case fill
}

extension UIControl {
    var localizedHorizontalContentAlignment : LocalizedHorizontalContentAlignment {
        get {
            switch self.contentHorizontalAlignment {
            case .left:
                return self.isRightToLeft ? .trailing : .leading
            case .right:
                return self.isRightToLeft ? .leading : .trailing
            case .center:
                return .center
            case .fill:
                return .fill
            }
        }
        set {
            switch newValue {
            case .leading:
                self.contentHorizontalAlignment = self.isRightToLeft ? .right : .left
            case .trailing:
                self.contentHorizontalAlignment = self.isRightToLeft ? .left : .right
            case .center:
                self.contentHorizontalAlignment = .center
            case .fill:
                self.contentHorizontalAlignment = .fill
            }
        }
    }
}
