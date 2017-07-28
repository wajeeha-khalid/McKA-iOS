//
//  ProfileBanner.swift
//  edX
//
//  Created by Michael Katz on 9/28/15.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit

/** Helper Class to display a Profile image and username in a row. Optional change [📷] button. */
class ProfileBanner: UIView {

    enum Style {
        case lightContent
        case darkContent

        var textColor: UIColor {
            switch(self) {
            case .lightContent:
                return OEXStyles.shared().neutralWhiteT()
            case .darkContent:
                return OEXStyles.shared().neutralBlackT()
            }
        }
    }
    
    let shortProfView: ProfileImageView = ProfileImageView()
    let usernameLabel: UILabel = UILabel()
    let editable: Bool
    let changeCallback: (()->())?
    let changeButton = IconButton()

    var style = Style.lightContent {
        didSet {
            usernameLabel.attributedText = usernameStyle.attributedString(withText: usernameLabel.attributedText?.string)
        }
    }
  
    fileprivate func setupViews() {
        addSubview(shortProfView)
        addSubview(usernameLabel)
        
        usernameLabel.setContentHuggingPriority(1, for: .horizontal)
        
        shortProfView.snp.makeConstraints { (make) -> Void in
            make.leading.equalTo(self.snp.leadingMargin)
            make.height.equalTo(40)
            make.width.equalTo(shortProfView.snp.height)
            make.centerY.equalTo(self)
        }
        
        usernameLabel.snp.makeConstraints { (make) -> Void in
            make.leading.equalTo(shortProfView.snp.trailing).offset(6)
            make.centerY.equalTo(shortProfView)
        }
        
        if editable {
            isUserInteractionEnabled = true
            addSubview(changeButton)

            changeButton.setIconAndTitle(Icon.camera, title: Strings.Profile.changePictureButton)
            changeButton.accessibilityHint = Strings.Profile.changePictureAccessibilityHint
            
            changeButton.snp.makeConstraints({ (make) -> Void in
                make.centerY.equalTo(shortProfView)
                make.trailing.equalTo(self.snp.trailingMargin).priority(.high)
                make.leading.equalTo(usernameLabel).priority(.low)
            })
            
            changeButton.oex_addAction({ [weak self] _ in
                self?.changeCallback?()
            }, for: .touchUpInside)
        }
      

    }
    
    init(editable: Bool, didChange: @escaping (()->())) {
        self.editable = editable
        changeCallback = didChange
        super.init(frame: CGRect.zero)
        setupViews()
    }
    
    override init(frame: CGRect) {
        editable = false
        changeCallback = nil
        
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showProfile(_ profile: UserProfile, networkManager: NetworkManager) {
        shortProfView.remoteImage = profile.image(networkManager)
        usernameLabel.attributedText = usernameStyle.attributedString(withText: profile.username)
    }

    var usernameStyle : OEXTextStyle {
        return OEXTextStyle(weight : .normal, size: .large, color: style.textColor)
    }
}
