//
//  AudioBlockViewController.swift
//  edX
//
//  Created by Ravi on 22/01/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

private let StandardVideoAspectRatio : CGFloat = 0.6


class AudioBlockViewController: UIViewController,CourseBlockViewController,OEXAudioPlayerInterfaceDelegate, StatusBarOverriding, InterfaceOrientationOverriding {

    typealias Environment = protocol<DataManagerProvider, OEXInterfaceProvider, ReachabilityProvider>
    
    let environment : Environment
    let blockID : CourseBlockID?
    let courseQuerier : CourseOutlineQuerier
    let audioController : OEXAudioPlayerInterface
    
    
    let loader = BackedStream<CourseBlock>()
    var contentView : UIView?
    var rotateDeviceMessageView : IconMessageView?

    
    let loadController : LoadStateViewController
    
    init(environment : Environment, blockID : CourseBlockID?, courseID: String) {
        self.blockID = blockID
        self.environment = environment
        courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID)
        audioController = OEXAudioPlayerInterface()
        loadController = LoadStateViewController()
        
        super.init(nibName: nil, bundle: nil)
        
        addChildViewController(audioController)
        audioController.didMoveToParentViewController(self)
        audioController.delegate = self
        
        
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
                            let audioUrl = self?.environment.interface?.stateForAudioWithID((self?.blockID!)!)
                        {
                            self?.showLoadedBlock(audioUrl)
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
        
        contentView!.addSubview(audioController.view)
        audioController.view.translatesAutoresizingMaskIntoConstraints = false
        audioController.fadeInOnLoad = false
        audioController.hidesNextPrev = true
        
        
        rotateDeviceMessageView = IconMessageView(icon: .HeadPhones, message: Strings.audioPodcast)
        contentView!.addSubview(rotateDeviceMessageView!)
        
        view.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        view.setNeedsUpdateConstraints()
        

        let audioString = self.environment.interface?.stateForAudioId(self.blockID)
        
        audioController.reqAudioString = audioString!;
        
        
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
               // self.showOverlayMessage(Strings.noWifiMessage)
                return
            }
            
            return
        }

		showFTUEIfNeeded()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        audioController.setAutoPlaying(false)
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
            audioController.height = view.bounds.size.width * StandardVideoAspectRatio
            audioController.width = view.bounds.size.width
            
            audioController.view.snp_remakeConstraints {make in
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
                make.top.equalTo(audioController.view.snp_bottom)
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
    
    private func applyLandscapeConstraints() {
        
        contentView?.snp_remakeConstraints {make in
            make.edges.equalTo(view)
        }
        
        //let playerHeight = view.bounds.size.height - (navigationController?.toolbar.bounds.height ?? 0)
        
//            videoController.height = playerHeight
//            videoController.width = view.bounds.size.width
//            
//            videoController.view.snp_remakeConstraints {make in
//                make.leading.equalTo(contentView!)
//                make.trailing.equalTo(contentView!)
//                if #available(iOS 9, *) {
//                    make.top.equalTo(self.topLayoutGuide.bottomAnchor)
//                }
//                else {
//                    make.top.equalTo(self.snp_topLayoutGuideBottom)
//                }
//                
//                make.height.equalTo(playerHeight)
//            }
//            
//            
//            rotateDeviceMessageView?.snp_remakeConstraints {make in
//                make.height.equalTo(0.0)
//            }
    }
    
    func movieTimedOut() {
        
//        if let controller = videoController.moviePlayerController where controller.fullscreen {
//            UIAlertView(title: Strings.videoContentNotAvailable, message: "", delegate: nil, cancelButtonTitle: nil, otherButtonTitles: Strings.close).show()
//        }
//        else {
//            self.showOverlayMessage(Strings.timeoutCheckInternetConnection)
//        }
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
    
    private func showLoadedBlock(audio : OEXHelperAudioDownload?) {
        
        dispatch_async(dispatch_get_main_queue()) {
            self.loadController.state = .Loaded
        }
        
    audioController.playAudioFor(audio!)
        
        
    }
    
    private func canDownloadVideo() -> Bool {
        let hasWifi = environment.reachability.isReachableViaWiFi() ?? false
        let onlyOnWifi = environment.dataManager.interface?.shouldDownloadOnlyOnWifi ?? false
        return !onlyOnWifi || hasWifi
    }
    
    override func childViewControllerForStatusBarStyle() -> UIViewController? {
     
        return audioController
        
    }
    
    override func childViewControllerForStatusBarHidden() -> UIViewController? {
       
        return audioController
        
    }
    
//    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
//        
//        
////        guard let videoPlayer = videoController.moviePlayerController else { return }
////        
////        if videoPlayer.fullscreen {
////            
////            if newCollection.verticalSizeClass == .Regular {
////                videoPlayer.setFullscreen(false, withOrientation: self.currentOrientation())
////            }
////            else {
////                videoPlayer.setFullscreen(true, withOrientation: self.currentOrientation())
////            }
////        }
//    }
    
    func audioPlayerTapped(sender: UIGestureRecognizer) {
        guard let audioPlayer = audioController.moviePlayerController else { return }
        
        if self.isVerticallyCompact() && !audioPlayer.fullscreen{
            audioPlayer.setFullscreen(true, withOrientation: self.currentOrientation())
        }
    }

	func showFTUEIfNeeded() {
		let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
		dispatch_after(delayTime, dispatch_get_main_queue()) { [weak self] in
			guard let stongSelf = self else {
				return
			}
			stongSelf.showUnitFTUE()
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

}
