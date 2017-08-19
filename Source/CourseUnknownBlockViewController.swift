//
//  CourseUnknownBlockViewController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 20/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class CourseUnknownBlockViewController: UIViewController, CourseBlockViewController {
    
    typealias Environment = DataManagerProvider & OEXInterfaceProvider
    
    let environment : Environment

    let blockID : CourseBlockID?
    let courseID : String
    var messageView : IconMessageView?
    
    var loader : edXCore.Stream<URL?>?
    init(blockID : CourseBlockID?, courseID : String, environment : Environment) {
        self.blockID = blockID
        self.courseID = courseID
        self.environment = environment
        
        super.init(nibName: nil, bundle: nil)
        
        let courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(self.courseID)
        courseQuerier.blockWithID(blockID).extendLifetimeUntilFirstResult (
            success:
            { [weak self] block in
                if let video = block.type.asVideo, video.isYoutubeVideo{
                    self?.showYoutubeMessage(Strings.Video.viewOnYoutube, message: Strings.Video.onlyOnYoutube, icon: Icon.courseModeVideo, videoUrl: video.videoURL)
                }
                else {
                    self?.showError()
                }
            },
            failure: {[weak self] _ in
                self?.showError()
            }
        )
    }
    
    fileprivate func showYoutubeMessage(_ buttonTitle: String, message: String, icon: Icon, videoUrl: String?) {
        messageView = IconMessageView(icon: icon, message: message)
        messageView?.buttonInfo = MessageButtonInfo(title : buttonTitle)
        {
            if let videoURL = videoUrl, let url =  URL(string: videoURL) {
                UIApplication.shared.openURL(url)
            }
        }
        
        view.addSubview(messageView!)
    }
    
    fileprivate func showError() {
        messageView = IconMessageView(icon: Icon.courseUnknownContent, message: Strings.courseContentUnknown)
        messageView?.buttonInfo = MessageButtonInfo(title : Strings.openInBrowser)
        {
            [weak self] in
            self?.loader?.listen(self!, success : {url -> Void in
                if let url = url {
                    UIApplication.shared.openURL(url as URL)
                }
                }, failure : {_ in
            })
        }
        
        view.addSubview(messageView!)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = OEXStyles.shared.standardBackgroundColor()
        
    }
    
    override func updateViewConstraints() {
        
        if  self.isVerticallyCompact() {
            applyLandscapeConstraints()
        }
        else{
            applyPortraitConstraints()
        }
        
        super.updateViewConstraints()
    }
    
    fileprivate func applyPortraitConstraints() {
        messageView?.snp.remakeConstraints { (make) -> Void in
            make.edges.equalTo(view)
        }
    }
    
    fileprivate func applyLandscapeConstraints() {
        messageView?.snp.remakeConstraints { (make) -> Void in
            make.edges.equalTo(view)
            let barHeight = navigationController?.toolbar.frame.size.height ?? 0.0
            make.bottom.equalTo(view.snp.bottom).offset(-barHeight)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if loader?.value == nil {
            loader = environment.dataManager.courseDataManager.querierForCourseWithID(self.courseID).blockWithID(self.blockID).map {
                return $0.webURL
            }.firstSuccess()
        }
    }
    
}
