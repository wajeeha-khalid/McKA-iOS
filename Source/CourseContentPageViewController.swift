//
//  CourseContentPageViewController.swift
//  edX
//
//  Created by Akiva Leffert on 5/1/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import MckinseyXBlocks



///Types(mostly vc's) that want to show custom actions in the bottom bar should implement this
/// protocol and return their custom actions. This protocol will be replaced once we get the
/// XBlock Protocol in master since that also has this property...
protocol ActionViewProvider {
    var actionView: UIView? { get }
}

extension ActionViewProvider where Self: XBlock {
    var actionView: UIView? {
        return self.primaryActionView
    }
}

extension MRQViewController: ActionViewProvider {
    
}

extension MCQViewController: ActionViewProvider {
    
}

extension AssessmentViewController: ActionViewProvider {}

extension FTPulleyManagerViewController: ActionViewProvider {
}

//This view is added as the titleView of navigationItem to display lesson title and module title
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
}

public protocol CourseContentPageViewControllerDelegate : class {
    func courseContentPageViewController(_ controller : CourseContentPageViewController, enteredBlockWithID blockID : CourseBlockID, parentID : CourseBlockID)
}

extension CourseBlockDisplayType {
    var isCacheable : Bool {
        switch self {
        case .video: return false
        case .mcq: return false
        case .mrq: return false
        case .assessment: return false
        case .freeText: return false
        case .ooyalaVideo: return false
        case .audio: return false //Added By Ravi on 22Jan'17 to Implement AudioPodcast
        case .unknown, .html(_), .outline, .lesson, .unit, .discussion: return true
        }
    }
}


// This is shown at the bottom to implement navigation and action items
class BottomBar: UIView {
    let rightButton: UIButton = UIButton()
    let leftButton: UIButton = UIButton()
    var actionView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let actionView = actionView {
                addSubview(actionView)
                actionView.snp.makeConstraints{ make in
                    make.center.equalTo(self)
                    make.leading.greaterThanOrEqualTo(leftButton.snp.trailing).offset(StandardHorizontalMargin)
                    make.trailing.lessThanOrEqualTo(rightButton.snp.leading).offset(-StandardHorizontalMargin)
                }
                
            }
        }
    }
    
    init() {
        super.init(frame: .zero)
        addSubview(rightButton)
        addSubview(leftButton)
        rightButton.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.trailing.equalTo(self).offset(-StandardHorizontalMargin)
        }
        leftButton.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
        }

        leftButton.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        rightButton.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        rightButton.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        rightButton.accessibilityLabel = "Next"
        leftButton.accessibilityLabel = "Previous"
        leftButton.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        let borderLine = UIView()
        addSubview(borderLine)
        borderLine.backgroundColor = UIColor(colorLiteralRed: 0.7, green: 0.7, blue: 0.7, alpha: 0.8)
        borderLine.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.width.equalTo(self)
            make.leading.equalTo(self)
            make.top.equalTo(self)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// Container for scrolling horizontally between different screens of course content
open class CourseContentPageViewController : UIViewController,UIPageViewControllerDataSource, UIPageViewControllerDelegate, CourseBlockViewController, StatusBarOverriding, InterfaceOrientationOverriding {
    
    public typealias Environment = OEXAnalyticsProvider & DataManagerProvider & OEXRouterProvider & OEXSessionProvider & NetworkManagerProvider & ReachabilityProvider & OEXInterfaceProvider

    fileprivate let pageViewController: UIPageViewController
    fileprivate let initialLoadController : LoadStateViewController
    fileprivate let environment : Environment
    fileprivate var componentID : CourseBlockID?
    fileprivate var sequentialID : CourseBlockID?
    private let bottomBar = BottomBar()
    open var chapterID : CourseBlockID?
    open fileprivate(set) var blockID : CourseBlockID?
    fileprivate let titleView = TitleView()
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
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        super.init(nibName: nil, bundle: nil)
        addChildViewController(pageViewController)
        view.addSubview(pageViewController.view)
        view.addSubview(bottomBar)
        bottomBar.snp.makeConstraints { make in
            make.height.equalTo(50)
            make.width.equalTo(view)
            make.leading.equalTo(view)
            make.bottom.equalTo(view)
        }
        
        pageViewController.view.snp.makeConstraints { make in
            make.top.equalTo(view)
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.bottom.equalTo(bottomBar.snp.top)
        }
        bottomBar.rightButton.addTarget(self, action: #selector(self.showNext), for: .touchUpInside)
        bottomBar.leftButton.addTarget(self, action: #selector(self.showPrev), for: .touchUpInside)
        pageViewController.didMove(toParentViewController: self)
        pageViewController.setViewControllers([initialLoadController], direction: .forward, animated: false, completion: nil)
       
        self.pageViewController.dataSource = self
        self.pageViewController.delegate = self
        
        let moduleListItem = UIBarButtonItem(image: #imageLiteral(resourceName: "ModuleListIcon"), style: .plain, target: self, action: #selector(self.showModuleList))
        navigationItem.rightBarButtonItem = moduleListItem
        addStreamListeners()
    }
    
    func showModuleList() {
        
        // a hack to quickly get the title without calculating
        let lessonTitle = titleView.lessonName
        
        courseQuerier.unitsForLesson(withID: self.blockID!).map {
            $0.enumerated().map({ (index, block) in
                ModuleViewModel(identifier: block.blockID, title: block.displayName, progress: .notStarted, duration: 9, number: index + 1)
            })
        }.extendLifetimeUntilFirstResult { result in
            switch result {
            case .success(let modules):
                
                let moduleListViewController = ModuleTableViewController(lessonTitle: lessonTitle ?? "", modules: modules)
                moduleListViewController.delegate = self
                let drawerViewController = BottomDrawerViewController(childViewController: moduleListViewController, scrollView: moduleListViewController.tableView)
                self.present(drawerViewController, animated: true, completion: nil)
            case _:
                break
            }
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        // required by the compiler because UIViewController implements NSCoding,
        // but we don't actually want to serialize these things
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewWillAppear(_ animated : Bool) {
        super.viewWillAppear(animated)
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
        guard let controller = pageViewController.viewControllers?.first else { return }
        storeViewedStatus()
        updateNavigationBars(controller)
    }

    func chatCompleted(_ notification: Notification) {
        guard let blockId = notification.userInfo?["blockId"] as? String else {
            return
        }

        storeViewedStatus(blockId: blockId)

        guard let controller = pageViewController.viewControllers?.first as? HTMLBlockViewController else { return }
        guard blockId == controller.blockID else { return }

        updateNavigationBars(controller, isChatCompleted: true)
    }
    
    fileprivate func addStreamListeners() {
        contentLoader.listen(self,
            success : {[weak self] cursor -> Void in
                if let owner = self,
                     let controller = owner.controllerForBlock(cursor.current.block)
                {
                    owner.pageViewController.setViewControllers([controller], direction: UIPageViewControllerNavigationDirection.forward, animated: false, completion: nil)
                    self?.updateNavigationForEnteredController(controller)
                }
                else {
                    self?.initialLoadController.state = LoadState.failed(NSError.oex_courseContentLoadError())
                    self?.updateNavigationBars()
                }
                
                return
            }, failure : {[weak self] error in

                self?.pageViewController.dataSource = nil
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
    
    fileprivate func updateNavigationBars(_ controller : UIViewController? = nil, isChatCompleted: Bool = false) {
        if let cursor = contentLoader.value {
        
            let item = cursor.current
            
            //update lesson id to track correct module list
            courseQuerier.blockWithID(item.parent)
                .transform {
                    self.courseQuerier.lessonContaining(unit: $0)
                }.extendLifetimeUntilFirstResult { result in
                    switch result {
                    case .success(let lesson):
                        self.blockID = lesson.blockID
                    case _:
                        break
                    }
            }
            
            
            // TODO: just leaving this if block here because it does some stuff related to course
            // progress. Once we implement progress we should Remove this from here...
            if let controller = controller {
                
                if let _ = unitCompletionPolicy(for: controller, itemId: item.block.blockID, chatCompleted: isChatCompleted), let _ = self.environment.interface {
                    if item.nextGroup != nil || cursor.hasNext == false {
                        setCompletedStatusForUnits()
                    }
                } else {
                    storeViewedStatus()
                    
                    if item.nextGroup != nil || cursor.hasNext == false {
                        setCompletedStatusForUnits()
                    }
                }
            }
            
            let nextGroup = item.nextGroup
            //update the navigation Items
            if let next = nextGroup {
                
                // find the lesson that contains current module
                let lessonOfCurrentUnit = courseQuerier.blockWithID(item.parent)
                    .transform {
                        self.courseQuerier.lessonContaining(unit: $0)
                }
                
                // find the lesson that contains next module
                let lessonOfNextUnit = courseQuerier.lessonContaining(unit: next)
                
                let nextStream: edXCore.Stream<(UIImage, String)> = joinStreams(lessonOfCurrentUnit, lessonOfNextUnit)
                .transform { (parentOfCurrent, parentOfNext) in
                    if parentOfCurrent.blockID == parentOfNext.blockID {
                        return Stream(value: (BrandingThemes.shared.nextModuleIcon, "Up Next: \(next.displayName)"))
                    } else {
                        return self.courseQuerier.parentOfBlockWithID(parentOfNext.blockID)
                            .transform {
                                self.courseQuerier.blockWithID($0)
                            }.map { course in
                               let index = course.children.index(of: parentOfNext.blockID)! + 1
                                return (BrandingThemes.shared.nextModuleIcon, "Up Next: Lesson \(index) \n \(next.displayName)")
                        }
                    }
                }
                
                nextStream.extendLifetimeUntilFirstResult(completion: { result in
                    switch result {
                    case let .success(icon, text):
                        let label = UILabel()
                        label.font = UIFont.systemFont(ofSize: 12.0)
                        label.textColor = UIColor.lightGray
                        label.numberOfLines = 2
                        label.textAlignment = .center
                        label.text = text
                        if let actionItem = (controller as? ActionViewProvider)?.actionView {
                            self.bottomBar.actionView = actionItem
                        } else {
                            self.bottomBar.actionView = label
                        }
                        self.bottomBar.rightButton.setImage(icon, for: .normal)
                    case _:
                        break
                    }
                })
            } else {
                self.bottomBar.actionView = (controller as? ActionViewProvider)?.actionView
                let icon = BrandingThemes.shared.nextComponentIcon
                bottomBar.rightButton.setImage(icon, for: .normal)
            }
            
            if let prev = item.prevGroup {
                
                // find the lesson that contains current module
                let lessonOfCurrentUnit = courseQuerier.blockWithID(item.parent)
                    .transform {
                        self.courseQuerier.lessonContaining(unit: $0)
                }
                
                // find the lesson that contains next module
                let lessonOfPrevUnit = courseQuerier.lessonContaining(unit: prev)
                joinStreams(lessonOfCurrentUnit, lessonOfPrevUnit)
                    .extendLifetimeUntilFirstResult(completion: { result in
                        switch result {
                        case let .success(currentLesson, prevLesson)
                            where currentLesson.blockID != prevLesson.blockID:
                            self.bottomBar.leftButton.setImage(BrandingThemes.shared.prevModuleIcon, for: .normal)
                        case _:
                            self.bottomBar.leftButton.setImage(BrandingThemes.shared.prevModuleIcon, for: .normal)
                        }
                })
            } else {
                bottomBar.leftButton.setImage(BrandingThemes.shared.prevComponentIcon, for: .normal)
            }
            
            //update navigationItem Titles
            courseQuerier.blockWithID(item.parent).transform { module in
                self.courseQuerier.lessonContaining(unit: module)
                    .map {
                        ($0, module)
                }
                }.map { (lesson, module) -> (String, String, Int, Int) in
                    let index = module.children.index(of: item.block.blockID)!
                    return (lesson.displayName, module.displayName, index + 1, module.children.count)
                }.extendLifetimeUntilFirstResult(completion: { (result) in
                    switch result {
                    case .success(let (lessonName, moduleName, currentModule, totalModules)):
                        self.titleView.lessonName = lessonName
                        self.titleView.moduleName = "\(moduleName) · \(currentModule) of \(totalModules)"
                        self.navigationController?.navigationBar.setNeedsLayout()
                        self.navigationController?.navigationBar.layoutIfNeeded()
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
            
            let shouldShowPrevious = item.prevGroup != nil || cursor.hasPrev
            let shouldShowNext = item.nextGroup != nil || cursor.hasNext
            switch (shouldShowPrevious, shouldShowNext) {
            case (true, true):
                bottomBar.rightButton.isHidden = false
                bottomBar.leftButton.isHidden = false
            case (true, false):
                bottomBar.rightButton.isHidden = true
                bottomBar.leftButton.isHidden = false
            case (false, true):
                bottomBar.rightButton.isHidden = false
                bottomBar.leftButton.isHidden = true
            case (false, false):
                bottomBar.rightButton.isHidden = true
                bottomBar.leftButton.isHidden = true
            }
        }
        else {
            bottomBar.rightButton.isHidden = true
            bottomBar.leftButton.isHidden = true
            bottomBar.actionView = nil
        }
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
        if let currentController = pageViewController.viewControllers?.first,
            let nextController = self.siblingWithDirection(direction, fromController: currentController)
        {
            pageViewController.setViewControllers([nextController], direction: direction, animated: true, completion: nil)
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
        if let controller = pageViewController.viewControllers?.last as? StatusBarOverriding as? UIViewController {
            return controller
        }
        else {
            return super.childViewControllerForStatusBarStyle
        }
    }
    
    override open var childViewControllerForStatusBarHidden : UIViewController? {
        if let controller = pageViewController.viewControllers?.last as? StatusBarOverriding as? UIViewController {
            return controller
        }
        else {
            return super.childViewControllerForStatusBarHidden
        }
        
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


extension CourseContentPageViewController: ModuleTableViewControllerDelegate {
    func moduleTableViewController(_ vc: ModuleTableViewController, didSelectModuleWithID moduleId: CourseBlockID) {
        dismiss(animated: true, completion: nil)
        
        let current = contentLoader.value?.current
        
        // if we are already in the selected module don't do anything
        if current?.parent == moduleId {
            return
        }
        
        contentLoader.value?.updateCurrentToItemMatching({ item in
            item.parent == moduleId
        })
        
        guard let newController = contentLoader.value?.current.block,
            let viewController = controllerForBlock(newController) else {
            return
        }
    
        pageViewController.setViewControllers([viewController], direction: .forward, animated: false, completion: nil)
        updateNavigationForEnteredController(viewController)
        
    }
}

// MARK: Testing
extension CourseContentPageViewController {
    public func t_blockIDForCurrentViewController() -> edXCore.Stream<CourseBlockID> {
        return contentLoader.flatMap {blocks in
            let controller = (self.pageViewController.viewControllers?.first as? CourseBlockViewController)
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
