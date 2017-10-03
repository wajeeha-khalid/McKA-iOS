//
//  OyalaPlayerManager.swift
//  edX
//
//  Created by Shafqat Muneer on 10/2/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation
import edXCore
import MckinseyXBlocks

class OyalaPlayerManager:NSObject, OyalaPlayerDelegate {
    func enableLandscapeMode(_ enable:Bool) {
        let appDelegate = UIApplication.shared.delegate as! OEXAppDelegate
        appDelegate.shouldRotate = enable
        
        //If device is in landscape and user exit from full screen mode then
        //forcefully rotate view to portrait.
        if !enable {
            let value = UIInterfaceOrientation.portraitUpsideDown.rawValue
            UIDevice.current.setValue(value, forKey: "orientation")
        }
    }
}
