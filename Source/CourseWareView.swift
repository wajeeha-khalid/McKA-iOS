//
//  CourseWareView.swift
//  edX
//
//  Created by Deepak Nagarajan on 24/02/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

class CourseWareView: UIView {

    @IBOutlet weak var contentLabel :  UILabel?
    @IBOutlet weak var okBtn  : UIButton?
    @IBOutlet weak var xConstraint  : NSLayoutConstraint?
    @IBOutlet weak var ftueBG : UIImageView?
    var clickedIndex : Int?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.xConstraint!.constant = 50
        self.backgroundColor = UIColor.clear
        clickedIndex = 0
        UIApplication.shared.keyWindow?.addSubview(self)
        okBtn?.layer.borderColor = UIColor.white.cgColor
    }

    
    @IBAction func okBtnClicked (_ sender : UIButton) {
      updateContentandMoveView(clickedIndex!)
      clickedIndex =  clickedIndex!+1
    }
    
    func updateContentandMoveView(_ courseIndex : Int){
        if(courseIndex == 0){
            self.layoutIfNeeded()
            UIView.animate(withDuration: Double(0.5), animations: {
                self.xConstraint!.constant = 239
                self.layoutIfNeeded()
            })
            self.contentLabel?.text = "Work through all parts to unlock the next unit."
            self.ftueBG?.image = UIImage(named: "Combined_Shape")

        }else if(courseIndex == 1){
            self.okBtn?.setTitle("GOT IT", for: UIControlState())
            self.contentLabel?.text = "Download unit contents for whenever it suits you."
            self.ftueBG?.image = UIImage(named: "CombinedShape")
        }else if (courseIndex == 2) {
             self .removeFromSuperview()
            UserDefaults.standard.set(false, forKey: "showCourseware")
        }
        else{
            return
        }
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
