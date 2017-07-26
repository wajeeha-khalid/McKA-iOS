//
//  OEXCoursewareViewController.swift
//  edX
//
//  Created by Naveen Katari on 24/01/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit


public enum CellType {
    case CompletedUnit
    case LiveUnit
    case LockedUnit
}

public enum TitleType {
    case NavTitle
    case CourseProgress
    case AssignmentCount
}


public class OEXCoursewareViewController: OfflineSupportViewController, UITableViewDelegate, UITableViewDataSource {
    
    public typealias Environment = protocol<OEXAnalyticsProvider, OEXConfigProvider, DataManagerProvider, NetworkManagerProvider, ReachabilityProvider, OEXRouterProvider, OEXInterfaceProvider, OEXRouterProvider, OEXSessionProvider, OEXConfigProvider>
    
    @IBOutlet weak var unitsTableView: UITableView!
    @IBOutlet weak var prevButton: UIButton!
    @IBOutlet weak var sectionTitleLabel: UILabel!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var sectionCountLabel: UILabel!
    @IBOutlet weak var sectionHidingView: UIView!
    @IBOutlet weak var navrTitleView: UIView!
    @IBOutlet weak var precentageCompletedLabel: UILabel!
    @IBOutlet weak var courseDurationLabel: UILabel!
    @IBOutlet weak var courseDurationTextLabel: UILabel!
    @IBOutlet weak var colonLabel: UILabel!
    
    private var rootID : CourseBlockID?
    private let courseID: String
    private var sectionIndex: Int = 0
    private let environment: Environment
    private let courseQuerier : CourseOutlineQuerier
    private let blockIDStream = BackedStream<CourseBlockID?>()
    private let headersLoader = BackedStream<CourseOutlineQuerier.BlockGroup>()
    private let rowsLoader = BackedStream<[CourseOutlineQuerier.BlockGroup]>()
    private let loadController : LoadStateViewController
    private var progressSpinner : SpinnerView = SpinnerView(size: .Large, color: .Primary)
    private var isTitle : Bool = true
    private var titleType : TitleType
    private var navigationTitle : String?
    var downloadController  : DownloadController
    var totalComponentsCount: Int = 0
    var viewedComponentsCount: Int = 0
    
    private var sections: [CourseOutlineQuerier.BlockGroup]?
    private var unitsForSelectedSection: [CourseBlock]?
    private var numberOfUnitsPerSection = [Int]()
    private var readStatusArray = [Int]()
    private var liveUnitIndex : Int?
    
    
    public init(environment: Environment, courseID: String, rootID : CourseBlockID?) {
        self.environment = environment
        self.courseID = courseID
        courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID)
        loadController = LoadStateViewController()
        titleType = TitleType.NavTitle
        downloadController  = DownloadController(courseQuerier: courseQuerier, analytics: environment.analytics)
        super.init(env : environment)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.unitsTableView.registerNib(UINib(nibName: "CourseUnitsViewCell", bundle: nil), forCellReuseIdentifier: "UnitsCell")
        self.unitsTableView.registerNib(UINib(nibName: "CourseLiveUnitViewCell", bundle:nil), forCellReuseIdentifier:"CourseLiveCell")
        loadController.setupInController(self, contentView: self.unitsTableView)
        
        let courseStream = BackedStream<UserCourseEnrollment>()
        courseStream.backWithStream(environment.dataManager.enrollmentManager.streamForCourseWithID(courseID))
        courseStream.listenOnce(self) {[weak self] in
            self?.resultLoaded($0)
            self?.unitsTableView.tableFooterView = UIView()
        }
        
        self.navigationTitle = self.navigationItem.title
        self.courseDurationLabel.hidden = true
        self.precentageCompletedLabel.hidden = true
        self.courseDurationTextLabel.hidden = true
        self.colonLabel.hidden = true
        self.sectionHidingView.hidden = true
        
        let backImage = UIImage (named : "ic_backchevron.png")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
        let attachmentImage = UIImage(named: "ic_attachment.png")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: attachmentImage, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(showHandouts))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: backImage, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(popAction))
        
        self.addListeners()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(receivedSavingNotification), name: kLocalSavingNotification, object: nil)
        
        // Register for download progress notifications
        for notification in OEXCoursewareViewController.getContentDownloadNotificationTypes() {
            NSNotificationCenter.defaultCenter().oex_addObserver(self, name: notification) { (notification, observer, _) -> Void in
                if let visibleIndexPaths = observer.unitsTableView.indexPathsForVisibleRows {
                    observer.unitsTableView.beginUpdates()
                    observer.unitsTableView.reloadRowsAtIndexPaths(visibleIndexPaths, withRowAnimation: .None)
                    observer.unitsTableView.endUpdates()
                }
            }
        }
		setupSectionNavButtons()
    }
    
    class func getContentDownloadNotificationTypes() -> [String] {
        return [OEXDownloadProgressChangedNotification, OEXDownloadEndedNotification]
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController!.navigationBar.backgroundColor = UIColor.clearColor()
        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        self.navigationController!.navigationBar.translucent = true
        self.navigationController?.view.backgroundColor = UIColor.clearColor()
        
        let titleTapRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(changeNavigationTitle))
        self.navigationController!.navigationBar.addGestureRecognizer(titleTapRecognizer)
        
        unitsTableView.reloadData()
    }
    
    public override func viewWillDisappear(animated: Bool)  {
        super.viewWillDisappear(animated)
        self.navigationController!.navigationBar.translucent = false
        self.navigationController?.navigationBar.gestureRecognizers!.forEach( (self.navigationController?.navigationBar.removeGestureRecognizer)!)
        self.navigationController?.navigationBar.backgroundColor = UIColor.clearColor()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(named: "Mountain_header.png"), forBarMetrics: UIBarMetrics.Default)
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override public func updateViewConstraints() {
        loadController.insets = UIEdgeInsets(top: self.topLayoutGuide.length + 64, left: 0, bottom: self.bottomLayoutGuide.length, right : 0)
        super.updateViewConstraints()
    }
    
    override func reloadViewData() {
        reload()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    //MARK: Tableview DataSource
    
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == liveUnitIndex {
            return 140.0
        } else {
            return 100.0
        }
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let unitsForSelectedSection = unitsForSelectedSection {
            return unitsForSelectedSection.count
        } else {
            return 0
        }
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        guard let unit = unitsForSelectedSection?[indexPath.row] else {
            return UITableViewCell()
        }
        
        if indexPath.row == liveUnitIndex {
            // The live cell
            
            let liveCell = tableView.dequeueReusableCellWithIdentifier("CourseLiveCell") as! CourseLiveUnitViewCell
                        
            liveCell.getCellDetails(unit, index: indexPath.row)
            
            
            // Added By Ravi on 1Mar'17 for AudioPOdcats. Please dont remove/Move this code. We need to capture the Sectionname and ChapterName
            let audioStream = self.courseQuerier.flatMapRootedAtBlockWithID(unit.blockID)
            {
                block in (block.type.asAudio != nil) ? block.blockID : nil
            }

            // Added By Ravi on 1Mar'17 for AudioPOdcats.Please dont remove/Move this code. We need to capture the Sectionname and ChapterName
            let audioBlock = audioStream.value?.description
            let group = self.sections?[self.sectionIndex]
            let chapterName = group?.block.displayName
            let sectionName = unit.displayName
            
            
            let audioIds  = OEXHelperAudioDownload()
            
            if(audioBlock != nil && audioBlock != "[]")
            {
                if(chapterName != nil)
                {
                    // Here we  capture the Sectionname and ChapterName
                    audioIds.chapterName = chapterName
                    audioIds.sectionName = sectionName
                    audioIds.course_id = courseQuerier.courseID;
                    
                    self.environment.dataManager.interface?.updateHelperObject(audioIds, audioid: audioBlock)
                    
                }
            }



            // Poulate data
            liveCell.maxUserLevel = unit.children.count ?? 0
            liveCell.currentUserLevel = readStatusArray[indexPath.row]
            
            // Download handling
            liveCell.unitID = unit.blockID
            liveCell.downloadState = downloadController.stateForUnitWithID(unit.blockID)
            
            liveCell.downloadActionBlock = { [weak self] (selectedUnitID, sender) in
                guard let blockSelf = self else { return }
                
                guard blockSelf.canDownloadVideo() else {
                    blockSelf.navigationController?.showOverlayMessage(Strings.noWifiMessage)
                    return
                }
                
                blockSelf.downloadController.downloadMediaForUnitWithID(selectedUnitID)
                sender.downloadState = blockSelf.downloadController.stateForUnitWithID(selectedUnitID)
            }
            
            liveCell.cancelActionBlock = { [weak self] (selectedUnitID, sender) in
                guard let blockSelf = self else { return }
                
                blockSelf.downloadController.cancelDownloadForUnitWithID(selectedUnitID)
                sender.downloadState = blockSelf.downloadController.stateForUnitWithID(selectedUnitID)
            }
            
            
            // Configure the left button
            if unit.discussionBlock != nil {
                let discussionButton = MGSwipeButton(title: "Discussion\nForum",
                                                     icon: UIImage(named: "ic_discussion"),
                                                     backgroundColor: UIColor(red: 0.0, green: 221.0/255.0, blue: 253.0/255.0, alpha: 1.0)) { [weak self] (sender: MGSwipeTableCell!) -> Bool in
                                                        
                                                        guard let blockSelf = self else {
                                                            return true
                                                        }

                                                        guard blockSelf.environment.reachability.isReachable() else {
                                                            blockSelf.navigationController?.showOverlayMessage("You are not connected to the Internet. Please check your Internet connection.")
                                                            return true
                                                        }
                                                        
                                                        if let discussionBlock = unit.discussionBlock, let controller = blockSelf.environment.router?.controllerForBlock(discussionBlock, courseID: blockSelf.courseID) {
                                                            
                                                            blockSelf.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
                                                            blockSelf.navigationController?.pushViewController(controller, animated: true)
                                                        }
                                                        
                                                        return true
                }
                let imageSize = discussionButton.imageView?.frame.size
                let titleSize = discussionButton.titleLabel?.frame.size
                let totalHeight = (imageSize!.height + titleSize!.height)
                discussionButton.imageEdgeInsets = UIEdgeInsetsMake(-(totalHeight - imageSize!.height), 32.0, 0.0, 0.0)
                discussionButton.titleEdgeInsets = UIEdgeInsetsMake(0.0, -20.0, -(totalHeight - titleSize!.height),0.0)
                liveCell.leftButtons = [discussionButton]
            } else {
                liveCell.leftButtons = []
            }
            
            liveCell.leftSwipeSettings.transition = .Drag
            
            // Configure right buttons
            if liveCell.downloadState.state == .Complete {
                let deleteButton = MGSwipeButton(title: "Remove\nDownload",
                                                 backgroundColor: UIColor(red: 253.0/255.0, green: 0.0, blue: 121.0/255.0, alpha: 1.0)) { [weak self] (sender: MGSwipeTableCell!) -> Bool in
                                                    
                                                    guard let blockSelf = self, let sender = sender as? CourseLiveUnitViewCell, let selectedUnitID = sender.unitID else {
                                                        return true
                                                    }
                                                    
                                                    blockSelf.downloadController.deleteDownloadsForUnitWithID(selectedUnitID)
                                                    sender.downloadState = blockSelf.downloadController.stateForUnitWithID(selectedUnitID)
                                                    
                                                    return true
                }
                liveCell.rightButtons = [deleteButton]
            } else {
                liveCell.rightButtons = []
            }
            
            liveCell.rightSwipeSettings.transition = .Drag
            
            
            return liveCell
            
        } else if indexPath.row < liveUnitIndex {
            
            // Completed cells
            let cell = tableView.dequeueReusableCellWithIdentifier("UnitsCell") as! CourseUnitsViewCell
            cell.previousUnitLabel.hidden = true
            cell.unitTitle.textColor = UIColor(red: 98/255, green: 101/255, blue: 103/255, alpha: 1)
            cell.getCellDetails(unit, index: indexPath.row)
            cell.statusImage.image = UIImage(named:"ic_completed")
            
            cell.unitID = unit.blockID
            cell.downloadState = downloadController.stateForUnitWithID(unit.blockID)
            
            
            
            // Added By Ravi on 1Mar'17 for AudioPOdcats. Please dont remove/Move this code. We need to capture the Sectionname and ChapterName
            let audioStream = self.courseQuerier.flatMapRootedAtBlockWithID(unit.blockID)
            {
                block in (block.type.asAudio != nil) ? block.blockID : nil
            }
            
            // Added By Ravi on 1Mar'17 for AudioPOdcats.Please dont remove/Move this code. We need to capture the Sectionname and ChapterName
            let audioBlock = audioStream.value?.description
            let group = self.sections?[self.sectionIndex]
            let chapterName = group?.block.displayName
            let sectionName = unit.displayName
            
            
            let audioIds  = OEXHelperAudioDownload()
            
            if(audioBlock != nil && audioBlock != "[]")
            {
                if(chapterName != nil)
                {
                    // Here we  capture the Sectionname and ChapterName
                    audioIds.chapterName = chapterName
                    audioIds.sectionName = sectionName
                    audioIds.course_id = courseQuerier.courseID;
                    
                    self.environment.dataManager.interface?.updateHelperObject(audioIds, audioid: audioBlock)
                    
                }
            }

            
            // Download handling
            cell.downloadActionBlock = { [weak self] (selectedUnitID, sender) in
                guard let blockSelf = self else { return }
                
                guard blockSelf.canDownloadVideo() else {
                    blockSelf.navigationController?.showOverlayMessage(Strings.noWifiMessage)
                    return
                }
                
                blockSelf.downloadController.downloadMediaForUnitWithID(selectedUnitID)
                sender.downloadState = blockSelf.downloadController.stateForUnitWithID(selectedUnitID)
            }
            
            cell.cancelActionBlock = { [weak self] (selectedUnitID, sender) in
                guard let blockSelf = self else { return }
                
                blockSelf.downloadController.cancelDownloadForUnitWithID(selectedUnitID)
                sender.downloadState = blockSelf.downloadController.stateForUnitWithID(selectedUnitID)
            }
            
            // Configure the left button
            if unit.discussionBlock != nil {
                let discussionButton = MGSwipeButton(title: "Discussion\nForum",
                                                     icon: UIImage(named: "ic_discussion"),
                                                     backgroundColor: UIColor(red: 0.0, green: 221.0/255.0, blue: 253.0/255.0, alpha: 1.0)) { [weak self] (sender: MGSwipeTableCell!) -> Bool in
                                                        
                                                        guard let blockSelf = self else {
                                                            return true
                                                        }

                                                        guard blockSelf.environment.reachability.isReachable() else {
                                                            blockSelf.navigationController?.showOverlayMessage("You are not connected to the Internet. Please check your Internet connection.")
                                                            return true
                                                        }

                                                        if let discussionBlock = unit.discussionBlock, let controller = blockSelf.environment.router?.controllerForBlock(discussionBlock, courseID: blockSelf.courseID) {
                                                            
                                                            blockSelf.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
                                                            blockSelf.navigationController?.pushViewController(controller, animated: true)
                                                        }
                                                        
                                                        return true
                }
                let imageSize = discussionButton.imageView?.frame.size
                let titleSize = discussionButton.titleLabel?.frame.size
                let totalHeight = (imageSize!.height + titleSize!.height)
                discussionButton.imageEdgeInsets = UIEdgeInsetsMake(-(totalHeight - imageSize!.height), 32.0, 0.0, 0.0)
                discussionButton.titleEdgeInsets = UIEdgeInsetsMake(0.0, -20.0, -(totalHeight - titleSize!.height),0.0)
                cell.leftButtons = [discussionButton]
            } else {
                cell.leftButtons = []
            }
            
            cell.leftSwipeSettings.transition = .Drag
            
            // Configure right buttons
            if cell.downloadState.state == .Complete {
                let deleteButton = MGSwipeButton(title: "Remove\nDownload",
                                                 backgroundColor: UIColor(red: 253.0/255.0, green: 0.0, blue: 121.0/255.0, alpha: 1.0)) { [weak self] (sender: MGSwipeTableCell!) -> Bool in
                                                    
                                                    guard let blockSelf = self, let sender = sender as? CourseUnitsViewCell, let selectedUnitID = sender.unitID else {
                                                        return true
                                                    }
                                                    
                                                    blockSelf.downloadController.deleteDownloadsForUnitWithID(selectedUnitID)
                                                    sender.downloadState = blockSelf.downloadController.stateForUnitWithID(selectedUnitID)
                                                    
                                                    return true
                }
                
                cell.rightButtons = [deleteButton]
            } else {
                cell.rightButtons = []
            }
            
            cell.rightSwipeSettings.transition = .Drag


            return cell
            
        } else {
            
            // Locked cells
            let cell = tableView.dequeueReusableCellWithIdentifier("UnitsCell") as! CourseUnitsViewCell
            
            cell.unitID = unit.blockID
            cell.downloadState = downloadController.stateForUnitWithID(unit.blockID)
            
            
            // Added By Ravi on 1Mar'17 for AudioPOdcats. Please dont remove/Move this code. We need to capture the Sectionname and ChapterName
            let audioStream = self.courseQuerier.flatMapRootedAtBlockWithID(unit.blockID)
            {
                block in (block.type.asAudio != nil) ? block.blockID : nil
            }
            
            // Added By Ravi on 1Mar'17 for AudioPOdcats.Please dont remove/Move this code. We need to capture the Sectionname and ChapterName
            let audioBlock = audioStream.value?.description
            let group = self.sections?[self.sectionIndex]
            let chapterName = group?.block.displayName
            let sectionName = unit.displayName
            
            
            let audioIds  = OEXHelperAudioDownload()
            
            if(audioBlock != nil && audioBlock != "[]")
            {
                if(chapterName != nil)
                {
                    // Here we  capture the Sectionname and ChapterName
                    audioIds.chapterName = chapterName
                    audioIds.sectionName = sectionName
                    audioIds.course_id = courseQuerier.courseID;
                    
                    self.environment.dataManager.interface?.updateHelperObject(audioIds, audioid: audioBlock)
                    
                }
            }

            cell.getCellDetails(unit, index: indexPath.row)
            cell.unitTitle.textColor = UIColor(red: 185/255, green: 185/255, blue: 185/255, alpha: 1)
            cell.previousUnitLabel.hidden = false
            if indexPath.row == 0 {
                cell.previousUnitLabel.text = "Please complete previous section to unlock"
            } else {
                cell.previousUnitLabel.text = "Complete Unit \(indexPath.row) to unlock"
            }
            cell.statusImage.image = UIImage(named:"ic_lock")
            
            // Configure the left button
            cell.leftButtons = []
            
            // Configure right buttons
            if cell.downloadState.state == .Complete {
                let deleteButton = MGSwipeButton(title: "Remove\nDownload",
                                                 backgroundColor: UIColor(red: 253.0/255.0, green: 0.0, blue: 121.0/255.0, alpha: 1.0)) { [weak self] (sender: MGSwipeTableCell!) -> Bool in
                                                    
                                                    guard let blockSelf = self, let sender = sender as? CourseUnitsViewCell, let selectedUnitID = sender.unitID else {
                                                        return true
                                                    }
                                                    
                                                    blockSelf.downloadController.deleteDownloadsForUnitWithID(selectedUnitID)
                                                    sender.downloadState = blockSelf.downloadController.stateForUnitWithID(selectedUnitID)
                                                    
                                                    return true
                }
                
                cell.rightButtons = [deleteButton]
            } else {
                cell.rightButtons = []
            }
            
            cell.rightSwipeSettings.transition = .Drag
            
            
            // Download handling
            cell.downloadActionBlock = { [weak self] (selectedUnitID, sender) in
                guard let blockSelf = self else { return }
                
                guard blockSelf.canDownloadVideo() else {
                    blockSelf.navigationController?.showOverlayMessage(Strings.noWifiMessage)
                    return
                }
                
                blockSelf.downloadController.downloadMediaForUnitWithID(selectedUnitID)
                sender.downloadState = blockSelf.downloadController.stateForUnitWithID(selectedUnitID)
            }
            
            cell.cancelActionBlock = { [weak self] (selectedUnitID, sender) in
                guard let blockSelf = self else { return }
                
                blockSelf.downloadController.cancelDownloadForUnitWithID(selectedUnitID)
                sender.downloadState = blockSelf.downloadController.stateForUnitWithID(selectedUnitID)
            }
            
            return cell
        }
    }
    
    
    //MARK: Table view delegate
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // Do not allow the user to browse locked units
        guard indexPath.row <= liveUnitIndex else {
            return
        }
        
        if let unit = unitsForSelectedSection?[indexPath.row], let section = sections?[sectionIndex] {
            
            // Do not allow the user to view not downloaded content
            let downloadState = downloadController.stateForUnitWithID(unit.blockID)
            if downloadState.state == .Active || downloadState.state == .Available {
                navigationController?.showOverlayMessage(OEXLocalizedString("NEED_TO_DOWNLOAD", nil))
                return
            }
            
            var targetStartingIndex = max(readStatusArray[indexPath.row] - 1, 0)
            if readStatusArray[indexPath.row] == unit.children.count{
                targetStartingIndex = 0
            }
            let initialComponent = targetStartingIndex < unit.children.count ? unit.children[targetStartingIndex] : unit.children.first
            
            if let controller = self.environment.router?.unitControllerForCourseID(courseID, sequentialID:unit.blockID, blockID: nil, initialChildID: initialComponent) {
                
                if let delegate = controller as? CourseContentPageViewControllerDelegate {
                    controller.navigationDelegate = delegate
                }
                
                controller.chapterID = section.block.blockID
                
                self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
    
    private func resultLoaded(result : Result<UserCourseEnrollment>) {
        switch result {
        case let .Success(enrollment):
            self.loadedCourseWithEnrollment(enrollment)
        case let .Failure(error):
            debugPrint("Enrollment error: \(error)")
            break
        }
    }
    
    private func loadedCourseWithEnrollment(enrollment: UserCourseEnrollment) {
        navigationItem.title = enrollment.course.name
    }
    
    
    //MARK: Prev and Next Button
    
    @IBAction func prevButtonAction(sender: AnyObject) {
        
        sectionIndex -= 1
        
        reloadUnitsForSelectedSection()
        
        rootID = getLiveUnitBlockID()
        reloadComponents()
        
        if let sections = sections {
            sectionCountLabel.text = "Section \(sectionIndex + 1) of \(sections.count)"
            sectionTitleLabel.text = sections[self.sectionIndex].block.displayName
        }

		setupSectionNavButtons()
    }
    
    @IBAction func nextButtonAction(sender: AnyObject) {
        sectionIndex += 1
        
        reloadUnitsForSelectedSection()
        
        rootID = getLiveUnitBlockID()
        reloadComponents()
        
        // UI adgastments
        if let sections = self.sections {
            sectionCountLabel.text = "Section \(sectionIndex + 1) of \(sections.count)"
            sectionTitleLabel.text = sections[self.sectionIndex].block.displayName
        }

		setupSectionNavButtons()
    }

	private func setupSectionNavButtons() {
		nextButton.hidden = true
		prevButton.hidden = true

		if let sections = self.sections {
			nextButton.hidden = (sectionIndex == sections.count - 1)
			prevButton.hidden = (sectionIndex == 0)
		}
	}

    @objc private func showHandouts() {
        self.environment.router?.showHandoutsFromController(self, courseID: courseID)
    }
    
    @objc private func popAction() {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    
    //MARK: Listener Method
    
    private func addListeners() {
        
        headersLoader.backWithStream(blockIDStream.transform {[weak self] blockID in
            if let owner = self {
                return owner.courseQuerier.childrenOfBlockWithID(self!.rootID)
            }
            else {
                return Stream<CourseOutlineQuerier.BlockGroup>(error: NSError.oex_courseContentLoadError())
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
                return Stream(error: NSError.oex_courseContentLoadError())
            }}
        )
        
        blockIDStream.backWithStream(Stream(value: rootID))
        
        headersLoader.listen(self, success: { headers in
            //self?.setupNavigationItem(headers.block)
            }, failure: {[weak self] error in
                self?.showErrorIfNecessary(error)
            }
        )
        
        rowsLoader.listen(self, success : {[weak self] (groups) in
            
            guard let blockSelf = self else { return }
            blockSelf.sectionHidingView.hidden = true
            
            if (blockSelf.rootID == nil) {
                
                blockSelf.sections = groups                               // Set the data source
                
                blockSelf.restoreViewedState()
                
                // Enable the next button if we have more than one sections
                blockSelf.setupSectionNavButtons()
                
                // Update the state
                blockSelf.loadController.state = groups.count == 0 ? blockSelf.emptyState() : .Loaded
                
                //
                if groups.count > blockSelf.sectionIndex {
                    
                    blockSelf.reloadUnitsForSelectedSection()
                    
                    let currentSection = groups[blockSelf.sectionIndex]
                    blockSelf.rootID = blockSelf.getLiveUnitBlockID()
                    
                    // Set the title
                    blockSelf.sectionTitleLabel.text = currentSection.block.displayName
                    blockSelf.sectionCountLabel.text = "Section \(blockSelf.sectionIndex + 1) of \(groups.count)"
                    
                    blockSelf.reloadComponents()
					let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
					dispatch_after(delayTime, dispatch_get_main_queue()) {
						blockSelf.showFTUE()
					}
                }
            }
            }, failure : {[weak self] error in
                self?.showErrorIfNecessary(error)
                
            }, finally: { _ in }
        )
    }
    
    
    //MARK: Error handling methods
    
    private func emptyState() -> LoadState {
        sectionHidingView.hidden = false
        return LoadState.empty(icon: .UnknownError, message : Strings.coursewareUnavailable)
    }
    
    private func showErrorIfNecessary(error : NSError) {
        if loadController.state.isInitial {
            sectionHidingView.hidden = false
            loadController.state = LoadState.failed(error)
        }
    }
    
    private func canDownloadVideo() -> Bool {
        let hasWifi = environment.reachability.isReachableViaWiFi() ?? false
        let onlyOnWifi = environment.dataManager.interface?.shouldDownloadOnlyOnWifi ?? false
        return !onlyOnWifi || hasWifi
    }
    
    
    //MARK : selector methods
    //TODO : Replace static text with the dynamic one once API is integrated
    @objc private func changeNavigationTitle(){
        if self.titleType == TitleType.NavTitle{
            //self.courseDurationLabel.hidden = false
            self.courseDurationTextLabel.hidden = false
            self.precentageCompletedLabel.hidden = false
            //self.courseDurationLabel.text = ""
            self.courseDurationTextLabel.text = ""
            
            let atrString = "Course Duration : 2 hours"
            
            let  myMutableString = NSMutableAttributedString(string: atrString, attributes: [NSFontAttributeName:UIFont(name: "Raleway-SemiBold", size: 14.0)!])
            
            myMutableString.addAttribute(NSForegroundColorAttributeName, value: UIColor.piqueGreen(), range: NSRange(location:18,length:7))
            
            courseDurationTextLabel.attributedText = myMutableString
            self.precentageCompletedLabel.text = "0% Complete"
            if totalComponentsCount > 0{
                let percentage = (Float(viewedComponentsCount)/Float(totalComponentsCount)) * 100
                self.precentageCompletedLabel.text = "(\(Int(min(percentage, 100)))% Complete)"
            }
            self.titleType = TitleType.CourseProgress
            self.navigationItem.title = ""
            //self.colonLabel.hidden = false
                    }
        else if self.titleType == TitleType.CourseProgress{

            //*** Uncomment when assignments needs to be shown ***///
            //self.courseDurationLabel.text = "Name"
            //self.courseDurationTextLabel.text = "Assignment 3"
            //self.precentageCompletedLabel.text = "(2 of 3 Complete)"
            //self.titleType = TitleType.AssignmentCount
            self.courseDurationTextLabel.hidden = true
            self.precentageCompletedLabel.hidden = true
            //self.colonLabel.hidden = true
            self.navigationItem.title = self.navigationTitle
            self.titleType = TitleType.NavTitle
        }
        else if self.titleType == TitleType.AssignmentCount{
            // self.courseDurationLabel.hidden = true
            self.courseDurationTextLabel.hidden = true
            self.precentageCompletedLabel.hidden = true
            //self.colonLabel.hidden = true
            self.navigationItem.title = self.navigationTitle
            self.titleType = TitleType.NavTitle
        }

    }
    
    @objc private func receivedSavingNotification() {
        
        if let recalculatedLiveUnitID = getLiveUnitBlockID() where rootID != recalculatedLiveUnitID {
            // The live unit changes, reload componet for the new rootID
            rootID = recalculatedLiveUnitID
        } else {
            reloadComponents()
        }
    }
    
    private func restoreViewedState() {
        
        //Viewed Key consuming logic added by Naveen
        if let sections = sections {
            
            totalComponentsCount = 0
            numberOfUnitsPerSection.removeAll()
            
            var index = 0
            
            sections.forEach({ (section) in
              
                numberOfUnitsPerSection.append(0)

                section.children.forEach({ (subsection) in
                    
                    // Get the units for each subsection
                    unitsForSubsectionWithID(subsection.blockID, success: { [unowned self] (units) in
                        
                        // Get the components for each unit
                        units.forEach({ (unit) in
                            
                            var isUnitCompleted : Bool?
                            
                            self.componentsForUnitWithID(unit.blockID, success: { (components) in
                                
                                components.forEach({ (component) in
                                    
                                    self.totalComponentsCount += 1
                                    
                                    if component.viewed == true {
                                        self.storeViewedStatus(component.blockID, viewed: component.viewed!, sequential_id: unit.blockID)
                                        isUnitCompleted = true
                                    }
                                    else{
                                        isUnitCompleted = false
                                    }
                                })
                                }, failure: { _ in }
                            )
                            
                            // Mark the unit completed if needed
                            if isUnitCompleted == true {
                                self.setCompletedStatusForUnits(unit.blockID, completed: true, chapter_id: section.block.blockID)
                            }
                            
                        })
                        
                        self.numberOfUnitsPerSection[index] += units.count
                        
                        }, failure: { _ in }
                    )
                })
                
                index += 1
            })
        }
    }
    
    private func reloadUnitsForSelectedSection() {
        
        if let currentSection = sections?[sectionIndex] {
            
            var totalUnits = [CourseBlock]()
            
            currentSection.children.forEach({ (subsection) in
              
                unitsForSubsectionWithID(subsection.blockID, success: { (units) in
                    totalUnits.appendContentsOf(units)
                    }, failure: { _ in })
            })
            
            unitsForSelectedSection = totalUnits
        }
    }
    
    private func reloadComponents() {
        
        // Go through all the sections and get the number of completed components
        if let unitsForSelectedSection = unitsForSelectedSection {
            
            readStatusArray.removeAll()         // Clear the previous read status
            
            for unit in unitsForSelectedSection {
                
                if let viewedComponents = environment.dataManager.interface?.getViewedComponentsForVertical(unit.blockID) {
                    readStatusArray.append(viewedComponents.count)
                } else {
                    readStatusArray.append(0)
                }
            }
        }
        
        if let components = self.environment.dataManager.interface?.getViewedComponentsForCourseID(courseID){
            viewedComponentsCount = components.count
        }
        
        progressView.setProgress(Float(viewedComponentsCount)/Float(totalComponentsCount), animated: true)
        unitsTableView.reloadData()
    }
    
    private func getLiveUnitBlockID() -> CourseBlockID? {
        
        if sectionIndex > 0 {
            
            // We need to calculate if the previous section is completed
            if let previousSection = sections?[sectionIndex-1] {
                
                if let completedUnits = environment.dataManager.interface?.getCompletedUnitsForChapterID(previousSection.block.blockID) {
                    
                    if numberOfUnitsPerSection[sectionIndex-1] > completedUnits.count {
                        // The previous section is not complete, lock it
                        liveUnitIndex = -1
                        return nil
                    }
                }
            }
        }
        
        if let unitsForSelectedSection = unitsForSelectedSection, let currentSection = sections?[sectionIndex] {
            
            if let completedUnits = environment.dataManager.interface?.getCompletedUnitsForChapterID(currentSection.block.blockID) {
                
                // Find the ids of all completed units
                var completedUnitBlockIDs = [String]()
                for unit in completedUnits {
                    
                    if let model = unit as? UnitData {
                        completedUnitBlockIDs.append(model.unitID)
                    }
                }
                
                // Find the first not completed unit and mark it as live
                var index = 0
                for unit in unitsForSelectedSection {
                    
                    if completedUnitBlockIDs.contains(unit.blockID) == false {
                        // We found a not completed unit
                        liveUnitIndex = index
                        return unit.blockID
                    }
                    
                    // Advance the index
                    index += 1
                }
                
                // If we reached this point all the units are completed, no live units
                liveUnitIndex = index
                return nil
            }
        }
        
        return nil
    }
    
    
    //MARK: Downloading components
    
    private func unitsForSubsectionWithID(subsectionID: CourseBlockID, success: ([CourseBlock]) -> Void, failure: (NSError) -> Void) {
        
        let subsectionStream = BackedStream<CourseBlockID>()
        subsectionStream.backWithStream(Stream(value: subsectionID))
        
        let componentsLoader = BackedStream<CourseOutlineQuerier.BlockGroup>()
        
        componentsLoader.backWithStream(subsectionStream.transform {[weak self] (blockID) in
            if let owner = self {
                return owner.courseQuerier.childrenOfBlockWithID(subsectionID)
            } else {
                return Stream<CourseOutlineQuerier.BlockGroup>(error: NSError.oex_courseContentLoadError())
            }})
        
        componentsLoader.listenOnce(self, success: { (components) in
            success(components.children)
            }, failure : { error in
                failure(error)
        })
    }

    private func componentsForUnitWithID(unitID: CourseBlockID, success: ([CourseBlock]) -> Void, failure: (NSError) -> Void) {
        
        let unitStream = BackedStream<CourseBlockID>()
        unitStream.backWithStream(Stream(value: unitID))
        
        let componentsLoader = BackedStream<CourseOutlineQuerier.BlockGroup>()
        
        componentsLoader.backWithStream(unitStream.transform {[weak self] (blockID) in
            if let owner = self {
                return owner.courseQuerier.childrenOfBlockWithID(unitID)
            } else {
                return Stream<CourseOutlineQuerier.BlockGroup>(error: NSError.oex_courseContentLoadError())
            }})
        
        componentsLoader.listenOnce(self, success: { (components) in
            success(components.children)
            }, failure : { error in
                failure(error)
        })
    }
    
    
    //MARK : Viewed Status
    func storeViewedStatus(component_id : String, viewed : Bool, sequential_id : String){
        let offlineTracker = OEXHelperOfflineTracker()
        offlineTracker.componentID = component_id
        offlineTracker.isViewed = viewed
        offlineTracker.unitID = sequential_id
        offlineTracker.courseID = courseID
        self.environment.dataManager.interface?.setViewedStatus(offlineTracker)
    }
    
    func setCompletedStatusForUnits(sequential_id : String, completed : Bool, chapter_id : String){
        let completionTracker = OEXHelperUnitCompletionTracker()
        completionTracker.isCompleted = completed
        completionTracker.unitID = sequential_id
        completionTracker.chapterID = chapter_id
        completionTracker.courseID = courseID
        self.environment.dataManager.interface?.setCompletedStatus(completionTracker)
    }
    
    
    //MARK: CourseWare -FTUE
    func showFTUE(){
		let showedFTUE = NSUserDefaults.standardUserDefaults().boolForKey("Course FTUE")
		guard !showedFTUE && liveUnitIndex == 0,
			let rootController = UIApplication.sharedApplication().delegate?.window??.rootViewController,
			let index = liveUnitIndex,
			let liveCell = unitsTableView.cellForRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0)) as? CourseLiveUnitViewCell,
			let levelView = liveCell.userLevelView  else { return }

		let coachController = CourseCoachmarkViewController()
		coachController.snapshotView = levelView.snapshotViewAfterScreenUpdates(true)
		coachController.titleText = navigationTitle

		rootController.addChildViewController(coachController)
		coachController.view.frame = rootController.view.bounds
		rootController.view.addSubview(coachController.view)
		coachController.didMoveToParentViewController(rootController)
		coachController.view.alpha = 0.01
		UIView.animateWithDuration(0.2) { 
			coachController.view.alpha = 1.0
		}
		NSUserDefaults.standardUserDefaults().setBool(true, forKey: "Course FTUE")
    }
    
    //MARK : Refresh View
    func reload() {
        self.blockIDStream.backWithStream(Stream(value : courseID))
    }
}
