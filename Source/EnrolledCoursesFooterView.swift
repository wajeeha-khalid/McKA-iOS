//
//  EnrolledCoursesFooterView.swift
//  edX
//
//  Created by Akiva Leffert on 12/23/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

class EnrolledCoursesFooterView : UIView {
    fileprivate let promptLabel = UILabel()
    fileprivate let findCoursesButton = UIButton(type:.system)
    fileprivate let missingCourseButton = UIButton(type: .system)
    
    fileprivate let container = UIView()
    
    var findCoursesAction : (() -> Void)?
    var missingCoursesAction : (() -> Void)?
    
    fileprivate var findCoursesTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared.neutralDark())
    }
    
    init() {
        super.init(frame: CGRect.zero)
        
        addSubview(container)
        container.addSubview(promptLabel)
        container.addSubview(findCoursesButton)
        container.addSubview(missingCourseButton)
        
        self.promptLabel.attributedText = findCoursesTextStyle.attributedString(withText: Strings.EnrollmentList.findCoursesPrompt)
        self.promptLabel.textAlignment = .center
        
        self.findCoursesButton.applyButtonStyle(OEXStyles.shared.filledPrimaryButtonStyle, withTitle: Strings.EnrollmentList.findCourses.oex_uppercaseStringInCurrentLocale())
        
        self.missingCourseButton.applyButtonStyle(OEXStyles.shared.linkButtonStyle, withTitle: Strings.EnrollmentList.lookingForCourse)
        
        container.backgroundColor = OEXStyles.shared.standardBackgroundColor()
        container.applyBorderStyle(BorderStyle())
        
        container.snp.makeConstraints {make in
            make.top.equalTo(self).offset(CourseCardCell.margin)
            make.bottom.equalTo(self)
            make.leading.equalTo(self).offset(CourseCardCell.margin)
            make.trailing.equalTo(self).offset(-CourseCardCell.margin)
        }
        
        self.promptLabel.snp.makeConstraints {make in
            make.leading.equalTo(container).offset(StandardHorizontalMargin)
            make.trailing.equalTo(container).offset(-StandardHorizontalMargin)
            make.top.equalTo(container).offset(StandardVerticalMargin)
        }
        
        self.findCoursesButton.snp.makeConstraints {make in
            make.leading.equalTo(promptLabel)
            make.trailing.equalTo(promptLabel)
            make.top.equalTo(promptLabel.snp.bottom).offset(StandardVerticalMargin)
        }
        
        self.missingCourseButton.snp.makeConstraints {make in
            make.leading.equalTo(promptLabel)
            make.trailing.equalTo(promptLabel)
            make.top.equalTo(findCoursesButton.snp.bottom).offset(StandardVerticalMargin)
            make.bottom.equalTo(container).offset(-StandardVerticalMargin)
        }
        
        findCoursesButton.oex_addAction({[weak self] _ in
            self?.findCoursesAction?()
            }, for: .touchUpInside)
        
        missingCourseButton.oex_addAction({[weak self] _ in
            self?.missingCoursesAction?()
            }, for: .touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
