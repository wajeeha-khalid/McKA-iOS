//
//  BrandingThemes.swift
//  edX
//
//  Created by Shafqat Muneer on 8/10/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit
import SwiftyJSON

struct ThemeIdentifiers {
    static let logoURL = "logo_url"
    static let navBarColor = "navigation_bar_color"
    static let courseCardOverlayColor = "course_card_overlay_color"
}

/**
    Purpose of this class to read theming detail from provided theming file and
    make theming details available on app level.
 */
open class BrandingThemes: NSObject {
    
    open static var shared = BrandingThemes(brandingFile: MCKINSEY_THEME_FILE)
    private var themeDictionary = [String: AnyObject]()
    
    convenience init(brandingFile:String) {
        self.init()
        themeDictionary = initializeThemeDictionary(themeFileName: brandingFile)
    }
    
    func applyThemeWith(fileName:String) {
        themeDictionary = initializeThemeDictionary(themeFileName: fileName)
    }
    
    func initializeThemeDictionary(themeFileName:String) -> [String: AnyObject] {
        guard let filePath = Bundle.main.path(forResource: themeFileName, ofType: "json") else {
            return defaultTheme()
        }
        
        var error : NSError?
        let data = try? Data(contentsOf: URL(fileURLWithPath: filePath))
        
        if let theme = data.flatMap ({(d: Data) -> [String : AnyObject]? in
            return JSON(data: d, error: &error).dictionaryObject as [String : AnyObject]?
        }) {
            return theme
        } else {
            return defaultTheme()
        }
    }
    
    fileprivate func defaultTheme() -> [String: AnyObject] {
        return DefaultTheming.defaultTheme as [String : AnyObject]
    }

    // MARK: Methods to get theming attributes
    public func getLogoURL() -> String {
        return themeDictionary[ThemeIdentifiers.logoURL] as! String
    }
    
    public func getNavigationBarColor() -> UIColor {
        let hexColorValue:String = valueForIdentifier(ThemeIdentifiers.navBarColor)
        let color = UIColor(hexString: hexColorValue, alpha: 0.9)
        return color
    }
    
    public func getCourseCardOverlayColor() -> UIColor {
        let hexColorValue:String = valueForIdentifier(ThemeIdentifiers.courseCardOverlayColor)
        let color = UIColor(hexString: hexColorValue, alpha: 0.9)
        return color
    }
    
    public func valueForIdentifier(_ identifier: String) -> String {
        return themeDictionary[identifier] as! String
    }
    // MARK:---
    
    public lazy var nextModuleIcon: UIImage = {
        return IconBuilder.arrowWithCircularBackground(
            ofSize: CGSize(width: 24, height: 24),
            backgroundColor : self.getNavigationBarColor(),
            arrowWidth: 12.0,
            arrowHeight: 1.5,
            arrowColor: UIColor.white,
            arrowDirection: .right
        )
    }()
    
    public lazy var prevModuleIcon: UIImage = {
        return IconBuilder.arrowWithCircularBackground(
            ofSize: CGSize(width: 24, height: 24),
            backgroundColor : self.getNavigationBarColor(),
            arrowWidth: 12.0,
            arrowHeight: 1.5,
            arrowColor: UIColor.white,
            arrowDirection: .left
        )
    }()
    
    public lazy var nextLessonIcon: UIImage = {
        return IconBuilder.arrowWithCircularBackground(
            ofSize: CGSize(width: 24, height: 24),
            backgroundColor : UIColor.lightGray,
            arrowWidth: 12.0,
            arrowHeight: 1.5,
            arrowColor: UIColor.white,
            arrowDirection: .right
        )
    }()
    
    public lazy var prevLessonIcon: UIImage = {
        return IconBuilder.arrowWithCircularBackground(
            ofSize: CGSize(width: 24, height: 24),
            backgroundColor : UIColor.lightGray,
            arrowWidth: 12.0,
            arrowHeight: 1.5,
            arrowColor: UIColor.white,
            arrowDirection: .left
        )
    }()
    
    public lazy var prevComponentIcon: UIImage = {
        return IconBuilder.arrowWithCircularBackground(
            ofSize: CGSize(width: 24, height: 24),
            backgroundColor : UIColor.clear,
            arrowWidth: 16.0,
            arrowHeight: 2.0,
            arrowColor: self.getNavigationBarColor(),
            arrowDirection: .left
        )
    }()
    
    public lazy var nextComponentIcon: UIImage = {
        return IconBuilder.arrowWithCircularBackground(
            ofSize: CGSize(width: 24, height: 24),
            backgroundColor : UIColor.clear,
            arrowWidth: 16.0,
            arrowHeight: 2.0,
            arrowColor: self.getNavigationBarColor(),
            arrowDirection: .right
        )
    }()
    
    
}

/**
    Its the default theming structure. If in any case, error thrown during
    reading to theming json file then by default this theme detail will be applied.
 */
class DefaultTheming: NSObject {
    static let defaultTheme = [
        "logo_url": "img_logo_mckinsey.png",
        "navigation_bar_color":"#2790F0",
        "course_card_overlay_color":"#2790F0"
    ]
}
