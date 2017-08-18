//
//  SnackbarViews.swift
//  edX
//
//  Created by Saeed Bashir on 7/15/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
private let animationDuration: TimeInterval = 1.0

open class VersionUpgradeView: UIView {
    fileprivate let messageLabel = UILabel()
    fileprivate let upgradeButton = UIButton(type: .system)
    fileprivate let dismissButton = UIButton(type: .system)
    fileprivate var messageLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared.neutralDark())
    }
    
    fileprivate var buttonLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .semiBold, size: .base, color: OEXStyles.shared.neutralDark())
    }
    
    init(message: String) {
        super.init(frame: CGRect.zero)
        self.backgroundColor = OEXStyles.shared.warningBase()
        messageLabel.numberOfLines = 0
        messageLabel.attributedText = messageLabelStyle.attributedString(withText: message)
        upgradeButton.setAttributedTitle(buttonLabelStyle.attributedString(withText: Strings.VersionUpgrade.update), for: [])
        dismissButton.setAttributedTitle(buttonLabelStyle.attributedString(withText: Strings.VersionUpgrade.dismiss), for: [])
        
        addSubview(messageLabel)
        addSubview(dismissButton)
        addSubview(upgradeButton)
        
        addConstraints()
        addButtonActions()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func addConstraints() {
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(self).offset(StandardVerticalMargin)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.trailing.equalTo(self).offset(-StandardHorizontalMargin)
        }
        
        upgradeButton.snp.makeConstraints { (make) in
            make.top.equalTo(messageLabel.snp.bottom)
            make.trailing.equalTo(self).offset(-StandardHorizontalMargin)
            make.bottom.equalTo(self).offset(-StandardVerticalMargin)
        }
        
        dismissButton.snp.makeConstraints { (make) in
            make.top.equalTo(messageLabel.snp.bottom)
            make.trailing.equalTo(upgradeButton.snp.leading).offset(-StandardHorizontalMargin)
            make.bottom.equalTo(self).offset(-StandardVerticalMargin)
        }
    }
    
    fileprivate func addButtonActions() {
        dismissButton.oex_addAction({[weak self] _ in
            self?.dismissView()
            }, for: .touchUpInside)
        
        upgradeButton.oex_addAction({[weak self]  _ in
            if let URL = OEXConfig.shared().appUpgradeConfig.iOSAppStoreURL() {
                if UIApplication.shared.canOpenURL(URL as URL) {
                    self?.dismissView()
                    UIApplication.shared.openURL(URL as URL)
                    isActionTakenOnUpgradeSnackBar = true
                }
            }
            }, for: .touchUpInside)
    }
    
    fileprivate func dismissView() {
        var container = superview
        if container == nil {
            container = self
        }
        
        UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.1, options: .curveEaseOut, animations: {
            self.transform = CGAffineTransform.identity
            }, completion: { _ in
                container?.removeFromSuperview()
                isActionTakenOnUpgradeSnackBar = true
        })
    }
}

open class OfflineView: UIView {
    fileprivate let messageLabel = UILabel()
    fileprivate let reloadButton = UIButton(type: .system)
    fileprivate let dismissButton = UIButton(type: .system)
    fileprivate var selector: Selector?
    fileprivate var messageLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared.neutralDark())
    }
    
    fileprivate var buttonLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .semiBold, size: .base, color: OEXStyles.shared.neutralDark())
    }
    
    init(message: String, selector: Selector?) {
        super.init(frame: CGRect.zero)
        self.selector = selector
        self.backgroundColor = OEXStyles.shared.warningBase()
        messageLabel.numberOfLines = 0
        messageLabel.attributedText = messageLabelStyle.attributedString(withText: message)
        reloadButton.setAttributedTitle(buttonLabelStyle.attributedString(withText: Strings.reload), for: [])
        dismissButton.setAttributedTitle(buttonLabelStyle.attributedString(withText: Strings.VersionUpgrade.dismiss), for: [])
        addSubview(messageLabel)
        addSubview(dismissButton)
        addSubview(reloadButton)
        
        addConstraints()
        addButtonActions()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    fileprivate func addConstraints() {
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(self).offset(StandardVerticalMargin)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.trailing.lessThanOrEqualTo(dismissButton).offset(-StandardHorizontalMargin)
            make.centerY.equalTo(reloadButton)
        }
        
        reloadButton.snp.makeConstraints { (make) in
            make.top.equalTo(messageLabel)
            make.trailing.equalTo(self).offset(-StandardHorizontalMargin)
            make.bottom.equalTo(self).offset(-StandardVerticalMargin)
        }
        
        dismissButton.snp.makeConstraints { (make) in
            make.top.equalTo(reloadButton)
            make.trailing.equalTo(reloadButton.snp.leading).offset(-StandardHorizontalMargin)
            make.bottom.equalTo(self).offset(-StandardVerticalMargin)
        }
    }
    
    fileprivate func addButtonActions() {
        dismissButton.oex_addAction({[weak self] _ in
            self?.dismissView()
            }, for: .touchUpInside)
        
        reloadButton.oex_addAction({[weak self] _ in
            let controller = self?.firstAvailableUIViewController()
            if let controller = controller, let selector = self?.selector {
                if controller.responds(to: selector) && OEXRouter.shared().environment.reachability.isReachable() {
                    controller.perform(selector)
                    self?.dismissView()
                }
            }
            else {
                self?.dismissView()
            }
            }, for: .touchUpInside)
    }
    
    fileprivate func dismissView() {
        var container = superview
        if container == nil {
            container = self
        }
        
        UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.1, options: .curveEaseOut, animations: {
            self.transform = CGAffineTransform.identity
            }, completion: { _ in
                container!.removeFromSuperview()
        })
    }
}
