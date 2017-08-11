//
//  EnrolledCoursesViewController.swift
//  edX
//
//  Created by Akiva Leffert on 12/21/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

var isActionTakenOnUpgradeSnackBar: Bool = false
let brandingHeaderViewHeight:CGFloat = 50.0

class EnrolledCoursesViewController : OfflineSupportViewController, CoursesTableViewControllerDelegate, PullRefreshControllerDelegate {
    
    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & NetworkManagerProvider & ReachabilityProvider & OEXRouterProvider & OEXSessionProvider
    
    fileprivate let environment : Environment
    fileprivate let tableController : CoursesTableViewController
    fileprivate let loadController = LoadStateViewController()
    fileprivate let refreshController = PullRefreshController()
    fileprivate let insetsController = ContentInsetsController()
    fileprivate let enrollmentFeed: Feed<[UserCourseEnrollment]?>
    fileprivate let userPreferencesFeed: Feed<UserPreference?>

    init(environment: Environment) {
        self.tableController = CoursesTableViewController(environment: environment, context: .enrollmentList)
        self.enrollmentFeed = environment.dataManager.enrollmentManager.feed
        self.userPreferencesFeed = environment.dataManager.userPreferenceManager.feed
        self.environment = environment
        
        super.init(env: environment)
        self.navigationItem.title = Strings.myCourses
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.accessibilityIdentifier = "enrolled-courses-screen"

        addChildViewController(tableController)
        tableController.didMove(toParentViewController: self)
        self.loadController.setupInController(self, contentView: tableController.view)
        
        self.view.addSubview(tableController.view)
        tableController.view.snp.makeConstraints {make in
            make.edges.equalTo(self.view)
        }
        
        tableController.delegate = self
        
        self.view.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        
        refreshController.setupInScrollView(self.tableController.tableView)
        refreshController.delegate = self
        
        insetsController.setupInController(self, scrollView: tableController.tableView)
        insetsController.addSource(self.refreshController)

        // We visually separate each course card so we also need a little padding
        // at the bottom to match
        insetsController.addSource(
            ConstantInsetsSource(insets: UIEdgeInsets(top: 0, left: 0, bottom: StandardVerticalMargin, right: 0), affectsScrollIndicators: false)
        )
        
        self.enrollmentFeed.refresh()
        self.userPreferencesFeed.refresh()
        
        setupListener()
        setupFooter()
        setupHeaderView()
        setupObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        environment.analytics.trackScreen(withName: OEXAnalyticsScreenMyCourses)
        showVersionUpgradeSnackBarIfNecessary()
        super.viewWillAppear(animated)
    }
    
    override func reloadViewData() {
        refreshIfNecessary()
    }

    fileprivate func setupListener() {
        
        enrollmentFeed.output.listen(self) {[weak self] result in
            if !(self?.enrollmentFeed.output.active ?? false) {
                self?.refreshController.endRefreshing()
            }
            
            switch result {
            case let .success(enrollments):
                if let enrollments = enrollments {
                    self?.tableController.courses = enrollments.filter{$0.isActive}.flatMap { CourseViewModel(lessonCount: nil,  persistImage: true, course: $0.course) } 
                    self?.tableController.tableView.reloadData()
                    self?.loadController.state = .loaded
                    if enrollments.count <= 0 {
                        self?.enrollmentsEmptyState()
                    }
                }
                else {
                    self?.loadController.state = .initial
                }
            case let .failure(error):
                self?.loadController.state = LoadState.failed(error)
                if error.errorIsThisType(NSError.oex_outdatedVersionError()) {
                    self?.hideSnackBar()
                }
            }
        }
    }
    
    /// Setup branding header view
    fileprivate func setupHeaderView() {
        let header = BrandingHeaderView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: brandingHeaderViewHeight))
        header.sizeToFit()
        self.tableController.tableView.tableHeaderView = header
    }
    
    fileprivate func setupFooter() {
        if environment.config.courseEnrollmentConfig.isCourseDiscoveryEnabled() {
            let footer = EnrolledCoursesFooterView()
            footer.findCoursesAction = {[weak self] in
                self?.environment.router?.showCourseCatalog(nil)
            }
            footer.missingCoursesAction = {[weak self] in
                self?.showCourseNotListedAlert()
            }
            
            footer.sizeToFit()
            self.tableController.tableView.tableFooterView = footer
        }
        else {
            tableController.tableView.tableFooterView = UIView()
        }
    }
    
    fileprivate func enrollmentsEmptyState() {
        if !environment.config.courseEnrollmentConfig.isCourseDiscoveryEnabled() {
            let error = NSError.oex_error(with: .unknown, message: Strings.EnrollmentList.noEnrollment)
            loadController.state = LoadState.failed(error, icon: Icon.unknownError)
        }
    }
    
    fileprivate func setupObservers() {
        let config = environment.config
        NotificationCenter.default.oex_addObserver( self, name: NSNotification.Name.OEXExternalRegistrationWithExistingAccount.rawValue) { (notification, observer, _) -> Void in
            let platform = config.platformName()
            let service = notification.object as? String ?? ""
            let message = Strings.externalRegistrationBecameLogin(platformName: platform, service: service)
            observer.showOverlayMessage(message)
        }
        
        NotificationCenter.default.oex_addObserver( self, name: AppNewVersionAvailableNotification) { (notification, observer, _) -> Void in
            observer.showVersionUpgradeSnackBarIfNecessary()
        }
    }
    
    func refreshIfNecessary() {
        if environment.reachability.isReachable() && !enrollmentFeed.output.active {
            enrollmentFeed.refresh()
            if loadController.state.isError {
                loadController.state = .initial
            }
        }
    }
    
    fileprivate func showCourseNotListedAlert() {
        let alertController = UIAlertController().showAlertWithTitle(nil, message: Strings.courseNotListed, cancelButtonTitle: nil, onViewController: self)
        alertController.addButtonWithTitle(Strings.ok, actionBlock: { (action) in
            DispatchQueue.main.async(execute: { 
                UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.navigationItem.leftBarButtonItem)
            })
        })
    }
    
    fileprivate func showVersionUpgradeSnackBarIfNecessary() {
        if let _ = VersionUpgradeInfoController.sharedController.latestVersion {
            var infoString = Strings.VersionUpgrade.newVersionAvailable
            if let _ = VersionUpgradeInfoController.sharedController.lastSupportedDateString {
                infoString = Strings.VersionUpgrade.deprecatedMessage
            }
            
            if !isActionTakenOnUpgradeSnackBar {
                showVersionUpgradeSnackBar(infoString)
            }
        }
        else {
            hideSnackBar()
        }
    }
    
    func coursesTableChoseCourse(_ course: OEXCourse) {
        if let course_id = course.course_id {
            self.environment.router?.showCourseWithID(course_id, fromController: self, animated: true)
        }
        else {
            preconditionFailure("course without a course id")
        }
    }
    
    func refreshControllerActivated(_ controller: PullRefreshController) {
        self.enrollmentFeed.refresh()
        self.userPreferencesFeed.refresh()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableController.tableView.autolayoutFooter()
    }
}

// For testing use only
extension EnrolledCoursesViewController {
    var t_loaded: edXCore.Stream<()> {
        return self.enrollmentFeed.output.map {_ in
            return ()
        }
    }
}
