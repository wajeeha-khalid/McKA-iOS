//
//  OEXFontsTests.swift
//  edX
//
//  Created by José Antonio González on 11/8/16.
//  Copyright © 2016 edX. All rights reserved.
//

import edX
import XCTest


class OEXFontsTests: XCTestCase {
    
    var oexFonts : OEXFonts {
        return OEXFonts.sharedInstance
    }
    
    func testFontFileExistence() {
        let filePath : String? = Bundle.main.path(forResource: "fonts", ofType: "json")
        XCTAssertNotNil(filePath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: filePath ?? ""))
    }
    
    func testFontDataFactory() {
        _ = oexFonts.fallbackFonts()
        XCTAssertNotNil(oexFonts.fontForIdentifier(OEXFonts.FontIdentifiers.regular, size: 12))
    }
    
    func testFontParsing() {
        XCTAssertNotNil(oexFonts.fontForIdentifier(OEXFonts.FontIdentifiers.regular, size: 12))
        XCTAssertNotNil(oexFonts.fontForIdentifier(OEXFonts.FontIdentifiers.semiBold, size: 12))
        XCTAssertNotNil(oexFonts.fontForIdentifier(OEXFonts.FontIdentifiers.bold, size: 12))
        XCTAssertNotNil(oexFonts.fontForIdentifier(OEXFonts.FontIdentifiers.light, size: 12))
        XCTAssertNotEqual(oexFonts.fontForIdentifier(OEXFonts.FontIdentifiers.regular, size: 12), oexFonts.fontForIdentifier(OEXFonts.FontIdentifiers.semiBold, size: 12))
    }
    
}
