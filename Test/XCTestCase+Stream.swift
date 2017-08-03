//
//  XCTestCase+Stream.swift
//  edX
//
//  Created by Akiva Leffert on 3/7/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
import edX

extension XCTestCase {
    func waitForStream<A>(_ stream : edXCore.Stream<A>, fireIfAlreadyLoaded: Bool = true, verifier : ((Result<A>) -> Void)? = nil) {
        let expectation = self.expectation(description: "stream fires")
        stream.extendLifetimeUntilFirstResult(fireIfAlreadyLoaded: fireIfAlreadyLoaded) {
            verifier?($0)
            expectation.fulfill()
        }
        waitForExpectations()
    }
}
