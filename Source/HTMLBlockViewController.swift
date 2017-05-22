//
//  HTMLBlockViewController.swift
//  edX
//
//  Created by Akiva Leffert on 5/26/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public class HTMLBlockViewController: UIViewController, CourseBlockViewController, PreloadableBlockController {
    
    public typealias Environment = protocol<OEXAnalyticsProvider, OEXConfigProvider, DataManagerProvider, OEXSessionProvider>
    
    public let courseID : String
    public var appDelegate : OEXAppDelegate
    public let blockID : CourseBlockID?
    
    private let webController : CachedWebViewController
    
    private let loader = BackedStream<CourseBlock>()
    private let courseQuerier : CourseOutlineQuerier
    
    public init(blockID : CourseBlockID?, courseID : String, environment : Environment) {
        self.courseID = courseID
        self.blockID = blockID
        
        webController = CachedWebViewController(environment: environment, blockID: self.blockID)
        courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID)
        appDelegate = UIApplication.sharedApplication().delegate as! OEXAppDelegate
        super.init(nibName : nil, bundle : nil)
        
        addChildViewController(webController)
        webController.didMoveToParentViewController(self)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate.shouldRotate = false
        view.addSubview(webController.view)
        view.backgroundColor = UIColor.whiteColor()
    }
    
    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        appDelegate.shouldRotate = false
    }
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }

	public override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		showFTUEIfNeeded()
	}
    
    private func loadData() {
        if !loader.hasBacking {
            loader.backWithStream(courseQuerier.blockWithID(self.blockID).firstSuccess())
            loader.listen (self, success : {[weak self] block in
                if let url = block.blockURL {
                    let request = NSURLRequest(URL: url)
                    self?.webController.loadRequest(request)
                }
                else {
                    self?.webController.showError(nil)
                }
            }, failure : {[weak self] error in
                self?.webController.showError(error)
            })
        }
    }
    
    public func preloadData() {
        let _ = self.view
        loadData()
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
