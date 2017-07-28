//
//  UserProfileView.swift
//  edX
//
//  Created by Akiva Leffert on 4/4/16.
//  Copyright © 2016 edX. All rights reserved.
//
import SnapKit

class UserProfileView : UIView, UIScrollViewDelegate {

    fileprivate let margin = 4

    fileprivate class SystemLabel: UILabel {
        fileprivate override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
            return super.textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines).insetBy(dx: 10, dy: 0)
        }
        fileprivate override func drawText(in rect: CGRect) {
            let newRect = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            super.drawText(in: UIEdgeInsetsInsetRect(rect, newRect))
        }
    }

    fileprivate let scrollView = UIScrollView()
    fileprivate let usernameLabel = UILabel()
    fileprivate let messageLabel = UILabel()
    fileprivate let countryLabel = UILabel()
    fileprivate let languageLabel = UILabel()
    fileprivate let bioText = UITextView()
    fileprivate let tabs = TabContainerView()
    fileprivate let bioSystemMessage = SystemLabel()
    fileprivate let avatarImage = ProfileImageView()
    fileprivate let header = ProfileBanner()
    fileprivate let bottomBackground = UIView()
    fileprivate var tabTopConstraintLimited : Constraint? = nil
    fileprivate var tabTopConstraintFull : Constraint? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(scrollView)

        setupViews()
        setupConstraints()
    }

    fileprivate func setupViews() {
        scrollView.backgroundColor = UIColor(hexString: "02E0A6", alpha: 1.0)
        scrollView.delegate = self

        avatarImage.borderWidth = 3.0
        scrollView.addSubview(avatarImage)

        usernameLabel.setContentHuggingPriority(1000, for: .vertical)
        scrollView.addSubview(usernameLabel)

        messageLabel.isHidden = true
        messageLabel.numberOfLines = 0
        messageLabel.setContentHuggingPriority(1000, for: .vertical)
        scrollView.addSubview(messageLabel)

        languageLabel.accessibilityHint = Strings.Profile.languageAccessibilityHint
        languageLabel.setContentHuggingPriority(1000, for: .vertical)
        scrollView.addSubview(languageLabel)

        countryLabel.accessibilityHint = Strings.Profile.countryAccessibilityHint
        countryLabel.setContentHuggingPriority(1000, for: .vertical)
        scrollView.addSubview(countryLabel)

        bioText.backgroundColor = UIColor.clear
        bioText.textAlignment = .natural
        bioText.isScrollEnabled = false
        bioText.isEditable = false
        bioText.textContainer.lineFragmentPadding = 0;
        bioText.textContainerInset = UIEdgeInsets.zero

        tabs.layoutMargins = UIEdgeInsets(top: StandardHorizontalMargin, left: StandardHorizontalMargin, bottom: StandardHorizontalMargin, right: StandardHorizontalMargin)

        tabs.items = [bioTab]
        scrollView.addSubview(tabs)

        bottomBackground.backgroundColor = bioText.backgroundColor
        scrollView.insertSubview(bottomBackground, belowSubview: tabs)

        bioSystemMessage.isHidden = true
        bioSystemMessage.numberOfLines = 0
        bioSystemMessage.backgroundColor = OEXStyles.shared().primaryXLightColor()
        scrollView.insertSubview(bioSystemMessage, aboveSubview: tabs)

        header.style = .lightContent
        header.backgroundColor = scrollView.backgroundColor
        header.isHidden = true
        self.addSubview(header)

        bottomBackground.backgroundColor = OEXStyles.shared().standardBackgroundColor()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func setupConstraints() {
        scrollView.snp.makeConstraints { (make) -> Void in
            make.edges.equalTo(self)
        }
        avatarImage.snp.makeConstraints { (make) -> Void in
            make.width.equalTo(avatarImage.snp.height)
            make.width.equalTo(166)
            make.centerX.equalTo(scrollView)
            make.top.equalTo(scrollView.snp.topMargin).offset(20)
        }

        usernameLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(avatarImage.snp.bottom).offset(margin)
            make.centerX.equalTo(scrollView)
        }

        messageLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(usernameLabel.snp.bottom).offset(margin).priority(.high)
            make.centerX.equalTo(scrollView)
        }

        languageLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(messageLabel.snp.bottom)
            make.centerX.equalTo(scrollView)
        }

        countryLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(languageLabel.snp.bottom)
            make.centerX.equalTo(scrollView)
        }

        tabs.snp.makeConstraints { (make) -> Void in
           
            make.bottom.equalTo(scrollView)
            make.leading.equalTo(scrollView)
            make.trailing.equalTo(scrollView)
            make.width.equalTo(scrollView)
        }

        bioSystemMessage.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(tabs)
            make.bottom.greaterThanOrEqualTo(self)
            make.leading.equalTo(scrollView)
            make.trailing.equalTo(scrollView)
            make.width.equalTo(scrollView)
        }

        bottomBackground.snp.makeConstraints {make in
            make.edges.equalTo(bioSystemMessage)
        }

        header.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(scrollView)
            make.leading.equalTo(scrollView)
            make.trailing.equalTo(scrollView)
            make.height.equalTo(56)
        }
    }

    fileprivate func setMessage(_ message: String?) {
        if let message = message {
            let messageStyle = OEXTextStyle(weight: .semiBold, size: .large, color: OEXStyles.shared().primaryXLightColor())

            messageLabel.isHidden = false
            messageLabel.snp.remakeConstraints { (make) -> Void in
                make.top.equalTo(usernameLabel.snp.bottom).offset(margin).priority(.high)
                make.centerX.equalTo(scrollView)
            }
            countryLabel.isHidden = true
            languageLabel.isHidden = true

            messageLabel.attributedText = messageStyle.attributedString(withText: message)
        } else {
            messageLabel.isHidden = true
            messageLabel.snp.updateConstraints({ (make) -> Void in
                make.height.equalTo(0)
            })

            countryLabel.isHidden = false
            languageLabel.isHidden = false

        }
    }

    fileprivate func messageForProfile(_ profile : UserProfile, editable : Bool) -> String? {
        if profile.sharingLimitedProfile {
            return editable ? Strings.Profile.showingLimited : Strings.Profile.learnerHasLimitedProfile(platformName: OEXConfig.shared().platformName())
        }
        else {
            return nil
        }
    }

    fileprivate var bioTab : TabItem {
        return TabItem(name: "About", view: bioText, identifier: "bio")
    }

    func populateFields(_ profile: UserProfile, editable : Bool, networkManager : NetworkManager) {
        let usernameStyle = OEXTextStyle(weight : .bold, size: .xxLarge, color: OEXStyles.shared().neutralWhiteT())
        let infoStyle = OEXTextStyle(weight: .semiBold, size: .large, color: OEXStyles.shared().primaryXLightColor())
        let bioStyle = OEXStyles.shared().textAreaBodyStyle
        let messageStyle = OEXMutableTextStyle(weight: .bold, size: .large, color: OEXStyles.shared().neutralDark())
        messageStyle.alignment = .center


        usernameLabel.attributedText = usernameStyle.attributedString(withText: profile.username)
        bioSystemMessage.isHidden = true

        avatarImage.remoteImage = profile.image(networkManager)

        setMessage(messageForProfile(profile, editable: editable))

        if profile.sharingLimitedProfile {
            
            self.tabs.snp.remakeConstraints({ (make) in
                make.top.equalTo(self.messageLabel.snp.bottom).offset(35).priority(.high)
                make.bottom.equalTo(scrollView)
                make.leading.equalTo(scrollView)
                make.trailing.equalTo(scrollView)
                make.width.equalTo(scrollView)
            })
            
            if (profile.parentalConsent ?? false) && editable {
                let message = NSMutableAttributedString(attributedString: messageStyle.attributedString(withText: Strings.Profile.ageLimit))

                bioSystemMessage.attributedText = message
                bioSystemMessage.isHidden = false
            }
        } else {
            
            self.tabs.snp.remakeConstraints({ (make) in
                make.top.equalTo(self.countryLabel.snp.bottom).offset(35).priority(.high)
                make.bottom.equalTo(scrollView)
                make.leading.equalTo(scrollView)
                make.trailing.equalTo(scrollView)
                make.width.equalTo(scrollView)
            })
            self.bioText.text = ""
            if let language = profile.language {
                let icon = Icon.comment.attributedTextWithStyle(infoStyle)
                let langText = infoStyle.attributedString(withText: language)
                languageLabel.attributedText = NSAttributedString.joinInNaturalLayout([icon, langText])
            }
            if let country = profile.country {
                let icon = Icon.country.attributedTextWithStyle(infoStyle)
                let countryText = infoStyle.attributedString(withText: country)
                countryLabel.attributedText = NSAttributedString.joinInNaturalLayout([icon, countryText])
            }
            if let bio = profile.bio {
                bioText.attributedText = bioStyle.attributedString(withText: bio)
            } else {
                let message = messageStyle.attributedString(withText: Strings.Profile.noBio)
                bioSystemMessage.attributedText = message
                bioSystemMessage.isHidden = false
            }
        }
        
        header.showProfile(profile, networkManager: networkManager)
    }

    var extraTabs : [ProfileTabItem] = [] {
        didSet {
            let instantiatedTabs = extraTabs.map {tab in tab(scrollView) }
            tabs.items = [bioTab] + instantiatedTabs
        }
    }
    
    @objc func scrollViewDidScroll(_ scrollView: UIScrollView) {
        UIView.animate(withDuration: 0.25, animations: {
            self.header.isHidden = scrollView.contentOffset.y < self.avatarImage.frame.maxY
        }) 
    }

    func chooseTab(_ identifier: String) {
        tabs.showTabWithIdentifier(identifier)
    }
}
