//
//  CourseCardView.swift
//  edX
//
//  Created by Jianfeng Qiu on 13/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

final class CourseProgressView: UIView {
    
    var progressView: UIView?
    
    var progress: CourseProgress = .notStarted {
        didSet {
            progressView?.removeFromSuperview()
            switch progress {
            case .completed:
                let image = UIImage(named: "CheckMark")
                progressView = UIImageView(image: image)
                addSubview(progressView!)
                addConstraints(to: progressView!)
            case .inPorgress(progress: let value):
                let view = MBCircularProgressBarView()
                view.maxValue = 100
                view.value = CGFloat(value)
                view.unitString = "%"
                view.fontColor = UIColor.whiteColor()
                view.valueFontSize = 14.0
                view.unitFontSize = 14.0
                let fontName = UIFont.systemFontOfSize(12.0).fontName
                view.unitFontName = fontName
                view.valueFontName = fontName
                view.progressColor = UIColor.whiteColor()
                view.progressStrokeColor = UIColor.clearColor()
                view.progressLineWidth = 2.0
                view.emptyLineWidth = 3.0
                view.emptyLineColor = UIColor(colorLiteralRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.3)
                view.emptyLineStrokeColor = UIColor.clearColor()
                view.progressRotationAngle = 50
                view.progressAngle = 100
                view.progressCapType = 1
                view.backgroundColor = UIColor.clearColor()
                progressView = view
                addSubview(view)
                addConstraints(to: view)
            case .notStarted:
                let image = UIImage(named: "RightArrow")
                progressView = UIImageView(image: image)
                addSubview(progressView!)
                addConstraints(to: progressView!)
            }
        }
    }
    
    private func addConstraints(to progressView: UIView) {
        progressView.snp_makeConstraints { (make) in
            make.centerY.equalTo(self)
            make.centerX.equalTo(self)
            make.height.equalTo(self)
            make.width.equalTo(self)
        }
    }
}


//TODO: Remove `CourseCardView` and rename this class to `CourseCardView`
class NewCourseCardView: UIView {
    private let courseTitleLabel = UILabel()
    private let lessonLabel = UILabel()
    private let progressView = CourseProgressView()
    let imageView = UIImageView()
    private let overlayView = UIView()
    private let labelsStackView = UIView()
    
    var tapAction : (NewCourseCardView -> ())?
    
    var coverImage: RemoteImage? {
        get {
            return imageView.remoteImage
        } set {
            imageView.remoteImage = newValue
        }
    }
    
    var couseTitle: String? {
        get {
            return courseTitleLabel.text
        } set  {
            courseTitleLabel.text = newValue
        }
    }
    
    var lessonText: String? {
        get {
            return lessonLabel.text
        } set {
            lessonLabel.text = newValue
        }
    }
    
    
    var progress: CourseProgress {
        get {
            return progressView.progress
        }
        set {
           progressView.progress = newValue
            if case .completed = newValue {
                overlayView.backgroundColor = UIColor(colorLiteralRed: 39/255.0, green: 144/255.0, blue: 240/255.0, alpha: 0.95)
            } else {
                overlayView.backgroundColor = UIColor.clearColor()
            }
        }
    }
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(imageView)
        addSubview(overlayView)
        addSubview(labelsStackView)
        addSubview(progressView)
        labelsStackView.addSubview(courseTitleLabel)
        labelsStackView.addSubview(lessonLabel)
        imageView.contentMode = .ScaleAspectFill
        imageView.hidesLoadingSpinner = true
        lessonLabel.textColor = UIColor.whiteColor()
        courseTitleLabel.textColor = UIColor.whiteColor()
        courseTitleLabel.font = UIFont.boldSystemFontOfSize(16.0)
        lessonLabel.font = UIFont.systemFontOfSize(12.0)
        progressView.backgroundColor = UIColor.clearColor()
        courseTitleLabel.numberOfLines = 2
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapAction(_:)))
        userInteractionEnabled = true
        addGestureRecognizer(tapGestureRecognizer)
        setUpViews()
    }
    
    @objc private func tapAction(sender: UITapGestureRecognizer) {
        tapAction?(self)
    }
    
    private func setUpViews() {
        
        imageView.snp_makeConstraints { (make) in
            make.top.equalTo(self)
            make.bottom.equalTo(self)
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
        }
        
        overlayView.snp_makeConstraints { (make) in
            make.top.equalTo(self)
            make.bottom.equalTo(self)
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
        }
        
        progressView.snp_makeConstraints { (make) in
            make.width.equalTo(46)
            make.height.equalTo(46)
            make.centerY.equalTo(labelsStackView)
            make.trailing.equalTo(self).offset(-StandardHorizontalMargin)
        }
        
        labelsStackView.snp_makeConstraints { (make) in
            make.bottom.equalTo(self).offset(-30)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.trailing.lessThanOrEqualTo(progressView.snp_leading).offset(-StandardHorizontalMargin)
        }
        
        courseTitleLabel.snp_makeConstraints { (make) in
            make.top.equalTo(labelsStackView)
            make.leading.equalTo(labelsStackView)
            make.trailing.equalTo(labelsStackView)
        }
        
        lessonLabel.snp_makeConstraints { (make) in
            make.top.equalTo(courseTitleLabel.snp_bottom).offset(7)
            make.leading.equalTo(labelsStackView)
            make.trailing.equalTo(labelsStackView)
            make.bottom.equalTo(labelsStackView)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


@IBDesignable
class CourseCardView: UIView, UIGestureRecognizerDelegate {
    private let arrowHeight = 15.0
    private let verticalMargin = 10
    var isMyVideos: Bool
    
    var course: OEXCourse?
    
    private let coverImageView = UIImageView()
    private let container = UIView()
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let bottomLine = UIView()
    private let bottomTrailingLabel = UILabel()
    private let overlayContainer = UIView()
    
    var tapAction : (CourseCardView -> ())?
    
    private var titleTextStyle : OEXTextStyle {
        return OEXTextStyle(weight : .Normal, size: .Large, color: OEXStyles.sharedStyles().neutralBlack())
    }
    private var detailTextStyle : OEXTextStyle {
        return OEXTextStyle(weight : .Normal, size: .XXXSmall, color: OEXStyles.sharedStyles().neutralXDark())
    }
    
    private func setup() {
        configureViews()
        accessibilityTraits = UIAccessibilityTraitStaticText
        accessibilityHint = Strings.accessibilityShowsCourseContent
    }
    
    override init(frame : CGRect) {
        self.isMyVideos = false
        super.init(frame : frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.isMyVideos = true
        super.init(coder: aDecoder)
        setup()
    }
    
    @available(iOS 8.0, *)
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        let bundle = NSBundle(forClass: self.dynamicType)
        coverImageView.image = UIImage(named:"placeholderCourseCardImage", inBundle: bundle, compatibleWithTraitCollection: self.traitCollection)
        titleLabel.attributedText = titleTextStyle.attributedStringWithText("Demo Course")
        detailLabel.attributedText = detailTextStyle.attributedStringWithText("edx | DemoX")
        bottomTrailingLabel.attributedText = detailTextStyle.attributedStringWithText("X Videos, 1.23 MB")
    }
    
    func configureViews() {
        self.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        self.clipsToBounds = true
        self.bottomLine.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        
        self.container.backgroundColor = OEXStyles.sharedStyles().neutralWhite().colorWithAlphaComponent(0.85)
        self.coverImageView.backgroundColor = OEXStyles.sharedStyles().neutralWhiteT()
        self.coverImageView.contentMode = UIViewContentMode.ScaleAspectFill
        self.coverImageView.clipsToBounds = true
        self.coverImageView.hidesLoadingSpinner = false
        
        self.container.accessibilityIdentifier = "Title Bar"
        self.container.addSubview(titleLabel)
        self.container.addSubview(detailLabel)
        self.container.addSubview(bottomTrailingLabel)
        
        self.addSubview(coverImageView)
        self.addSubview(container)

         self.container.hidden = true
        self.insertSubview(bottomLine, aboveSubview: coverImageView)
        self.addSubview(overlayContainer)
        coverImageView.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, forAxis: .Horizontal)
        coverImageView.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, forAxis: .Vertical)
        detailLabel.setContentHuggingPriority(UILayoutPriorityDefaultLow, forAxis: UILayoutConstraintAxis.Horizontal)
        detailLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, forAxis: UILayoutConstraintAxis.Horizontal)
        
        self.container.snp_makeConstraints { make -> Void in
            make.leading.equalTo(self)
            make.trailing.equalTo(self).priorityRequired()
            make.bottom.equalTo(self).offset(-OEXStyles.dividerSize())
        }
        self.coverImageView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self)
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.height.equalTo(self.coverImageView.snp_width).multipliedBy(0.533).priorityLow()
            make.bottom.equalTo(self)
        }
        self.detailLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self.container).offset(StandardHorizontalMargin)
            make.top.equalTo(self.titleLabel.snp_bottom)
            make.bottom.equalTo(self.container).offset(-verticalMargin)
            make.trailing.equalTo(self.titleLabel)
        }
        self.bottomLine.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.bottom.equalTo(self)
            make.top.equalTo(self.container.snp_bottom)
        }
        
        self.bottomTrailingLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(detailLabel)
            make.trailing.equalTo(self.container).offset(-StandardHorizontalMargin)
        }

        self.overlayContainer.snp_makeConstraints {make in
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.top.equalTo(self)
            make.bottom.equalTo(container.snp_top)
        }
        
        let tapGesture = UITapGestureRecognizer {[weak self] _ in self?.cardTapped() }
        tapGesture.delegate = self
        self.addGestureRecognizer(tapGesture)
    }

    override func updateConstraints() {
        if let accessory = titleAccessoryView {
            accessory.snp_remakeConstraints { make in
                make.trailing.equalTo(container).offset(-StandardHorizontalMargin)
                make.centerY.equalTo(container)
            }
        }

        self.titleLabel.snp_remakeConstraints { (make) -> Void in
            make.leading.equalTo(container).offset(StandardHorizontalMargin)
            if let accessory = titleAccessoryView {
                make.trailing.lessThanOrEqualTo(accessory).offset(-StandardHorizontalMargin)
            }
            else {
                make.trailing.equalTo(container).offset(-StandardHorizontalMargin)
            }
            make.top.equalTo(container).offset(verticalMargin)
        }

        super.updateConstraints()
    }

    var titleAccessoryView : UIView? = nil {
        willSet {
            titleAccessoryView?.removeFromSuperview()
        }
        didSet {
            if let accessory = titleAccessoryView {
                container.addSubview(accessory)
            }
            updateConstraints()
        }
    }
    
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        return tapAction != nil
    }
    
    var titleText : String? {
        get {
            return self.titleLabel.text
        }
        set {
            self.titleLabel.attributedText = titleTextStyle.attributedStringWithText(newValue)
            updateAcessibilityLabel()
        }
    }
    
    var detailText : String? {
        get {
            return self.detailLabel.text
        }
        set {
            self.detailLabel.attributedText = detailTextStyle.attributedStringWithText(newValue)
            updateAcessibilityLabel()
        }
    }
    
    var bottomTrailingText : String? {
        get {
            return self.bottomTrailingLabel.text
        }
        
        set {
            self.bottomTrailingLabel.attributedText = detailTextStyle.attributedStringWithText(newValue)
            self.bottomTrailingLabel.hidden = !(newValue != nil && !newValue!.isEmpty)
            updateAcessibilityLabel()
        }
    }
    
    var coverImage : RemoteImage? {
        get {
            return self.coverImageView.remoteImage
        }
        set {
            self.coverImageView.remoteImage = newValue
        }
    }
    
    private func cardTapped() {
        self.tapAction?(self)
    }
    
    func wrapTitleLabel() {
        self.titleLabel.numberOfLines = 3
        self.titleLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        self.titleLabel.minimumScaleFactor = 0.5
        self.titleLabel.adjustsFontSizeToFitWidth = true
        self.layoutIfNeeded()
    }
    
    func updateAcessibilityLabel()-> String {
        var accessibilityString = ""
        
        if let title = titleText {
            accessibilityString = title
        }
        
        if let text = detailText {
         let formatedDetailText = text.stringByReplacingOccurrencesOfString("|", withString: "")
            accessibilityString = "\(accessibilityString),\(Strings.accessibilityBy) \(formatedDetailText)"
        }
        
        if let bottomText = bottomTrailingText {
            accessibilityString = "\(accessibilityString), \(bottomText)"
        }
        
        accessibilityLabel = accessibilityString
        return accessibilityString
    }
    
    func addCenteredOverlay(view : UIView) {
        addSubview(view)
        view.snp_makeConstraints {make in
            make.center.equalTo(overlayContainer)
        }
    }
}
