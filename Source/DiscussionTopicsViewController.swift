//
//  DiscussionTopicsViewController.swift
//  edX
//
//  Created by Jianfeng Qiu on 11/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import UIKit

open class DiscussionTopicsViewController: OfflineSupportViewController, UITableViewDataSource, UITableViewDelegate, InterfaceOrientationOverriding  {
    
    public typealias Environment = DataManagerProvider & OEXRouterProvider & OEXAnalyticsProvider & ReachabilityProvider & OEXSessionProvider & NetworkManagerProvider
    
    fileprivate enum TableSection : Int {
        case allPosts
        case following
        case courseTopics
    }
    
    fileprivate let topics = BackedStream<[DiscussionTopic]>()
    fileprivate let environment: Environment
    fileprivate let courseID : String
    
    fileprivate let searchBar = UISearchBar()
    fileprivate var searchBarDelegate : DiscussionSearchBarDelegate?
    fileprivate let loadController : LoadStateViewController
    
    fileprivate let contentView = UIView()
    fileprivate let tableView = UITableView()
    fileprivate let searchBarSeparator = UIView()
    
    public init(environment: Environment, courseID: String) {
        self.environment = environment
        self.courseID = courseID
        self.loadController = LoadStateViewController()
        
       super.init(env: environment)
        
        let stream = environment.dataManager.courseDataManager.discussionManagerForCourseWithID(courseID).topics
        topics.backWithStream(stream.map {
            return DiscussionTopic.linearizeTopics($0)
            }
        )
        
        tableView.estimatedRowHeight = 80.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = UIView(frame: .zero)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        // required by the compiler because UIViewController implements NSCoding,
        // but we don't actually want to serialize these things
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = Strings.discussionTopics
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        view.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        searchBarSeparator.backgroundColor = OEXStyles.shared().neutralLight()
        
        self.view.addSubview(contentView)
        self.contentView.addSubview(tableView)
        self.contentView.addSubview(searchBar)
        self.contentView.addSubview(searchBarSeparator)
        
        // Set up tableView
        tableView.dataSource = self
        tableView.delegate = self
        if #available(iOS 9.0, *) {
            tableView.cellLayoutMarginsFollowReadableWidth = false
        }
        
        searchBar.applyStandardStyles(withPlaceholder: Strings.searchAllPosts)
        
        searchBarDelegate = DiscussionSearchBarDelegate() { [weak self] text in
            if let owner = self {
                owner.environment.router?.showPostsFromController(owner, courseID: owner.courseID, queryString : text)
            }
        }
        
        searchBar.delegate = searchBarDelegate
        
        contentView.snp.makeConstraints {make in
            make.edges.equalTo(self.view)
        }
        
        searchBar.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(contentView)
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.bottom.equalTo(searchBarSeparator.snp.top)
        }
        
        searchBarSeparator.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(OEXStyles.dividerSize())
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.bottom.equalTo(tableView.snp.top)
        }
        
        tableView.snp.makeConstraints { make -> Void in
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.bottom.equalTo(contentView)
        }
        
        // Register tableViewCell
        tableView.register(DiscussionTopicCell.classForCoder(), forCellReuseIdentifier: DiscussionTopicCell.identifier)
        
        loadController.setupInController(self, contentView: contentView)
        loadTopics()
    }
    
    fileprivate func loadTopics() {
        
        topics.listen(self, success : {[weak self]_ in
            self?.loadedData()
            }, failure : {[weak self] error in
                self?.loadController.state = LoadState.failed(error)
            })
    }
    
    fileprivate func refreshTopics() {
        loadController.state = .initial
        let stream = environment.dataManager.courseDataManager.discussionManagerForCourseWithID(courseID).topics
        topics.backWithStream(stream.map {
            return DiscussionTopic.linearizeTopics($0)
            }
        )
        loadTopics()
    }
    
    func loadedData() {
        self.loadController.state = topics.value?.count == 0 ? LoadState.empty(icon: .noTopics, message : Strings.unableToLoadCourseContent) : .loaded
        self.tableView.reloadData()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: false)
        }
        
        self.environment.analytics.trackScreen(withName: OEXAnalyticsScreenViewTopics, courseID: self.courseID, value: nil)
        
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func reloadViewData() {
        refreshTopics()
    }
    
    override open var shouldAutorotate : Bool {
        return true
    }
    
    override open var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    // MARK: - TableView Data and Delegate
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
        case TableSection.allPosts.rawValue:
            return 1
        case TableSection.following.rawValue:
            return 1
        case TableSection.courseTopics.rawValue:
            return self.topics.value?.count ?? 0
        default:
            return 0
        }
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: DiscussionTopicCell.identifier, for: indexPath) as! DiscussionTopicCell
        
        var topic : DiscussionTopic? = nil
        
        switch (indexPath.section) {
        case TableSection.allPosts.rawValue:
            topic = DiscussionTopic(id: nil, name: Strings.allPosts, children: [DiscussionTopic](), depth: 0, icon:nil)
        case TableSection.following.rawValue:
            topic = DiscussionTopic(id: nil, name: Strings.postsImFollowing, children: [DiscussionTopic](), depth: 0, icon: Icon.followStar)
        case TableSection.courseTopics.rawValue:
            if let discussionTopic = self.topics.value?[indexPath.row] {
                topic = discussionTopic
            }
        default:
            assert(true, "Unknown section type.")
        }
        
        if let discussionTopic = topic {
            cell.topic = discussionTopic
        }
        return cell
    }
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.view.endEditing(true)
        
        switch (indexPath.section) {
        case TableSection.allPosts.rawValue:
            environment.router?.showAllPostsFromController(self, courseID: courseID, followedOnly: false)
        case TableSection.following.rawValue:
            environment.router?.showAllPostsFromController(self, courseID: courseID, followedOnly: true)
        case TableSection.courseTopics.rawValue:
            if let topic = self.topics.value?[indexPath.row] {
                    environment.router?.showPostsFromController(self, courseID: courseID, topic: topic)
            }
        default: ()
        }
        
        
    }
    
    open func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
}

extension DiscussionTopicsViewController {
    public func t_topicsLoaded() -> edXCore.Stream<[DiscussionTopic]> {
        return topics
    }
}
