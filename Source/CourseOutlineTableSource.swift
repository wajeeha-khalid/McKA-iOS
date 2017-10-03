//
//  CourseOutlineTableSource.swift
//  edX
//
//  Created by Akiva Leffert on 4/30/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

protocol CourseOutlineTableControllerDelegate : class {
    func outlineTableController(_ controller : CourseOutlineTableController, choseBlock:CourseBlock, withParentID:CourseBlockID)
    func outlineTableController(_ controller : CourseOutlineTableController, choseDownloadVideos videos:[OEXHelperVideoDownload], rootedAtBlock block: CourseBlock)
    func outlineTableController(_ controller : CourseOutlineTableController, choseDownloadVideoForBlock block:CourseBlock)
    func outlineTableController(_ controller : CourseOutlineTableController, choseDownloadAudios audios:[OEXHelperAudioDownload], rootedAtBlock block: CourseBlock)
    func outlineTableController(_ controller : CourseOutlineTableController, choseDownloadAudioForBlock block:CourseBlock)
    func outlineTableControllerChoseShowDownloads(_ controller : CourseOutlineTableController)
}

class CourseOutlineTableController : UITableViewController, CourseVideoTableViewCellDelegate, CourseAudioTableViewCellDelegate, CourseSectionTableViewCellDelegate {
    
    typealias Environment = DataManagerProvider & OEXInterfaceProvider
    
    weak var delegate : CourseOutlineTableControllerDelegate?
    fileprivate let environment : Environment
    fileprivate let courseQuerier : CourseOutlineQuerier
    
    fileprivate let headerContainer = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 44))
    fileprivate let lastAccessedView = CourseOutlineHeaderView(frame: CGRect.zero, styles: OEXStyles.shared, titleText : Strings.lastAccessed, subtitleText : "Placeholder")
    let refreshController = PullRefreshController()
    
    init(environment : Environment, courseID : String) {
        self.environment = environment
        self.courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var groups : [CourseOutlineQuerier.BlockGroup] = []
    var highlightedBlockID : CourseBlockID? = nil
    
    override func viewDidLoad() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.register(CourseOutlineHeaderCell.self, forHeaderFooterViewReuseIdentifier: CourseOutlineHeaderCell.identifier)
        tableView.register(CourseVideoTableViewCell.self, forCellReuseIdentifier: CourseVideoTableViewCell.identifier)
        tableView.register(CourseHTMLTableViewCell.self, forCellReuseIdentifier: CourseHTMLTableViewCell.identifier)
        tableView.register(CourseProblemTableViewCell.self, forCellReuseIdentifier: CourseProblemTableViewCell.identifier)
        tableView.register(CourseUnknownTableViewCell.self, forCellReuseIdentifier: CourseUnknownTableViewCell.identifier)
        tableView.register(CourseSectionTableViewCell.self, forCellReuseIdentifier: CourseSectionTableViewCell.identifier)
        tableView.register(DiscussionTableViewCell.self, forCellReuseIdentifier: DiscussionTableViewCell.identifier)
        tableView.register(CourseAudioTableViewCell.self, forCellReuseIdentifier: CourseAudioTableViewCell.identifier) //Added By Ravi on 22Jan'17 to Implement AudioPodcast


        
        headerContainer.addSubview(lastAccessedView)
        lastAccessedView.snp.makeConstraints { (make) -> Void in
            make.edges.equalTo(self.headerContainer)
        }
        
        refreshController.setupInScrollView(self.tableView)
    }
    
    fileprivate func indexPathForBlockWithID(_ blockID : CourseBlockID) -> IndexPath? {
        for (i, group) in groups.enumerated() {
            for (j, block) in group.children.enumerated() {
                if block.blockID == blockID {
                    return IndexPath(row: j, section: i)
                }
            }
        }
        return nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let path = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: path, animated: false)
        }
        if let highlightID = highlightedBlockID, let indexPath = indexPathForBlockWithID(highlightID)
        {
            tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.middle, animated: false)
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return groups.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let group = groups[section]
        return group.children.count
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Will remove manual heights when dropping iOS7 support and move to automatic cell heights.
        return 60.0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let group = groups[section]
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: CourseOutlineHeaderCell.identifier) as! CourseOutlineHeaderCell
        header.block = group.block
        return header
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let group = groups[indexPath.section]
        let nodes = group.children
        let block = nodes[indexPath.row]
        switch nodes[indexPath.row].displayType {
        case .video:
            let cell = tableView.dequeueReusableCell(withIdentifier: CourseVideoTableViewCell.identifier, for: indexPath) as! CourseVideoTableViewCell
            cell.block = block
            cell.localState = environment.dataManager.interface?.stateForVideo(withID: block.blockID, courseID : courseQuerier.courseID)
            cell.delegate = self
            return cell
        case .audio:
            let cell = tableView.dequeueReusableCell(withIdentifier: CourseAudioTableViewCell.identifier, for: indexPath) as! CourseAudioTableViewCell
            cell.block = block
            cell.localState = environment.dataManager.interface?.stateForAudio(withID: block.blockID)
            cell.delegate = self
            return cell
        case .html(.base):
            let cell = tableView.dequeueReusableCell(withIdentifier: CourseHTMLTableViewCell.identifier, for: indexPath) as! CourseHTMLTableViewCell
            cell.block = block
            return cell
        case .html(.problem):
            let cell = tableView.dequeueReusableCell(withIdentifier: CourseProblemTableViewCell.identifier, for: indexPath) as! CourseProblemTableViewCell
            cell.block = block
            return cell
        case .poll(.base):
            let cell = tableView.dequeueReusableCell(withIdentifier: CourseHTMLTableViewCell.identifier, for: indexPath) as! CourseHTMLTableViewCell
            cell.block = block
            return cell
        case .poll(.problem):
            let cell = tableView.dequeueReusableCell(withIdentifier: CourseProblemTableViewCell.identifier, for: indexPath) as! CourseProblemTableViewCell
            cell.block = block
            return cell
        case .survey(.base):
            let cell = tableView.dequeueReusableCell(withIdentifier: CourseHTMLTableViewCell.identifier, for: indexPath) as! CourseHTMLTableViewCell
            cell.block = block
            return cell
        case .survey(.problem):
            let cell = tableView.dequeueReusableCell(withIdentifier: CourseProblemTableViewCell.identifier, for: indexPath) as! CourseProblemTableViewCell
            cell.block = block
            return cell
        case .imageExplorer(.base):
            let cell = tableView.dequeueReusableCell(withIdentifier: CourseHTMLTableViewCell.identifier, for: indexPath) as! CourseHTMLTableViewCell
            cell.block = block
            return cell
        case .imageExplorer(.problem):
            let cell = tableView.dequeueReusableCell(withIdentifier: CourseProblemTableViewCell.identifier, for: indexPath) as! CourseProblemTableViewCell
            cell.block = block
            return cell
        case .unknown:
            let cell = tableView.dequeueReusableCell(withIdentifier: CourseUnknownTableViewCell.identifier, for: indexPath) as! CourseUnknownTableViewCell
            cell.block = block
            return cell
        case .outline, .unit, .lesson:
            let cell = tableView.dequeueReusableCell(withIdentifier: CourseSectionTableViewCell.identifier, for: indexPath) as! CourseSectionTableViewCell
            cell.block = nodes[indexPath.row]
            let videoStream = courseQuerier.flatMapRootedAtBlockWithID(block.blockID) { block in
                (block.type.asVideo != nil) ? block.blockID : nil
            }
            let courseID = courseQuerier.courseID
            cell.videos = videoStream.map({[weak self] videoIDs in
                let videos = self?.environment.dataManager.interface?.statesForVideos(withIDs: videoIDs, courseID: courseID) ?? []
                return videos.filter { video in (video.summary?.isSupportedVideo ?? false)}
            })
            cell.delegate = self
            return cell
        case .discussion:
            let cell = tableView.dequeueReusableCell(withIdentifier: DiscussionTableViewCell.identifier, for: indexPath) as! DiscussionTableViewCell
            cell.block = block
            return cell
        case .mcq:
            fatalError("not supported")
        case .mrq:
            fatalError("not supported")
        case .ooyalaVideo:
            fatalError("unimplemented")
        case .freeText:
            fatalError("not supported")
        case .assessment:
            fatalError("not supported")
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? CourseBlockContainerCell else {
            assertionFailure("All course outline cells should implement CourseBlockContainerCell")
            return
        }
        
        let highlighted = cell.block?.blockID != nil && cell.block?.blockID == self.highlightedBlockID
        cell.applyStyle(highlighted ? .highlighted : .normal)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let group = groups[indexPath.section]
        let chosenBlock = group.children[indexPath.row]
        self.delegate?.outlineTableController(self, choseBlock: chosenBlock, withParentID: group.block.blockID)
    }
    
    func videoCellChoseDownload(_ cell: CourseVideoTableViewCell, block : CourseBlock) {
        self.delegate?.outlineTableController(self, choseDownloadVideoForBlock: block)
    }
    
    func videoCellChoseShowDownloads(_ cell: CourseVideoTableViewCell) {
        self.delegate?.outlineTableControllerChoseShowDownloads(self)
    }
    
    //Added By Ravi On 22Jan'17 to implement Audio Podcast Download
    func audioCellChoseDownload(_ cell: CourseAudioTableViewCell, block : CourseBlock) {
        self.delegate?.outlineTableController(self, choseDownloadAudioForBlock: block)
    }
    
    //Added By Ravi On 22Jan'17 to implement Audio Podcast Download
    func audioCellChoseShowDownloads(_ cell: CourseAudioTableViewCell) {
        self.delegate?.outlineTableControllerChoseShowDownloads(self)
    }

    func sectionCellChoseShowDownloads(_ cell: CourseSectionTableViewCell) {
        self.delegate?.outlineTableControllerChoseShowDownloads(self)
    }
    
    func sectionCellChoseDownload(_ cell: CourseSectionTableViewCell, videos: [OEXHelperVideoDownload], forBlock block : CourseBlock) {
        self.delegate?.outlineTableController(self, choseDownloadVideos: videos, rootedAtBlock:block)
    }
    
    func choseViewLastAccessedWithItem(_ item : CourseLastAccessed) {
        for group in groups {
            let childNodes = group.children
            let currentLastViewedIndex = childNodes.firstIndexMatching({$0.blockID == item.moduleId})
            if let matchedIndex = currentLastViewedIndex {
                self.delegate?.outlineTableController(self, choseBlock: childNodes[matchedIndex], withParentID: group.block.blockID)
                break
            }
        }
    }
    
    /// Shows the last accessed Header from the item as argument. Also, sets the relevant action if the course block exists in the course outline.
    func showLastAccessedWithItem(_ item : CourseLastAccessed) {
        tableView.tableHeaderView = self.headerContainer
        lastAccessedView.subtitleText = item.moduleName
        lastAccessedView.setViewButtonAction { [weak self] _ in
            self?.choseViewLastAccessedWithItem(item)
        }
    }
    
    func hideLastAccessed() {
        tableView.tableHeaderView = nil
    }
}
