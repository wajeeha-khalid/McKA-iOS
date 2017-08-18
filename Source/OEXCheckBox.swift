//
//  OEXCheckBox.swift
//  edX
//
//  Created by Michael Katz on 8/27/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

open class OEXCheckBox: UIButton {
    
    @IBInspectable open var checked: Bool = false {
        didSet {
            updateState()
        }
    }
    
    fileprivate func _setup() {
        imageView?.contentMode = .scaleAspectFit
        
        addTarget(self, action: #selector(OEXCheckBox.tapped), for: .touchUpInside)
        updateState()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _setup()
    }
    
    open override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        updateState()
    }
    
    fileprivate func updateState() {
        let newIcon = checked ? Icon.checkCircleO : Icon.circleO
        let size = min(bounds.width, bounds.height)
        let image = newIcon.imageWithFontSize(size)
        setImage(image, for: UIControlState())
        accessibilityLabel = checked ? Strings.accessibilityCheckboxChecked : Strings.accessibilityCheckboxUnchecked
        accessibilityHint = checked ? Strings.accessibilityCheckboxHintChecked : Strings.accessibilityCheckboxHintUnchecked
    }
    
    func tapped() {
        checked = !checked
        sendActions(for: .valueChanged)
    }
}
