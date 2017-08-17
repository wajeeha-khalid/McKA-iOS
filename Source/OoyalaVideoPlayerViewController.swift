//
//  OoyalaVideoPlayerViewController.swift
//  edX
//
//  Created by Salman Jamil on 8/8/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit
import MckinseyXBlocks

/// This class adapts an OyalaPlayerViewController into `CourseBlockViewController` since the
/// `CourseContentPageViewController` expects its child blocks to conform to this type...
@available(iOS 9.0, *)
class OoylaPlayerCourseBlockAdapter: UIViewController, CourseBlockViewController {
    
    let blockID: CourseBlockID?
    let courseID: CourseBlockID
    let adaptedViewController: OyalaPlayerViewController
    
    
    init(blockID: CourseBlockID?, courseID: CourseBlockID, adaptedViewController: OyalaPlayerViewController) {
        self.blockID = blockID
        self.courseID = courseID
        self.adaptedViewController = adaptedViewController
        super.init(nibName: nil, bundle: nil)
        loadViewIfNeeded()
        addChildViewController(adaptedViewController)
        view.addSubview(adaptedViewController.view)
        adaptedViewController.view.snp.makeConstraints { make in
            make.top.equalTo(view)
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.height.equalTo(view)
        }
        adaptedViewController.didMove(toParentViewController: self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        adaptedViewController.puase()
    }
}

