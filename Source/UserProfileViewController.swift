//
//  UserProfileViewController.swift
//  edX
//
//  Created by Michael Katz on 9/22/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class UserProfileViewController: OfflineSupportViewController, UserProfilePresenterDelegate {
    
    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & NetworkManagerProvider & OEXRouterProvider & ReachabilityProvider & DataManagerProvider & OEXSessionProvider
    
    fileprivate let environment : Environment

    fileprivate let editable: Bool

    fileprivate let loadController = LoadStateViewController()
    fileprivate let contentView = UserProfileView(frame: CGRect.zero)
    fileprivate let presenter : UserProfilePresenter
    
    convenience init(environment : UserProfileNetworkPresenter.Environment & Environment, username : String, editable: Bool) {

        let presenter = UserProfileNetworkPresenter(environment: environment, username: username)
        self.init(environment: environment, presenter: presenter, editable: editable)
        presenter.delegate = self
    }

    init(environment: Environment, presenter: UserProfilePresenter, editable: Bool) {
        self.editable = editable
        self.environment = environment
        self.presenter = presenter
        super.init(env: environment)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(contentView)
        contentView.snp.makeConstraints {make in
            make.edges.equalTo(view)
        }
        
        if editable {
            let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: nil, action: nil)
            editButton.oex_setAction() { [weak self] in
                self?.environment.router?.showProfileEditorFromController(self!)
            }
            editButton.accessibilityLabel = Strings.Profile.editAccessibility
            navigationItem.rightBarButtonItem = editButton
        }

        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: UIBarButtonItemStyle.plain, target: nil, action: nil)

        addProfileListener()
        addExtraTabsListener()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        environment.analytics.trackScreen(withName: OEXAnalyticsScreenProfileView)

        presenter.refresh()
        contentView.setNeedsUpdateConstraints()
    }
    
    override func reloadViewData() {
        presenter.refresh()
    }

    fileprivate func addProfileListener() {
        let editable = self.editable
        let networkManager = environment.networkManager
        presenter.profileStream.listen(self, success: { [weak self] profile in
            // TODO: Refactor UserProfileView to take a dumb model so we don't need to pass it a network manager
            self?.contentView.populateFields(profile, editable: editable, networkManager: networkManager)
            self?.loadController.state = .loaded
            }, failure : { [weak self] error in
                self?.loadController.state = LoadState.failed(error, message: Strings.Profile.unableToGet)
            })
    }

    fileprivate func addExtraTabsListener() {
        presenter.tabStream.listen(self, success: {[weak self] in
            self?.contentView.extraTabs = $0
            }, failure: {_ in
                // ignore. Better to just not show tabs and still show the profile assuming the rest of it worked fine
            }
        )
    }

    func presenter(_ presenter: UserProfilePresenter, choseShareURL url: URL) {
        let message = Strings.Accomplishments.shareText(platformName:self.environment.config.platformName())
        let controller = UIActivityViewController(
            activityItems: [message, url],
            applicationActivities: nil
        )
        self.present(controller, animated: true, completion: nil)
    }
}


extension UserProfileViewController {
    func t_chooseTab(_ identifier: String) {
        self.contentView.chooseTab(identifier)
    }
}
