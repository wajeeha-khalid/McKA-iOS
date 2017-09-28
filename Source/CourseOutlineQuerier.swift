//
//  CourseOutlineQuerier.swift
//  edX
//
//  Created by Akiva Leffert on 5/4/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

private enum TraversalDirection {
    case forward
    case reverse
}

open class CourseOutlineQuerier : NSObject {
    public struct GroupItem {
        public let block : CourseBlock
        public let nextGroup : CourseBlock?
        public let prevGroup : CourseBlock?
        public let parent : CourseBlockID
        
        init(sourceCursor : ListCursor<CourseBlock>, contextCursor : ListCursor<BlockGroup>) {
            block = sourceCursor.current
            nextGroup = sourceCursor.hasNext ? nil : contextCursor.peekNext()?.block
            prevGroup = sourceCursor.hasPrev ? nil : contextCursor.peekPrev()?.block
            parent = contextCursor.current.block.blockID
        }
    }
    
    public struct BlockGroup {
        public let block : CourseBlock
        public let children : [CourseBlock]
    }
    
    
    open fileprivate(set) var courseID : String
    fileprivate let enrollmentManager: EnrollmentManager?
    fileprivate let interface : OEXInterface?
    fileprivate let networkManager : NetworkManager?
    fileprivate let session : OEXSession?
    fileprivate let courseOutline : BackedStream<CourseOutline> = BackedStream()
    open var needsRefresh : Bool = false
    
    public init(courseID : String, interface : OEXInterface?, enrollmentManager: EnrollmentManager?, networkManager : NetworkManager?, session : OEXSession?) {
        self.courseID = courseID
        self.interface = interface
        self.enrollmentManager = enrollmentManager
        self.networkManager = networkManager
        self.session = session
        super.init()
        addListener()
    }
    
    /// Use this to create a querier with an existing outline.
    /// Typically used for tests
    public init(courseID : String, outline : CourseOutline) {
        self.courseOutline.backWithStream(edXCore.Stream(value : outline))
        self.courseID = courseID
        self.enrollmentManager = nil
        self.interface = nil
        self.networkManager = nil
        self.session = nil
        
        super.init()
        addListener()
    }
    
    fileprivate func addListener() {
        courseOutline.listen(self,
                             success : {[weak self] outline in
                                self?.loadedNodes(outline.blocks)
            }, failure : { _ in
            }
        )
    }
    
    fileprivate func loadedNodes(_ blocks : [CourseBlockID : CourseBlock]) {
        var videos : [OEXVideoSummary] = []
        var audios : [OEXAudioSummary] = []  //Added By Ravi on 22Jan'17 to Implement AudioPodcast
        for (_, block) in blocks {
            switch block.type {
            case let .video(video):
                videos.append(video)
            case let .audio(audio):
                audios.append(audio)
            default:
                break
            }
        }
        
        self.interface?.addVideos(videos, forCourseWithID: courseID)
        self.interface?.addAudios(audios, forCourseWithID: courseID)
    }
    
    fileprivate func loadOutlineIfNecessary() {
        if (courseOutline.value == nil || needsRefresh) && !courseOutline.active {
            needsRefresh = false
            if let enrollment = self.enrollmentManager?.enrolledCourseWithID(courseID),
                let access = enrollment.course.courseware_access, !access.has_access
            {
                let stream = edXCore.Stream<CourseOutline>(error: OEXCoursewareAccessError(coursewareAccess: access, displayInfo: enrollment.course.start_display_info))
                courseOutline.backWithStream(stream)
            }
            else {
                let request = CourseOutlineAPI.requestWithCourseID(courseID, username : session?.currentUser?.username)
                if let loader = networkManager?.streamForRequest(request, persistResponse: true) {
                    courseOutline.backWithStream(loader)
                }
            }
        }
    }
    
    open var rootID : edXCore.Stream<CourseBlockID> {
        loadOutlineIfNecessary()
        return courseOutline.map { return $0.root }
    }
    
    open func spanningCursorForBlockWithID(_ blockID : CourseBlockID?, initialChildID : CourseBlockID?) -> edXCore.Stream<ListCursor<GroupItem>> {
        loadOutlineIfNecessary()
        return courseOutline.flatMap {[weak self] outline in
            if let blockID = blockID,
                let child = initialChildID ?? self?.blockWithID(blockID, inOutline: outline)?.children.first,
                let groupCursor = self?.cursorForLeafGroupsAdjacentToBlockWithID(blockID, inOutline: outline),
                let flatCursor = self?.flattenGroupCursor(groupCursor, startingAtChild: child)
            {
                return Success(flatCursor)
            }
            else {
                return Failure(NSError.oex_courseContentLoadError())
            }
        }
    }
    
    fileprivate func depthOfBlockWithID(_ blockID : CourseBlockID, inOutline outline : CourseOutline) -> Int? {
        var depth = 0
        var current = blockID
        while let parent = outline.parentOfBlockWithID(current), current != outline.root  {
            current = parent
            depth = depth + 1
        }
        
        return depth
    }
    
    // Returns all groups before (or after if direction is .Reverse) the given block at its same tree depth
    fileprivate func leafGroupsFromDirection(_ direction : TraversalDirection, forBlockWithID blockID : CourseBlockID, inOutline outline : CourseOutline) -> [BlockGroup] {
        var queue : [(blockID : CourseBlockID, depth : Int)] = []
        let root = (blockID : outline.root, depth : 0)
        
        queue.append(root)
        
        let depth : Int
        if let d = depthOfBlockWithID(blockID, inOutline : outline) {
            depth = d
        }
        else {
            // block not found so just return empty
            return []
        }
        
        // Do a basic breadth first traversal
        var groups : [BlockGroup] = []
        while let next = queue.last {
            queue.removeLast()
            if next.blockID == blockID {
                break
            }
            if let block = blockWithID(next.blockID, inOutline: outline) {
                if next.depth == depth {
                    // Don't add groups with no children since we don't want to display them
                    if let group = childrenOfBlockWithID(next.blockID, inOutline: outline), group.children.count > 0 {
                        // Account for the traversal direction. The output should always be left to right
                        switch direction {
                        case .forward: groups.append(group)
                        case .reverse: groups.insert(group, at:0)
                        }
                    }
                    // At the correct depth so skip all our children
                    continue
                }
                
                let children : [CourseBlockID]
                switch direction {
                case .forward: children = block.children
                case .reverse: children = Array(block.children.reversed())
                }
                
                for child in children {
                    let item = (blockID : child, depth : next.depth + 1)
                    queue.insert(item, at: 0)
                }
            }
        }
        return groups
    }
    
    // Turns a list of block groups into a flattened list of blocks with context information
    fileprivate func flattenGroupCursor(_ groupCursor : ListCursor<BlockGroup>, startingAtChild startChild: CourseBlockID) -> ListCursor<GroupItem>? {
        let cursor =
            ListCursor(list: groupCursor.current.children) {child in
                child.blockID == startChild}
                ?? ListCursor(startOfList: groupCursor.current.children)
        
        if let cursor = cursor {
            var before : [GroupItem] = []
            var after : [GroupItem] = []
            
            // Add the items from the current group
            let current = GroupItem(sourceCursor: cursor, contextCursor: groupCursor)
            let cursorBefore = ListCursor(cursor: cursor)
            cursorBefore.loopToStartExcludingCurrent {(cursor, _) in
                let item = GroupItem(sourceCursor: cursor, contextCursor: groupCursor)
                before.append(item)
            }
            let cursorAfter = ListCursor(cursor: cursor)
            cursorAfter.loopToEndExcludingCurrent {(cursor, _) in
                let item = GroupItem(sourceCursor: cursor, contextCursor: groupCursor)
                after.append(item)
            }
            
            // Now go through all the other groups
            let backCursor = ListCursor(cursor: groupCursor)
            backCursor.loopToStartExcludingCurrent {(contextCursor, _) in
                let cursor = ListCursor(endOfList: contextCursor.current.children)
                cursor?.loopToStart {(cursor, _) in
                    let item = GroupItem(sourceCursor: cursor, contextCursor: contextCursor)
                    before.append(item)
                }
            }
            
            let forwardCursor = ListCursor(cursor: groupCursor)
            forwardCursor.loopToEndExcludingCurrent {(contextCursor, _) in
                let cursor = ListCursor(startOfList: contextCursor.current.children)
                cursor?.loopToEnd {(cursor, _) in
                    let item = GroupItem(sourceCursor: cursor, contextCursor: contextCursor)
                    after.append(item)
                }
            }
            
            return ListCursor(before: Array(before.reversed()), current: current, after: after)
        }
        return nil
    }
    
    fileprivate func cursorForLeafGroupsAdjacentToBlockWithID(_ blockID : CourseBlockID, inOutline outline : CourseOutline) -> ListCursor<BlockGroup>? {
        
        
        if let current = childrenOfBlockWithID(blockID, inOutline: outline) {
            
            let before = leafGroupsFromDirection(.forward, forBlockWithID: blockID, inOutline: outline)
            let after = leafGroupsFromDirection(.reverse, forBlockWithID: blockID, inOutline: outline)
            
            return ListCursor(before: before, current: current, after: after)
        }
        else {
            return nil
        }
    }
    
    open func parentOfBlockWithID(_ blockID : CourseBlockID) -> edXCore.Stream<CourseBlockID?> {
        loadOutlineIfNecessary()
        
        return courseOutline.flatMap {(outline : CourseOutline) -> Result<CourseBlockID?> in
            if blockID == outline.root {
                return Success(nil)
            }
            else {
                if let blockID = outline.parentOfBlockWithID(blockID) {
                    return Success(blockID)
                }
                else {
                    return Failure(NSError.oex_courseContentLoadError())
                }
                
            }
        }
    }
    
    /// Loads all the children of the given block.
    /// nil means use the course root.
    open func childrenOfBlockWithID(_ blockID : CourseBlockID?) -> edXCore.Stream<BlockGroup> {
        
        loadOutlineIfNecessary()
        
        return courseOutline.flatMap {[weak self] (outline : CourseOutline) -> Result<BlockGroup> in
            let children = self?.childrenOfBlockWithID(blockID, inOutline: outline)
            
            return children.toResult(NSError.oex_courseContentLoadError())
        }
    }
    
    fileprivate func childrenOfBlockWithID(_ blockID : CourseBlockID?, inOutline outline : CourseOutline) -> BlockGroup? {
        if let block = self.blockWithID(blockID ?? outline.root, inOutline: outline)
        {
            
            if case .unit = block.type {
                
                block.children = block.children.filter({ (blockID) -> Bool in
                    if blockID.contains("type@discussion")  {
                        return false
                    } else {
                        return true
                    }
                })
            }
            var childBlocks = block.children.flatMap({ self.blockWithID($0, inOutline: outline) })
            
            // combine the html blocks followed by video blocks
            if case .unit = block.type {
                childBlocks  = combineDescriptionBlocksFollowedByVideoBlocks(from: childBlocks)
                childBlocks = swapRawHTMLAndFreeTextPositions(from: childBlocks)
            }
            
            if childBlocks.count > 0  {
                
                switch childBlocks.first!.type {
                case .unit:
                    childBlocks.forEach({ (courseComponent) in
                        
                        for (index, childBlockID ) in courseComponent.children.enumerated(){
                            if childBlockID.contains("type@discussion"){
                                courseComponent.discussionBlock = self.blockWithID(childBlockID).value
                                courseComponent.children.remove(at: index)
                            }
                        }
                        
                    })
                default:
                    break
                }
                
            }
            return BlockGroup(block : block, children : childBlocks)
        }
        else {
            return nil
        }
    }
    
    /// This method iterates all the blocks and look for an html component followed by an 
    /// ooyala video component. In case any such component is found the html component is 
    /// removed from the list and it's content are passed to ooyala video component....
    func combineDescriptionBlocksFollowedByVideoBlocks(from blocks: [CourseBlock]) -> [CourseBlock] {
        return blocks.reduce([], { (acc, block) -> [CourseBlock] in
            guard let last = acc.last else {
                return [block]
            }
            if case let .ooyalaVideo(contentID, playerCode, _) = block.type, case .html (let content) = last.type {
                var clipped = acc.dropLast()
                block.type = .ooyalaVideo(contentID: contentID, playerCode: playerCode, htmlDescription: content)
                clipped.append(block)
                return Array(clipped)
            }
            return acc + [block]
        })
    }
    
    func swapRawHTMLAndFreeTextPositions(from blocks: [CourseBlock]) -> [CourseBlock] {
        var swappedBlocks = blocks
        for (index, block) in blocks.enumerated() {
            if case .freeText(_) = block.type {
                if index < blocks.count - 1 {
                    if case .html (_) = blocks[index + 1].type {
                        swappedBlocks[index] = blocks[index + 1]
                        swappedBlocks[index + 1] = blocks[index]
                    }
                }
            }
        }
        
        return swappedBlocks
        
    }
    
    fileprivate func flatMapRootedAtBlockWithID<A>(_ id : CourseBlockID, inOutline outline : CourseOutline, transform : (CourseBlock) -> [A], accumulator : inout [A]) {
        if let block = self.blockWithID(id, inOutline: outline) {
            accumulator.append(contentsOf: transform(block))
            for child in block.children {
                flatMapRootedAtBlockWithID(child, inOutline: outline, transform: transform, accumulator: &accumulator)
            }
        }
    }
    
    
    open func flatMapRootedAtBlockWithID<A>(_ id : CourseBlockID, transform : @escaping (CourseBlock) -> [A]) -> edXCore.Stream<[A]> {
        loadOutlineIfNecessary()
        return courseOutline.map {[weak self] outline -> [A] in
            var result : [A] = []
            self?.flatMapRootedAtBlockWithID(id, inOutline: outline, transform: transform, accumulator: &result)
            return result
        }
    }
    
    open func flatMapRootedAtBlockWithID<A>(_ id : CourseBlockID, transform : @escaping (CourseBlock) -> A?) -> edXCore.Stream<[A]> {
        return flatMapRootedAtBlockWithID(id, transform: { block in
            return transform(block).map { [$0] } ?? []
        })
    }
    
    /// Loads the given block.
    /// nil means use the course root.
    open func blockWithID(_ id : CourseBlockID?) -> edXCore.Stream<CourseBlock> {
        loadOutlineIfNecessary()
        return courseOutline.flatMap {outline in
            let blockID = id ?? outline.root
            let block = self.blockWithID(blockID, inOutline : outline)
            return block.toResult(NSError.oex_courseContentLoadError())
        }
    }
    
    fileprivate func blockWithID(_ id : CourseBlockID, inOutline outline : CourseOutline) -> CourseBlock? {
        if let block = outline.blocks[id], case .unit = block.type {
            let mutableBlock = block
            let children = mutableBlock.children.flatMap {
                outline.blocks[$0]
            }
            let combined = combineDescriptionBlocksFollowedByVideoBlocks(from: children)
            mutableBlock.children = combined.map{$0.blockID}
            return block
        } else if let block = outline.blocks[id] {
            return block
        }
        return nil
    }
}

extension CourseOutlineQuerier {
    // the block against this id must have `chatper` type
    func unitsForLesson(withID lessonID: CourseBlockID) -> edXCore.Stream<[CourseBlock]> {
        
        return childrenOfBlockWithID(lessonID).transform { (lesson: BlockGroup) -> edXCore.Stream<[CourseBlock]> in
            let sequentials = lesson.children.map { section in
                self.childrenOfBlockWithID(section.blockID).map {
                    $0.children
                }
            }
            
            let flattened = joinStreams(sequentials).map {
                $0.flatMap {$0}
            }
            
            return flattened
            }.map {
                $0.filter { !$0.children.isEmpty }
        }
    }
    
    func lessonContaining(unit: CourseBlock) -> edXCore.Stream<CourseBlock> {
        guard case .unit = unit.type else {
            fatalError("The type of unit must be a vertical")
        }
        
        return parentOfBlockWithID(unit.blockID)
            .transform {
                self.blockWithID($0)
            }.transform { block in
                switch block.type {
                case .chapter:
                    return Stream(value: block)
                case _:
                    return self.parentOfBlockWithID(block.blockID).transform {
                        self.blockWithID($0)
                    }
                }
        }
    }
    
}
