//
//  ViewTopMessageController.swift
//  edX
//
//  Created by Akiva Leffert on 6/4/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

open class ViewTopMessageController : NSObject, ContentInsetsSource {

    weak open var insetsDelegate : ContentInsetsSourceDelegate?
    
    fileprivate let containerView = UIView(frame: CGRect.zero)
    fileprivate let messageView : UIView
    
    fileprivate var wasActive : Bool = false
    
    fileprivate let active : (Void) -> Bool
    
    public init(messageView: UIView, active : @escaping (Void) -> Bool) {
        self.active = active
        self.messageView = messageView
        
        super.init()
        containerView.addSubview(messageView)
        containerView.setNeedsUpdateConstraints()
        containerView.clipsToBounds = true
        
        update()
    }
    
    open var affectsScrollIndicators : Bool {
        return true
    }
    
    final public var currentInsets : UIEdgeInsets {
        let height = active() ? messageView.bounds.size.height : 0
        return UIEdgeInsets(top: height, left: 0, bottom: 0, right: 0)
    }
    
    final public func setupInController(_ controller : UIViewController) {
        controller.view.addSubview(containerView)
        containerView.snp.makeConstraints {make in
            make.leading.equalTo(controller.view)
            make.trailing.equalTo(controller.view)
            // TODO: snp verify
           /* if #available(iOS 9, *) {
                make.top.equalTo(controller.topLayoutGuide.bottomAnchor)
            }
            else {
                make.top.equalTo(controller.snp_topLayoutGuideBottom)
            }*/
            make.top.equalTo(controller.topLayoutGuide.snp.bottom)
            make.height.equalTo(messageView)
        }
    }
    
    final fileprivate func update() {
        messageView.snp.remakeConstraints { make in
            make.leading.equalTo(containerView)
            make.trailing.equalTo(containerView)
            
            if active() {
                containerView.isUserInteractionEnabled = true
                make.top.equalTo(containerView.snp.top)
            }
            else {
                containerView.isUserInteractionEnabled = false
                make.bottom.equalTo(containerView.snp.top)
            }
        }
        messageView.setNeedsLayout()
        messageView.layoutIfNeeded()
        
        if(!wasActive && active()) {
            containerView.superview?.bringSubview(toFront: containerView)
        }
        wasActive = active()
        
        self.insetsDelegate?.contentInsetsSourceChanged(self)
    }
    
    
    final func updateAnimated() {
        UIView.animate(withDuration: 0.4, delay: 0.0,
            usingSpringWithDamping: 1, initialSpringVelocity: 0.1,
            options: UIViewAnimationOptions(),
            animations: {
                self.update()
            }, completion:nil)
        
    }
}


extension ViewTopMessageController {
    public var t_messageHidden : Bool {
        return messageView.frame.maxY <= 0
    }
}
