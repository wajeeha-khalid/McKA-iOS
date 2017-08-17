//
//  CourseOutlineItemView.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 18/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

protocol CourseBlockContainerCell {
    var block : CourseBlock? { get }
    func applyStyle(_ style : TableCellStyle)
}

private let TitleOffsetTrailing = -10
private let SubtitleOffsetTrailing = -10
private let IconSize = CGSize(width: 25, height: 25)
private let CellOffsetTrailing : CGFloat = -10
private let TitleOffsetCenterY = -10
private let TitleOffsetLeading = 40
private let SubtitleOffsetCenterY = 10
private let DownloadCountOffsetTrailing = -2

private let SmallIconSize : CGFloat = 15
private let IconFontSize : CGFloat = 15

open class CourseOutlineItemView: UIView {
    static let detailFontStyle = OEXTextStyle(weight: .normal, size: .small, color : OEXStyles.shared.neutralBase())
    
    fileprivate let fontStyle = OEXTextStyle(weight: .normal, size: .base, color : OEXStyles.shared.neutralBlack())
    fileprivate let titleLabel = UILabel()
    fileprivate let subtitleLabel = UILabel()
    fileprivate let leadingImageButton = UIButton(type: UIButtonType.system)
    fileprivate let checkmark = UIImageView()
    fileprivate let trailingContainer = UIView()
    
    var hasLeadingImageIcon :Bool {
        return leadingImageButton.image(for: .normal) != nil
    }
    
    open var isGraded : Bool? {
        get {
            return !checkmark.isHidden
        }
        set {
            checkmark.isHidden = !(newValue!)
            setNeedsUpdateConstraints()
        }
    }
    
    var leadingIconColor : UIColor? {
        get {
            return leadingImageButton.tintColor
        }
        set {
            leadingImageButton.tintColor = newValue
        }
    }

    func imageForIcon(_ icon : Icon?) -> UIImage? {
        return icon?.imageWithFontSize(IconFontSize)
    }
    
    init() {
        super.init(frame: CGRect.zero)
        
        leadingImageButton.tintColor = OEXStyles.shared.primaryBaseColor()
        leadingImageButton.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .horizontal)
        trailingContainer.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .horizontal)
        
        leadingImageButton.accessibilityTraits = UIAccessibilityTraitImage
        titleLabel.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .horizontal)
        
        checkmark.image = Icon.graded.imageWithFontSize(15)
        checkmark.tintColor = OEXStyles.shared.neutralBase()
        
        isGraded = false
        addSubviews()
        setAccessibility()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setTitleText(_ title : String?) {
        titleLabel.attributedText = fontStyle.attributedString(withText: title)
    }
    
    func setDetailText(_ title : String) {
        subtitleLabel.attributedText = CourseOutlineItemView.detailFontStyle.attributedString(withText: title)
        setNeedsUpdateConstraints()
    }
    
    func setContentIcon(_ icon : Icon?) {
        leadingImageButton.setImage(icon?.imageWithFontSize(IconFontSize), for: UIControlState())
        setNeedsUpdateConstraints()
        if let accessibilityText = icon?.accessibilityText {
            leadingImageButton.accessibilityLabel = accessibilityText
        }
    }
    
    override open func updateConstraints() {
        leadingImageButton.snp.updateConstraints { (make) -> Void in
            make.centerY.equalTo(self)
            if hasLeadingImageIcon {
                make.leading.equalTo(self).offset(StandardHorizontalMargin)
            }
            else {
                make.leading.equalTo(self)
            }
            make.size.equalTo(IconSize)
        }
        
        let shouldOffsetTitle = !(subtitleLabel.text?.isEmpty ?? true)
        titleLabel.snp.updateConstraints { (make) -> Void in
            let titleOffset = shouldOffsetTitle ? TitleOffsetCenterY : 0
            make.centerY.equalTo(self).offset(titleOffset)
            if hasLeadingImageIcon {
                make.leading.equalTo(leadingImageButton.snp.trailing).offset(StandardHorizontalMargin)
            }
            else {
                make.leading.equalTo(self).offset(StandardHorizontalMargin)
            }
            make.trailing.lessThanOrEqualTo(trailingContainer.snp.leading).offset(TitleOffsetTrailing)
        }
        
        super.updateConstraints()
    }
    
    fileprivate func addSubviews() {
        addSubview(leadingImageButton)
        addSubview(trailingContainer)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(checkmark)
        
        // For performance only add the static constraints once
        subtitleLabel.snp.makeConstraints { (make) -> Void in
            make.centerY.equalTo(self).offset(SubtitleOffsetCenterY)
            make.leading.equalTo(titleLabel)
            make.trailing.lessThanOrEqualTo(trailingContainer.snp.leading).offset(TitleOffsetTrailing)
        }
        
        checkmark.snp.makeConstraints { (make) -> Void in
            make.centerY.equalTo(subtitleLabel.snp.centerY)
            make.leading.equalTo(subtitleLabel.snp.trailing).offset(5)
            make.size.equalTo(CGSize(width: SmallIconSize, height: SmallIconSize))
        }
        
        trailingContainer.snp.makeConstraints { (make) -> Void in
            make.trailing.equalTo(self.snp.trailing).offset(CellOffsetTrailing)
            make.centerY.equalTo(self)
        }
    }
    
    var trailingView : UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let view = trailingView {
                trailingContainer.addSubview(view)
                view.snp.makeConstraints {make in
                    // required to prevent long titles from compressing this
                    make.edges.equalTo(trailingContainer).priority(.required)
                }
            }
            setNeedsLayout()
        }
    }
    
    open override class var requiresConstraintBasedLayout : Bool {
        return true
    }
    
    fileprivate func setAccessibility() {
        subtitleLabel.isAccessibilityElement = false
    }
    
}
