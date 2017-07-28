//
//  NSNotificationCenter+SafeSwift.swift
//  edX
//
//  Created by Akiva Leffert on 5/15/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

private class NotificationListener : NSObject, Removable {
    var action : ((Notification, Removable) -> Void)?
    var removeAction : ((NotificationListener) -> Void)?

    @objc func notificationFired(_ notification : Notification) {
        self.action?(notification, self)
    }
    
    func remove() {
        NotificationCenter.default.removeObserver(self)
        self.removeAction?(self)
        self.action = nil
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}


extension NotificationCenter {
    @discardableResult func oex_addObserver<Observer : NSObject>(_ observer : Observer, name : String, action : @escaping (Notification, Observer, Removable) -> Void) -> Removable {
        let listener = NotificationListener()
        listener.action = {[weak observer] (notification, removable) in
            if let observer = observer {
                action(notification, observer, removable)
            }
        }
        let removable = observer.oex_performAction {
            listener.remove()
        }
        self.addObserver(listener, selector: #selector(NotificationListener.notificationFired(_:)), name: NSNotification.Name(rawValue: name), object: nil)
        
        return BlockRemovable { removable.remove() }
    }
}

@discardableResult public func addNotificationObserver<Observer : NSObject>(_ observer : Observer, name : String, action : @escaping (Notification, Observer, Removable) -> Void) -> Removable {
    return NotificationCenter.default.oex_addObserver(observer, name: name, action: action)
}
