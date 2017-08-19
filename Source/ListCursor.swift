//
//  ListCursor.swift
//  edX
//
//  Created by Akiva Leffert on 6/26/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation


open class ListCursor<A> {
    
    fileprivate var index : Int
    fileprivate let list : [A]
    
    public init(before : [A], current : A, after : [A]) {
        self.index = before.count
        var list = before
        list.append(current)
        list.append(contentsOf: after)
        self.list = list
    }
    
    // Will fail if current is not in the list
    public init?(list: [A], currentFinder : (A) -> Bool) {
        if let index = list.firstIndexMatching(currentFinder) {
            self.index = index
            self.list = list
        }
        else {
            self.index = 0
            self.list = []
            return nil
        }
    }
    
    public init(cursor : ListCursor<A>) {
        self.index = cursor.index
        self.list = cursor.list
    }
    
    public init?(startOfList list : [A]) {
        if list.count == 0 {
            self.index = 0
            self.list = []
            return nil
        }
        else {
            self.index = 0
            self.list = list
        }
    }
    
    public init?(endOfList list : [A]) {
        if list.count == 0 {
            self.index = 0
            self.list = []
            return nil
        }
        else {
            self.index = list.count - 1
            self.list = list
        }
    }
    
    public func map<B>(transform: (A) -> B) -> ListCursor<B> {
        /*
        let beforeCursor = ListCursor(cursor: self)
        var before: [B] = []
        beforeCursor.loopToStartExcludingCurrent { (cursor, _) in
            before.append(transform(cursor.current))
        }
        let current = transform(self.current)
        let afterCursor = ListCursor(cursor: self)
        var after: [B] = []
        afterCursor.loopToEndExcludingCurrent { (cursor, _) in
            after.append(transform(cursor.current))
        }
        let reversed: [B] = Array(before.reversed())
        return ListCursor<B>(before: reversed, current: current, after: after)*/
        let mapped = list.map(transform)
        let cursor = ListCursor<B>(startOfList: mapped)
        cursor!.index = self.index
        return cursor!
    }
    
    open func updateCurrentToItemMatching(_ matcher : (A) -> Bool) {
        if let index = list.firstIndexMatching(matcher) {
            self.index = index
        }
        else {
            assert(false, "Could not find item in cursor")
        }
    }
    
    /// Return the previous value if available and decrement the index
    open func prev() -> A? {
        if hasPrev {
            index = index - 1
            return list[index]
        }
        else {
            return nil
        }
    }
    
    /// Return the next value if available and increment the index
    open func next() -> A? {
        if hasNext {
            index = index + 1
            return list[index]
        }
        else {
            return nil
        }
    }
    
    open var hasPrev : Bool {
        return index > 0
    }
    
    open var hasNext : Bool {
        return index + 1 < list.count
    }
    
    open var current : A {
        assert(index >= 0 && index < list.count, "Invariant violated")
        return list[index]
    }
    
    /// Return the previous value if possible without changing the current index
    open func peekPrev() -> A? {
        if hasPrev {
            return list[index - 1]
        }
        else {
            return nil
        }
    }
    
    
    /// Return the next value if possible without changing the current index
    open func peekNext() -> A? {
        if hasNext {
            return list[index + 1]
        }
        else {
            return nil
        }
    }
    
    open func loopToStartExcludingCurrent(_ f : (ListCursor<A>, Int) -> Void) {
        while let _ = prev() {
            f(self, self.index)
        }
    }
    
    open func loopToEndExcludingCurrent(_ f : (ListCursor<A>, Int) -> Void) {
        while let _ = next() {
            f(self, self.index)
        }
    }
    
    /// Loops through all values backward to the beginning, including the current block
    open func loopToStart(_ f : (ListCursor<A>, Int) -> Void) {
        for i in Array((0 ... self.index).reversed()) {
            self.index = i
            f(self, i)
        }
    }
    
    /// Loops through all values forward to the end, including the current block
    open func loopToEnd(_ f : (ListCursor<A>, Int) -> Void) {
        for i in self.index ..< self.list.count {
            self.index = i
            f(self, i)
        }
    }
}
