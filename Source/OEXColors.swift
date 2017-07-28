//
//  OEXColors.swift
//  edX
//
//  Created by Danial Zahid on 8/17/16.
//  Copyright © 2016 edX. All rights reserved.
//

import UIKit
import SwiftyJSON

open class OEXColors: NSObject {

    //MARK: - Shared Instance
    open static let sharedInstance = OEXColors()
    @objc public enum ColorsIdentifiers: Int {
        case piqueGreen = 1, primaryXDarkColor, primaryDarkColor, primaryBaseColor, primaryLightColor, primaryXLightColor,
        secondaryXDarkColor, secondaryDarkColor, secondaryBaseColor, secondaryLightColor, secondaryXLightColor,
        neutralBlack, neutralBlackT, neutralXDark, neutralDark, neutralBase,
        neutralLight, neutralXLight, neutralXXLight, neutralWhite, neutralWhiteT,
        utilitySuccessDark, utilitySuccessBase, utilitySuccessLight,
        warningDark, warningBase, warningLight,
        errorDark, errorBase, errorLight,
        banner, random
    }
    
    open var colorsDictionary = [String: AnyObject]()
    
    fileprivate override init() {
        super.init()
        colorsDictionary = initializeColorsDictionary()
    }
    
    fileprivate func initializeColorsDictionary() -> [String: AnyObject] {
        guard let filePath = Bundle.main.path(forResource: "colors", ofType: "json") else {
            return fallbackColors()
        }
        if let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) {
            var error : NSError?
            
            if let json = JSON(data: data, error: &error).dictionaryObject{
                return json as [String : AnyObject]
            }
            return fallbackColors()
        }
        return fallbackColors()
    }
    
    open func fallbackColors() -> [String: AnyObject] {
        return OEXColorsDataFactory.colors as [String : AnyObject]
    }
    
    open func colorForIdentifier(_ identifier: ColorsIdentifiers) -> UIColor {
        return colorForIdentifier(identifier, alpha: 1.0)
    }
    
    open func colorForIdentifier(_ identifier: ColorsIdentifiers, alpha: CGFloat) -> UIColor {
        if let hexValue = colorsDictionary[getIdentifier(identifier)] as? String {
            let color = UIColor(hexString: hexValue, alpha: alpha)
            return color
        }

        return UIColor(hexString: getIdentifier(ColorsIdentifiers.random), alpha: 1.0)
    }
    
    fileprivate func getIdentifier(_ identifier: ColorsIdentifiers) -> String {
        switch identifier {
        case .piqueGreen:
            return "piqueGreen"
        case .primaryXDarkColor:
            return "primaryXDarkColor"
        case .primaryDarkColor:
            return "primaryDarkColor"
        case .primaryBaseColor:
            return "primaryBaseColor"
        case .primaryLightColor:
            return "primaryLightColor"
        case .primaryXLightColor:
            return "primaryXLightColor"
        case .secondaryXDarkColor:
            return "secondaryXDarkColor"
        case .secondaryDarkColor:
            return "secondaryDarkColor"
        case .secondaryBaseColor:
            return "secondaryBaseColor"
        case .secondaryLightColor:
            return "secondaryLightColor"
        case .secondaryXLightColor:
            return "secondaryXLightColor"
        case .neutralBlack:
            return "neutralBlack"
        case .neutralBlackT:
            return "neutralBlackT"
        case .neutralXDark:
            return "neutralXDark"
        case .neutralDark:
            return "neutralDark"
        case .neutralBase:
            return "neutralBase"
        case .neutralLight:
            return "neutralLight"
        case .neutralXLight:
            return "neutralXLight"
        case .neutralXXLight:
            return "neutralXXLight"
        case .neutralWhite:
            return "neutralWhite"
        case .neutralWhiteT:
            return "neutralWhiteT"
        case .utilitySuccessDark:
            return "utilitySuccessDark"
        case .utilitySuccessBase:
            return "utilitySuccessBase"
        case .utilitySuccessLight:
            return "utilitySuccessLight"
        case .warningDark:
            return "warningDark"
        case .warningBase:
            return "warningBase"
        case .warningLight:
            return "warningLight"
        case .errorDark:
            return "errorDark"
        case .errorBase:
            return "errorBase"
        case .errorLight:
            return "errorLight"
        case .banner:
            return "banner"
        case .random:
            fallthrough
        default:
            //Assert to crash on development, and return a random color for distribution
            assert(false, "Could not find the required color in colors.json")
            return "#FABA12"
            
        }
    }
}
