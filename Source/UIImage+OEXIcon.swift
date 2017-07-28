//
//  UIImage+OEXIcon.swift
//  edX
//
//  Created by Michael Katz on 8/28/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

let videoIconSize: CGFloat = 32.0


extension UIImage { //OEXIcon
    class func MenuIcon() -> UIImage {
        return Icon.menu.barButtonImage(deltaFromDefault: 0)
    }
    
    class func RewindIcon() -> UIImage {
        return Icon.videoRewind.imageWithFontSize(videoIconSize)
    }
    
    class func ExpandIcon() -> UIImage {
        return Icon.videoFullscreen.imageWithFontSize(videoIconSize)
    }
    
    class func ShrinkIcon() -> UIImage {
        return Icon.videoShrink.imageWithFontSize(videoIconSize)
    }
    
    class func OpenURL() -> UIImage {
        return Icon.openURL.imageWithFontSize(videoIconSize)
    }
    
    class func PauseIcon() -> UIImage {
        return Icon.videoPause.imageWithFontSize(videoIconSize)
    }

    class func PlayIcon() -> UIImage {
        return Icon.videoPlay.imageWithFontSize(videoIconSize)
    }
    
    class func SettingsIcon() -> UIImage {
        return Icon.settings.imageWithFontSize(videoIconSize)
    }
    
    class func PlayTitle() -> NSAttributedString {
        let style = OEXMutableTextStyle(weight: .normal, size: .xxLarge, color: UIColor.white)
        style.alignment = .center
        return Icon.videoPlay.attributedTextWithStyle(style, inline: true)
    }
    
    class func PauseTitle() -> NSAttributedString {
        let style = OEXMutableTextStyle(weight: .normal, size: .xxLarge, color: UIColor.white)
        style.alignment = .center
        return Icon.videoPause.attributedTextWithStyle(style, inline: true)
    }
}
