//
//  BrandingThemeTests.swift
//  edX
//
//  Created by Shafqat Muneer on 8/11/17.
//  Copyright © 2017 edX. All rights reserved.
//

import XCTest
@testable import edX

class BrandingThemeTests: XCTestCase {
    let defaultThemeDictionary = [
        "logo_url": "img_logo_mckinsey.png",
        "navigation_bar_color":"#2790F0",
        "course_card_overlay_color":"#2790F0"
    ]
    
    let chemoursThemeDictionary = [
        "logo_url": "img_logo_chemours.png",
        "navigation_bar_color":"#F38333",
        "course_card_overlay_color":"#EC913C"
    ]

    let brandingTheme = BrandingThemes.shared
    
    func applyDefaultTheme() {
        brandingTheme.applyThemeWith(fileName: "mckinsey_theming")
    }
    
    func applyCustomTheme() {
        brandingTheme.applyThemeWith(fileName: "chemours_theming")
    }
    
    func testDefaultCompanyLogoApplied() {
        applyDefaultTheme()
        let appliedDefaultLogoURL = brandingTheme.valueForIdentifier(ThemeIdentifiers.logoURL)
        XCTAssertEqual(appliedDefaultLogoURL, defaultThemeDictionary["logo_url"])
    }
    
    func testDefaultNavigationColorApplied() {
        applyDefaultTheme()
        let appliedDefaultNavigationBarColor = brandingTheme.valueForIdentifier(ThemeIdentifiers.navBarColor)
        XCTAssertEqual(appliedDefaultNavigationBarColor, defaultThemeDictionary["navigation_bar_color"])
    }
    
    func testDefaultCompletedCourseCardTintColorApplied() {
        applyDefaultTheme()
        let appliedDefaultCompletedCourseTintColor = brandingTheme.valueForIdentifier(ThemeIdentifiers.courseCardOverlayColor)
        XCTAssertEqual(appliedDefaultCompletedCourseTintColor, defaultThemeDictionary["course_card_overlay_color"])
    }
    
    func testCustomCompanyLogoApplied() {
        applyCustomTheme()
        let appliedCustomLogoURL = brandingTheme.valueForIdentifier(ThemeIdentifiers.logoURL)
        XCTAssertEqual(appliedCustomLogoURL, chemoursThemeDictionary["logo_url"])
    }
    
    func testCustomNavigationColorApplied() {
        applyCustomTheme()
        let appliedCustomNavigationBarColor = brandingTheme.valueForIdentifier(ThemeIdentifiers.navBarColor)
        XCTAssertEqual(appliedCustomNavigationBarColor, chemoursThemeDictionary["navigation_bar_color"])
    }
    
    func testCustomCompletedCourseCardTintColorApplied() {
        applyCustomTheme()
        let appliedCustomCompletedCourseTintColor = brandingTheme.valueForIdentifier(ThemeIdentifiers.courseCardOverlayColor)
        XCTAssertEqual(appliedCustomCompletedCourseTintColor, chemoursThemeDictionary["course_card_overlay_color"])
    }
}
