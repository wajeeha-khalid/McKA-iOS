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
import SnapKit

private let StandardVideoAspectRatio : CGFloat = 0.6

class VideoBlockViewController : UIViewController, CourseBlockViewController, OEXVideoPlayerInterfaceDelegate,GVRVideoPlayerInterfaceDelegate, StatusBarOverriding, InterfaceOrientationOverriding {
    
    typealias Environment = DataManagerProvider & OEXInterfaceProvider & ReachabilityProvider
    
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
        videoController.didMove(toParentViewController: self)
        videoController.delegate = self
        
        addChildViewController(gvrVideoController)
        gvrVideoController.didMove(toParentViewController: self)
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
                        if let video = block.type.asVideo, video.isYoutubeVideo,
                            let url = block.blockURL
                        {
                            self?.showYoutubeMessage(url as URL)
                        }
                        else if
                            let video = self?.environment.interface?.stateForVideo(withID: self?.blockID, courseID : self?.courseID), block.type.asVideo?.preferredEncoding != nil
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
        
        contentView = UIView(frame: CGRect.zero)
        view.addSubview(contentView!)
        loadController.setupInController(self, contentView : contentView!)
        
        // Added by Ravi for VR Video functionality.
        
        let video = self.environment.interface?.stateForVideo(withID: self.blockID, courseID : self.courseID)
        let videoUrl = video?.summary?.videoURL
        
        gvrTransitionView.frame = self.revealViewController().view.frame
        self.revealViewController().view.addSubview(gvrTransitionView)
        self.revealViewController().view.bringSubview(toFront: gvrTransitionView)
        gvrTransitionView.updateConstraints()
        
        if (videoUrl?.range(of: VR_VIDEO_IDENTIFIER)) != nil
        {
            loadVRVideoView()
        }
        else
        {
            loadVideoView()
        }

        view.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        view.setNeedsUpdateConstraints()
    }

	func showFTUEIfNeeded() {
		let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
		DispatchQueue.main.asyncAfter(deadline: delayTime) { [weak self] in
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
		let showedFTUE = UserDefaults.standard.bool(forKey: "Unit FTUE")
		guard !showedFTUE,
			let rootController = UIApplication.shared.delegate?.window??.rootViewController else { return }

		let coachController = UnitCoachmarkViewController()

		rootController.addChildViewController(coachController)
		coachController.view.frame = rootController.view.bounds
		rootController.view.addSubview(coachController.view)
		coachController.didMove(toParentViewController: rootController)
		coachController.view.alpha = 0.01
		UIView.animate(withDuration: 0.2, animations: {
			coachController.view.alpha = 1.0
		}) 
		UserDefaults.standard.set(true, forKey: "Unit FTUE")
	}

	func showUnitVRFTUE(){
		let showedFTUE = UserDefaults.standard.bool(forKey: "Unit VR FTUE")
		guard !showedFTUE,
			let rootController = UIApplication.shared.delegate?.window??.rootViewController else { return }

		let coachController = VRCoachmarkViewController()
		coachController.completion = {
			self.showUnitFTUE()
		}

		rootController.addChildViewController(coachController)
		coachController.view.frame = rootController.view.bounds
		rootController.view.addSubview(coachController.view)
		coachController.didMove(toParentViewController: rootController)
		coachController.view.alpha = 0.01
		UIView.animate(withDuration: 0.2, animations: {
			coachController.view.alpha = 1.0
		}) 
		UserDefaults.standard.set(true, forKey: "Unit VR FTUE")
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
                self.gvrTransitionView.isHidden = false
                self.gvrTransitionView.startCountdown(from: 10, withCompletion: {
                    
                    self.gvrTransitionView.isHidden = true
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
        
        rotateDeviceMessageView = IconMessageView(icon: .rotateDevice, message: Strings.rotateDevice)
        contentView!.addSubview(rotateDeviceMessageView!)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.loadVideoIfNecessary()
    }
    
    override func viewDidAppear(_ animated : Bool) {
        
        // There's a weird OS bug where the bottom layout guide doesn't get set properly until
        // the layout cycle after viewDidAppear so cause a layout cycle
        self.view.setNeedsUpdateConstraints()
        self.view.updateConstraintsIfNeeded()
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        super.viewDidAppear(animated)
        
        guard canDownloadVideo() else {
            guard let video = self.environment.interface?.stateForVideo(withID: self.blockID, courseID : self.courseID), video.downloadState == .complete else {
                self.showOverlayMessage(Strings.noWifiMessage)
                return
            }
            
            return
        }

		showFTUEIfNeeded()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        videoController.setAutoPlaying(false)
    }
    
    fileprivate func loadVideoIfNecessary() {
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
    
    
    
    fileprivate func applyPortraitConstraints() {
        
        contentView?.snp.remakeConstraints {make in
            make.edges.equalTo(view)
        }
        
        if self.isVRVideo == true
        {
            gvrVideoController.height = view.bounds.size.width * StandardVideoAspectRatio
            gvrVideoController.width = view.bounds.size.width
            
            gvrVideoController.view.snp.remakeConstraints {make in
                make.leading.equalTo(contentView!)
                make.trailing.equalTo(contentView!)
                //TODO: snp verify
               /* if #available(iOS 9, *) {
                    make.top.equalTo(self.topLayoutGuide.bottomAnchor)
                }
                else {
                    make.top.equalTo(self.snp_topLayoutGuideBottom)
                } */
                make.top.equalTo(topLayoutGuide.snp.bottom)
                make.height.equalTo(view.bounds.size.width * StandardVideoAspectRatio) //0.8
            }
            
            cardBoardMessageView?.snp.remakeConstraints {make in
                make.top.equalTo(gvrVideoController.view.snp.bottom)
                make.leading.equalTo(contentView!)
                make.trailing.equalTo(contentView!)
                // There's a weird OS bug where the bottom layout guide doesn't get set properly until
                // the layout cycle after viewDidAppear, so use the parent in the mean time
                //TODO: snp verify
               /* if #available(iOS 9, *) {
                    make.bottom.equalTo(self.bottomLayoutGuide.topAnchor)
                }
                else {
                    make.bottom.equalTo(self.snp.bottomLayoutGuideTop)
                }*/
                make.bottom.equalTo(bottomLayoutGuide.snp.top)
            }
        }
        else
        {
            
            videoController.height = view.bounds.size.width * StandardVideoAspectRatio
            videoController.width = view.bounds.size.width
            
            videoController.view.snp.remakeConstraints {make in
                make.leading.equalTo(contentView!)
                make.trailing.equalTo(contentView!)
                //TODO: snp verify
               /* if #available(iOS 9, *) {
                    make.top.equalTo(self.topLayoutGuide.bottomAnchor)
                }
                else {
                    make.top.equalTo(self.snp_topLayoutGuideBottom)
                } */
                make.top.equalTo(topLayoutGuide.snp.bottom)
                make.height.equalTo(view.bounds.size.width * StandardVideoAspectRatio)
            }
            
            rotateDeviceMessageView?.snp.remakeConstraints {make in
                make.top.equalTo(videoController.view.snp.bottom)
                make.leading.equalTo(contentView!)
                make.trailing.equalTo(contentView!)
                // There's a weird OS bug where the bottom layout guide doesn't get set properly until
                // the layout cycle after viewDidAppear, so use the parent in the mean time
                //TODO: snp verify
               /* if #available(iOS 9, *) {
                    make.bottom.equalTo(self.bottomLayoutGuide.topAnchor)
                }
                else {
                    make.bottom.equalTo(self.snp.bottomLayoutGuideTop)
                } */
                make.bottom.equalTo(bottomLayoutGuide.snp.top)
            }
            
            
        }
        
    }
    
    fileprivate func applyLandscapeConstraints() {
        
        contentView?.snp.remakeConstraints {make in
            make.edges.equalTo(view)
        }
        
        let playerHeight = view.bounds.size.height - (navigationController?.toolbar.bounds.height ?? 0)
        
        if self.isVRVideo == false
        {
            videoController.height = playerHeight
            videoController.width = view.bounds.size.width
            
            videoController.view.snp.remakeConstraints {make in
                make.leading.equalTo(contentView!)
                make.trailing.equalTo(contentView!)
                //TODO: snp verify
                /*
                if #available(iOS 9, *) {
                    make.top.equalTo(self.topLayoutGuide.bottomAnchor)
                }
                else {
                    make.top.equalTo(self.snp_topLayoutGuideBottom)
                }*/
                make.top.equalTo(topLayoutGuide.snp.bottom)
                
                make.height.equalTo(playerHeight)
            }
            
            
            rotateDeviceMessageView?.snp.remakeConstraints {make in
                make.height.equalTo(0.0)
            }
        }
    }
    
    func movieTimedOut() {
        
        if let controller = videoController.moviePlayerController, controller.isFullscreen {
            UIAlertView(title: Strings.videoContentNotAvailable, message: "", delegate: nil, cancelButtonTitle: nil, otherButtonTitles: Strings.close).show()
        }
        else {
            self.showOverlayMessage(Strings.timeoutCheckInternetConnection)
        }
    }
    
    fileprivate func showError(_ error : NSError?) {
        loadController.state = LoadState.failed(error, icon: .unknownError, message: Strings.videoContentNotAvailable)
    }
    
    fileprivate func showYoutubeMessage(_ url: URL) {
        let buttonInfo = MessageButtonInfo(title: Strings.Video.viewOnYoutube) {
            if UIApplication.shared.canOpenURL(url){
                UIApplication.shared.openURL(url)
            }
        }
        loadController.state = LoadState.empty(icon: .courseModeVideo, message: Strings.Video.onlyOnYoutube, attributedMessage: nil, accessibilityMessage: nil, buttonInfo: buttonInfo)
    }
    
    fileprivate func showLoadedBlock(_ block : CourseBlock, forVideo video: OEXHelperVideoDownload) {
        navigationItem.title = block.displayName
        
        DispatchQueue.main.async {
            self.loadController.state = .loaded
        }
        
        if self.isVRVideo == true
        {

            //Added by Ravi on 24Feb'17 for smooth scrolling.
            DispatchQueue.main.async {
                self.gvrVideoController.playVideo(for: video)
            }
        }
        else
        {
            videoController.playVideo(for: video)
        }
        
        
    }
    
    fileprivate func canDownloadVideo() -> Bool {
        let hasWifi = environment.reachability.isReachableViaWiFi() 
        let onlyOnWifi = environment.dataManager.interface?.shouldDownloadOnlyOnWifi ?? false
        return !onlyOnWifi || hasWifi
    }
    
    override var childViewControllerForStatusBarStyle : UIViewController? {
        if self.isVRVideo == true
        {
            return gvrVideoController
        }
        else
        {
            return videoController
        }
        
    }
    
    override var childViewControllerForStatusBarHidden : UIViewController? {
        if self.isVRVideo == true
        {
            return gvrVideoController
        }
        else
        {
            return videoController
        }
        
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        
        
        guard let videoPlayer = videoController.moviePlayerController else { return }
        
        if videoPlayer.isFullscreen {
            
            if newCollection.verticalSizeClass == .regular {
                videoPlayer.setFullscreen(false, with: self.currentOrientation())
            }
            else {
                videoPlayer.setFullscreen(true, with: self.currentOrientation())
            }
        }
    }
    
    func videoPlayerTapped(_ sender: UIGestureRecognizer) {
        guard let videoPlayer = videoController.moviePlayerController else { return }
        
        if self.isVerticallyCompact() && !videoPlayer.isFullscreen{
            videoPlayer.setFullscreen(true, with: self.currentOrientation())
        }
    }
}
