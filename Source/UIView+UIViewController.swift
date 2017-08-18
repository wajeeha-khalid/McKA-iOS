//
//  UIView+UIViewController.swift
//  edX
//
//  Created by Saeed Bashir on 7/15/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

extension UIView {
    func firstAvailableUIViewController() -> UIViewController? {
        return traverseResponderChainForUIViewController()
    }
    
    fileprivate func traverseResponderChainForUIViewController() -> UIViewController? {
        let nextResponder = self.next
        if let nextResponder = nextResponder {
            if nextResponder.isKind(of: UIViewController.self) {
                return nextResponder as? UIViewController
            }
            else if nextResponder.isKind(of: UIView.self){
                let view = nextResponder as? UIView
                return view?.traverseResponderChainForUIViewController()
            }
        }
        
        return nil
    }
}
