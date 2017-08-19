//
//  OEXCoursewareViewController.swift
//  edX
//
//  Created by Naveen Katari on 24/01/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}



public enum CellType {
    case completedUnit
    case liveUnit
    case lockedUnit
}

public enum TitleType {
    case navTitle
    case courseProgress
    case assignmentCount
}


open class OEXCoursewareViewController: OfflineSupportViewController, UITableViewDelegate, UITableViewDataSource {
    
    public typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & NetworkManagerProvider & ReachabilityProvider & OEXRouterProvider & OEXInterfaceProvider & OEXRouterProvider & OEXSessionProvider & OEXConfigProvider
    
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
    
    fileprivate var rootID : CourseBlockID?
    fileprivate let courseID: String
    fileprivate var sectionIndex: Int = 0
    fileprivate let environment: Environment
    fileprivate let courseQuerier : CourseOutlineQuerier
    fileprivate let blockIDStream = BackedStream<CourseBlockID?>()
    fileprivate let headersLoader = BackedStream<CourseOutlineQuerier.BlockGroup>()
    fileprivate let rowsLoader = BackedStream<[CourseOutlineQuerier.BlockGroup]>()
    fileprivate let loadController : LoadStateViewController
    fileprivate var progressSpinner : SpinnerView = SpinnerView(size: .large, color: .primary)
    fileprivate var isTitle : Bool = true
    fileprivate var titleType : TitleType
    fileprivate var navigationTitle : String?
    var downloadController  : DownloadController
    var totalComponentsCount: Int = 0
    var viewedComponentsCount: Int = 0
    
    fileprivate var sections: [CourseOutlineQuerier.BlockGroup]?
    fileprivate var unitsForSelectedSection: [CourseBlock]?
    fileprivate var numberOfUnitsPerSection = [Int]()
    fileprivate var readStatusArray = [Int]()
    fileprivate var liveUnitIndex : Int?
    
    
    public init(environment: Environment, courseID: String, rootID : CourseBlockID?) {
        self.environment = environment
        self.courseID = courseID
        courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID)
        loadController = LoadStateViewController()
        titleType = TitleType.navTitle
        downloadController  = DownloadController(courseQuerier: courseQuerier, analytics: environment.analytics)
        super.init(env : environment)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.unitsTableView.register(UINib(nibName: "CourseUnitsViewCell", bundle: nil), forCellReuseIdentifier: "UnitsCell")
        self.unitsTableView.register(UINib(nibName: "CourseLiveUnitViewCell", bundle:nil), forCellReuseIdentifier:"CourseLiveCell")
        loadController.setupInController(self, contentView: self.unitsTableView)
        
        let courseStream = BackedStream<UserCourseEnrollment>()
        courseStream.backWithStream(environment.dataManager.enrollmentManager.streamForCourseWithID(courseID))
        courseStream.listenOnce(self) {[weak self] in
            self?.resultLoaded($0)
            self?.unitsTableView.tableFooterView = UIView()
        }
        
        self.navigationTitle = self.navigationItem.title
        self.courseDurationLabel.isHidden = true
        self.precentageCompletedLabel.isHidden = true
        self.courseDurationTextLabel.isHidden = true
        self.colonLabel.isHidden = true
        self.sectionHidingView.isHidden = true
        
        let backImage = UIImage (named : "ic_backchevron.png")!.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        let attachmentImage = UIImage(named: "ic_attachment.png")!.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: attachmentImage, style: UIBarButtonItemStyle.plain, target: self, action: #selector(showHandouts))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: backImage, style: UIBarButtonItemStyle.plain, target: self, action: #selector(popAction))
        
        self.addListeners()
        
        NotificationCenter.default.addObserver(self, selector: #selector(receivedSavingNotification), name: NSNotification.Name(rawValue: kLocalSavingNotification), object: nil)
        
        // Register for download progress notifications
        for notification in OEXCoursewareViewController.getContentDownloadNotificationTypes() {
            NotificationCenter.default.oex_addObserver( self, name: notification) { (notification, observer, _) -> Void in
                if let visibleIndexPaths = observer.unitsTableView.indexPathsForVisibleRows {
                    observer.unitsTableView.beginUpdates()
                    observer.unitsTableView.reloadRows(at: visibleIndexPaths, with: .none)
                    observer.unitsTableView.endUpdates()
                }
            }
        }
		setupSectionNavButtons()
    }
    
    class func getContentDownloadNotificationTypes() -> [String] {
        return [NSNotification.Name.OEXDownloadProgressChanged.rawValue, NSNotification.Name.OEXDownloadEnded.rawValue]
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController!.navigationBar.backgroundColor = UIColor.clear
        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        self.navigationController!.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = UIColor.clear
        
        let titleTapRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(changeNavigationTitle))
        self.navigationController!.navigationBar.addGestureRecognizer(titleTapRecognizer)
        
        unitsTableView.reloadData()
    }
    
    open override func viewWillDisappear(_ animated: Bool)  {
        super.viewWillDisappear(animated)
        self.navigationController!.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.gestureRecognizers!.forEach( (self.navigationController?.navigationBar.removeGestureRecognizer)!)
        self.navigationController?.navigationBar.backgroundColor = UIColor.clear
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(named: "Mountain_header.png"), for: UIBarMetrics.default)
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override open func updateViewConstraints() {
        loadController.insets = UIEdgeInsets(top: self.topLayoutGuide.length + 64, left: 0, bottom: self.bottomLayoutGuide.length, right : 0)
        super.updateViewConstraints()
    }
    
    override func reloadViewData() {
        reload()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    //MARK: Tableview DataSource
    
    open func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == liveUnitIndex {
            return 140.0
        } else {
            return 100.0
        }
    }
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let unitsForSelectedSection = unitsForSelectedSection {
            return unitsForSelectedSection.count
        } else {
            return 0
        }
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let unit = unitsForSelectedSection?[indexPath.row] else {
            return UITableViewCell()
        }
        
        if indexPath.row == liveUnitIndex {
            // The live cell
            
            let liveCell = tableView.dequeueReusableCell(withIdentifier: "CourseLiveCell") as! CourseLiveUnitViewCell
                        
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
            liveCell.maxUserLevel = unit.children.count 
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
                                                            
                                                            blockSelf.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
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
            
            liveCell.leftSwipeSettings.transition = .drag
            
            // Configure right buttons
            if liveCell.downloadState.state == .complete {
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
            
            liveCell.rightSwipeSettings.transition = .drag
            
            
            return liveCell
            
        } else if indexPath.row < liveUnitIndex {
            
            // Completed cells
            let cell = tableView.dequeueReusableCell(withIdentifier: "UnitsCell") as! CourseUnitsViewCell
            cell.previousUnitLabel.isHidden = true
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
                                                            
                                                            blockSelf.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
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
            
            cell.leftSwipeSettings.transition = .drag
            
            // Configure right buttons
            if cell.downloadState.state == .complete {
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
            
            cell.rightSwipeSettings.transition = .drag


            return cell
            
        } else {
            
            // Locked cells
            let cell = tableView.dequeueReusableCell(withIdentifier: "UnitsCell") as! CourseUnitsViewCell
            
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
            cell.previousUnitLabel.isHidden = false
            if indexPath.row == 0 {
                cell.previousUnitLabel.text = "Please complete previous section to unlock"
            } else {
                cell.previousUnitLabel.text = "Complete Unit \(indexPath.row) to unlock"
            }
            cell.statusImage.image = UIImage(named:"ic_lock")
            
            // Configure the left button
            cell.leftButtons = []
            
            // Configure right buttons
            if cell.downloadState.state == .complete {
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
            
            cell.rightSwipeSettings.transition = .drag
            
            
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
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Do not allow the user to browse locked units
        guard indexPath.row <= liveUnitIndex else {
            return
        }
        
        if let unit = unitsForSelectedSection?[indexPath.row], let section = sections?[sectionIndex] {
            
            // Do not allow the user to view not downloaded content
            let downloadState = downloadController.stateForUnitWithID(unit.blockID)
            if downloadState.state == .active || downloadState.state == .available {
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
                
                self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
    
    fileprivate func resultLoaded(_ result : Result<UserCourseEnrollment>) {
        switch result {
        case let .success(enrollment):
            self.loadedCourseWithEnrollment(enrollment)
        case let .failure(error):
            debugPrint("Enrollment error: \(error)")
            break
        }
    }
    
    fileprivate func loadedCourseWithEnrollment(_ enrollment: UserCourseEnrollment) {
        navigationItem.title = enrollment.course.name
    }
    
    
    //MARK: Prev and Next Button
    
    @IBAction func prevButtonAction(_ sender: AnyObject) {
        
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
    
    @IBAction func nextButtonAction(_ sender: AnyObject) {
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

	fileprivate func setupSectionNavButtons() {
		nextButton.isHidden = true
		prevButton.isHidden = true

		if let sections = self.sections {
			nextButton.isHidden = (sectionIndex == sections.count - 1)
			prevButton.isHidden = (sectionIndex == 0)
		}
	}

    @objc fileprivate func showHandouts() {
        self.environment.router?.showHandoutsFromController(self, courseID: courseID)
    }
    
    @objc fileprivate func popAction() {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    //MARK: Listener Method
    
    fileprivate func addListeners() {
        
        headersLoader.backWithStream(blockIDStream.transform {[weak self] blockID in
            if let owner = self {
                return owner.courseQuerier.childrenOfBlockWithID(self!.rootID)
            }
            else {
                return edXCore.Stream<CourseOutlineQuerier.BlockGroup>(error: NSError.oex_courseContentLoadError())
            }}
        )
        
        rowsLoader.backWithStream(headersLoader.transform {[weak self] headers in
            if let owner = self {
                let children = headers.children.filter{
                    header in header.displayName.lowercased().contains("discussion_course") == false
                    }.map {header in
                    return owner.courseQuerier.childrenOfBlockWithID(header.blockID)
                }
                return joinStreams(children)
            }
            else {
                return edXCore.Stream(error: NSError.oex_courseContentLoadError())
            }}
        )
        
        blockIDStream.backWithStream(edXCore.Stream(value: rootID))
        
        headersLoader.listen(self, success: { headers in
            //self?.setupNavigationItem(headers.block)
            }, failure: {[weak self] error in
                self?.showErrorIfNecessary(error)
            }
        )
        
        rowsLoader.listen(self, success : {[weak self] (groups) in
            
            guard let blockSelf = self else { return }
            blockSelf.sectionHidingView.isHidden = true
            
            if (blockSelf.rootID == nil) {
                
                blockSelf.sections = groups                               // Set the data source
                
                blockSelf.restoreViewedState()
                
                // Enable the next button if we have more than one sections
                blockSelf.setupSectionNavButtons()
                
                // Update the state
                blockSelf.loadController.state = groups.count == 0 ? blockSelf.emptyState() : .loaded
                
                //
                if groups.count > blockSelf.sectionIndex {
                    
                    blockSelf.reloadUnitsForSelectedSection()
                    
                    let currentSection = groups[blockSelf.sectionIndex]
                    blockSelf.rootID = blockSelf.getLiveUnitBlockID()
                    
                    // Set the title
                    blockSelf.sectionTitleLabel.text = currentSection.block.displayName
                    blockSelf.sectionCountLabel.text = "Section \(blockSelf.sectionIndex + 1) of \(groups.count)"
                    blockSelf.reloadComponents()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                        blockSelf.showFTUE()
                    })
                }
            }
            }, failure : {[weak self] error in
                self?.showErrorIfNecessary(error)
                
            }, finally: { _ in }
        )
    }
    
    
    //MARK: Error handling methods
    
    fileprivate func emptyState() -> LoadState {
        sectionHidingView.isHidden = false
        return LoadState.empty(icon: .unknownError, message : Strings.coursewareUnavailable)
    }
    
    fileprivate func showErrorIfNecessary(_ error : NSError) {
        if loadController.state.isInitial {
            sectionHidingView.isHidden = false
            loadController.state = LoadState.failed(error)
        }
    }
    
    fileprivate func canDownloadVideo() -> Bool {
        let hasWifi = environment.reachability.isReachableViaWiFi() 
        let onlyOnWifi = environment.dataManager.interface?.shouldDownloadOnlyOnWifi ?? false
        return !onlyOnWifi || hasWifi
    }
    
    
    //MARK : selector methods
    //TODO : Replace static text with the dynamic one once API is integrated
    @objc fileprivate func changeNavigationTitle(){
        if self.titleType == TitleType.navTitle{
            //self.courseDurationLabel.hidden = false
            self.courseDurationTextLabel.isHidden = false
            self.precentageCompletedLabel.isHidden = false
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
            self.titleType = TitleType.courseProgress
            self.navigationItem.title = ""
            //self.colonLabel.hidden = false
                    }
        else if self.titleType == TitleType.courseProgress{

            //*** Uncomment when assignments needs to be shown ***///
            //self.courseDurationLabel.text = "Name"
            //self.courseDurationTextLabel.text = "Assignment 3"
            //self.precentageCompletedLabel.text = "(2 of 3 Complete)"
            //self.titleType = TitleType.AssignmentCount
            self.courseDurationTextLabel.isHidden = true
            self.precentageCompletedLabel.isHidden = true
            //self.colonLabel.hidden = true
            self.navigationItem.title = self.navigationTitle
            self.titleType = TitleType.navTitle
        }
        else if self.titleType == TitleType.assignmentCount{
            // self.courseDurationLabel.hidden = true
            self.courseDurationTextLabel.isHidden = true
            self.precentageCompletedLabel.isHidden = true
            //self.colonLabel.hidden = true
            self.navigationItem.title = self.navigationTitle
            self.titleType = TitleType.navTitle
        }

    }
    
    @objc fileprivate func receivedSavingNotification() {
        
        if let recalculatedLiveUnitID = getLiveUnitBlockID(), rootID != recalculatedLiveUnitID {
            // The live unit changes, reload componet for the new rootID
            rootID = recalculatedLiveUnitID
        } else {
            reloadComponents()
        }
    }
    
    fileprivate func restoreViewedState() {
        
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
    
    fileprivate func reloadUnitsForSelectedSection() {
        
        if let currentSection = sections?[sectionIndex] {
            
            var totalUnits = [CourseBlock]()
            
            currentSection.children.forEach({ (subsection) in
              
                unitsForSubsectionWithID(subsection.blockID, success: { (units) in
                    totalUnits.append(contentsOf: units)
                    }, failure: { _ in })
            })
            
            unitsForSelectedSection = totalUnits
        }
    }
    
    fileprivate func reloadComponents() {
        
        // Go through all the sections and get the number of completed components
        if let unitsForSelectedSection = unitsForSelectedSection {
            
            readStatusArray.removeAll()         // Clear the previous read status
            
            for unit in unitsForSelectedSection {
                
                if let viewedComponents = environment.dataManager.interface?.getViewedComponents(forVertical: unit.blockID) {
                    readStatusArray.append(viewedComponents.count)
                } else {
                    readStatusArray.append(0)
                }
            }
        }
        
        if let components = self.environment.dataManager.interface?.getViewedComponents(forCourseID: courseID){
            viewedComponentsCount = components.count
        }
        
        progressView.setProgress(Float(viewedComponentsCount)/Float(totalComponentsCount), animated: true)
        unitsTableView.reloadData()
    }
    
    fileprivate func getLiveUnitBlockID() -> CourseBlockID? {
        
        if sectionIndex > 0 {
            
            // We need to calculate if the previous section is completed
            if let previousSection = sections?[sectionIndex-1] {
                
                if let completedUnits = environment.dataManager.interface?.getCompletedUnits(forChapterID: previousSection.block.blockID) {
                    
                    if numberOfUnitsPerSection[sectionIndex-1] > completedUnits.count {
                        // The previous section is not complete, lock it
                        liveUnitIndex = -1
                        return nil
                    }
                }
            }
        }
        
        if let unitsForSelectedSection = unitsForSelectedSection, let currentSection = sections?[sectionIndex] {
            
            if let completedUnits = environment.dataManager.interface?.getCompletedUnits(forChapterID: currentSection.block.blockID) {
                
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
    
    fileprivate func unitsForSubsectionWithID(_ subsectionID: CourseBlockID, success: @escaping ([CourseBlock]) -> Void, failure: @escaping (NSError) -> Void) {
        
        let subsectionStream = BackedStream<CourseBlockID>()
        subsectionStream.backWithStream(edXCore.Stream(value: subsectionID))
        
        let componentsLoader = BackedStream<CourseOutlineQuerier.BlockGroup>()
        
        componentsLoader.backWithStream(subsectionStream.transform {[weak self] (blockID) in
            if let owner = self {
                return owner.courseQuerier.childrenOfBlockWithID(subsectionID)
            } else {
                return edXCore.Stream<CourseOutlineQuerier.BlockGroup>(error: NSError.oex_courseContentLoadError())
            }})
        
        componentsLoader.listenOnce(self, success: { (components) in
            success(components.children)
            }, failure : { error in
                failure(error)
        })
    }

    fileprivate func componentsForUnitWithID(_ unitID: CourseBlockID, success: @escaping ([CourseBlock]) -> Void, failure: @escaping (NSError) -> Void) {
        
        let unitStream = BackedStream<CourseBlockID>()
        unitStream.backWithStream(edXCore.Stream(value: unitID))
        
        let componentsLoader = BackedStream<CourseOutlineQuerier.BlockGroup>()
        
        componentsLoader.backWithStream(unitStream.transform {[weak self] (blockID) in
            if let owner = self {
                return owner.courseQuerier.childrenOfBlockWithID(unitID)
            } else {
                return edXCore.Stream<CourseOutlineQuerier.BlockGroup>(error: NSError.oex_courseContentLoadError())
            }})
        
        componentsLoader.listenOnce(self, success: { (components) in
            success(components.children)
            }, failure : { error in
                failure(error)
        })
    }
    
    
    //MARK : Viewed Status
    func storeViewedStatus(_ component_id : String, viewed : Bool, sequential_id : String){
        let offlineTracker = OEXHelperOfflineTracker()
        offlineTracker.componentID = component_id
        offlineTracker.isViewed = viewed
        offlineTracker.unitID = sequential_id
        offlineTracker.courseID = courseID
        self.environment.dataManager.interface?.setViewedStatus(offlineTracker)
    }
    
    func setCompletedStatusForUnits(_ sequential_id : String, completed : Bool, chapter_id : String){
        let completionTracker = OEXHelperUnitCompletionTracker()
        completionTracker.isCompleted = completed
        completionTracker.unitID = sequential_id
        completionTracker.chapterID = chapter_id
        completionTracker.courseID = courseID
        self.environment.dataManager.interface?.setCompletedStatus(completionTracker)
    }
    
    
    //MARK: CourseWare -FTUE
    func showFTUE(){
		let showedFTUE = UserDefaults.standard.bool(forKey: "Course FTUE")
		guard !showedFTUE && liveUnitIndex == 0,
			let rootController = UIApplication.shared.delegate?.window??.rootViewController,
			let index = liveUnitIndex,
			let liveCell = unitsTableView.cellForRow(at: IndexPath(row: index, section: 0)) as? CourseLiveUnitViewCell,
			let levelView = liveCell.userLevelView  else { return }

		let coachController = CourseCoachmarkViewController()
		coachController.snapshotView = levelView.snapshotView(afterScreenUpdates: true)
		coachController.titleText = navigationTitle

		rootController.addChildViewController(coachController)
		coachController.view.frame = rootController.view.bounds
		rootController.view.addSubview(coachController.view)
		coachController.didMove(toParentViewController: rootController)
		coachController.view.alpha = 0.01
		UIView.animate(withDuration: 0.2, animations: { 
			coachController.view.alpha = 1.0
		}) 
		UserDefaults.standard.set(true, forKey: "Course FTUE")
    }
    
    //MARK : Refresh View
    func reload() {
        self.blockIDStream.backWithStream(edXCore.Stream(value : courseID))
    }
}
