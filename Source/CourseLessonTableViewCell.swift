//
//  CourseLessonTableViewCell.swift
//  edX
//
//  Created by Shafqat Muneer on 7/18/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

class CourseLessonTableViewCell: UITableViewCell {
    @IBOutlet weak var lessonNumber: UILabel!
    @IBOutlet weak var lessonName: UILabel!
    @IBOutlet weak var completedStatus: UILabel!
    @IBOutlet weak var statusImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    var lessonViewModel: LessonViewModel? {
        didSet {
            if let model = lessonViewModel {
                lessonNumber.text = "LESSON \(model.number + 1)"
                lessonName.text = model.title
                switch model.state {
                case .complete:
                    statusImageView.image = UIImage(named: "completed")
                    completedStatus.text = "Completed"
                case .inProgress:
                    statusImageView.image = UIImage(named: "in_progress")
                    completedStatus.text = "In Progress"
                case .notStarted:
                    statusImageView.image = UIImage(named: "not_started")
                    completedStatus.text = "Not Started"
                }
            }
        }
    }
}
