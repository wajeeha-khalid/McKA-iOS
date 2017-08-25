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

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    var lessonViewModel: LessonViewModel? {
        didSet {
            if let model = lessonViewModel {
                lessonNumber.text = "LESSON \(model.number + 1)"
                lessonName.text = model.title
                statusImageView.image = model.state.image
                completedStatus.text = model.state.description
            }
        }
    }
}
