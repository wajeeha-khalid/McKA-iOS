//
//  CourseCoachmarkViewController.swift
//  edX
//
//  Created by Dmitry on 18/04/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

class CourseCoachmarkViewController: UIViewController {
	var snapshotView: UIView?
	var titleText: String?
	var currentCoachmarkIndex = 1
	var totalCoachMarks = 4
	
	@IBOutlet weak var titleView: UILabel!
	@IBOutlet weak var progressContainer: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

		titleView.text = titleText

		if let snaphsot = snapshotView {
			progressContainer.addSubview(snaphsot)
		}
		setupCurrentCoachMark()
    }

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()

		if let snaphsot = snapshotView {
			var frame = snaphsot.frame

			frame.origin = CGPoint(x: 8.0, y: 8.0)
			snaphsot.layer.frame = frame
		}
	}


	@IBAction func okButtonPressed(_: UIButton) {
		currentCoachmarkIndex += 1
		if currentCoachmarkIndex > totalCoachMarks {
			view.removeFromSuperview()
			removeFromParentViewController()
			return
		}
		setupCurrentCoachMark()
	}

	func setupCurrentCoachMark() {
		for index in 1...totalCoachMarks {
			guard let coachview = view.viewWithTag(index) else {
				continue
			}

			coachview.isHidden = (index != currentCoachmarkIndex)
		}
	}
}
