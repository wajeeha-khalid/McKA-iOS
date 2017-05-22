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
    case UserProfile, MyCourse, MyMedia, AppSettings, MySettings, LicensingTerms, SubmitFeedback, Logout
}

private let LogoutCellDefaultHeight: CGFloat = 160.0
private let versionButtonStyle = OEXTextStyle(weight:.Normal, size:.XXSmall, color: OEXStyles.sharedStyles().neutralWhite())

class OEXRearTableViewController : UITableViewController {

    // TODO replace this with a proper injection when we nuke the storyboard
    struct Environment {
        let analytics = OEXRouter.sharedRouter().environment.analytics
        let config = OEXRouter.sharedRouter().environment.config
        let interface = OEXRouter.sharedRouter().environment.interface
        let networkManager = OEXRouter.sharedRouter().environment.networkManager
        let session = OEXRouter.sharedRouter().environment.session
        let userProfileManager = OEXRouter.sharedRouter().environment.dataManager.userProfileManager
        weak var router = OEXRouter.sharedRouter()
    }
    
    @IBOutlet var coursesLabel: UILabel!
    @IBOutlet var videosLabel: UILabel!
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
       
        let environmentName = self.environment.config.environmentName()
        let appVersion = NSBundle.mainBundle().oex_buildVersionString()
        appVersionButton.setAttributedTitle(versionButtonStyle.attributedStringWithText(Strings.versionDisplay(number: appVersion, environment: environmentName)), forState:.Normal)
        appVersionButton.accessibilityTraits = UIAccessibilityTraitStaticText
        
        //UI
        logoutButton.setBackgroundImage(UIImage(named: "bt_logout_active"), forState: .Highlighted)
        
        //Listen to notification
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(OEXRearTableViewController.dataAvailable(_:)), name: NOTIFICATION_URL_RESPONSE, object: nil)
        
        coursesLabel.text = Strings.myCourses
        videosLabel.text = Strings.myMedia
        //recentMediaLabel.text = Strings.recentMedia
        appSettingsLabel.text = Strings.appSettings
        settingsLabel.text = Strings.mySettings
        submitFeedbackLabel.text = Strings.SubmitFeedback.optionTitle
        licensingTermsLabel.text = Strings.licensingTerms
        logoutButton.setTitle(Strings.logout.oex_uppercaseStringInCurrentLocale(), forState: .Normal)
        setFonts()
        setNaturalTextAlignment()
        setAccessibilityLabels()
        
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
    
    private func setupProfileLoader() {
        guard environment.config.profilesEnabled else { return }
        profileFeed = self.environment.userProfileManager.feedForCurrentUser()
        profileFeed?.output.listen(self,  success: { profile in
            self.userProfilePicture.remoteImage = profile.image(self.environment.networkManager)
            }, failure : { _ in
                Logger.logError("Profiles", "Unable to fetch profile")
        })
    }
    
    private func updateUIWithUserInfo() {
        if let currentUser = environment.session.currentUser {
            userNameLabel.text = currentUser.name
            userEmailLabel.text = currentUser.email
            profileFeed?.refresh()
        }
    }
    
    private func setNaturalTextAlignment() {
        coursesLabel.textAlignment = .Natural
        videosLabel.textAlignment = .Natural
        //recentMediaLabel.textAlignment = .Natural
        appSettingsLabel.textAlignment = .Natural
        settingsLabel.textAlignment = .Natural
        submitFeedbackLabel.textAlignment = .Natural
        userNameLabel.textAlignment = .Natural
        licensingTermsLabel.textAlignment = .Natural
        userNameLabel.adjustsFontSizeToFitWidth = true
        userEmailLabel.textAlignment = .Natural
    }
    
    private func setAccessibilityLabels() {
        userNameLabel.accessibilityLabel = userNameLabel.text
        userEmailLabel.accessibilityLabel = userEmailLabel.text
        coursesLabel.accessibilityLabel = coursesLabel.text
        videosLabel.accessibilityLabel = videosLabel.text
        //recentMediaLabel.accessibilityLabel = recentMediaLabel.text
        appSettingsLabel.accessibilityLabel = appSettingsLabel.text
        settingsLabel.accessibilityLabel = settingsLabel.text
        submitFeedbackLabel.accessibilityLabel = submitFeedbackLabel.text
        licensingTermsLabel.accessibilityLabel = licensingTermsLabel.text
        logoutButton.accessibilityLabel = logoutButton.titleLabel!.text
        userProfilePicture.accessibilityLabel = Strings.accessibilityUserAvatar
    }
    
    private func setFonts(){
        let RearTableFont = UIFont.init(name: "Raleway-Medium", size: 16)
        
        coursesLabel.font = RearTableFont
        videosLabel.font = RearTableFont
        //recentMediaLabel.font = UIFont.init(name: "Raleway-Medium", size: 16)
        appSettingsLabel.font = RearTableFont
        settingsLabel.font = RearTableFont
        submitFeedbackLabel.font = RearTableFont
        licensingTermsLabel.font = RearTableFont
        userNameLabel.font = UIFont.init(name: "Raleway-Medium", size: 22)
        userEmailLabel.font = UIFont.init(name: "Raleway-Medium", size: 14)
        logoutButton.titleLabel?.font = UIFont.init(name: "Raleway-Bold", size: 18)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return OEXStyles.sharedStyles().standardStatusBarStyle()
    }
    
    override func tableView(tableView: UITableView, didHighlightRowAtIndexPath indexPath: NSIndexPath) {
        let cell = self.tableView(tableView, cellForRowAtIndexPath: indexPath)
        cell.selectionStyle = UITableViewCellSelectionStyle.Gray
        if let separatorImage = cell.contentView.viewWithTag(10) {
            separatorImage.hidden = true
        }
    }
    
    override func tableView(tableView: UITableView, didUnhighlightRowAtIndexPath indexPath: NSIndexPath) {
        let cell = self.tableView(tableView, cellForRowAtIndexPath: indexPath)
        if let separatorImage = cell.contentView.viewWithTag(10) {
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue()) {
                separatorImage.hidden = false
            }
        }
        
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let option = OEXRearViewOptions(rawValue: indexPath.row) {
            switch option {
            case .UserProfile:
                guard environment.config.profilesEnabled else { break }
                guard let currentUserName = environment.session.currentUser?.username else { return }
                environment.router?.showProfileForUsername(username: currentUserName)
            case .MyCourse:
                environment.router?.showMyCourses()
            case .MyMedia:
                environment.router?.showMyVideos()
            //case .RecentMedia:
              //  environment.router?.showMyVideos()
            case .AppSettings:
                environment.router?.showMySettings()
            case .MySettings:
                environment.router?.showAccountSettings()
            case .LicensingTerms:
                environment.router?.showLicensingTerms()
            case .SubmitFeedback:
                launchEmailComposer()
            case .Logout:
                break
            }
        }
       tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        if indexPath.row == OEXRearViewOptions.Debug.rawValue && !environment.config.shouldShowDebug() {
//            return 0
//        }
//        else if indexPath.row == OEXRearViewOptions.FindCourses.rawValue && !environment.config.courseEnrollmentConfig.isCourseDiscoveryEnabled() {
//            return 0
//        }
       if indexPath.row == OEXRearViewOptions.Logout.rawValue {
            let screenHeight = UIScreen.mainScreen().bounds.height
            let tableviewHeight = tableView.contentSize.height
            return max((screenHeight - tableviewHeight) + LogoutCellDefaultHeight, LogoutCellDefaultHeight)
        }
        
        
        return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
    }
    
    @IBAction func logoutClicked(sender: UIButton) {
        OEXFileUtility.nukeUserPIIData()
        self.environment.router?.logout()
    }
    
    func dataAvailable(notification: NSNotification) {
        let successString = notification.userInfo![NOTIFICATION_KEY_STATUS] as? String;
        let URLString = notification.userInfo![NOTIFICATION_KEY_URL] as? String;
        
        if successString == NOTIFICATION_VALUE_URL_STATUS_SUCCESS && URLString == environment.interface?.URLStringForType(URL_USER_DETAILS) {
            updateUIWithUserInfo()
        }
    }
}

extension OEXRearTableViewController : MFMailComposeViewControllerDelegate {

    static func supportEmailMessageTemplate() -> String {
        let osVersionText = Strings.SubmitFeedback.osVersion(version: UIDevice.currentDevice().systemVersion)
        let appVersionText = Strings.SubmitFeedback.appVersion(version: NSBundle.mainBundle().oex_shortVersionString(), build: NSBundle.mainBundle().oex_buildVersionString())
        let deviceModelText = Strings.SubmitFeedback.deviceModel(model: UIDevice.currentDevice().model)
        let body = ["\n", Strings.SubmitFeedback.marker, osVersionText, appVersionText, deviceModelText].joinWithSeparator("\n")
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
            presentViewController(mail, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
