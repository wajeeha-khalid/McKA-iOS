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
class OoylaPlayerCourseBlockAdapter: UIViewController, CourseBlockViewController {
    
    let blockID: CourseBlockID?
    let courseID: CourseBlockID
    
    @available(iOS 9.0, *)
    init(blockID: CourseBlockID?, courseID: CourseBlockID, adaptedViewController: OyalaPlayerViewController) {
        self.blockID = blockID
        self.courseID = courseID
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
    
}

