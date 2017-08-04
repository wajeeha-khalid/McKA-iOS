//
//  UIViewController+Overlay.swift
//  edX
//
//  Created by Akiva Leffert on 12/23/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation
import SnapKit

private var StatusMessageHideActionKey = "StatusMessageHideActionKey"
private var SnackBarHideActionKey = "SnackBarHideActionKey"

private typealias StatusMessageRemovalInfo = (action : () -> Void, container : UIView)
private typealias TemporaryViewRemovalInfo = (action : () -> Void, container : UIView)

private class StatusMessageView : UIView {
    
    fileprivate let messageLabel = UILabel()
    fileprivate let margin = 20
    
    init(message: String) {
        super.init(frame: CGRect.zero)

        messageLabel.numberOfLines = 0
        addSubview(messageLabel)
        
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        //always fill the view
        blurEffectView.frame = self.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.insertSubview(blurEffectView, belowSubview: messageLabel)
        
        self.backgroundColor = UIColor.clear
        messageLabel.attributedText = statusMessageStyle.attributedString(withText: message)
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(self).offset(margin)
            make.leading.equalTo(self).offset(margin)
            make.trailing.equalTo(self).offset(-margin)
            make.bottom.equalTo(self).offset(-margin)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate var statusMessageStyle: OEXMutableTextStyle {
        let style = OEXMutableTextStyle(weight: .normal, size: .base, color: UIColor.white)
        style.alignment = .center;
        style.lineBreakMode = NSLineBreakMode.byWordWrapping;
        return style;
        
    }
}

private let visibleDuration: TimeInterval = 5.0
private let animationDuration: TimeInterval = 1.0

extension UIViewController {
    
    func showOverlayMessageView(_ messageView : UIView) {
        let container = PassthroughView()
        container.clipsToBounds = true
        view.addSubview(container)
        container.addSubview(messageView)
        
        container.snp.makeConstraints {make in
            make.top.equalTo(topLayoutGuide.snp.top)
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
        }
        messageView.snp.makeConstraints {make in
            make.edges.equalTo(container)
        }
        
        let size = messageView.systemLayoutSizeFitting(CGSize(width: view.bounds.width, height: CGFloat.greatestFiniteMagnitude))
        messageView.transform = CGAffineTransform(translationX: 0, y: -size.height)
        container.layoutIfNeeded()
        
        let hideAction = {[weak self] in
            let hideInfo = objc_getAssociatedObject(self, &StatusMessageHideActionKey) as? Box<StatusMessageRemovalInfo>
            if hideInfo?.value.container == container {
                objc_setAssociatedObject(self, &StatusMessageHideActionKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            
            UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.1, options: .curveEaseOut, animations: {
                messageView.transform = CGAffineTransform(translationX: 0, y: -size.height)
                }, completion: { _ in
                    container.removeFromSuperview()
            })
        }
        
        // show
        UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.1, options: .curveEaseIn, animations: { () -> Void in
            messageView.transform = CGAffineTransform.identity
            }, completion: {_ in
                let delay = DispatchTime.now() + Double(Int64(visibleDuration * TimeInterval(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: delay) {
                    hideAction()
                }
        })
        
        let info : StatusMessageRemovalInfo = (action: hideAction, container: container)
        objc_setAssociatedObject(self, &StatusMessageHideActionKey, Box(info), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func showOverlayMessage(_ string : String) {
        let hideInfo = objc_getAssociatedObject(self, &StatusMessageHideActionKey) as? Box<StatusMessageRemovalInfo>
        hideInfo?.value.action()
        let view = StatusMessageView(message: string)
        showOverlayMessageView(view)
    }
    
    func showSnackBarView(_ snackBarView : UIView) {
        let container = PassthroughView()
        container.clipsToBounds = true
        view.addSubview(container)
        container.addSubview(snackBarView)
        
        
        
        container.snp.makeConstraints {make in
            make.bottom.equalTo(bottomLayoutGuide.snp.bottom)
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
        }
        snackBarView.snp.makeConstraints {make in
            make.edges.equalTo(container)
        }
        
        let hideAction = {[weak self] in
            let hideInfo = objc_getAssociatedObject(self, &SnackBarHideActionKey) as? Box<TemporaryViewRemovalInfo>
            if hideInfo?.value.container == container {
                objc_setAssociatedObject(self, &SnackBarHideActionKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            
            UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.1, options: .curveEaseOut, animations: {
                snackBarView.transform = CGAffineTransform.identity
                }, completion: { _ in
                    container.removeFromSuperview()
            })
        }
        
        // show
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.1, options: .curveEaseIn, animations: { () -> Void in
            snackBarView.transform = CGAffineTransform.identity
            }, completion: nil)
        
        let info : TemporaryViewRemovalInfo = (action: hideAction, container: container)
        objc_setAssociatedObject(self, &SnackBarHideActionKey, Box(info), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func showVersionUpgradeSnackBar(_ string: String) {
        let hideInfo = objc_getAssociatedObject(self, &SnackBarHideActionKey) as? Box<TemporaryViewRemovalInfo>
        hideInfo?.value.action()
        let view = VersionUpgradeView(message: string)
        showSnackBarView(view)
    }
    
    
    func showOfflineSnackBar(_ message: String, selector: Selector?) {
        let hideInfo = objc_getAssociatedObject(self, &SnackBarHideActionKey) as? Box<TemporaryViewRemovalInfo>
        hideInfo?.value.action()
        let view = OfflineView(message: message, selector: selector)
        showSnackBarView(view)
    }
    
    func hideSnackBar() {
        let hideInfo = objc_getAssociatedObject(self, &SnackBarHideActionKey) as? Box<TemporaryViewRemovalInfo>
        hideInfo?.value.action()
    }
}


// For use in testing only
extension UIViewController {
    
    var t_isShowingOverlayMessage : Bool {
        return objc_getAssociatedObject(self, &StatusMessageHideActionKey) as? Box<StatusMessageRemovalInfo> != nil
    }
    
    var t_isShowingSnackBar : Bool {
        return objc_getAssociatedObject(self, &SnackBarHideActionKey) as? Box<TemporaryViewRemovalInfo> != nil
    }
    
}
