//
//  CourseVideoTableViewCell.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 12/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit


protocol CourseVideoTableViewCellDelegate : class {
    func videoCellChoseDownload(_ cell : CourseVideoTableViewCell, block : CourseBlock)
    func videoCellChoseShowDownloads(_ cell : CourseVideoTableViewCell)
}

private let titleLabelCenterYOffset = -12

class CourseVideoTableViewCell: UITableViewCell, CourseBlockContainerCell {
    
    static let identifier = "CourseVideoTableViewCellIdentifier"
    weak var delegate : CourseVideoTableViewCellDelegate?
    
    fileprivate let content = CourseOutlineItemView()
    fileprivate let downloadView = DownloadsAccessoryView()
    
    var block : CourseBlock? = nil {
        didSet {
            content.setTitleText(block?.displayName)
            if let video = block?.type.asVideo {
                video.isSupportedVideo ? (downloadView.isHidden = false) : (downloadView.isHidden = true)
            }
        }
    }
        
    var localState : OEXHelperVideoDownload? {
        didSet {
            updateDownloadViewForVideoState()
            content.setDetailText(OEXDateFormatting.formatSeconds(asVideoLength: localState?.summary?.duration ?? 0))
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(content)
        content.snp.makeConstraints { (make) -> Void in
            make.edges.equalTo(contentView)
        }
        content.setContentIcon(Icon.courseVideoContent)
        
        downloadView.downloadAction = {[weak self] _ in
            if let owner = self, let block = owner.block {
                owner.delegate?.videoCellChoseDownload(owner, block : block)
            }
        }
        
        for notification in [NSNotification.Name.OEXDownloadProgressChanged, NSNotification.Name.OEXDownloadEnded, NSNotification.Name.OEXVideoStateChanged] {
            NotificationCenter.default.oex_addObserver(self, name: notification.rawValue) { (_, observer, _) -> Void in
                observer.updateDownloadViewForVideoState()
            }
        }
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addAction {[weak self]_ in
            if let owner = self, owner.downloadState == .downloading {
                owner.delegate?.videoCellChoseShowDownloads(owner)
            }
        }
        downloadView.addGestureRecognizer(tapGesture)
        
        content.trailingView = downloadView
        downloadView.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .horizontal)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate var downloadState : DownloadsAccessoryView.State {
        switch localState?.downloadProgress ?? 0 {
        case 0:
            return .available
        case OEXMaxDownloadProgress:
            return .done
        default:
            return .downloading
        }
    }
    
    fileprivate func updateDownloadViewForVideoState() {
        switch localState?.watchedState ?? .unwatched {
        case .unwatched, .partiallyWatched:
            content.leadingIconColor = OEXStyles.shared().primaryBaseColor()
        case .watched:
            content.leadingIconColor = OEXStyles.shared().neutralDark()
        }
        
        guard !(self.localState?.summary?.onlyOnWeb ?? false) else {
            content.trailingView = nil
            return
        }
        
        content.trailingView = downloadView
        downloadView.state = downloadState
    }
}
