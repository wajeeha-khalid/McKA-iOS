//
//  CourseContentPageViewController.swift
//  edX
//
//  Created by Akiva Leffert on 5/1/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation


protocol Command {
    var title: String { get }
    func execute()
}

protocol CommandProvider {
    var command: Command? { get }
}

final class BlockCommand: Command {
    var title: String {
        return "Submit"
    }
    
    func execute() {
        
    }
}

extension UIViewController: CommandProvider {
    var command: Command? {
        return nil
    }
}

fileprivate final class TitleView: UIView {
    
    private let lessonNameLabel = UILabel()
    private let moduleNameLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        //lessonName
        addSubview(lessonNameLabel)
        if #available(iOS 8.2, *) {
            lessonNameLabel.font = UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightSemibold)
        } else {
            lessonNameLabel.font = UIFont.systemFont(ofSize: 14.0)
        }
        lessonNameLabel.textColor = UIColor.white
        lessonNameLabel.numberOfLines = 1
        lessonNameLabel.textAlignment = .center
        
        addSubview(moduleNameLabel)
        moduleNameLabel.font = UIFont.systemFont(ofSize: 12.0)
        moduleNameLabel.textColor = UIColor(colorLiteralRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.7)
        moduleNameLabel.numberOfLines = 1
        moduleNameLabel.textAlignment = .center
        moduleNameLabel.lineBreakMode = .byTruncatingMiddle
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let lessonLabelSize = lessonNameLabel.sizeThatFits(size)
        let moduleNameLabelSize = moduleNameLabel.sizeThatFits(size)
        
        let height = lessonLabelSize.height + moduleNameLabelSize.height
        let width = min(max(moduleNameLabelSize.width, lessonLabelSize.width), size.width)
        return CGSize(width: width, height: height)
    }
    

    override func layoutSubviews() {
        let lessonLabelSize = lessonNameLabel.sizeThatFits(frame.size)
        lessonNameLabel.frame = CGRect(x: 0, y: 0, width: frame.width, height: lessonLabelSize.height)
        var lessonNameLabelCenter = lessonNameLabel.center
        lessonNameLabelCenter.x = frame.width / 2
        lessonNameLabel.center = lessonNameLabelCenter
        let moduleNameLabelSize = moduleNameLabel.sizeThatFits(frame.size)
        moduleNameLabel.frame = CGRect(x: 0, y: lessonNameLabel.frame.height, width: frame.width, height: moduleNameLabelSize.height)
        var moduleNameLabelCenter = moduleNameLabel.center
        moduleNameLabelCenter.x = frame.width / 2
        moduleNameLabel.center = moduleNameLabelCenter
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var lessonName: String? {
        didSet {
            lessonNameLabel.text = lessonName
        }
    }
    var moduleName: String? {
        didSet {
            moduleNameLabel.text = moduleName
        }
    }
    var currentComponent: Int?
    var totalComponents: Int?
}

public protocol CourseContentPageViewControllerDelegate : class {
    func courseContentPageViewController(_ controller : CourseContentPageViewController, enteredBlockWithID blockID : CourseBlockID, parentID : CourseBlockID)
}

extension CourseBlockDisplayType {
    var isCacheable : Bool {
        switch self {
        case .video: return false
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
    fileprivate let titleView = TitleView()
    open var courseID : String {
        return courseQuerier.courseID
    }
    
    var commandToExecute: Command?
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
        self.navigationController?.toolbar.tintColor = UIColor.blue
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
        navigationItem.titleView = titleView
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
            if let seqID = self.sequentialID {
                let stream = courseQuerier.spanningCursorForBlockWithID(seqID, initialChildID: componentID)
                contentLoader.backWithStream(stream.firstSuccess())
            } else if let blockID = self.blockID {
                courseQuerier.unitsForLesson(withID: blockID).extendLifetimeUntilFirstResult { result in
                    switch result {
                    case .success(let units):
                        self.sequentialID = units.first?.blockID
                        let stream = self.courseQuerier.spanningCursorForBlockWithID(self.sequentialID, initialChildID: nil)
                        self.contentLoader.backWithStream(stream.firstSuccess())
                    case .failure:
                        break
                    }
                }
            }
        }
    }
    
    func showNext() {
        moveInDirection(.forward)
    }
    
    func showPrev() {
        moveInDirection(.reverse)
    }
    
    fileprivate func toolbarItemWithGroupItem(_ item : CourseOutlineQuerier.GroupItem, adjacentGroup : CourseBlock?, direction : DetailToolbarButton.Direction, enabled : Bool) -> UIBarButtonItem {
        
        switch direction {
        case .next:
            
            let upcomingModule = contentLoader.value?.current.nextGroup
            if upcomingModule != nil {
                let image = #imageLiteral(resourceName: "Icon_NextModule").withRenderingMode(.alwaysOriginal)
                return UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(self.showNext))
            }
            else{
                return UIBarButtonItem(image: #imageLiteral(resourceName: "Icon_NextComponent").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(self.showNext))
            }
        case .prev:
            let previousModule = contentLoader.value?.current.prevGroup
            if previousModule != nil {
                return UIBarButtonItem(image: #imageLiteral(resourceName: "Icon_PreviousModule").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(self.showPrev))
            } else if contentLoader.value?.hasPrev == true {
               return UIBarButtonItem(image: #imageLiteral(resourceName: "Icon_PrevComponent").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(self.showPrev))
            } else {
                return UIBarButtonItem()
            }
        }
    }
    
    
    fileprivate func updateNavigationBars(_ controller : UIViewController? = nil, isChatCompleted: Bool = false) {
        if let cursor = contentLoader.value {
            let item = cursor.current
            
            courseQuerier.blockWithID(item.parent).transform { module in
                self.courseQuerier.parentOfBlockWithID(module.blockID)
                    .transform{ lessonID in  self.courseQuerier.blockWithID(lessonID) }
                    .map { lesson in
                    return (module.displayName, lesson.displayName)
                    }.map { (moduleName, lessonName) -> (String, String, Int, Int) in
                        let index = module.children.index(of: item.block.blockID) ?? 0
                        return (moduleName, lessonName, index + 1, module.children.count)
                }
            }.extendLifetimeUntilFirstResult(completion: { (result) in
                switch result {
                case .success(let (moduleName, lessonName, currentModule, totalModules)):
                    self.titleView.lessonName = lessonName
                    self.titleView.moduleName = "\(moduleName) . \(currentModule) of \(totalModules)"
                    self.titleView.sizeToFit()
                case .failure:
                    break
                }
            })
            
            self.componentID = item.block.blockID
            if environment.reachability.isReachable(){
                let username = environment.session.currentUser?.username ?? ""
                environment.networkManager.updateCourseProgress(username, componentIDs: self.componentID!, onCompletion: { [weak self] (success) in
                    guard let blockSelf = self else { return }
                    if success == true{
                        blockSelf.environment.dataManager.interface?.updateViewedComponents(forID: blockSelf.componentID!, synced: true)
                    }
                    })
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
            
            let shouldShowPrevious = item.prevGroup != nil || cursor.hasPrev
            let shouldShowNext = item.nextGroup != nil || cursor.hasNext
            let vc = viewControllers?.first
            let actionItem = vc?.command.map { command -> UIBarButtonItem in
                let button = UIButton(type: .custom)
                button.layer.cornerRadius = 14.0
                button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 15, bottom: 5, right: 15)
                button.addTarget(self, action: #selector(self.executeCommand), for: .touchUpInside)
                button.backgroundColor = UIColor(red:38/255.0, green:144/255.0, blue:240/255.0, alpha:1)
                if #available(iOS 8.2, *) {
                    button.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFontWeightSemibold)
                }
                button.setTitle(command.title, for: .normal)
                button.sizeToFit()
                return UIBarButtonItem(customView: button)
            }
            commandToExecute = vc?.command
            let centerItems: [UIBarButtonItem]
            if let item = actionItem {
                centerItems = [
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                item,
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                ]
            } else if let upcomingModule = item.nextGroup {
                let label = UILabel()
                label.text = "Up Next: \(upcomingModule.displayName)"
                let item  = UIBarButtonItem(customView: label)
                label.sizeToFit()
                label.textColor = UIColor.lightGray
                label.font = UIFont.systemFont(ofSize: 12.0)
                let x = UIBarButtonItem(title: label.text, style: .plain, target: nil, action: nil)
                centerItems = [
                    UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                    x,
                    UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                ]
            } else {
                centerItems = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),]
            }
            switch (shouldShowPrevious, shouldShowNext) {
            case (true, true):
                self.setToolbarItems(
                    [prevItem] + centerItems + [nextItem], animated : true)
            case (true, false):
                self.setToolbarItems(
                    [prevItem] + centerItems, animated : true)
            case (false, true):
                self.setToolbarItems(
                    centerItems + [nextItem], animated : true)
            case (false, false):
                self.setToolbarItems(
                   centerItems, animated : true)
            }
        }
        else {
            self.toolbarItems = []
        }
    }
    
    func executeCommand() {
        commandToExecute?.execute()
    }
    // MARK: Paging
    
    fileprivate func siblingWithDirection(_ direction : UIPageViewControllerNavigationDirection, fromController viewController: UIViewController) -> UIViewController? {
        let item : CourseOutlineQuerier.GroupItem?
        switch direction {
        case .forward:
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
