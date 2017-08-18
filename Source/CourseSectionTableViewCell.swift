//
//  CourseSectionTableViewCell.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 04/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

protocol CourseSectionTableViewCellDelegate : class {
    func sectionCellChoseDownload(_ cell : CourseSectionTableViewCell, videos : [OEXHelperVideoDownload], forBlock block : CourseBlock)
    func sectionCellChoseShowDownloads(_ cell : CourseSectionTableViewCell)
}

class CourseSectionTableViewCell: UITableViewCell, CourseBlockContainerCell {
    
    static let identifier = "CourseSectionTableViewCellIdentifier"
    
    fileprivate let content = CourseOutlineItemView()
    fileprivate let downloadView = DownloadsAccessoryView()

    weak var delegate : CourseSectionTableViewCellDelegate?
    
    fileprivate let videosStream = BackedStream<[OEXHelperVideoDownload]>()
    fileprivate let audiosStream = BackedStream<[OEXHelperAudioDownload]>()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(content)
        content.snp.makeConstraints { (make) -> Void in
            make.edges.equalTo(contentView)
        }

        downloadView.downloadAction = {[weak self] _ in
            if let owner = self, let block = owner.block, let videos = self?.videosStream.value {
                owner.delegate?.sectionCellChoseDownload(owner, videos: videos, forBlock: block)
            }
        }
        videosStream.listen(self) {[weak self] downloads in
            if let downloads = downloads.value, let state = self?.downloadStateForDownloads(downloads) {
                self?.downloadView.state = state
                self?.content.trailingView = self?.downloadView
                self?.downloadView.itemCount = downloads.count
            }
            else {
                self?.content.trailingView = nil
            }
        }
        
        for notification in [NSNotification.Name.OEXDownloadProgressChanged, NSNotification.Name.OEXDownloadEnded, NSNotification.Name.OEXVideoStateChanged] {
            NotificationCenter.default.oex_addObserver(self, name: notification.rawValue) { (_, observer, _) -> Void in
                if let state = observer.downloadStateForDownloads(observer.videosStream.value) {
                    observer.downloadView.state = state
                }
                else {
                    observer.content.trailingView = nil
                }
            }
        }
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addAction {[weak self]_ in
            if let owner = self, owner.downloadView.state == .downloading {
                owner.delegate?.sectionCellChoseShowDownloads(owner)
            }
        }
        downloadView.addGestureRecognizer(tapGesture)
    }
    
    var videos : edXCore.Stream<[OEXHelperVideoDownload]> = edXCore.Stream() {
        didSet {
            videosStream.backWithStream(videos)
        }
    }
    
    var audios : edXCore.Stream<[OEXHelperAudioDownload]> = edXCore.Stream() {
        didSet {
            audiosStream.backWithStream(audios)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        videosStream.backWithStream(edXCore.Stream(value:[]))
    }
    
    func downloadStateForDownloads(_ videos : [OEXHelperVideoDownload]?) -> DownloadsAccessoryView.State? {
        if let videos = videos, videos.count > 0 {
            let allDownloading = videos.reduce(true) {(acc, video) in
                return acc && video.downloadState == .partial
            }
            
            let allCompleted = videos.reduce(true) {(acc, video) in
                return acc && video.downloadState == .complete
            }
            
            if allDownloading {
                return .downloading
            }
            else if allCompleted {
                return .done
            }
            else {
                return .available
            }
        }
        else {
            return nil
        }
    }
    
    var block : CourseBlock? = nil {
        didSet {
            content.setTitleText(block?.displayName)
            content.isGraded = block?.graded
            content.setDetailText(block?.format ?? "")
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
