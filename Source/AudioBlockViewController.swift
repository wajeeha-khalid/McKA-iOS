//
//  AudioBlockViewController.swift
//  edX
//
//  Created by Ravi on 22/01/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit
import SnapKit
private let StandardVideoAspectRatio : CGFloat = 0.6


class AudioBlockViewController: UIViewController,CourseBlockViewController,OEXAudioPlayerInterfaceDelegate, StatusBarOverriding, InterfaceOrientationOverriding {

    typealias Environment = DataManagerProvider & OEXInterfaceProvider & ReachabilityProvider
    
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
        audioController.didMove(toParentViewController: self)
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
                        if let video = block.type.asVideo, video.isYoutubeVideo,
                            let url = block.blockURL
                        {
                            self?.showYoutubeMessage(url as URL)
                        }
                        else if
                            let audioUrl = self?.environment.interface?.stateForAudio(withID: (self?.blockID!)!)
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
        
        contentView = UIView(frame: CGRect.zero)
        view.addSubview(contentView!)
        loadController.setupInController(self, contentView : contentView!)
        
        contentView!.addSubview(audioController.view)
        audioController.view.translatesAutoresizingMaskIntoConstraints = false
        audioController.fadeInOnLoad = false
        audioController.hidesNextPrev = true
        
        
        rotateDeviceMessageView = IconMessageView(icon: .headPhones, message: Strings.audioPodcast)
        contentView!.addSubview(rotateDeviceMessageView!)
        
        view.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        view.setNeedsUpdateConstraints()
        

        let audioString = self.environment.interface?.state(forAudioId: self.blockID)
        
        audioController.reqAudioString = audioString!;
        
        
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
               // self.showOverlayMessage(Strings.noWifiMessage)
                return
            }
            
            return
        }

		showFTUEIfNeeded()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        audioController.setAutoPlaying(false)
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
            audioController.height = view.bounds.size.width * StandardVideoAspectRatio
            audioController.width = view.bounds.size.width
            
            audioController.view.snp.remakeConstraints {make in
                make.leading.equalTo(contentView!)
                make.trailing.equalTo(contentView!)
                //TODO: snp verify
               /* if #available(iOS 9, *) {
                    make.top.equalTo(topLayoutGuide.snp.bottom)
                }
                else {
                    make.top.equalTo(self.snp_topLayoutGuideBottom)
                }*/
                make.top.equalTo(topLayoutGuide.snp.bottom)
                make.height.equalTo(view.bounds.size.width * StandardVideoAspectRatio)
            }
            
            rotateDeviceMessageView?.snp.remakeConstraints {make in
                make.top.equalTo(audioController.view.snp.bottom)
                make.leading.equalTo(contentView!)
                make.trailing.equalTo(contentView!)
                // There's a weird OS bug where the bottom layout guide doesn't get set properly until
                // the layout cycle after viewDidAppear, so use the parent in the mean time
                //TODO: snp verify
                /*
                if #available(iOS 9, *) {
                    make.bottom.equalTo(self.bottomLayoutGuide.topAnchor)
                }
                else {
                    make.bottom.equalTo(self.snp.bottomLayoutGuideTop)
                }*/
                make.bottom.equalTo(bottomLayoutGuide.snp.top)
            }
        
        
    }
    
    fileprivate func applyLandscapeConstraints() {
        
        contentView?.snp.remakeConstraints {make in
            make.edges.equalTo(view)
        }
        
        //let playerHeight = view.bounds.size.height - (navigationController?.toolbar.bounds.height ?? 0)
        
//            videoController.height = playerHeight
//            videoController.width = view.bounds.size.width
//            
//            videoController.view.snp.remakeConstraints {make in
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
//            rotateDeviceMessageView?.snp.remakeConstraints {make in
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
    
    fileprivate func showLoadedBlock(_ audio : OEXHelperAudioDownload?) {
        
        DispatchQueue.main.async {
            self.loadController.state = .loaded
        }
        
    audioController.playAudio(for: audio!)
        
        
    }
    
    fileprivate func canDownloadVideo() -> Bool {
        let hasWifi = environment.reachability.isReachableViaWiFi() 
        let onlyOnWifi = environment.dataManager.interface?.shouldDownloadOnlyOnWifi ?? false
        return !onlyOnWifi || hasWifi
    }
    
    override var childViewControllerForStatusBarStyle : UIViewController? {
     
        return audioController
        
    }
    
    override var childViewControllerForStatusBarHidden : UIViewController? {
       
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
    
    func audioPlayerTapped(_ sender: UIGestureRecognizer) {
        guard let audioPlayer = audioController.moviePlayerController else { return }
        
        if self.isVerticallyCompact() && !audioPlayer.isFullscreen{
            audioPlayer.setFullscreen(true, with: self.currentOrientation())
        }
    }

	func showFTUEIfNeeded() {
		let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
		DispatchQueue.main.asyncAfter(deadline: delayTime) { [weak self] in
			guard let stongSelf = self else {
				return
			}
			stongSelf.showUnitFTUE()
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

}
