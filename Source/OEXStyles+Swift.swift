//
//  OEXStyles+Swift.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 25/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import UIKit

struct ShadowStyle {
    let angle: Int //degrees
    let color: UIColor
    let opacity: CGFloat //0..1
    let distance: CGFloat
    let size: CGFloat

    var shadow: NSShadow {
        let shadow = NSShadow()
        shadow.shadowColor = color.withAlphaComponent(opacity)
        shadow.shadowOffset = CGSize(width: cos(CGFloat(angle) / 180.0 * CGFloat(Float.pi)), height: sin(CGFloat(angle) / 180.0 * CGFloat(Float.pi)))
        shadow.shadowBlurRadius = size
        return shadow
    }
}

extension OEXStyles {
    
    var navigationTitleTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .semiBold, size: .base, color : navigationItemTintColor())
    }
    
    var navigationButtonTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .semiBold, size: .small, color: nil)
    }
    
    fileprivate var searchBarTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .xSmall, color: OEXStyles.shared.neutralBlack())
    }
    
    public func applyGlobalAppearance() {
        if let image = UIImage(named: "navigationBarBackground") {
            let color = BrandingThemes.shared.getNavigationBarColor()
            let colorImage = UIImage.image(from: color, size: image.size)
            let blended = image.blendendImage(with: colorImage, blendMode: .normal, alpha: 1.0)
            UINavigationBar.appearance().setBackgroundImage(blended, for: UIBarMetrics.default)
        }
        UINavigationBar.appearance().tintColor = navigationItemTintColor()
        UINavigationBar.appearance().titleTextAttributes = navigationTitleTextStyle.attributes
        UIBarButtonItem.appearance().setTitleTextAttributes(navigationButtonTextStyle.attributes, for: UIControlState())
        
        UIToolbar.appearance().tintColor = navigationBarColor()
        
        let styleAttributes = OEXTextStyle(weight: .normal, size : .small, color : self.neutralBlack()).attributes
        UISegmentedControl.appearance().setTitleTextAttributes(styleAttributes, for: UIControlState.selected)
        UISegmentedControl.appearance().setTitleTextAttributes(styleAttributes, for: UIControlState())
        UISegmentedControl.appearance().tintColor = self.primaryXLightColor()
        
        UINavigationBar.appearance().isTranslucent = false

        if #available(iOS 9.0, *) {
            UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.classForCoder() as! UIAppearanceContainer.Type]).defaultTextAttributes = searchBarTextStyle.attributes
        }
        else {
            //Make sure we remove UIAppearance+Swift.h+m when we drop iOS8 support
            UITextField.my_appearanceWhenContained(in: UISearchBar.classForCoder() as! UIAppearanceContainer.Type).defaultTextAttributes = searchBarTextStyle.attributes
        }
    }
    
    ///**Warning:** Not from style guide. Do not add more uses
    public var progressBarTintColor : UIColor {
        return UIColor(red: CGFloat(126.0/255.0), green: CGFloat(199.0/255.0), blue: CGFloat(143.0/255.0), alpha: CGFloat(1.00))
    }
    
    ///**Warning:** Not from style guide. Do not add more uses
    public var progressBarTrackTintColor : UIColor {
        return UIColor(red: CGFloat(223.0/255.0), green: CGFloat(242.0/255.0), blue: CGFloat(228.0/255.0), alpha: CGFloat(1.00))
    }


    var standardTextViewInsets : UIEdgeInsets {
        return UIEdgeInsetsMake(8, 8, 8, 8)
    }
    
    var standardFooterHeight : CGFloat {
        return 50
    }
    
    var standardVerticalMargin : CGFloat {
        return 8.0
    }
    
    var discussionsBackgroundColor : UIColor {
        return OEXStyles.shared.neutralXLight()
    }

// Standard text Styles
    
    var textAreaBodyStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(weight: OEXTextWeight.normal, size: .small, color: OEXStyles.shared.neutralDark())
        style.lineBreakMode = .byWordWrapping
        return style
    }

// Standard button styles

    var filledPrimaryButtonStyle : ButtonStyle {
        return filledButtonStyle(OEXStyles.shared.primaryBaseColor())
    }

    func filledButtonStyle(_ color: UIColor) -> ButtonStyle {
        let buttonMargins : CGFloat = 8
        let borderStyle = BorderStyle()
        let textStyle = OEXTextStyle(weight: .normal, size: .base, color: self.neutralWhite())
        return ButtonStyle(textStyle: textStyle, backgroundColor: color, borderStyle: borderStyle,
                           contentInsets : UIEdgeInsetsMake(buttonMargins, buttonMargins, buttonMargins, buttonMargins))
    }
    
    var linkButtonStyle: ButtonStyle {
        let textStyle = OEXTextStyle(weight: .normal, size: .small, color: self.primaryBaseColor())
        return ButtonStyle(textStyle: textStyle, backgroundColor: nil)
    }
    
    var filledEmphasisButtonStyle : ButtonStyle {
        let buttonMargins : CGFloat = 12
        let result = filledPrimaryButtonStyle
        result.backgroundColor = OEXStyles.shared.utilitySuccessBase()
        result.textStyle = result.textStyle.withSize(.xLarge)
        result.contentInsets = UIEdgeInsetsMake(buttonMargins, buttonMargins, buttonMargins, buttonMargins)
        return result
    }
    
// Standard border styles
    var entryFieldBorderStyle : BorderStyle {
        return BorderStyle(width: .size(1), color: OEXStyles.shared.neutralLight())
    }
    
//Standard Divider styles
    
    var standardDividerColor : UIColor {
        return self.neutralLight()
    }
}

//Standard Search Bar styles
extension UISearchBar {
    func applyStandardStyles(withPlaceholder placeholder : String? = nil) {
        self.placeholder = placeholder
        self.showsCancelButton = false
        self.searchBarStyle = .default
        self.backgroundColor = OEXStyles.shared.neutralWhiteT()
        
    }
}

//Convenience computed properties for margins
var StandardHorizontalMargin : CGFloat {
    return OEXStyles.shared.standardHorizontalMargin()
}

var StandardVerticalMargin : CGFloat {
    return OEXStyles.shared.standardVerticalMargin
}
