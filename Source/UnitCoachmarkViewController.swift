//
//  UnitCoachmarkViewController.swift
//  edX
//
//  Created by Dmitry on 19/04/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

class UnitCoachmarkViewController: UIViewController {
	var currentCoachmarkIndex = 1
	var totalCoachMarks = 2

	override func viewDidLoad() {
		super.viewDidLoad()
		setupCurrentCoachMark()
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

			coachview.hidden = (index != currentCoachmarkIndex)
		}
	}
}
