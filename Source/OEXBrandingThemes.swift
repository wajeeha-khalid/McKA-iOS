//
//  OEXBrandingThemes.swift
//  edX
//
//  Created by Shafqat Muneer on 8/10/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit
import SwiftyJSON

/**
    Purpose of this class to read theming detail from provided theming file and
    make theming details available on app level.
 */
open class OEXBrandingThemes: NSObject {
    
    @objc public enum ThemeIdentifiers: Int {
        case logoURL = 1,
        navBarColor,
        courseCardOverlayColor
    }
    
    open static var sharedInstance = OEXBrandingThemes(brandingFile: MCKINSEY_THEME_FILE)
    open var themeDictionary = [String: AnyObject]()
    
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
        if let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) {
            var error : NSError?
            
            if let json = JSON(data: data, error: &error).dictionaryObject{
                return json as [String : AnyObject]
            }
            return defaultTheme()
        }
        return defaultTheme()
    }
    
    fileprivate func defaultTheme() -> [String: AnyObject] {
        return OEXDefaultTheming.defaultTheme as [String : AnyObject]
    }
    
    open func valueForIdentifier(_ identifier: ThemeIdentifiers) -> String {
        return themeDictionary[getIdentifier(identifier)] as! String
    }
    
    fileprivate func getIdentifier(_ identifier: ThemeIdentifiers) -> String {
        switch identifier {
        case .logoURL:
            return "logo_url"
        case .navBarColor:
            return "navigation_bar_color"
        case .courseCardOverlayColor:
            return "course_card_overlay_color"
        }
    }
}

/**
    Its the default theming structure. If in any case, error thrown during
    reading to theming json file then by default this theme detail will be applied.
 */
class OEXDefaultTheming: NSObject {
    static let defaultTheme = [
        "logo_url": "img_logo_mckinsey.png",
        "navigation_bar_color":"#2790F0",
        "course_card_overlay_color":"#2790F0"
    ]
}
