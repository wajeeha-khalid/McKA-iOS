//
//  UserProfilePresenter.swift
//  edX
//
//  Created by Akiva Leffert on 4/8/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

extension Accomplishment {
    init(badge: BadgeAssertion, networkManager: NetworkManager) {
        let image = RemoteImageImpl(url: badge.imageURL, networkManager: networkManager, placeholder: nil, persist: false)
        self.init(image: image, title: badge.badgeClass.name, detail: badge.badgeClass.detail, date: badge.created, shareURL: badge.assertionURL)
    }
}

protocol UserProfilePresenterDelegate : class {
    func presenter(_ presenter: UserProfilePresenter, choseShareURL url: URL)
}

typealias ProfileTabItem = (UIScrollView) -> TabItem

protocol UserProfilePresenter: class {

    var profileStream: edXCore.Stream<UserProfile> { get }
    var tabStream: edXCore.Stream<[ProfileTabItem]> { get }
    func refresh() -> Void

    weak var delegate: UserProfilePresenterDelegate? { get }
}

class UserProfileNetworkPresenter : NSObject, UserProfilePresenter {
    typealias Environment = OEXConfigProvider & DataManagerProvider & NetworkManagerProvider & OEXSessionProvider

    static let AccomplishmentsTabIdentifier = "AccomplishmentsTab"
    fileprivate let profileFeed: Feed<UserProfile>
    fileprivate let environment: Environment
    fileprivate let username: String

    var profileStream: edXCore.Stream<UserProfile> {
        return profileFeed.output
    }

    weak var delegate: UserProfilePresenterDelegate?

    init(environment: Environment, username: String) {
        self.profileFeed = environment.dataManager.userProfileManager.feedForUser(username)
        self.environment = environment
        self.username = username

        super.init()

        self.refresh()
    }

    func refresh() {
        profileFeed.refresh()
    }

    fileprivate var canShareAccomplishments : Bool {
        return self.username == self.environment.session.currentUser?.username
    }

    lazy var tabStream: edXCore.Stream<[ProfileTabItem]> = {
        if self.environment.config.badgesEnabled {
            // turn badges into accomplishments
            let networkManager = self.environment.networkManager
            let paginator = WrappedPaginator(networkManager: self.environment.networkManager) {
                BadgesAPI.requestBadgesForUser(self.username, page: $0).map {paginatedBadges in
                    // turn badges into accomplishments
                    return paginatedBadges.map {badges in
                        badges.map {badge in
                            return Accomplishment(badge: badge, networkManager: networkManager)
                        }
                    }
                }
            }
            paginator.loadMore()

            let sink = Sink<[Accomplishment]>()
            paginator.stream.listenOnce(self) {
                sink.send($0)
            }

            let accomplishmentsTab = sink.map {accomplishments -> ProfileTabItem? in
                    return self.tabWithAccomplishments(accomplishments, paginator: AnyPaginator(paginator))
            }
            return joinStreams([accomplishmentsTab]).map { $0.flatMap { $0 }}
        }
        else {
            return edXCore.Stream(value: [])
        }
    }()


    fileprivate func tabWithAccomplishments(_ accomplishments: [Accomplishment], paginator: AnyPaginator<Accomplishment>) -> ProfileTabItem? {
        // turn accomplishments into the accomplishments tab
        if accomplishments.count > 0 {
            return {scrollView -> TabItem in
                let shareAction : (Accomplishment) -> Void = {[weak self] in
                    if let owner = self {
                        owner.delegate?.presenter(owner, choseShareURL:$0.shareURL as URL)
                    }
                }
                let view = AccomplishmentsView(paginator: paginator, containingScrollView: scrollView, shareAction: self.canShareAccomplishments ? shareAction: nil)
                return TabItem(
                    name: Strings.Accomplishments.title,
                    view: view,
                    identifier: UserProfileNetworkPresenter.AccomplishmentsTabIdentifier
                )
            }
        }
        else {
            return nil
        }
    }

}
