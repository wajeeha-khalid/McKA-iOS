//
//  OoyalaVideoPlayerViewController.swift
//  edX
//
//  Created by Salman Jamil on 8/8/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit
import MckinseyXBlocks

// This class Adapts any `UIViewController` into `CourseBlockViewController`
class CourseBlockViewControllerAdapter: UIViewController, CourseBlockViewController {
    
    let blockID: CourseBlockID?
    let courseID: CourseBlockID
    let adaptedViewController: UIViewController
    
    init(blockID: CourseBlockID?, courseID: CourseBlockID, adaptedViewController: UIViewController) {
        self.blockID = blockID
        self.courseID = courseID
        self.adaptedViewController = adaptedViewController
        super.init(nibName: nil, bundle: nil)
        if #available(iOS 9.0, *) {
            loadViewIfNeeded()
        } else {
            loadView()
        }
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

extension CourseBlockViewControllerAdapter: XBlock {
    var primaryActionView: UIView? {
        return (adaptedViewController as? XBlock)?.primaryActionView
    }
}

extension CourseBlockViewControllerAdapter: ActionViewProvider {
    
}


