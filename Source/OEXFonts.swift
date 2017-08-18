//
//  OEXFonts.swift
//  edX
//
//  Created by José Antonio González on 11/2/16.
//  Copyright © 2016 edX. All rights reserved.
//

import UIKit
import SwiftyJSON

open class OEXFonts: NSObject {
    
    //MARK: - Shared Instance
    open static let sharedInstance = OEXFonts()
    @objc public enum FontIdentifiers: Int {
        case regular = 1, italic, semiBold, semiBoldItalic, bold, boldItalic, light, lightItalic, extraBold, extraBoldItalic, irregular
    }
    
    open var fontsDictionary = [String: AnyObject]()
    
    fileprivate override init() {
        super.init()
        fontsDictionary = initializeFontsDictionary()
    }
    
    fileprivate func initializeFontsDictionary() -> [String: AnyObject] {
        guard let filePath = Bundle.main.path(forResource: "fonts", ofType: "json") else {
            return fallbackFonts()
        }
        if let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) {
            var error : NSError?
            
            if let json = JSON(data: data, error: &error).dictionaryObject{
                return json as [String : AnyObject]
            }
        }
        return fallbackFonts()
    }
    
    open func fallbackFonts() -> [String: AnyObject] {
        return OEXFontsDataFactory.fonts as [String : AnyObject]
    }
    
    open func fontForIdentifier(_ identifier: FontIdentifiers, size: CGFloat) -> UIFont {
        if let fontName = fontsDictionary[getIdentifier(identifier)] as? String {
            return UIFont(name: fontName, size: size)!
        }
        return UIFont(name:getIdentifier(FontIdentifiers.irregular), size: size)!
    }
    
    fileprivate func getIdentifier(_ identifier: FontIdentifiers) -> String {
        switch identifier {
        case .regular:
            return "regular"
        case .italic:
            return "italic"
        case .semiBold:
            return "semiBold"
        case .semiBoldItalic:
            return "semiBoldItalic"
        case .bold:
            return "bold"
        case .boldItalic:
            return "boldItalic"
        case .light:
            return "light"
        case .lightItalic:
            return "lightItalic"
        case .extraBold:
            return "extraBold"
        case .extraBoldItalic:
            return "extraBoldItalic"
        case .irregular:
            fallthrough
        default:
            //Assert to crash on development, and return Zapfino font
            assert(false, "Could not find the required font in fonts.json")
            return "Zapfino"
        }
    }
}

