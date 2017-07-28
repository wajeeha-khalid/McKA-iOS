//
//  MockLastAccessedProvider.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 07/07/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

open class MockLastAccessedProvider: LastAccessedProvider {
   
    fileprivate var mockLastAccessedItem : CourseLastAccessed?
    
    public init() { }
    
    open func getLastAccessedSectionForCourseID(_ courseID: String) -> CourseLastAccessed? {
        return self.mockLastAccessedItem
    }
    
    open func setLastAccessedSubSectionWithID(_ subsectionID: String, subsectionName: String, courseID: String?, timeStamp: String) {
        self.mockLastAccessedItem = CourseLastAccessed(moduleId: subsectionID, moduleName: subsectionName)
    }
    
    open func resetLastAccessedItem() {
        self.mockLastAccessedItem = nil
    }
}
