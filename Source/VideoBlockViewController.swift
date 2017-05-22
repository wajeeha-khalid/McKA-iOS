//
//  VideoBlockViewController.swift
//  edX
//
//  Created by Akiva Leffert on 5/6/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import MediaPlayer
import UIKit

private let StandardVideoAspectRatio : CGFloat = 0.6

class VideoBlockViewController : UIViewController, CourseBlockViewController, OEXVideoPlayerInterfaceDelegate,GVRVideoPlayerInterfaceDelegate, StatusBarOverriding, InterfaceOrientationOverriding {
    
    typealias Environment = protocol<DataManagerProvider, OEXInterfaceProvider, ReachabilityProvider>
    
    let environment : Environment
    let blockID : CourseBlockID?
    let courseQuerier : CourseOutlineQuerier
    let videoController : OEXVideoPlayerInterface
    let gvrVideoController : GVRVideoPlayerInterface // Added by Ravi
    let gvrTransitionView : GVRTransitionCounterView
    
    let loader = BackedStream<CourseBlock>()
    
    var rotateDeviceMessageView : IconMessageView?
    var cardBoardMessageView : ImageMessageView? // Ravi
    var contentView : UIView?
    var isVRVideo : Bool // Added by Ravi
    var gvrView : UIView? // Added by Ravi.
    
    let loadController : LoadStateViewController
    
    init(environment : Environment, blockID : CourseBlockID?, courseID: String) {
        self.blockID = blockID
        self.environment = environment
        courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID)
        videoController = OEXVideoPlayerInterface()
        loadController = LoadStateViewController()
        gvrVideoController = GVRVideoPlayerInterface()
        gvrTransitionView = GVRTransitionCounterView()
        self.isVRVideo = false
        
        super.init(nibName: nil, bundle: nil)
        
        addChildViewController(videoController)
        videoController.didMoveToParentViewController(self)
        videoController.delegate = self
        
        addChildViewController(gvrVideoController)
        gvrVideoController.didMoveToParentViewController(self)
        gvrVideoController.delegate = self
        
        addLoadListener()
    }
    
    var courseID : String {
        return courseQuerier.courseID
    }
    
    required init?(coder aDecoder: NSCoder) {
        // required by the compiler because UIViewController implements NSCoding,
        // but we don't actually want to serialize these things
        fatalError("init(coder:) has not been implemented")
    }
    
    func addLoadListener() {
        loader.listen (self,
                       success : { [weak self] block in
                        if let video = block.type.asVideo where video.isYoutubeVideo,
                            let url = block.blockURL
                        {
                            self?.showYoutubeMessage(url)
                        }
                        else if
                            let video = self?.environment.interface?.stateForVideoWithID(self?.blockID, courseID : self?.courseID)
                            where block.type.asVideo?.preferredEncoding != nil
                        {
                            self?.showLoadedBlock(block, forVideo: video)
                        }
                        else {
                            self?.showError(nil)
                        }
            }, failure : {[weak self] error in
                self?.showError(error)
            }
        )
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contentView = UIView(frame: CGRectZero)
        view.addSubview(contentView!)
        loadController.setupInController(self, contentView : contentView!)
        
        // Added by Ravi for VR Video functionality.
        
        let video = self.environment.interface?.stateForVideoWithID(self.blockID, courseID : self.courseID)
        let videoUrl = video?.summary?.videoURL
        
        gvrTransitionView.frame = self.revealViewController().view.frame
        self.revealViewController().view.addSubview(gvrTransitionView)
        self.revealViewController().view.bringSubviewToFront(gvrTransitionView)
        gvrTransitionView.updateConstraints()
        
        if (videoUrl?.rangeOfString(VR_VIDEO_IDENTIFIER)) != nil
        {
            loadVRVideoView()
        }
        else
        {
            loadVideoView()
        }

        view.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        view.setNeedsUpdateConstraints()
    }

	func showFTUEIfNeeded() {
		let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
		dispatch_after(delayTime, dispatch_get_main_queue()) { [weak self] in
			guard let stongSelf = self else {
				return
			}
			if stongSelf.isVRVideo {
				stongSelf.showUnitVRFTUE()
			} else {
				stongSelf.showUnitFTUE()
			}
		}
	}

	func showUnitFTUE(){
		let showedFTUE = NSUserDefaults.standardUserDefaults().boolForKey("Unit FTUE")
		guard !showedFTUE,
			let rootController = UIApplication.sharedApplication().delegate?.window??.rootViewController else { return }

		let coachController = UnitCoachmarkViewController()

		rootController.addChildViewController(coachController)
		coachController.view.frame = rootController.view.bounds
		rootController.view.addSubview(coachController.view)
		coachController.didMoveToParentViewController(rootController)
		coachController.view.alpha = 0.01
		UIView.animateWithDuration(0.2) {
			coachController.view.alpha = 1.0
		}
		NSUserDefaults.standardUserDefaults().setBool(true, forKey: "Unit FTUE")
	}

	func showUnitVRFTUE(){
		let showedFTUE = NSUserDefaults.standardUserDefaults().boolForKey("Unit VR FTUE")
		guard !showedFTUE,
			let rootController = UIApplication.sharedApplication().delegate?.window??.rootViewController else { return }

		let coachController = VRCoachmarkViewController()
		coachController.completion = {
			self.showUnitFTUE()
		}

		rootController.addChildViewController(coachController)
		coachController.view.frame = rootController.view.bounds
		rootController.view.addSubview(coachController.view)
		coachController.didMoveToParentViewController(rootController)
		coachController.view.alpha = 0.01
		UIView.animateWithDuration(0.2) {
			coachController.view.alpha = 1.0
		}
		NSUserDefaults.standardUserDefaults().setBool(true, forKey: "Unit VR FTUE")
	}

    
    // Added by Ravi on 2/1/2017 to load VR Video
    
    
    func loadVRVideoView()
    {
        self.isVRVideo = true
        
        contentView!.addSubview(gvrVideoController.view)
        gvrVideoController.view.translatesAutoresizingMaskIntoConstraints = false
        
        let imageName = "cardboard"
        let vrimage = UIImage(named: imageName)
        
        cardBoardMessageView = ImageMessageView(image: vrimage, message: Strings.rotateDeviceVr)
        
        
        
        cardBoardMessageView?.cardboardButtonAction = {
            
            if self.gvrVideoController.didFinishLoading {
                self.gvrVideoController.gvrVideoView?.pause()
                self.gvrTransitionView.hidden = false
                self.gvrTransitionView.startCountdownFrom(10, withCompletion: {
                    
                    self.gvrTransitionView.hidden = true
                    self.gvrVideoController.displayVRPlayerInStereoMode()
                    self.gvrVideoController.gvrVideoView?.play()
                })
            } else {
                
                self.showOverlayMessage("Cannot Transition to Cardboard Mode until video has loaded")
            }
        }
        contentView!.addSubview(cardBoardMessageView!)
        
    }
    
    
    func loadVideoView()
    {
        self.isVRVideo = false
        contentView!.addSubview(videoController.view)
        videoController.view.translatesAutoresizingMaskIntoConstraints = false
        videoController.fadeInOnLoad = false
        videoController.hidesNextPrev = true
        
        rotateDeviceMessageView = IconMessageView(icon: .RotateDevice, message: Strings.rotateDevice)
        contentView!.addSubview(rotateDeviceMessageView!)
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.loadVideoIfNecessary()
    }
    
    override func viewDidAppear(animated : Bool) {
        
        // There's a weird OS bug where the bottom layout guide doesn't get set properly until
        // the layout cycle after viewDidAppear so cause a layout cycle
        self.view.setNeedsUpdateConstraints()
        self.view.updateConstraintsIfNeeded()
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        super.viewDidAppear(animated)
        
        guard canDownloadVideo() else {
            guard let video = self.environment.interface?.stateForVideoWithID(self.blockID, courseID : self.courseID) where video.downloadState == .Complete else {
                self.showOverlayMessage(Strings.noWifiMessage)
                return
            }
            
            return
        }

		showFTUEIfNeeded()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        videoController.setAutoPlaying(false)
    }
    
    private func loadVideoIfNecessary() {
        if !loader.hasBacking {
            loader.backWithStream(courseQuerier.blockWithID(self.blockID).firstSuccess())
        }
    }
    
    override func viewWillLayoutSubviews()
    {
        super.viewWillLayoutSubviews()
        
        updateViewConstraints()
        
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
    
    
    
    private func applyPortraitConstraints() {
        
        contentView?.snp_remakeConstraints {make in
            make.edges.equalTo(view)
        }
        
        if self.isVRVideo == true
        {
            gvrVideoController.height = view.bounds.size.width * StandardVideoAspectRatio
            gvrVideoController.width = view.bounds.size.width
            
            gvrVideoController.view.snp_remakeConstraints {make in
                make.leading.equalTo(contentView!)
                make.trailing.equalTo(contentView!)
                if #available(iOS 9, *) {
                    make.top.equalTo(self.topLayoutGuide.bottomAnchor)
                }
                else {
                    make.top.equalTo(self.snp_topLayoutGuideBottom)
                }
                
                make.height.equalTo(view.bounds.size.width * StandardVideoAspectRatio) //0.8
            }
            
            cardBoardMessageView?.snp_remakeConstraints {make in
                make.top.equalTo(gvrVideoController.view.snp_bottom)
                make.leading.equalTo(contentView!)
                make.trailing.equalTo(contentView!)
                // There's a weird OS bug where the bottom layout guide doesn't get set properly until
                // the layout cycle after viewDidAppear, so use the parent in the mean time
                if #available(iOS 9, *) {
                    make.bottom.equalTo(self.bottomLayoutGuide.topAnchor)
                }
                else {
                    make.bottom.equalTo(self.snp_bottomLayoutGuideTop)
                }
            }
        }
        else
        {
            
            videoController.height = view.bounds.size.width * StandardVideoAspectRatio
            videoController.width = view.bounds.size.width
            
            videoController.view.snp_remakeConstraints {make in
                make.leading.equalTo(contentView!)
                make.trailing.equalTo(contentView!)
                if #available(iOS 9, *) {
                    make.top.equalTo(self.topLayoutGuide.bottomAnchor)
                }
                else {
                    make.top.equalTo(self.snp_topLayoutGuideBottom)
                }
                
                make.height.equalTo(view.bounds.size.width * StandardVideoAspectRatio)
            }
            
            rotateDeviceMessageView?.snp_remakeConstraints {make in
                make.top.equalTo(videoController.view.snp_bottom)
                make.leading.equalTo(contentView!)
                make.trailing.equalTo(contentView!)
                // There's a weird OS bug where the bottom layout guide doesn't get set properly until
                // the layout cycle after viewDidAppear, so use the parent in the mean time
                if #available(iOS 9, *) {
                    make.bottom.equalTo(self.bottomLayoutGuide.topAnchor)
                }
                else {
                    make.bottom.equalTo(self.snp_bottomLayoutGuideTop)
                }
            }
            
            
        }
        
    }
    
    private func applyLandscapeConstraints() {
        
        contentView?.snp_remakeConstraints {make in
            make.edges.equalTo(view)
        }
        
        let playerHeight = view.bounds.size.height - (navigationController?.toolbar.bounds.height ?? 0)
        
        if self.isVRVideo == false
        {
            videoController.height = playerHeight
            videoController.width = view.bounds.size.width
            
            videoController.view.snp_remakeConstraints {make in
                make.leading.equalTo(contentView!)
                make.trailing.equalTo(contentView!)
                if #available(iOS 9, *) {
                    make.top.equalTo(self.topLayoutGuide.bottomAnchor)
                }
                else {
                    make.top.equalTo(self.snp_topLayoutGuideBottom)
                }
                
                make.height.equalTo(playerHeight)
            }
            
            
            rotateDeviceMessageView?.snp_remakeConstraints {make in
                make.height.equalTo(0.0)
            }
        }
    }
    
    func movieTimedOut() {
        
        if let controller = videoController.moviePlayerController where controller.fullscreen {
            UIAlertView(title: Strings.videoContentNotAvailable, message: "", delegate: nil, cancelButtonTitle: nil, otherButtonTitles: Strings.close).show()
        }
        else {
            self.showOverlayMessage(Strings.timeoutCheckInternetConnection)
        }
    }
    
    private func showError(error : NSError?) {
        loadController.state = LoadState.failed(error, icon: .UnknownError, message: Strings.videoContentNotAvailable)
    }
    
    private func showYoutubeMessage(url: NSURL) {
        let buttonInfo = MessageButtonInfo(title: Strings.Video.viewOnYoutube) {
            if UIApplication.sharedApplication().canOpenURL(url){
                UIApplication.sharedApplication().openURL(url)
            }
        }
        loadController.state = LoadState.empty(icon: .CourseModeVideo, message: Strings.Video.onlyOnYoutube, attributedMessage: nil, accessibilityMessage: nil, buttonInfo: buttonInfo)
    }
    
    private func showLoadedBlock(block : CourseBlock, forVideo video: OEXHelperVideoDownload) {
        navigationItem.title = block.displayName
        
        dispatch_async(dispatch_get_main_queue()) {
            self.loadController.state = .Loaded
        }
        
        if self.isVRVideo == true
        {

            //Added by Ravi on 24Feb'17 for smooth scrolling.
            dispatch_async(dispatch_get_main_queue()) {
                self.gvrVideoController.playVideoFor(video)
            }
        }
        else
        {
            videoController.playVideoFor(video)
        }
        
        
    }
    
    private func canDownloadVideo() -> Bool {
        let hasWifi = environment.reachability.isReachableViaWiFi() ?? false
        let onlyOnWifi = environment.dataManager.interface?.shouldDownloadOnlyOnWifi ?? false
        return !onlyOnWifi || hasWifi
    }
    
    override func childViewControllerForStatusBarStyle() -> UIViewController? {
        if self.isVRVideo == true
        {
            return gvrVideoController
        }
        else
        {
            return videoController
        }
        
    }
    
    override func childViewControllerForStatusBarHidden() -> UIViewController? {
        if self.isVRVideo == true
        {
            return gvrVideoController
        }
        else
        {
            return videoController
        }
        
    }
    
    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        
        guard let videoPlayer = videoController.moviePlayerController else { return }
        
        if videoPlayer.fullscreen {
            
            if newCollection.verticalSizeClass == .Regular {
                videoPlayer.setFullscreen(false, withOrientation: self.currentOrientation())
            }
            else {
                videoPlayer.setFullscreen(true, withOrientation: self.currentOrientation())
            }
        }
    }
    
    func videoPlayerTapped(sender: UIGestureRecognizer) {
        guard let videoPlayer = videoController.moviePlayerController else { return }
        
        if self.isVerticallyCompact() && !videoPlayer.fullscreen{
            videoPlayer.setFullscreen(true, withOrientation: self.currentOrientation())
        }
    }
}
