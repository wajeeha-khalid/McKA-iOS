//
//  CourseLastAccessedController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 03/07/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public protocol CourseLastAccessedControllerDelegate : class {
    func courseLastAccessedControllerDidFetchLastAccessedItem(_ item : CourseLastAccessed?)
}

open class CourseLastAccessedController: NSObject {
   
    fileprivate let lastAccessedLoader = BackedStream<(CourseBlock, CourseLastAccessed)>()
    fileprivate let blockID : CourseBlockID?
    fileprivate let dataManager : DataManager
    fileprivate let networkManager : NetworkManager
    fileprivate let courseQuerier : CourseOutlineQuerier
    fileprivate let lastAccessedProvider : LastAccessedProvider?
    
    fileprivate var courseID : String {
        return courseQuerier.courseID
    }
    
    open weak var delegate : CourseLastAccessedControllerDelegate?
    
    /// Strictly a test variable used as a trigger flag. Not to be used out of the test scope
    fileprivate var t_hasTriggeredSetLastAccessed = false
    
    
    public init(blockID : CourseBlockID?, dataManager : DataManager, networkManager : NetworkManager, courseQuerier: CourseOutlineQuerier, lastAccessedProvider : LastAccessedProvider? = nil) {
        self.blockID = blockID
        self.dataManager = dataManager
        self.networkManager = networkManager
        self.courseQuerier = courseQuerier
        self.lastAccessedProvider = lastAccessedProvider ?? dataManager.interface
        
        super.init()
        
        addListener()
    }
    
    fileprivate var canShowLastAccessed : Bool {
        // We only show at the root level
        return blockID == nil
    }
    
    fileprivate var canUpdateLastAccessed : Bool {
        return blockID != nil
    }
    
    open func loadLastAccessed() {
        if !canShowLastAccessed {
            return
        }
        
        if let firstLoad = lastAccessedProvider?.getLastAccessedSectionForCourseID(self.courseID) {
            let blockStream = expandAccessStream(edXCore.Stream(value : firstLoad))
            lastAccessedLoader.backWithStream(blockStream)
        }
        
        let request = UserAPI.requestLastVisitedModuleForCourseID(courseID)
        let lastAccessed = self.networkManager.streamForRequest(request)
        lastAccessedLoader.backWithStream(expandAccessStream(lastAccessed))
    }
    
    open func saveLastAccessed() {
        if !canUpdateLastAccessed {
            return
        }
        
        if let currentCourseBlockID = self.blockID {
            t_hasTriggeredSetLastAccessed = true
            let request = UserAPI.setLastVisitedModuleForBlockID(self.courseID, module_id: currentCourseBlockID)
            let courseID = self.courseID
            expandAccessStream(self.networkManager.streamForRequest(request)).extendLifetimeUntilFirstResult {[weak self] result in
                result.ifSuccess() {info in
                    let block = info.0
                    let lastAccessedItem = info.1
                    
                    if let owner = self {
                        owner.lastAccessedProvider?.setLastAccessedSubSectionWithID(lastAccessedItem.moduleId,
                            subsectionName: block.displayName,
                            courseID: courseID,
                            timeStamp: OEXDateFormatting.serverString(with: Date()))
                    }
                }
            }
        }
    }

    func addListener() {
        lastAccessedLoader.listen(self) {[weak self] info in
            info.ifSuccess {
                let block = $0.0
                var item = $0.1
                item.moduleName = block.displayName
                
                self?.lastAccessedProvider?.setLastAccessedSubSectionWithID(item.moduleId, subsectionName: block.displayName, courseID: self?.courseID, timeStamp: OEXDateFormatting.serverString(with: Date()))
                self?.delegate?.courseLastAccessedControllerDidFetchLastAccessedItem(item)
            }
            
            info.ifFailure { [weak self] error in
                self?.delegate?.courseLastAccessedControllerDidFetchLastAccessedItem(nil)
            }
        }
        
    }
    
    fileprivate func expandAccessStream(_ stream : edXCore.Stream<CourseLastAccessed>) -> edXCore.Stream<(CourseBlock, CourseLastAccessed)> {
        return stream.transform {[weak self] lastAccessed in
            return joinStreams(self?.courseQuerier.blockWithID(lastAccessed.moduleId) ?? edXCore.Stream<CourseBlock>(), edXCore.Stream(value: lastAccessed))
        }
    }
}

