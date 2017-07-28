//
//  Paginator.swift
//  edX
//
//  Created by Akiva Leffert on 12/16/15.
//  Copyright © 2015 edX. All rights reserved.
//

protocol Paginator {
    associatedtype Element
    // Accumulation of all the objects loaded so far
    var stream : edXCore.Stream<[Element]> { get }
    var hasNext : Bool { get }
    func loadMore()
}

// Since Swift doesn't support generic protocols, we need a way to wrap
// the associated type from Paginator into a generic parameter.
// This bridges the two. This is slightly awkward so 
// TODO: Revisit when Swift supports generic protocols
class AnyPaginator<A> : Paginator {
    typealias Element = A
    let stream : edXCore.Stream<[Element]>
    fileprivate var _hasNext: () -> Bool
    let _loadMore: () -> Void
    
    init<P: Paginator>(_ paginator : P) where P.Element == A {
        self.stream = paginator.stream
        self._loadMore = paginator.loadMore
        self._hasNext = { paginator.hasNext }
    }
    
    var hasNext : Bool {
        return _hasNext()
    }
    
    func loadMore() {
        self._loadMore()
    }
}

class WrappedPaginator<A> : NSObject, Paginator {
    typealias Element = A
    
    fileprivate var itemStream = BackedStream<Paginated<[A]>>()
    fileprivate var generator : (Int) -> edXCore.Stream<Paginated<[A]>>
    fileprivate var currentPage : Int = PaginationDefaults.startPage
    
    init(generator : @escaping (Int) -> edXCore.Stream<Paginated<[A]>>) {
        self.generator = generator
    }
    
    convenience init(networkManager : NetworkManager, requestGenerator : @escaping (Int) -> NetworkRequest<Paginated<[A]>>) {
        self.init {page in
            let request = requestGenerator(page)
            return networkManager.streamForRequest(request)
        }
    }
    
    fileprivate(set) lazy var stream : edXCore.Stream<[A]> = {
        accumulate(self.itemStream.map { $0.value } )
    }()
    
    var hasNext: Bool {
        return currentPage == PaginationDefaults.startPage || (stream.value?.count ?? 0) != itemStream.value?.pagination.totalCount
    }
    
    func loadMore() {
        if !itemStream.active && hasNext {
            let stream = generator(currentPage)
            stream.listenOnce(self) {[weak self] in
                if $0.isSuccess {
                    self?.currentPage += 1
                }
            }
            itemStream.backWithStream(stream)
        }
    }
}
