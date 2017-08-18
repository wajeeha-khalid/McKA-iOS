//
//  CourseOutlineViewController.swift
//  edX
//
//  Created by Akiva Leffert on 4/30/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import UIKit

open class CourseOutlineViewController :
    OfflineSupportViewController,
    CourseBlockViewController,
    CourseOutlineTableControllerDelegate,
    CourseContentPageViewControllerDelegate,
    CourseLastAccessedControllerDelegate,
    PullRefreshControllerDelegate
{
    public typealias Environment = OEXAnalyticsProvider & DataManagerProvider & OEXInterfaceProvider & NetworkManagerProvider & ReachabilityProvider & OEXRouterProvider & OEXSessionProvider

    
    fileprivate var rootID : CourseBlockID?
    fileprivate var environment : Environment
    
    fileprivate let courseQuerier : CourseOutlineQuerier
    fileprivate let tableController : CourseOutlineTableController
    
    fileprivate let blockIDStream = BackedStream<CourseBlockID?>()
    fileprivate let headersLoader = BackedStream<CourseOutlineQuerier.BlockGroup>()
    fileprivate let rowsLoader = BackedStream<[CourseOutlineQuerier.BlockGroup]>()
    
    fileprivate let loadController : LoadStateViewController
    fileprivate let insetsController : ContentInsetsController
    fileprivate var lastAccessedController : CourseLastAccessedController
    
    
    /// Strictly a test variable used as a trigger flag. Not to be used out of the test scope
    fileprivate var t_hasTriggeredSetLastAccessed = false
    
    open var blockID : CourseBlockID? {
        return blockIDStream.value ?? nil
    }
    
    open var courseID : String {
        return courseQuerier.courseID
    }
    
    public init(environment: Environment, courseID : String, rootID : CourseBlockID?) {
        self.rootID = rootID
        self.environment = environment
        courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID)
        
        loadController = LoadStateViewController()
        insetsController = ContentInsetsController()
        
        tableController = CourseOutlineTableController(environment : self.environment, courseID: courseID)
        
        lastAccessedController = CourseLastAccessedController(blockID: rootID , dataManager: environment.dataManager, networkManager: environment.networkManager, courseQuerier: courseQuerier)
        
        super.init(env: environment)
        
        lastAccessedController.delegate = self
        
        addChildViewController(tableController)
        tableController.didMove(toParentViewController: self)
        tableController.delegate = self
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        // required by the compiler because UIViewController implements NSCoding,
        // but we don't actually want to serialize these things
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = OEXStyles.shared.standardBackgroundColor()
        view.addSubview(tableController.view)
        
        loadController.setupInController(self, contentView:tableController.view)
        tableController.refreshController.setupInScrollView(tableController.tableView)
        tableController.refreshController.delegate = self
        
        insetsController.setupInController(self, scrollView : self.tableController.tableView)
        insetsController.addSource(tableController.refreshController)
        self.view.setNeedsUpdateConstraints()
        addListeners()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lastAccessedController.loadLastAccessed()
        lastAccessedController.saveLastAccessed()
        let stream = joinStreams(courseQuerier.rootID, courseQuerier.blockWithID(blockID))
        stream.extendLifetimeUntilFirstResult (success :
            { (rootID, block) in
                if self.blockID == rootID || self.blockID == nil {
                    self.environment.analytics.trackScreen(withName: OEXAnalyticsScreenCourseOutline, courseID: self.courseID, value: nil)
                }
                else {
                    self.environment.analytics.trackScreen(withName: OEXAnalyticsScreenSectionOutline, courseID: self.courseID, value: block.internalName)
                }
            },
            failure: {
                Logger.logError("ANALYTICS", "Unable to load block: \($0)")
            }
        )
    }
    
    override open var shouldAutorotate : Bool {
        return true
    }
    
    override open var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return .portrait
    }
    
    override open func updateViewConstraints() {
        loadController.insets = UIEdgeInsets(top: self.topLayoutGuide.length, left: 0, bottom: self.bottomLayoutGuide.length, right : 0)
        
        tableController.view.snp.updateConstraints {make in
            make.edges.equalTo(self.view)
        }
        super.updateViewConstraints()
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.insetsController.updateInsets()
    }
    
    override func reloadViewData() {
        reload()
    }
    
    fileprivate func setupNavigationItem(_ block : CourseBlock) {
        self.navigationItem.title = block.displayName
    }
    
    fileprivate func reload() {
        self.blockIDStream.backWithStream(edXCore.Stream(value : self.blockID))
    }
    
    fileprivate func emptyState() -> LoadState {
        return LoadState.empty(icon: .unknownError, message : Strings.coursewareUnavailable)
    }
    
    fileprivate func showErrorIfNecessary(_ error : NSError) {
        if self.loadController.state.isInitial {
            self.loadController.state = LoadState.failed(error)
        }
    }
    
    fileprivate func addListeners() {
        headersLoader.backWithStream(blockIDStream.transform {[weak self] blockID in
            if let owner = self {
                return owner.courseQuerier.childrenOfBlockWithID(blockID)
            }
            else {
                return edXCore.Stream<CourseOutlineQuerier.BlockGroup>(error: NSError.oex_courseContentLoadError())
            }}
        )
        rowsLoader.backWithStream(headersLoader.transform {[weak self] headers in
            if let owner = self {
                let children = headers.children.map {header in
                    return owner.courseQuerier.childrenOfBlockWithID(header.blockID)
                }
                return joinStreams(children)
            }
            else {
                return edXCore.Stream(error: NSError.oex_courseContentLoadError())
            }}
        )
        
        self.blockIDStream.backWithStream(edXCore.Stream(value: rootID))
        
        headersLoader.listen(self,
            success: {[weak self] headers in
                self?.setupNavigationItem(headers.block)
            },
            failure: {[weak self] error in
                self?.showErrorIfNecessary(error)
            }
        )
        
        rowsLoader.listen(self,
            success : {[weak self] groups in
                if let owner = self {
                    owner.tableController.groups = groups
                    owner.tableController.tableView.reloadData()
                    owner.loadController.state = groups.count == 0 ? owner.emptyState() : .loaded
                }
            },
            failure : {[weak self] error in
                self?.showErrorIfNecessary(error)
            },
            finally: {[weak self] in
                if let active = self?.rowsLoader.active, !active {
                    self?.tableController.refreshController.endRefreshing()
                }
            }
        )
    }

    // MARK: Outline Table Delegate
    
    func outlineTableControllerChoseShowDownloads(_ controller: CourseOutlineTableController) {
        environment.router?.showDownloads(from: self)
    }
    
    fileprivate func canDownloadVideo() -> Bool {
        let hasWifi = environment.reachability.isReachableViaWiFi() 
        let onlyOnWifi = environment.dataManager.interface?.shouldDownloadOnlyOnWifi ?? false
        return !onlyOnWifi || hasWifi
    }
    
    func outlineTableController(_ controller: CourseOutlineTableController, choseDownloadVideos videos: [OEXHelperVideoDownload], rootedAtBlock block:CourseBlock) {
        guard canDownloadVideo() else {
            self.showOverlayMessage(Strings.noWifiMessage)
            return
        }
        
        self.environment.dataManager.interface?.downloadVideos(videos)
        
        let courseID = self.courseID
        let analytics = environment.analytics
        
        courseQuerier.parentOfBlockWithID(block.blockID).listenOnce(self, success:
            { parentID in
                analytics.trackSubSectionBulkVideoDownload(parentID, subsection: block.blockID, courseID: courseID, videoCount: videos.count)
            },
            failure: {error in
                Logger.logError("ANALYTICS", "Unable to find parent of block: \(block). Error: \(error.localizedDescription)")
            }
        )
    }
    
    func outlineTableController(_ controller: CourseOutlineTableController, choseDownloadVideoForBlock block: CourseBlock) {
        
        guard canDownloadVideo() else {
            self.showOverlayMessage(Strings.noWifiMessage)
            return
        }
        
        self.environment.dataManager.interface?.downloadVideos(withIDs: [block.blockID], courseID: courseID)
        environment.analytics.trackSingleVideoDownload(block.blockID, courseID: courseID, unitURL: block.webURL?.absoluteString)
    }
    
    
    
    // Added BY Ravi on 27Jan2017 for Audio Download
    
    
    func outlineTableController(_ controller: CourseOutlineTableController, choseDownloadAudios audios: [OEXHelperAudioDownload], rootedAtBlock block:CourseBlock) {
        guard canDownloadVideo() else {
            self.showOverlayMessage(Strings.noWifiMessage)
            return
        }
        
        self.environment.dataManager.interface?.downloadAudios(audios)
        
//        let courseID = self.courseID
//        let analytics = environment.analytics
//        
//        courseQuerier.parentOfBlockWithID(block.blockID).listenOnce(self, success:
//            { parentID in
//                analytics.trackSubSectionBulkVideoDownload(parentID, subsection: block.blockID, courseID: courseID, videoCount: audios.count)
//            },
//                                                                    failure: {error in
//                                                                        Logger.logError("ANALYTICS", "Unable to find parent of block: \(block). Error: \(error.localizedDescription)")
//            }
//        )
    }

    
    func outlineTableController(_ controller: CourseOutlineTableController, choseDownloadAudioForBlock block: CourseBlock) {
        
        guard canDownloadVideo() else {
            self.showOverlayMessage(Strings.noWifiMessage)
            return
        }
        
        self.environment.dataManager.interface?.downloadAudios(withIDs: [block.blockID])
        environment.analytics.trackSingleAudioDownload(block.blockID, courseID: courseID, unitURL: block.webURL?.absoluteString)
    }
    
    
    
    func outlineTableController(_ controller: CourseOutlineTableController, choseBlock block: CourseBlock, withParentID parent : CourseBlockID) {
        self.environment.router?.showContainerForBlockWithID(block.blockID, type:block.displayType, parentID: parent, courseID: courseQuerier.courseID, fromController:self)
    }
    
    //MARK: PullRefreshControllerDelegate
    open func refreshControllerActivated(_ controller: PullRefreshController) {
        courseQuerier.needsRefresh = true
        reload()
    }
    
    //MARK: CourseContentPageViewControllerDelegate
    open func courseContentPageViewController(_ controller: CourseContentPageViewController, enteredBlockWithID blockID: CourseBlockID, parentID: CourseBlockID) {
        self.blockIDStream.backWithStream(courseQuerier.parentOfBlockWithID(parentID))
        self.tableController.highlightedBlockID = blockID
    }
    
    //MARK: LastAccessedControllerDeleagte
    open func courseLastAccessedControllerDidFetchLastAccessedItem(_ item: CourseLastAccessed?) {
        if let lastAccessedItem = item {
            self.tableController.showLastAccessedWithItem(lastAccessedItem)
        }
        else {
            self.tableController.hideLastAccessed()
        }
        
    }
}

extension CourseOutlineViewController {
    
    public func t_setup() -> edXCore.Stream<Void> {
        return rowsLoader.map { _ in
        }
    }
    
    public func t_currentChildCount() -> Int {
        return tableController.groups.count
    }
    
    public func t_populateLastAccessedItem(_ item : CourseLastAccessed) -> Bool {
        self.tableController.showLastAccessedWithItem(item)
        return self.tableController.tableView.tableHeaderView != nil

    }
    
    public func t_didTriggerSetLastAccessed() -> Bool {
        return t_hasTriggeredSetLastAccessed
    }
    
}
