//
//  RevealViewController.swift
//  edX
//
//  Created by Akiva Leffert on 9/30/15.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit


class RevealViewController: SWRevealViewController, SWRevealViewControllerDelegate {

    // Dims the front content when the side drawer is visible
    fileprivate var dimmingOverlay : UIButton!
    
    override init!(rearViewController: UIViewController!, frontViewController: UIViewController!) {
        super.init(rearViewController: rearViewController, frontViewController: frontViewController)
        self.rearViewRevealWidth = 300
        self.rightViewRevealWidth = self.rearViewRevealWidth
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.rearViewRevealWidth = UIScreen.main.bounds.width * 0.8
        self.rightViewRevealWidth = self.rearViewRevealWidth
    }
    
    func loadStoryboardControllers() {
        // Do nothing. Just want to remove parent behavior
    }
    
    override func loadView() {
        dimmingOverlay = UIButton()
        dimmingOverlay.isHidden = true
        dimmingOverlay.alpha = 0
        dimmingOverlay.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        dimmingOverlay.backgroundColor = OEXStyles.shared.neutralBlack()
        dimmingOverlay.isExclusiveTouch = true
        dimmingOverlay.accessibilityLabel = Strings.accessibilityCloseMenu
        dimmingOverlay.oex_addAction({[weak self] _ in
            self?.toggleDrawerAnimated(true)
            }, for: .touchUpInside)
        
        super.loadView()
    }
    
    fileprivate func postNavigationStateChanged(_ state : OEXSideNavigationState) {
        NotificationCenter.default.post(name: NSNotification.Name.OEXSideNavigationChangedState, object: self, userInfo : [
            OEXSideNavigationChangedStateKey: state.rawValue as NSNumber
            ])
    }
    
    fileprivate func sideNavigationStateForPosition(_ position : FrontViewPosition) -> OEXSideNavigationState? {
        if isRightToLeft {
            switch position {
            case .left:
                return .hidden
            case .leftSide:
                return .visible
            default: return nil
            }
        }
        else {
            switch position {
            case .left:
                return .hidden
            case .right:
                return .visible
            default: return nil
            }
        }
    }
    
    fileprivate func defaultVOFocus() {
        view.accessibilityElements = view.subviews
    }
    
    @objc fileprivate func defaultMenuVOFocus() {
        view.accessibilityElements = [dimmingOverlay, rearViewController.view.subviews]
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification,  dimmingOverlay)
    }
    
    func revealController(_ revealController: SWRevealViewController!, didMoveTo position: FrontViewPosition) {
        guard let state = self.sideNavigationStateForPosition(position) else {
            return
        }
        
        switch state {
        case .hidden:
            UIView.animate(withDuration: 0.2, animations:
                { _ in
                    self.dimmingOverlay.alpha = 0
                }, completion: {_ in
                    self.dimmingOverlay.isHidden = true
                    self.dimmingOverlay.removeFromSuperview()
                    self.defaultVOFocus()
                }
            )
        case .visible:
            dimmingOverlay.frame = frontViewController.view.bounds
            frontViewController.view.addSubview(dimmingOverlay)
            dimmingOverlay.isHidden = false
            UIView.animate(withDuration: 0.5, animations: { _ in
                self.dimmingOverlay.alpha = 0.5
            }) 
            defaultMenuVOFocus()
        }
        postNavigationStateChanged(state)
    }

    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        if let container = self.frontViewController as? UINavigationController,
            let topController = container.topViewController, topController is InterfaceOrientationOverriding
        {
            return topController.supportedInterfaceOrientations
        }
        return .portrait
    }

}

extension SWRevealViewController {
    
    func setDrawerViewController(_ controller : UIViewController, animated : Bool) {
        if isRightToLeft {
            setRight(controller, animated: animated)
        }
        else {
            setRear(controller, animated: animated)
        }
    }
    
    func toggleDrawerAnimated(_ animated: Bool) {
        if isRightToLeft {
            self.rightRevealToggle(animated: animated)
        }
        else {
            self.revealToggle(animated: animated)
        }
    }
    
    // Note that this is different from the global right to left setting.
    // Prior to iOS 9, the overall navigation was not flipped even though individual screens might be
    fileprivate var isRightToLeft : Bool {
        if #available(iOS 9.0, *) {
            if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
                return true
            }
        }
        return false
    }
    
    @objc var drawerViewController : UIViewController {
        if isRightToLeft {
            return self.rightViewController
        }
        else {
            return self.rearViewController
        }
    }
    
}
