//
//  CourseContentPageViewController.swift
//  edX
//
//  Created by Akiva Leffert on 5/1/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

public protocol CourseContentPageViewControllerDelegate : class {
    func courseContentPageViewController(_ controller : CourseContentPageViewController, enteredBlockWithID blockID : CourseBlockID, parentID : CourseBlockID)
}

extension CourseBlockDisplayType {
    var isCacheable : Bool {
        switch self {
        case .video: return false
        case .mcq: return false
        case .mrq: return false
        case .freeText: return false
        case .audio: return false //Added By Ravi on 22Jan'17 to Implement AudioPodcast
        case .unknown, .html(_), .outline, .lesson, .unit, .discussion: return true
        }
    }
}

// Container for scrolling horizontally between different screens of course content
open class CourseContentPageViewController : UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, CourseBlockViewController, StatusBarOverriding, InterfaceOrientationOverriding {
    
    public typealias Environment = OEXAnalyticsProvider & DataManagerProvider & OEXRouterProvider & OEXSessionProvider & NetworkManagerProvider & ReachabilityProvider & OEXInterfaceProvider
    
    fileprivate let initialLoadController : LoadStateViewController
    fileprivate let environment : Environment
    fileprivate var componentID : CourseBlockID?
    fileprivate var sequentialID : CourseBlockID?
    open var chapterID : CourseBlockID?
    open fileprivate(set) var blockID : CourseBlockID?
    open var courseID : String {
        return courseQuerier.courseID
    }
    
    fileprivate var openURLButtonItem : UIBarButtonItem?
    fileprivate var contentLoader = BackedStream<ListCursor<CourseOutlineQuerier.GroupItem>>()
    
    fileprivate let courseQuerier : CourseOutlineQuerier
    weak var navigationDelegate : CourseContentPageViewControllerDelegate?
    
    ///Manages the caching of the viewControllers that have been viewed atleast once.
    ///Removes the ViewControllers from memory in case of a memory warning
    fileprivate let cacheManager : BlockViewControllerCacheManager
    var components : [CourseOutlineQuerier.BlockGroup]? = []

    
    public init(environment : Environment, courseID : CourseBlockID, rootID : CourseBlockID?, sequentialID: CourseBlockID?, initialChildID: CourseBlockID? = nil) {
        self.environment = environment
        self.blockID = rootID
        self.sequentialID = sequentialID
        self.componentID = initialChildID
        courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID)
        initialLoadController = LoadStateViewController()
        cacheManager = BlockViewControllerCacheManager()
        
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        self.setViewControllers([initialLoadController], direction: .forward, animated: false, completion: nil)
        
        self.dataSource = self
        self.delegate = self
        
        addStreamListeners()
    }

    public required init?(coder aDecoder: NSCoder) {
        // required by the compiler because UIViewController implements NSCoding,
        // but we don't actually want to serialize these things
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewWillAppear(_ animated : Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(false, animated: animated)
        //getViewedComponentsList()
        courseQuerier.blockWithID(blockID).extendLifetimeUntilFirstResult (success:
            { block in
                self.environment.analytics.trackScreen(withName: OEXAnalyticsScreenUnitDetail, courseID: self.courseID, value: block.internalName)
            },
            failure: {
                Logger.logError("ANALYTICS", "Unable to load block: \($0)")
            }
        )
        loadIfNecessary()

		UIApplication.shared.isIdleTimerDisabled = true
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setToolbarHidden(true, animated: animated)
		UIApplication.shared.isIdleTimerDisabled = false
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = OEXStyles.shared.standardBackgroundColor()
        
        // This is super hacky. Controls like sliders - that depend on pan gestures were getting intercepted
        // by the page view's scroll view. This seemed like the only solution.
        // Filed http://www.openradar.appspot.com/radar?id=6188034965897216 against Apple to better expose
        // this API.
        // Verified on iOS9 and iOS 8
        if let scrollView = (self.view.subviews.flatMap { return $0 as? UIScrollView }).first {
            scrollView.delaysContentTouches = false
        }

        NotificationCenter.default.addObserver(self, selector: #selector(watchedStateDidChange(_:)), name: NSNotification.Name.OEXVRWatchedStateChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(chatCompleted(_:)), name: NSNotification.Name(rawValue: "ChatCompletedNotification"), object: nil)
    }

    func watchedStateDidChange(_ notification: Notification) {
        guard let blockId = notification.userInfo?["blockId"] as? String else { return }
        guard blockId == self.componentID else { return }
        guard let controller = viewControllers?.first else { return }

        storeViewedStatus()
        updateNavigationBars(controller)
    }

    func chatCompleted(_ notification: Notification) {
        guard let blockId = notification.userInfo?["blockId"] as? String else {
            return
        }

        storeViewedStatus(blockId: blockId)

        guard let controller = viewControllers?.first as? HTMLBlockViewController else { return }
        guard blockId == controller.blockID else { return }

        updateNavigationBars(controller, isChatCompleted: true)
    }
    
    fileprivate func addStreamListeners() {
        contentLoader.listen(self,
            success : {[weak self] cursor -> Void in
                if let owner = self,
                     let controller = owner.controllerForBlock(cursor.current.block)
                {
                    owner.setViewControllers([controller], direction: UIPageViewControllerNavigationDirection.forward, animated: false, completion: nil)
                    self?.updateNavigationForEnteredController(controller)
                }
                else {
                    self?.initialLoadController.state = LoadState.failed(NSError.oex_courseContentLoadError())
                    self?.updateNavigationBars()
                }
                
                return
            }, failure : {[weak self] error in
                self?.dataSource = nil
             self?.initialLoadController.state = LoadState.failed(NSError.oex_courseContentLoadError())
            }
        )
    }
    
    fileprivate func loadIfNecessary() {
        if !contentLoader.hasBacking {
            let stream = courseQuerier.spanningCursorForBlockWithID(self.sequentialID, initialChildID: componentID)
            contentLoader.backWithStream(stream.firstSuccess())
        }
    }
    
    fileprivate func toolbarItemWithGroupItem(_ item : CourseOutlineQuerier.GroupItem, adjacentGroup : CourseBlock?, direction : DetailToolbarButton.Direction, enabled : Bool) -> UIBarButtonItem {
        let titleText : String
        let moveDirection : UIPageViewControllerNavigationDirection
        let isGroup = adjacentGroup != nil
        
        switch direction {
        case .next:
            //titleText = isGroup ? Strings.nextUnit : Strings.next // Commented by Ravi as the Unit is changed to Section
            if contentLoader.value?.current.nextGroup != nil || contentLoader.value?.hasNext == false{
                titleText = Strings.nextSection
            }
            else{
                titleText = Strings.next
            }
            moveDirection = .forward
        case .prev:
            //titleText = isGroup ? Strings.previousUnit : Strings.previous // Commented by Ravi as the Unit is changed to Section
            titleText = isGroup ? Strings.previousSection : Strings.previous
            moveDirection = .reverse
        }
        
        let destinationText = "";// Added by Ravi on 10Mar'17 as the Text should be removed.   //adjacentGroup?.displayName
        
        let view = DetailToolbarButton(direction: direction, titleText: titleText, destinationText: destinationText) {[weak self] in
            self?.moveInDirection(moveDirection)
        }
        view.sizeToFit()
        
        let barButtonItem =  UIBarButtonItem(customView: view)
        barButtonItem.isEnabled = enabled
        view.button.isEnabled = enabled
        return barButtonItem
    }
    
    fileprivate func updateNavigationBars(_ controller : UIViewController? = nil, isChatCompleted: Bool = false) {
        if let cursor = contentLoader.value {
            let item = cursor.current
            
            self.componentID = item.block.blockID
            //            storeViewedStatus()
            if environment.reachability.isReachable(){
                let username = environment.session.currentUser?.username ?? ""
                environment.networkManager.updateCourseProgress(username, componentIDs: self.componentID!, onCompletion: { [weak self] (success) in
                    guard let blockSelf = self else { return }
                    if success == true{
                        blockSelf.environment.dataManager.interface?.updateViewedComponents(forID: blockSelf.componentID!, synced: true)
                    }
                    })
            }
            // setProgress(self.componentID!)
            
            // only animate change if we haven't set a title yet, so the initial set happens without
            // animation to make the push transition work right
            let actions : () -> Void = {
                self.navigationItem.title = item.block.displayName
            }
            if let navigationBar = navigationController?.navigationBar, navigationItem.title != nil {
                let animated = navigationItem.title != nil
                UIView.transition(with: navigationBar,
                                          duration: 0.3 * (animated ? 1.0 : 0.0), options: UIViewAnimationOptions.transitionCrossDissolve,
                                          animations: actions, completion: nil)
            }
            else {
                actions()
            }
            
            var shouldEnableNextButton = false
            
            if let controller = controller {
                
                if let unitCompleted = unitCompletionPolicy(for: controller, itemId: item.block.blockID, chatCompleted: isChatCompleted), let interface = self.environment.interface {
                    shouldEnableNextButton = unitCompleted(item.block.blockID, interface)
                    if item.nextGroup != nil || cursor.hasNext == false {
                        setCompletedStatusForUnits()
                    }
                } else {
                    storeViewedStatus()
                    shouldEnableNextButton = true
                    
                    if item.nextGroup != nil || cursor.hasNext == false {
                        setCompletedStatusForUnits()
                    }
                }
            }
            
            let prevItem = toolbarItemWithGroupItem(item, adjacentGroup: item.prevGroup, direction: .prev, enabled: cursor.hasPrev)
            var nextItem = toolbarItemWithGroupItem(item, adjacentGroup: item.nextGroup, direction: .next, enabled: shouldEnableNextButton)
            
            if item.nextGroup != nil || cursor.hasNext == false {
                nextItem = toolbarItemWithGroupItem(item, adjacentGroup: item.nextGroup, direction: .next, enabled:shouldEnableNextButton)
            }
            
            if item.prevGroup == nil && cursor.hasPrev == true {
                self.setToolbarItems(
                    [
                        prevItem,
                        UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                        nextItem
                    ], animated : true)
            } else {
                self.setToolbarItems(
                    [
                        
                        UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                        nextItem
                    ], animated : true)
            }
            
        }
        else {
            self.toolbarItems = []
        }
    }
    // MARK: Paging
    
    fileprivate func siblingWithDirection(_ direction : UIPageViewControllerNavigationDirection, fromController viewController: UIViewController) -> UIViewController? {
        let item : CourseOutlineQuerier.GroupItem?
        switch direction {
        case .forward:
            if contentLoader.value?.current.nextGroup != nil || contentLoader.value?.hasNext == false{
                self.navigationController?.popViewController(animated: true)
            }
            item = contentLoader.value?.peekNext()
        case .reverse:
            item = contentLoader.value?.peekPrev()
        }
        return item.flatMap {
            controllerForBlock($0.block)
        }
    }
    
    fileprivate func updateNavigationForEnteredController(_ controller : UIViewController?) {
        
        if let blockController = controller as? CourseBlockViewController,
            let cursor = contentLoader.value
        {
            cursor.updateCurrentToItemMatching {
                blockController.blockID == $0.block.blockID
            }
            environment.analytics.trackViewedComponentForCourse(withID: courseID, blockID: cursor.current.block.blockID)
            self.navigationDelegate?.courseContentPageViewController(self, enteredBlockWithID: cursor.current.block.blockID, parentID: cursor.current.parent)
        }
        self.updateNavigationBars(controller)
    }
    
    fileprivate func moveInDirection(_ direction : UIPageViewControllerNavigationDirection) {
        if let currentController = viewControllers?.first,
            let nextController = self.siblingWithDirection(direction, fromController: currentController)
        {
            self.setViewControllers([nextController], direction: direction, animated: true, completion: nil)
            self.updateNavigationForEnteredController(nextController)
        }
    }
    
    open func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let item : CourseOutlineQuerier.GroupItem = contentLoader.value?.current else {

            return viewController
        }
        if item.prevGroup != nil {
            return nil
        }
        else {
            return siblingWithDirection(.reverse, fromController: viewController)
        }
    }
    
    open func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let item : CourseOutlineQuerier.GroupItem = contentLoader.value?.current else { return pageViewController.viewControllers?.first }

        if item.nextGroup != nil {
            return nil
        }
        else {
            if let shouldNavigateForward = unitCompletionPolicy(for: viewController, itemId: item.block.blockID, chatCompleted: false), let interface = self.environment.interface {
                if shouldNavigateForward(item.block.blockID, interface) {
                    return siblingWithDirection(.forward, fromController: viewController)
                } else {
                    return nil
                }
            } else {
                return siblingWithDirection(.forward, fromController: viewController)
            }
        }
    }
    
    open func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        self.updateNavigationForEnteredController(pageViewController.viewControllers?.first)
    }
    
    func controllerForBlock(_ block : CourseBlock) -> UIViewController? {
        let blockViewController : UIViewController?
        
        if let cachedViewController = self.cacheManager.getCachedViewControllerForBlockID(block.blockID) {
            blockViewController = cachedViewController
        }
        else {
            // Instantiate a new VC from the router if not found in cache already
            if let viewController = self.environment.router?.controllerForBlock(block, courseID: courseQuerier.courseID) {
                if block.displayType.isCacheable {
                    cacheManager.addToCache(viewController, blockID: block.blockID)
                }
                blockViewController = viewController
            }
            else {
                blockViewController = UIViewController()
                assert(false, "Couldn't instantiate viewController for Block \(block)")
            }

        }
        
        if let viewController = blockViewController {
            preloadAdjacentViewControllersFromViewController(viewController)
            return viewController
        }
        else {
            assert(false, "Couldn't instantiate viewController for Block \(block)")
            return nil
        }
        
        
    }
    

    override open var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle(barStyle : self.navigationController?.navigationBar.barStyle)
    }
    
    override open var childViewControllerForStatusBarStyle : UIViewController? {
        if let controller = viewControllers?.last as? StatusBarOverriding as? UIViewController {
            return controller
        }
        else {
            return super.childViewControllerForStatusBarStyle
        }
    }
    
    override open var childViewControllerForStatusBarHidden : UIViewController? {
        if let controller = viewControllers?.last as? StatusBarOverriding as? UIViewController {
            return controller
        }
        else {
            return super.childViewControllerForStatusBarHidden
        }
        
    }
    
    override open var shouldAutorotate : Bool {
        return false
    }
    
    override open var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return [.portrait , .landscapeLeft , .landscapeRight]
    }
    
    fileprivate func preloadBlock(_ block : CourseBlock) {
        guard !cacheManager.cacheHitForBlockID(block.blockID) else {
            return
        }
        guard block.displayType.isCacheable else {
            return
        }
        guard let controller = self.environment.router?.controllerForBlock(block, courseID: courseQuerier.courseID) else {
            return
        }
        cacheManager.addToCache(controller, blockID: block.blockID)
        
        if let preloadable = controller as? PreloadableBlockController {
            preloadable.preloadData()
        }
    }

    fileprivate func preloadAdjacentViewControllersFromViewController(_ controller : UIViewController) {
        if let block = contentLoader.value?.peekNext()?.block {
            preloadBlock(block)
        }
        
        if let block = contentLoader.value?.peekPrev()?.block {
            preloadBlock(block)
        }
    }

//MARK : Offline
    func storeViewedStatus(blockId: CourseBlockID? = nil) {
        let offlineTracker = OEXHelperOfflineTracker()
        offlineTracker.componentID = blockId ?? componentID
        offlineTracker.isViewed = true
        offlineTracker.unitID = sequentialID
        offlineTracker.courseID = courseID

        self.environment.dataManager.interface?.setViewedStatus(offlineTracker)
    }
    
    fileprivate func setCompletedStatusForUnits() {
        let completionTracker = OEXHelperUnitCompletionTracker()
        completionTracker.isCompleted = true
        completionTracker.unitID = sequentialID
        completionTracker.courseID = courseID
        completionTracker.chapterID = chapterID
        self.environment.dataManager.interface?.setCompletedStatus(completionTracker)
    }
    
    //MARK : Set progres API
    func setProgress(_ componentIDs : String){
        let username = environment.session.currentUser?.username ?? ""
        let request = ProgressAPI.setProgressForCourse(username: username, componentIDs: componentIDs)
        _ = environment.networkManager.streamForRequest(request)
    }
}




// MARK: Testing
extension CourseContentPageViewController {
    public func t_blockIDForCurrentViewController() -> edXCore.Stream<CourseBlockID> {
        return contentLoader.flatMap {blocks in
            let controller = (self.viewControllers?.first as? CourseBlockViewController)
            let blockID = controller?.blockID
            let result = blockID.toResult()
            return result
        }
    }
    
    public var t_prevButtonEnabled : Bool {
        return self.toolbarItems![0].isEnabled
    }
    
    public var t_nextButtonEnabled : Bool {
        return self.toolbarItems![2].isEnabled
    }
    
    public func t_goForward() {
        moveInDirection(.forward)
    }
    
    public func t_goBackward() {
        moveInDirection(.reverse)
    }
    
    
    
    
}
