//
//  OEXRouter+Swift.swift
//  edX
//
//  Created by Akiva Leffert on 5/7/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import MckinseyXBlocks

// The router is an indirection point for navigation throw our app.

// New router logic should live here so it can be written in Swift.
// We should gradually migrate the existing router class here and then
// get rid of the objc version

enum CourseHTMLBlockSubkind {
    case base
    case problem
}

enum CourseBlockDisplayType {
    case unknown
    case outline
    case lesson
    case unit
    case video
    case ooyalaVideo(contentID: String, playerCode: String, description: String?)
    case html(CourseHTMLBlockSubkind)
    case discussion(DiscussionModel)
    case audio //Added By Ravi on 22Jan'17 to Implement AudioPodcast
    case mcq(MCQ)
    case freeText(FreeText)
    case mrq(MCQ)
    
    var isUnknown : Bool {
        switch self {
        case .unknown: return true
        default: return false
        }
    }
}

extension CourseBlock {
    
    var displayType : CourseBlockDisplayType {
        switch self.type {
        case .unknown(_), .html: return multiDevice ? .html(.base) : .unknown
        case .problem: return multiDevice ? .html(.problem) : .unknown
        case .course: return .outline
        case .chapter: return .lesson
        case .section: return .outline
        case .unit: return .unit
        case let .ooyalaVideo(contentID, playerCode, description): return .ooyalaVideo(contentID: contentID, playerCode: playerCode, description: description)
        case let .video(summary): return (summary.isSupportedVideo) ? .video : .unknown
        case let .audio(summary): return (summary.onlyOnWeb || summary.isYoutubeVideo) ? .unknown : .audio //Added By Ravi on 22Jan'17 to Implement AudioPodcast
        case let .freeText(question): return .freeText(question)
        case let .discussion(discussionModel): return .discussion(discussionModel)
        case let .mcq(question): return .mcq(question)
        case let .mrq(question): return .mrq(question)
        }
    }
}


extension OEXRouter {
    func showLessonForCourseWithID(_ courseID : String, fromController controller : UIViewController) {
        showContainerForBlockWithID(nil, type: CourseBlockDisplayType.lesson, parentID: nil, courseID : courseID, fromController: controller)
    }
    
    var loginViewController: UIViewController {
        let viewController = LoginViewController(nibName: nil, bundle: nil)
        // We have to downcast here because we can't import swift headers in objective c 
        // header (.h) file which means there is no way for the router to declare its 
        // conformace of `LoginViewControllerDelegate` protocol unless we are in the (.m)
        // file of router. so we have to downcast it but this is guaranteed to succeed at
        // runtime. If someone has any better idea around it please let me know...
        viewController.delegate = self as? LoginViewControllerDelegate
        let appDelegate = UIApplication.shared.delegate as! OEXAppDelegate
        let presenter = LoginPresenter(authenticator: RemoteAuthenticator.shared, view: viewController, reachability: appDelegate.reachability)
        viewController.presenter = presenter
        return viewController
    }
    
    
    func showCoursewareForCourseWithID(_ courseID : String, fromController controller : UIViewController) {
        showContainerForBlockWithID(nil, type: CourseBlockDisplayType.outline, parentID: nil, courseID : courseID, fromController: controller)
    }
    
    func unitControllerForCourseID(_ courseID : String, sequentialID : CourseBlockID?, blockID : CourseBlockID?, initialChildID : CourseBlockID?) -> CourseContentPageViewController {
        let contentPageController = CourseContentPageViewController(environment: environment, courseID: courseID, rootID: blockID, sequentialID:sequentialID, initialChildID: initialChildID)
        return contentPageController
    }
    
    func showContainerForBlockWithID(_ blockID : CourseBlockID?, type : CourseBlockDisplayType, parentID : CourseBlockID?, courseID : CourseBlockID, fromController controller: UIViewController) {
        switch type {
        case .outline:
            fallthrough
        case .lesson:
            fallthrough
        case .unit:
            let outlineController = controllerForBlockWithID(blockID, type: type, courseID: courseID)
            controller.navigationController?.pushViewController(outlineController, animated: true)
        case .html:
            fallthrough
        case .mcq:
            fallthrough
        case .mrq:
            fallthrough
        case .freeText:
            fallthrough
        case .video:
            fallthrough
        case .ooyalaVideo:
            fallthrough
        case .audio:
            fallthrough
        case .unknown:
            let pageController = unitControllerForCourseID(courseID, sequentialID:nil, blockID: parentID, initialChildID: blockID)
            if let delegate = controller as? CourseContentPageViewControllerDelegate {
                pageController.navigationDelegate = delegate
            }
            controller.navigationController?.pushViewController(pageController, animated: true)
        case .discussion:
            let pageController = unitControllerForCourseID(courseID, sequentialID:nil, blockID: parentID, initialChildID: blockID)
            if let delegate = controller as? CourseContentPageViewControllerDelegate {
                pageController.navigationDelegate = delegate
            }
            controller.navigationController?.pushViewController(pageController, animated: true)
        }
    }
    
    fileprivate func controllerForBlockWithID(_ blockID : CourseBlockID?, type : CourseBlockDisplayType, courseID : String) -> UIViewController {
        switch type {
        case .outline:
            let outlineController = OEXCoursewareViewController(environment: self.environment, courseID: courseID, rootID: blockID)
            return outlineController
        case .lesson:
            let courseOutlineQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID)
            let interface = environment.interface
            let lessonViewModelDataSource = LessonViewModelDataSourceImplementation(querier: courseOutlineQuerier, interface: interface!)
            let courseLessonController = CourseLessonsViewController(environment: self.environment, courseID: courseID, rootID: blockID, lessonViewModelDataSource: lessonViewModelDataSource)
            return courseLessonController
        case .unit:
            return unitControllerForCourseID(courseID, sequentialID: nil, blockID: blockID, initialChildID: nil)
        case .html:
            let controller = HTMLBlockViewController(blockID: blockID, courseID : courseID, environment : environment)
            return controller
        case .video:
            let controller = VideoBlockViewController(environment: environment, blockID: blockID, courseID: courseID)
            return controller
        case let .ooyalaVideo(contentID, playerCode, description):
            // We are only going to support iOS 9 and above but currently chaging the deployment
            // target to 9.0 uncovers a some 150 warings that are there due to deprecations
            // it would take some time to fix those warnigns so for now i have wrapped the framework
            // usage around iOS 9.0 availability
            if #available(iOS 9.0, *) {
                let player = OyalaPlayerViewController(contentID: contentID, domain: "https://secure-cf-c.ooyala.com", pcode: playerCode, description: description)
                player.play()
                let adapter = CourseBlockViewControllerAdapter(blockID: blockID, courseID: courseID, adaptedViewController: player)

                return adapter
            } else {
                fatalError("We need to upgrade build settings to iOS")
            }
           
        case .audio:
            let controller = AudioBlockViewController(environment: environment, blockID: blockID, courseID: courseID)
            return controller
        case .mcq(let question):
            let options = question.choices.flatMap{ (choice: Choice) -> Option in
                let option = Option(content: choice.content, value: choice.value, tip: choice.tip)
                return option
            }
            let mcqQuestion = Question(id: question.id, choices: options, question: question.question, title: question.title, message: question.message)
            let mcqManager = MCQManager(blockID: blockID!, courseID: courseID, networkManager: self.environment.networkManager)
            let viewController = MCQViewController(question: mcqQuestion, resultMatcher: mcqManager)
            
            let adapter = CourseBlockViewControllerAdapter(blockID: blockID, courseID: courseID, adaptedViewController: viewController)
            return adapter
            
        case .mrq(let question):
            let options = question.choices.flatMap{ (choice: Choice) -> Option in
                let option = Option(content: choice.content, value: choice.value, tip: choice.tip)
                return option
            }
            let mrqQuestion = Question(id: question.id, choices: options, question: question.question, title: question.title, message: question.message)
            let mrqManager = MRQManager(blockID: blockID!, courseID: courseID, networkManager: self.environment.networkManager)
            let viewController = MRQViewController(question: mrqQuestion, resultMatcher: mrqManager)
            
            let adapter = CourseBlockViewControllerAdapter(blockID: blockID, courseID: courseID, adaptedViewController: viewController)
            return adapter
        case .freeText(let question):
            let message = question.message != "" ? question.message : nil
            let freeTextQuestion = FTQuestion(id: question.id, question: question.question, message: message)
            let ftManager = FTManager(blockID: blockID!, courseID: courseID, environment: environment)
            let freeTextController = FTPulleyManagerViewController(question: freeTextQuestion, ftAPIProtocol: ftManager)
            let adapter = CourseBlockViewControllerAdapter(blockID: blockID, courseID: courseID, adaptedViewController: freeTextController)
            return adapter
        case .unknown:
            let controller = CourseUnknownBlockViewController(blockID: blockID, courseID : courseID, environment : environment)
            return controller
        case let .discussion(discussionModel):
            let controller = DiscussionBlockViewController(blockID: blockID, courseID: courseID, topicID: discussionModel.topicID, environment: environment)
            return controller
        }
    }

    func controllerForBlock(_ block : CourseBlock, courseID : String) -> UIViewController {
        return controllerForBlockWithID(block.blockID, type: block.displayType, courseID: courseID)
    }
    
    @objc(showMyCoursesAnimated:pushingCourseWithID:) func showMyCourses(animated: Bool = true, pushingCourseWithID courseID: String? = nil) {
        let controller = EnrolledCoursesViewController(environment: self.environment)
        showContentStack(withRootController: controller, animated: animated)
        if let courseID = courseID {
            self.showCourseWithID(courseID, fromController: controller, animated: false)
        }
    }
    
    func showDiscussionResponsesFromViewController(_ controller: UIViewController, courseID : String, threadID : String) {
        let storyboard = UIStoryboard(name: "DiscussionResponses", bundle: nil)
        let responsesViewController = storyboard.instantiateInitialViewController() as! DiscussionResponsesViewController
        responsesViewController.environment = environment
        responsesViewController.courseID = courseID
        responsesViewController.threadID = threadID
        controller.navigationController?.pushViewController(responsesViewController, animated: true)
    }
    
    func showDiscussionCommentsFromViewController(_ controller: UIViewController, courseID : String, response : DiscussionComment, closed : Bool, thread: DiscussionThread) {
        let commentsVC = DiscussionCommentsViewController(environment: environment, courseID : courseID, responseItem: response, closed: closed, thread: thread)
       
        if let delegate = controller as? DiscussionCommentsViewControllerDelegate {
            commentsVC.delegate = delegate
        }
        
        controller.navigationController?.pushViewController(commentsVC, animated: true)
    }
    
    func showDiscussionNewCommentFromController(_ controller: UIViewController, courseID : String, thread:DiscussionThread, context: DiscussionNewCommentViewController.Context) {
        let newCommentViewController = DiscussionNewCommentViewController(environment: environment, courseID : courseID, thread:thread,  context: context)
        
        if let delegate = controller as? DiscussionNewCommentViewControllerDelegate {
            newCommentViewController.delegate = delegate
        }
        
        let navigationController = UINavigationController(rootViewController: newCommentViewController)
        controller.present(navigationController, animated: true, completion: nil)
    }
    
    func showPostsFromController(_ controller : UIViewController, courseID : String, topic: DiscussionTopic) {
        let postsController = PostsViewController(environment: environment, courseID: courseID, topic: topic)
        controller.navigationController?.pushViewController(postsController, animated: true)
    }
    
    func showAllPostsFromController(_ controller : UIViewController, courseID : String, followedOnly following : Bool) {
        let postsController = PostsViewController(environment: environment, courseID: courseID, following : following)
        controller.navigationController?.pushViewController(postsController, animated: true)
    }
    
    func showPostsFromController(_ controller : UIViewController, courseID : String, queryString : String) {
        let postsController = PostsViewController(environment: environment, courseID: courseID, queryString : queryString)
        
        controller.navigationController?.pushViewController(postsController, animated: true)
    }
    
    func showDiscussionTopicsFromController(_ controller: UIViewController, courseID : String) {
        let topicsController = DiscussionTopicsViewController(environment: environment, courseID: courseID)
        controller.navigationController?.pushViewController(topicsController, animated: true)
    }

    func showDiscussionNewPostFromController(_ controller: UIViewController, courseID : String, selectedTopic : DiscussionTopic?) {
        let newPostController = DiscussionNewPostViewController(environment: environment, courseID: courseID, selectedTopic: selectedTopic)
        if let delegate = controller as? DiscussionNewPostViewControllerDelegate {
            newPostController.delegate = delegate
        }
        let navigationController = UINavigationController(rootViewController: newPostController)
        controller.present(navigationController, animated: true, completion: nil)
    }
    
    func showHandoutsFromController(_ controller : UIViewController, courseID : String) {
        let handoutsViewController = CourseHandoutsViewController(environment: environment, courseID: courseID)
        controller.navigationController?.pushViewController(handoutsViewController, animated: true)
    }

    func showProfileForUsername(_ controller: UIViewController? = nil, username : String, editable: Bool = true) {
        OEXAnalytics.shared().trackProfileViewed(username)
        let editable = self.environment.session.currentUser?.username == username
        let profileController = UserProfileViewController(environment: environment, username: username, editable: editable)
        if let controller = controller {
            controller.navigationController?.pushViewController(profileController, animated: true)
        } else {
            self.showContentStack(withRootController: profileController, animated: true)
        }
    }
    
    func showProfileEditorFromController(_ controller : UIViewController) {
        guard let profile = environment.dataManager.userProfileManager.feedForCurrentUser().output.value else {
            return
        }
        let editController = UserProfileEditViewController(profile: profile, environment: environment)
        controller.navigationController?.pushViewController(editController, animated: true)
    }

    func showCertificate(_ url: URL, title: String?, fromController controller: UIViewController) {
        let c = CertificateViewController(environment: environment)
        c.title = title
        controller.navigationController?.pushViewController(c, animated: true)
        c.loadRequest(URLRequest(url: url))
    }
    
    func showCourseWithID(_ courseID : String, fromController: UIViewController, animated: Bool = true) {
        let controller = CourseDashboardViewController(environment: self.environment, courseID: courseID)
        fromController.navigationController?.pushViewController(controller, animated: animated)
    }
    
    func showCourseCatalog(_ bottomBar: UIView?) {
        let controller: UIViewController
        switch environment.config.courseEnrollmentConfig.type {
        case .Webview:
            controller = OEXFindCoursesViewController(bottomBar: bottomBar)
        case .Native, .None:
            controller = CourseCatalogViewController(environment: self.environment)
        }
        if revealController != nil {
            showContentStack(withRootController: controller, animated: true)
        } else {
            showControllerFromStartupScreen(controller)
        }
        self.environment.analytics.trackUserFindsCourses()
    }

    func showExploreCourses(_ bottomBar: UIView?) {
        let controller = OEXFindCoursesViewController(bottomBar: bottomBar)
        controller.startURL = .exploreSubjects
        if revealController != nil {
            showContentStack(withRootController: controller, animated: true)
        } else {
            showControllerFromStartupScreen(controller)
        }
    }

    fileprivate func showControllerFromStartupScreen(_ controller: UIViewController) {
        let backButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
        backButton.oex_setAction({
            controller.dismiss(animated: true, completion: nil)
        })
        controller.navigationItem.leftBarButtonItem = backButton
        let navController = ForwardingNavigationController(rootViewController: controller)

        present(navController, from:nil, completion: nil)
    }

    func showCourseCatalogDetail(_ courseID: String, fromController: UIViewController) {
        let detailController = CourseCatalogDetailViewController(environment: environment, courseID: courseID)
        fromController.navigationController?.pushViewController(detailController, animated: true)
    }

    // MARK: - LOGIN / LOGOUT

    func showSplash() {
        revealController = nil
        removeCurrentContentController()

        let splashController: UIViewController = self.loginViewController
       /* if UserDefaults.standard.bool(forKey: FIRST_TIME_USER_KEY) == true{
            splashController = self.loginViewController()
        } else {
            splashController = OEXFTUEViewController(environment: environment)
        } */
        
        makeContentControllerCurrent(splashController)
    }

    public func logout() {
        UserDefaults.standard.set(false, forKey: FTUE) //Added by Ravi on 10Mar'17 not show coach marks after logout.
        invalidateToken()
		PrefillCacheController.sharedController.reset()
        environment.session.closeAndClear()
        UAirship.push().userPushNotificationsEnabled = false
        UAirship.push().allowUnregisteringUserNotificationTypes = false
        BrandingThemes.shared.applyThemeWith(fileName: MCKINSEY_THEME_FILE)
        OEXStyles.shared.applyGlobalAppearance()
        showLoggedOutScreen()
        
    }
    
    func invalidateToken() {
        if let refreshToken = environment.session.token?.refreshToken, let clientID = environment.config.oauthClientID() {
            let networkRequest = LogoutApi.invalidateToken(refreshToken, clientID: clientID)
            environment.networkManager.taskForRequest(networkRequest) { result in }
        }
    }

    // MARK: - Debug
    func showDebugPane() {
        let debugMenu = DebugMenuViewController(environment: environment)
        showContentStack(withRootController: debugMenu, animated: true)
    }
}



