//
//  AccessibilityCLButton.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 28/07/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

open class AccessibilityCLButton: CLButton {

    fileprivate var selectedAccessibilityLabel : String?
    fileprivate var normalAccessibilityLabel : String?
    
    override open var isSelected: Bool {
        didSet {
            if isSelected {
                if let selectedLabel = selectedAccessibilityLabel {
                    self.accessibilityLabel = selectedLabel
                }
            }
            else {
                if let normalLabel = normalAccessibilityLabel {
                    self.accessibilityLabel = normalLabel
                }
            }
        }
    }
    
    open func setAccessibilityLabelsForStateNormal(normalStateLabel normalLabel: String?, selectedStateLabel selectedLabel: String?) {
        self.selectedAccessibilityLabel = selectedLabel
        self.normalAccessibilityLabel = normalLabel
    }
    
    open override func draw(_ rect: CGRect) {
        let r = UIBezierPath(ovalIn: rect)
        UIColor.black.withAlphaComponent(0.65).setFill()
        r.fill()
        super.draw(rect)
    }
}
