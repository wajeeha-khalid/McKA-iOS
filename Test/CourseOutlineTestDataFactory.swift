//
//  CourseOutlineTestDataFactory.swift
//  edX
//
//  Created by Akiva Leffert on 4/30/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import edX

open class CourseOutlineTestDataFactory {

    // This is temporarily part of the edX target instead of the edXTests target so we can use it as a fixture
    // during development. When that is not being done any more we should hook it up to the test target only
    
    open static func freshCourseOutline(_ courseID : String) -> CourseOutline {
        return CourseOutline(
            root : courseID,
            blocks : [
                courseID: CourseBlock(type: CourseBlockType.course, children : ["chapter1", "chapter2", "chapter3", "chapter4", "discussion_course"], blockID : courseID, name : "A Course", blockCounts : ["video" : 1], multiDevice : true),
                "chapter1": CourseBlock(type: CourseBlockType.chapter, children : ["section1.1", "section1.2"], blockID : "chapter1", name : "Chapter 1", blockCounts : ["video" : 1], multiDevice : true),
                "chapter2": CourseBlock(type: CourseBlockType.chapter, children : ["section2.1", "section2.2"], blockID : "chapter2", name : "Chapter 2", multiDevice : true),
                "chapter3": CourseBlock(type: CourseBlockType.chapter, children : ["section3.1"], blockID : "chapter3", name : "Chapter 3", multiDevice : true),
                "chapter4": CourseBlock(type: CourseBlockType.chapter, children : ["section4.1"], blockID : "chapter4", name : "Chapter 4", multiDevice : true),
                "section1.1": CourseBlock(type: CourseBlockType.section, children : ["unit1", "unit2"], blockID : "section1.1", name : "Section 1", blockCounts : ["video" : 1], multiDevice : true),
                "section1.2": CourseBlock(type: CourseBlockType.section, children : ["unit3"], blockID : "section1.2", name : "Section 2", multiDevice : true),
                "section2.1": CourseBlock(type: CourseBlockType.section, children : [], blockID : "section2.1", name : "Section 1", multiDevice : true),
                "section2.2": CourseBlock(type: CourseBlockType.section, children : [], blockID : "section2.2", name : "Section 2", multiDevice : true),
                "section3.1": CourseBlock(type: CourseBlockType.section, children : [], blockID : "section3.1", name : "Section 1", multiDevice : true),
                "section4.1": CourseBlock(type: CourseBlockType.section, children : [], blockID : "section4.1", name : "Section 1", multiDevice : true),
                "unit1": CourseBlock(type: CourseBlockType.unit, children : ["block1"], blockID : "unit1", name : "Unit 1", multiDevice : true),
                "unit2": CourseBlock(type: CourseBlockType.unit, children : ["block2", "block3", "block4", "block5"], blockID : "unit2", name : "Unit 2", blockCounts : ["video" : 1], multiDevice : true),
                "unit3": CourseBlock(type: CourseBlockType.unit, children : [], blockID : "unit3", name : "Unit 3", multiDevice : true),
                "block1": CourseBlock(type: CourseBlockType.html(""), children : [], blockID : "block1", name : "Block 1", multiDevice : true),
                "block2": CourseBlock(type: CourseBlockType.html(""), children : [], blockID : "block2", name : "Block 2", multiDevice : true),
                "block3": CourseBlock(type: CourseBlockType.problem, children : [], blockID : "block3", name : "Block 3", multiDevice : true),
                "block4": CourseBlock(type: CourseBlockType.video(OEXVideoSummaryTestDataFactory.localVideoWithID("block4", pathIDs: ["chapter1", "section1.1", "unit2"])), children : [], blockID : "block4", name : "Block 4", blockCounts : ["video" : 1], multiDevice : true),
                "block5": CourseBlock(type: CourseBlockType.unknown("something"), children : [], blockID : "block5", name : "Block 5", multiDevice : false)
            ])
    }
    
    
    open static func knownLastAccessedItem() -> CourseLastAccessed {
        return CourseLastAccessed(moduleId: "unit2", moduleName: "unit2")
    }
    
    open static func knownParentIDWithMultipleChildren() -> CourseBlockID {
        return "unit2"
    }
    
    open static func knownSection() -> CourseBlockID {
        return "section1.1"
    }
    
    open static func knownEmptySection() -> CourseBlockID {
        return "section2.1"
    }

    open static func knownVideoFilterableSection() -> CourseBlockID {
        return "unit2"
    }
    
    open static func knownHTMLBlockIDs() -> [CourseBlockID] {
        return ["block1", "block2"]
    }
}
