//
//  HTMLBlockViewController.swift
//  edX
//
//  Created by Akiva Leffert on 5/26/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

open class HTMLBlockViewController: UIViewController, CourseBlockViewController, PreloadableBlockController {
    
    public typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & OEXSessionProvider
    
    open let courseID : String
    open var appDelegate : OEXAppDelegate
    open let blockID : CourseBlockID?
    
    fileprivate let webController : CachedWebViewController
    
    fileprivate let loader = BackedStream<CourseBlock>()
    fileprivate let courseQuerier : CourseOutlineQuerier
    
    public init(blockID : CourseBlockID?, courseID : String, environment : Environment) {
        self.courseID = courseID
        self.blockID = blockID
        
        webController = CachedWebViewController(environment: environment, blockID: self.blockID)
        courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID)
        appDelegate = UIApplication.shared.delegate as! OEXAppDelegate
        super.init(nibName : nil, bundle : nil)
        
        addChildViewController(webController)
        webController.didMove(toParentViewController: self)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate.shouldRotate = false
        view.addSubview(webController.view)
        view.backgroundColor = UIColor.white
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        appDelegate.shouldRotate = false
    }
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }

	open override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		showFTUEIfNeeded()
	}
    
    fileprivate func loadData() {
        if !loader.hasBacking {
            loader.backWithStream(courseQuerier.blockWithID(self.blockID).firstSuccess())
            loader.listen (self, success : {[weak self] block in
                if let url = block.blockURL {
                    let request = NSURLRequest(url: url as URL)
                    self?.webController.loadRequest(request as URLRequest)
                }
                else {
                    self?.webController.showError(nil)
                }
            }, failure : {[weak self] error in
                self?.webController.showError(error)
            })
        }
    }
    
    open func preloadData() {
        let _ = self.view
        loadData()
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
