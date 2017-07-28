//
//  StartupViewController.swift
//  edX
//
//  Created by Michael Katz on 5/16/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

class StartupViewController: UIViewController, InterfaceOrientationOverriding {

    typealias Environment = OEXRouterProvider & OEXConfigProvider

    fileprivate let logoImageView = UIImageView()

    fileprivate let environment: Environment

    init(environment: Environment) {
        self.environment = environment

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupBackground()
        setupLogo()
        setupDiscoverButtons()
        setupBottomBar()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        OEXAnalytics.shared().trackScreen(withName: "launch")
    }

    override var shouldAutorotate : Bool {
        return false
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return .portrait
    }
    
    // MARK: - View Setup

    fileprivate func setupBackground() {
        let backgroundImage = UIImage(named: "launchBackground")
        let backgroundImageView = UIImageView(image: backgroundImage)
        backgroundImageView.contentMode = .scaleAspectFill
        view.addSubview(backgroundImageView)

        backgroundImageView.snp.makeConstraints { (make) in
            make.edges.equalTo(view)
        }
    }

    fileprivate func setupLogo() {
        let logo = UIImage(named: "logo")
        logoImageView.image = logo
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.accessibilityLabel = environment.config.platformName()
        logoImageView.isAccessibilityElement = true
        logoImageView.accessibilityTraits = UIAccessibilityTraitImage
        view.addSubview(logoImageView)

        logoImageView.snp.makeConstraints { (make) in
            make.centerY.equalTo(view.snp.bottom).dividedBy(5.0)
            make.centerX.equalTo(view.snp.centerX)
        }
    }

    fileprivate func setupDiscoverButtons() {

        let discoverButton = UIButton()
        discoverButton.applyButtonStyle(OEXStyles.shared().filledPrimaryButtonStyle, withTitle: Strings.Startup.discovercourses)
        let discoverEvent = OEXAnalytics.discoverCoursesEvent()
        discoverButton.oex_addAction({ [weak self] _ in
            self?.showCourses()
            }, for: .touchUpInside, analyticsEvent: discoverEvent)

        view.addSubview(discoverButton)


        let exploreButton = UIButton()
        exploreButton.applyButtonStyle(OEXStyles.shared().filledPrimaryButtonStyle, withTitle: Strings.Startup.exploreSubjects)
        let exploreEvent = OEXAnalytics.exploreSubjectsEvent()
        exploreButton.oex_addAction({ [weak self] _ in
            self?.exploreSubjects()
            }, for: .touchUpInside, analyticsEvent: exploreEvent)

        view.addSubview(exploreButton)

        discoverButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(view.snp.centerY)
            make.leading.equalTo(view.snp.leading).offset(30)
            make.trailing.equalTo(view.snp.trailing).inset(30)
            if environment.config.courseEnrollmentConfig.isCourseDiscoveryEnabled() {
                make.height.equalTo(40)
            } else {
                make.height.equalTo(0)
            }
        }

        exploreButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(view.snp.centerY).inset(35)
            make.leading.equalTo(view.snp.leading).offset(30)
            make.trailing.equalTo(view.snp.trailing).inset(30)
            make.height.equalTo(0)
        }
    }

    fileprivate func setupBottomBar() {
        let bottomBar = BottomBarView(environment: environment)
        view.addSubview(bottomBar)
        bottomBar.snp.makeConstraints { (make) in
            make.height.equalTo(50)
            make.bottom.equalTo(view)
            make.leading.equalTo(view.snp.leading)
            make.trailing.equalTo(view.snp.trailing)
        }

    }
    
    //MARK: - Actions
    func showCourses() {
        let bottomBar = BottomBarView(environment: environment)
        environment.router?.showCourseCatalog(bottomBar)
    }
    
    func exploreSubjects() {
        let bottomBar = BottomBarView(environment: environment)
        self.environment.router?.showExploreCourses(bottomBar)
    }
}

private class BottomBarView: UIView, NSCopying {
    typealias Environment = OEXRouterProvider
    fileprivate var environment : Environment?
    
    override init(frame: CGRect = CGRect.zero) {
        super.init(frame:frame)
        makeBottomBar()
    }
    
    convenience init (environment:Environment?) {
        self.init(frame: CGRect.zero)
        self.environment = environment
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func copy(with zone: NSZone?) -> Any {
        let copy = BottomBarView(environment: environment)
        return copy
    }
    
    fileprivate func makeBottomBar() {
        let bottomBar = UIView()
        let signInButton = UIButton()
        let registerButton = UIButton()
        let line = UIView()
        bottomBar.backgroundColor = UIColor.black.withAlphaComponent(0.90)
        
        signInButton.setTitle(Strings.signInText, for: UIControlState())
        let signInEvent = OEXAnalytics.loginEvent()
        signInButton.oex_addAction({ [weak self] _ in
            self?.showLogin()
            }, for: .touchUpInside, analyticsEvent: signInEvent)
        
        registerButton.setTitle(Strings.registerText, for: UIControlState())
        let signUpEvent = OEXAnalytics.registerEvent()
        registerButton.oex_addAction({ [weak self] _ in
            self?.showRegistration()
            }, for: .touchUpInside, analyticsEvent: signUpEvent)
        
        bottomBar.addSubview(registerButton)
        bottomBar.addSubview(signInButton)
        bottomBar.addSubview(line)
        
        signInButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(bottomBar)
            make.top.equalTo(bottomBar)
            make.bottom.equalTo(bottomBar)
            make.trailing.equalTo(bottomBar)
            make.leading.equalTo(line.snp.trailing)
        }
        
        registerButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(bottomBar)
            make.top.equalTo(bottomBar)
            make.bottom.equalTo(bottomBar)
            make.leading.equalTo(bottomBar)
            make.trailing.equalTo(line.snp.leading)        }
        
        line.backgroundColor = OEXStyles.shared().neutralBase()
        
        line.snp.makeConstraints { (make) in
            make.top.equalTo(bottomBar)
            make.bottom.equalTo(bottomBar)
            make.centerX.equalTo(bottomBar)
            make.width.equalTo(1)
        }
        
        addSubview(bottomBar)
        
        bottomBar.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
        
    }
    
    //MARK: - Actions
    func showLogin() {
        environment?.router?.showLoginScreen(from: firstAvailableUIViewController(), completion: nil)
    }
    
    func showRegistration() {
        environment?.router?.showSignUpScreen(from: firstAvailableUIViewController(), completion: nil)
    }
}
