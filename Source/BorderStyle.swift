//
//  BorderStyle.swift
//  edX
//
//  Created by Akiva Leffert on 6/4/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

open class BorderStyle {
    enum Width {
        case hairline
        case size(CGFloat)
        
        var value : CGFloat {
            switch self {
            case .hairline: return OEXStyles.dividerSize()
            case let .size(s): return s
            }
        }
    }
    
    enum Radius {
        case circle
        case size(CGFloat)
        
        func value(_ view: UIView) -> CGFloat {
            switch self {
            case .circle: return view.frame.size.height / 2.0
            case let .size(s): return s
            }
        }
    }
    
    static let defaultCornerRadius = OEXStyles.shared().boxCornerRadius()
    
    let cornerRadius : Radius
    let width : Width
    let color : UIColor?
    
    init(cornerRadius : Radius = .size(BorderStyle.defaultCornerRadius), width : Width = .size(0), color : UIColor? = nil) {
        self.cornerRadius = cornerRadius
        self.width = width
        self.color = color
    }
    
    fileprivate func applyToView(_ view : UIView) {
        let radius = cornerRadius.value(view)
        view.layer.cornerRadius = radius
        view.layer.borderWidth = width.value
        view.layer.borderColor = color?.cgColor
        if radius != 0 {
            view.clipsToBounds = true
        }
    }
    
    class func clearStyle() -> BorderStyle {
        return BorderStyle()
    }
}

extension UIView {
    func applyBorderStyle(_ style : BorderStyle) {
        style.applyToView(self)
    }
}
