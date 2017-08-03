//
//  OEXColorsTests.swift
//  edX
//
//  Created by Danial Zahid on 8/23/16.
//  Copyright © 2016 edX. All rights reserved.
//

import edX
import XCTest

class OEXColorsTests: XCTestCase {
    
    var oexColors : OEXColors {
        return OEXColors.sharedInstance
    }
    
    func testColorFileExistence() {
        let filePath : String? = Bundle.main.path(forResource: "colors", ofType: "json")
        XCTAssertNotNil(filePath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: filePath ?? ""))
    }
    
    func testColorDataFactory() {
        _ = oexColors.fallbackColors()
        XCTAssertNotNil(oexColors.colorForIdentifier(OEXColors.ColorsIdentifiers.primaryBaseColor))
    }
    
    func testColorParsing() {
        XCTAssertNotNil(oexColors.colorForIdentifier(OEXColors.ColorsIdentifiers.primaryBaseColor))
        XCTAssertNotNil(oexColors.colorForIdentifier(OEXColors.ColorsIdentifiers.primaryLightColor))
        XCTAssertNotNil(oexColors.colorForIdentifier(OEXColors.ColorsIdentifiers.primaryBaseColor, alpha: 0.5))
        XCTAssertNotNil(oexColors.colorForIdentifier(OEXColors.ColorsIdentifiers.primaryLightColor, alpha: 1.0))
        XCTAssertEqual(oexColors.colorForIdentifier(OEXColors.ColorsIdentifiers.primaryBaseColor), oexColors.colorForIdentifier(OEXColors.ColorsIdentifiers.primaryBaseColor, alpha: 1.0))
    }

}
