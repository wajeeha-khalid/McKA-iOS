//
//  DownloadProgressView.swift
//  edX
//
//  Created by Akiva Leffert on 6/3/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

private let titleLabelCenterYOffset : CGFloat = -8
private let subtitleLabelCenterYOffset : CGFloat = 8

open class CourseOutlineHeaderView: UIView {
    fileprivate let styles : OEXStyles
    
    fileprivate let verticalMargin = 3
    
    fileprivate let bottomDivider : UIView = UIView(frame: CGRect.zero)
    
    fileprivate let viewButton = UIButton(type: .system)
    fileprivate let messageView = UILabel(frame: CGRect.zero)
    fileprivate let subtitleLabel = UILabel(frame: CGRect.zero)
    
    fileprivate var contrastColor : UIColor {
        return styles.primaryBaseColor()
    }
    
    fileprivate var labelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .semiBold, size: .xSmall, color: contrastColor)
    }
    
    fileprivate var subtitleLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .small, color : OEXStyles.shared().neutralBlack())
    }
    
    fileprivate var viewButtonStyle : ButtonStyle {
        let textStyle = OEXTextStyle(weight: .semiBold, size: .small, color : contrastColor)
        return ButtonStyle(textStyle: textStyle, backgroundColor: nil, borderStyle: nil)
    }
    
    fileprivate var hasSubtitle : Bool {
        return !(subtitleLabel.text?.isEmpty ?? true)
    }
    
    open var subtitleText : String? {
        get {
            return subtitleLabel.text
        }
        set {
            subtitleLabel.attributedText = subtitleLabelStyle.attributedString(withText: newValue)
        }
    }
    
    public init(frame : CGRect, styles : OEXStyles, titleText : String? = nil, subtitleText : String? = nil) {
        self.styles = styles
        super.init(frame : frame)
        
        addSubview(viewButton)
        addSubview(messageView)
        addSubview(bottomDivider)
        addSubview(subtitleLabel)
        
        viewButton.applyButtonStyle(viewButtonStyle, withTitle : Strings.view)
        
        messageView.attributedText = labelStyle.attributedString(withText: titleText)
        subtitleLabel.attributedText = subtitleLabelStyle.attributedString(withText: subtitleText)
        
        backgroundColor = styles.primaryXLightColor()
        bottomDivider.backgroundColor = contrastColor
        
        bottomDivider.snp.makeConstraints {make in
            make.bottom.equalTo(self)
            make.height.equalTo(OEXStyles.dividerSize())
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
        }
        
        viewButton.snp.makeConstraints { make in
            make.trailing.equalTo(self.snp.trailing).offset(-StandardHorizontalMargin)
            make.centerY.equalTo(self)
            make.top.equalTo(self).offset(5)
            make.bottom.equalTo(self).offset(-5)
        }

        viewButton.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: UILayoutConstraintAxis.horizontal)
        
        messageView.snp.makeConstraints { make in
            let situationalCenterYOffset = hasSubtitle ? titleLabelCenterYOffset : 0
            make.centerY.equalTo(self).offset(situationalCenterYOffset)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
        }
        
        subtitleLabel.snp.makeConstraints { (make) -> Void in
            make.centerY.equalTo(self).offset(subtitleLabelCenterYOffset)
            make.leading.equalTo(messageView)
            make.trailing.lessThanOrEqualTo(viewButton.snp.leading).offset(-10)
        }
        subtitleLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: UILayoutConstraintAxis.horizontal)
    }
    
    open func setViewButtonAction(_ action: @escaping (AnyObject) -> Void) {
        self.viewButton.oex_removeAllActions()
        self.viewButton.oex_addAction(action as! (Any) -> Void, for: UIControlEvents.touchUpInside)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
