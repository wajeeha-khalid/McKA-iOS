//
//  Feed.swift
//  edX
//
//  Created by Michael Katz on 10/21/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

open class Feed<A> : LifetimeTrackable {
    open let lifetimeToken = NSObject()
    
    fileprivate let backing = BackedStream<A>()
    fileprivate let refreshTrigger : (BackedStream<A>) -> Void
    
    open var output : edXCore.Stream<A> {
        return backing
    }
    
    public init(refreshTrigger : @escaping (BackedStream<A>) -> Void) {
        self.refreshTrigger = refreshTrigger
    }
    
    open func refresh() {
        self.refreshTrigger(backing)
    }
    
    open func map<B>(_ f : @escaping (A) -> B) -> Feed<B> {
        let backing = BackedStream<A>()
        let result = Feed<B> { stream in
            self.refreshTrigger(backing)
            stream.backWithStream(backing.map(f))
        }
        return result
    }
}

open class BackedFeed<A> : Feed<A> {
    fileprivate var feed : Feed<A>?
    fileprivate var backingRemover : Removable?
    
    open var backingStream : BackedStream<A> {
        return self.backing
    }
    
    public init() {
        super.init {_ in } // we override refresh so we don't need this
    }
    
    open func backWithFeed(_ feed : Feed<A>) {
        self.removeBacking()
        
        self.feed = feed
        self.backingRemover = self.backing.addBackingStream(feed.backing)
    }
    
    open func removeBacking() {
        self.feed = nil
        self.backingRemover?.remove()
        self.backingRemover = nil
    }
    
    override open func refresh() {
        self.feed?.refresh()
    }
}

extension Feed {
    convenience init(request : NetworkRequest<A>, manager : NetworkManager, persistResponse: Bool = false) {
        self.init(refreshTrigger: {backing in
            backing.addBackingStream(manager.streamForRequest(request, persistResponse: persistResponse))
        })
    }
}
