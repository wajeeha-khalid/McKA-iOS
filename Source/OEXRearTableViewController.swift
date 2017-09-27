//
//  OEXRearTableController.swift
//  edX
//
//  Created by Michael Katz on 9/21/15.
//  Copyright (c) 2015 edX. All rights reserved.
//


import Foundation
import MessageUI

import edXCore

private enum OEXRearViewOptions: Int {
    case userProfile, myCourse, appSettings, mySettings, licensingTerms, submitFeedback, logout
}

private let LogoutCellDefaultHeight: CGFloat = 160.0
private let versionButtonStyle = OEXTextStyle(weight:.normal, size:.xxSmall, color: OEXStyles.shared.neutralWhite())

class OEXRearTableViewController : UITableViewController {

    // TODO replace this with a proper injection when we nuke the storyboard
    struct Environment {
        let analytics = OEXRouter.shared().environment.analytics
        let config = OEXRouter.shared().environment.config
        let interface = OEXRouter.shared().environment.interface
        let networkManager = OEXRouter.shared().environment.networkManager
        let session = OEXRouter.shared().environment.session
        let userProfileManager = OEXRouter.shared().environment.dataManager.userProfileManager
        weak var router = OEXRouter.shared()
    }
    
    @IBOutlet weak var profileCell: UITableViewCell!
    @IBOutlet var coursesLabel: UILabel!
//    @IBOutlet var videosLabel: UILabel!
    //@IBOutlet var recentMediaLabel: UILabel!
    @IBOutlet var appSettingsLabel: UILabel!
    @IBOutlet var settingsLabel: UILabel!
    @IBOutlet var submitFeedbackLabel: UILabel!
    @IBOutlet var logoutButton: UIButton!
    
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var userEmailLabel: UILabel!
    @IBOutlet var licensingTermsLabel: UILabel!
    
    @IBOutlet var userProfilePicture: UIImageView!
    @IBOutlet weak var appVersionButton: UIButton!
    
    lazy var environment = Environment()
    var profileFeed: Feed<UserProfile>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupProfileLoader()
        updateUIWithUserInfo()
       
        let environmentName = "McKA"//self.environment.config.environmentName()
        let appVersion = "0.8"//Bundle.main.oex_buildVersionString()
        appVersionButton.setAttributedTitle(versionButtonStyle.attributedString(withText: Strings.versionDisplay(number: appVersion, environment: environmentName)), for:.normal)
        appVersionButton.accessibilityTraits = UIAccessibilityTraitStaticText
        
        //UI
        //logoutButton.setBackgroundImage(UIImage(named: "bt_logout_active"), for: .highlighted)
        
        //Listen to notification
        NotificationCenter.default.addObserver(self, selector: #selector(OEXRearTableViewController.dataAvailable(_:)), name: NSNotification.Name(rawValue: NOTIFICATION_URL_RESPONSE), object: nil)
        
        coursesLabel.text = Strings.myCourses
//        videosLabel.text = Strings.myMedia
        //recentMediaLabel.text = Strings.recentMedia
        appSettingsLabel.text = Strings.appSettings
        settingsLabel.text = Strings.mySettings
        submitFeedbackLabel.text = Strings.SubmitFeedback.optionTitle
        licensingTermsLabel.text = Strings.licensingTerms
        logoutButton.setTitle(Strings.logout.oex_uppercaseStringInCurrentLocale(), for: .normal)
        setFonts()
        setNaturalTextAlignment()
        setAccessibilityLabels()
        let backgrounView = UIView()
        let topView = UIView()
        let bottomView = UIView()
        topView.backgroundColor = BrandingThemes.shared.getNavigationBarColor()
        bottomView.backgroundColor = UIColor(colorLiteralRed: 40/255.0, green: 43/255.0, blue: 47/255.0, alpha: 1.0)
        backgrounView.addSubview(topView)
        backgrounView.addSubview(bottomView)
        topView.snp.makeConstraints { make in
            make.width.equalTo(backgrounView)
            make.top.equalTo(backgrounView)
            make.leading.equalTo(backgrounView)
            make.height.equalTo(backgrounView.snp.height).dividedBy(2)
        }
        bottomView.snp.makeConstraints { make in
            make.width.equalTo(backgrounView)
            make.leading.equalTo(backgrounView)
            make.top.equalTo(topView.snp.bottom)
            make.height.equalTo(topView)
        }
        tableView.backgroundView = backgrounView
        profileCell.contentView.backgroundColor = UIColor.clear//BrandingThemes.shared.getNavigationBarColor()
        //  tableView.backgroundColor = BrandingThemes.shared.getNavigationBarColor()
        logoutButton.backgroundColor = BrandingThemes.shared.getNavigationBarColor()
        
//        if !environment.config.profilesEnabled {
//            //hide the profile image while not display the feature
//            //there is still a little extra padding, but this will just be a temporary issue anyway
//            userProfilePicture.hidden = true
//            let widthConstraint = userProfilePicture.constraints.filter { $0.identifier == "profileWidth" }[0]
//            let heightConstraint = userProfilePicture.constraints.filter { $0.identifier == "profileHeight" }[0]
//            widthConstraint.constant = 0
//            heightConstraint.constant = 85
//        }

    }
    
    fileprivate func setupProfileLoader() {
        guard environment.config.profilesEnabled else { return }
        profileFeed = self.environment.userProfileManager.feedForCurrentUser()
        profileFeed?.output.listen(self,  success: { profile in
            //self.userProfilePicture.remoteImage = profile.image(self.environment.networkManager)
            }, failure : { _ in
                Logger.logError("Profiles", "Unable to fetch profile")
        })
    }
    
    fileprivate func updateUIWithUserInfo() {
        if let currentUser = environment.session.currentUser {
            userNameLabel.text = currentUser.name
            userEmailLabel.text = currentUser.email
            profileFeed?.refresh()
        }
    }
    
    fileprivate func setNaturalTextAlignment() {
        coursesLabel.textAlignment = .natural
//        videosLabel.textAlignment = .natural
        //recentMediaLabel.textAlignment = .Natural
        appSettingsLabel.textAlignment = .natural
        settingsLabel.textAlignment = .natural
        submitFeedbackLabel.textAlignment = .natural
        userNameLabel.textAlignment = .natural
        licensingTermsLabel.textAlignment = .natural
        userNameLabel.adjustsFontSizeToFitWidth = true
        userEmailLabel.textAlignment = .natural
    }
    
    fileprivate func setAccessibilityLabels() {
        userNameLabel.accessibilityLabel = userNameLabel.text
        userEmailLabel.accessibilityLabel = userEmailLabel.text
        coursesLabel.accessibilityLabel = coursesLabel.text
//        videosLabel.accessibilityLabel = videosLabel.text
        //recentMediaLabel.accessibilityLabel = recentMediaLabel.text
        appSettingsLabel.accessibilityLabel = appSettingsLabel.text
        settingsLabel.accessibilityLabel = settingsLabel.text
        submitFeedbackLabel.accessibilityLabel = submitFeedbackLabel.text
        licensingTermsLabel.accessibilityLabel = licensingTermsLabel.text
        logoutButton.accessibilityLabel = logoutButton.titleLabel!.text
        userProfilePicture.accessibilityLabel = Strings.accessibilityUserAvatar
    }
    
    fileprivate func setFonts(){
        let RearTableFont = UIFont.init(name: "Raleway-Medium", size: 16)
        
        coursesLabel.font = RearTableFont
//        videosLabel.font = RearTableFont
        //recentMediaLabel.font = UIFont.init(name: "Raleway-Medium", size: 16)
        appSettingsLabel.font = RearTableFont
        settingsLabel.font = RearTableFont
        submitFeedbackLabel.font = RearTableFont
        licensingTermsLabel.font = RearTableFont
        userNameLabel.font = UIFont.init(name: "Raleway-Medium", size: 22)
        userEmailLabel.font = UIFont.init(name: "Raleway-Medium", size: 14)
        logoutButton.titleLabel?.font = UIFont.init(name: "Raleway-Bold", size: 18)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return OEXStyles.shared.standardStatusBarStyle()
    }
    
    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let cell = self.tableView(tableView, cellForRowAt: indexPath)
        cell.selectionStyle = UITableViewCellSelectionStyle.gray
        if let separatorImage = cell.contentView.viewWithTag(10) {
            separatorImage.isHidden = true
        }
    }
    
    override func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        let cell = self.tableView(tableView, cellForRowAt: indexPath)
        if let separatorImage = cell.contentView.viewWithTag(10) {
            let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                separatorImage.isHidden = false
            }
        }
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let option = OEXRearViewOptions(rawValue: indexPath.row) {
            switch option {
            case .userProfile:
                guard environment.config.profilesEnabled else { break }
                guard let currentUserName = environment.session.currentUser?.username else { return }
                environment.router?.showProfileForUsername(username: currentUserName)
            case .myCourse:
                environment.router?.showMyCourses()
//            case .myMedia:
//                environment.router?.showMyVideos()
            //case .RecentMedia:
              //  environment.router?.showMyVideos()
            case .appSettings:
                environment.router?.showMySettings()
            case .mySettings:
                environment.router?.showAccountSettings()
            case .licensingTerms:
                environment.router?.showLicensingTerms()
            case .submitFeedback:
                launchEmailComposer()
            case .logout:
                break
            }
        }
       tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        if indexPath.row == OEXRearViewOptions.Debug.rawValue && !environment.config.shouldShowDebug() {
//            return 0
//        }
//        else if indexPath.row == OEXRearViewOptions.FindCourses.rawValue && !environment.config.courseEnrollmentConfig.isCourseDiscoveryEnabled() {
//            return 0
//        }
       if indexPath.row == OEXRearViewOptions.logout.rawValue {
            let screenHeight = UIScreen.main.bounds.height
            let tableviewHeight = tableView.contentSize.height
            return max((screenHeight - tableviewHeight) + LogoutCellDefaultHeight, LogoutCellDefaultHeight)
        }
        
        
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    @IBAction func logoutClicked(_ sender: UIButton) {
        OEXFileUtility.nukeUserPIIData()
        self.environment.router?.logout()
    }
    
    func dataAvailable(_ notification: Notification) {
        let successString = notification.userInfo![NOTIFICATION_KEY_STATUS] as? String;
        let URLString = notification.userInfo![NOTIFICATION_KEY_URL] as? String;
        
        if successString == NOTIFICATION_VALUE_URL_STATUS_SUCCESS && URLString == environment.interface?.urlString(forType: URL_USER_DETAILS) {
            updateUIWithUserInfo()
        }
    }
}

extension OEXRearTableViewController : MFMailComposeViewControllerDelegate {

    static func supportEmailMessageTemplate() -> String {
        let osVersionText = Strings.SubmitFeedback.osVersion(version: UIDevice.current.systemVersion)
        let appVersionText = Strings.SubmitFeedback.appVersion(version: Bundle.main.oex_shortVersionString(), build: Bundle.main.oex_buildVersionString())
        let deviceModelText = Strings.SubmitFeedback.deviceModel(model: UIDevice.current.model)
        let body = ["\n", Strings.SubmitFeedback.marker, osVersionText, appVersionText, deviceModelText].joined(separator: "\n")
        return body
    }

    func launchEmailComposer() {
        if !MFMailComposeViewController.canSendMail() {
            let alert = UIAlertView(title: Strings.emailAccountNotSetUpTitle,
                message: Strings.emailAccountNotSetUpMessage,
                delegate: nil,
                cancelButtonTitle: Strings.ok)
            alert.show()
        } else {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setSubject(Strings.SubmitFeedback.messageSubject)

            mail.setMessageBody(OEXRearTableViewController.supportEmailMessageTemplate(), isHTML: false)
            if let fbAddress = environment.config.feedbackEmailAddress() {
                mail.setToRecipients([fbAddress])
            }
            present(mail, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true, completion: nil)
    }
}
