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
                view.fontColor = UIColor.white
                view.valueFontSize = 14.0
                view.unitFontSize = 14.0
                let fontName = UIFont.systemFont(ofSize: 12.0).fontName
                view.unitFontName = fontName
                view.valueFontName = fontName
                view.progressColor = UIColor.white
                view.progressStrokeColor = UIColor.clear
                view.progressLineWidth = 2.0
                view.emptyLineWidth = 3.0
                view.emptyLineColor = UIColor(colorLiteralRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.3)
                view.emptyLineStrokeColor = UIColor.clear
                view.progressRotationAngle = 50
                view.progressAngle = 100
                view.progressCapType = 1
                view.backgroundColor = UIColor.clear
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
    
    fileprivate func addConstraints(to progressView: UIView) {
        progressView.snp.makeConstraints { (make) in
            make.centerY.equalTo(self)
            make.centerX.equalTo(self)
            make.height.equalTo(self)
            make.width.equalTo(self)
        }
    }
}


//TODO: Remove `CourseCardView` and rename this class to `CourseCardView`
class NewCourseCardView: UIView {
    fileprivate let courseTitleLabel = UILabel()
    fileprivate let lessonLabel = UILabel()
    fileprivate let progressView = CourseProgressView()
    let imageView = UIImageView()
    fileprivate let overlayView = UIView()
    fileprivate let labelsStackView = UIView()
    
    var tapAction : ((NewCourseCardView) -> ())?
    
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
                overlayView.backgroundColor = BrandingThemes.shared.getCourseCardOverlayColor()
            } else {
                overlayView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
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
        imageView.contentMode = .scaleAspectFill
        imageView.hidesLoadingSpinner = true
        lessonLabel.textColor = UIColor.white
        courseTitleLabel.textColor = UIColor.white
        courseTitleLabel.font = UIFont.boldSystemFont(ofSize: 16.0)
        lessonLabel.font = UIFont.systemFont(ofSize: 12.0)
        progressView.backgroundColor = UIColor.clear
        courseTitleLabel.numberOfLines = 2
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapAction(_:)))
        isUserInteractionEnabled = true
        addGestureRecognizer(tapGestureRecognizer)
        setUpViews()
    }
    
    @objc fileprivate func tapAction(_ sender: UITapGestureRecognizer) {
        tapAction?(self)
    }
    
    fileprivate func setUpViews() {
        
        
        imageView.snp.makeConstraints { (make) in
            make.top.equalTo(self)
            make.bottom.equalTo(self)
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
        }
        
        overlayView.snp.makeConstraints { (make) in
            make.top.equalTo(self)
            make.bottom.equalTo(self)
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
        }
        
        progressView.snp.makeConstraints { (make) in
            make.width.equalTo(46)
            make.height.equalTo(46)
            make.centerY.equalTo(labelsStackView)
            make.trailing.equalTo(self).offset(-StandardHorizontalMargin)
        }
        
        labelsStackView.snp.makeConstraints { (make) in
            make.bottom.equalTo(self).offset(-30)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.trailing.lessThanOrEqualTo(progressView.snp.leading).offset(-StandardHorizontalMargin)
        }
        
        courseTitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(labelsStackView)
            make.leading.equalTo(labelsStackView)
            make.trailing.equalTo(labelsStackView)
        }
        
        lessonLabel.snp.makeConstraints { (make) in
            make.top.equalTo(courseTitleLabel.snp.bottom).offset(7)
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
    fileprivate let arrowHeight = 15.0
    fileprivate let verticalMargin = 10
    var isMyVideos: Bool
    
    var course: OEXCourse?
    
    fileprivate let coverImageView = UIImageView()
    fileprivate let container = UIView()
    fileprivate let titleLabel = UILabel()
    fileprivate let detailLabel = UILabel()
    fileprivate let bottomLine = UIView()
    fileprivate let bottomTrailingLabel = UILabel()
    fileprivate let overlayContainer = UIView()
    
    var tapAction : ((CourseCardView) -> ())?
    
    fileprivate var titleTextStyle : OEXTextStyle {
        return OEXTextStyle(weight : .normal, size: .large, color: OEXStyles.shared.neutralBlack())
    }
    fileprivate var detailTextStyle : OEXTextStyle {
        return OEXTextStyle(weight : .normal, size: .xxxSmall, color: OEXStyles.shared.neutralXDark())
    }
    
    fileprivate func setup() {
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
        
        let bundle = Bundle(for: type(of: self))
        coverImageView.image = UIImage(named:"placeholderCourseCardImage", in: bundle, compatibleWith: self.traitCollection)
        titleLabel.attributedText = titleTextStyle.attributedString(withText: "Demo Course")
        detailLabel.attributedText = detailTextStyle.attributedString(withText: "edx | DemoX")
        bottomTrailingLabel.attributedText = detailTextStyle.attributedString(withText: "X Videos, 1.23 MB")
    }
    
    func configureViews() {
        self.backgroundColor = OEXStyles.shared.neutralXLight()
        self.clipsToBounds = true
        self.bottomLine.backgroundColor = OEXStyles.shared.neutralXLight()
        
        self.container.backgroundColor = OEXStyles.shared.neutralWhite().withAlphaComponent(0.85)
        self.coverImageView.backgroundColor = OEXStyles.shared.neutralWhiteT()
        self.coverImageView.contentMode = UIViewContentMode.scaleAspectFill
        self.coverImageView.clipsToBounds = true
        self.coverImageView.hidesLoadingSpinner = false
        
        self.container.accessibilityIdentifier = "Title Bar"
        self.container.addSubview(titleLabel)
        self.container.addSubview(detailLabel)
        self.container.addSubview(bottomTrailingLabel)
        
        self.addSubview(coverImageView)
        self.addSubview(container)

         self.container.isHidden = true
        self.insertSubview(bottomLine, aboveSubview: coverImageView)
        self.addSubview(overlayContainer)
        coverImageView.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .horizontal)
        coverImageView.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .vertical)
        detailLabel.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: UILayoutConstraintAxis.horizontal)
        detailLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: UILayoutConstraintAxis.horizontal)
        
        self.container.snp.makeConstraints { make -> Void in
            make.leading.equalTo(self)
            make.trailing.equalTo(self).priority(.required)
            make.bottom.equalTo(self).offset(-OEXStyles.dividerSize())
        }
        self.coverImageView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self)
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.height.equalTo(self.coverImageView.snp.width).multipliedBy(0.533).priority(.low)
            make.bottom.equalTo(self)
        }
        self.detailLabel.snp.makeConstraints { (make) -> Void in
            make.leading.equalTo(self.container).offset(StandardHorizontalMargin)
            make.top.equalTo(self.titleLabel.snp.bottom)
            make.bottom.equalTo(self.container).offset(-verticalMargin)
            make.trailing.equalTo(self.titleLabel)
        }
        self.bottomLine.snp.makeConstraints { (make) -> Void in
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.bottom.equalTo(self)
            make.top.equalTo(self.container.snp.bottom)
        }
        
        self.bottomTrailingLabel.snp.makeConstraints { (make) -> Void in
            make.centerY.equalTo(detailLabel)
            make.trailing.equalTo(self.container).offset(-StandardHorizontalMargin)
        }

        self.overlayContainer.snp.makeConstraints {make in
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.top.equalTo(self)
            make.bottom.equalTo(container.snp.top)
        }
        
        let tapGesture = UITapGestureRecognizer {[weak self] _ in self?.cardTapped() }
        tapGesture.delegate = self
        self.addGestureRecognizer(tapGesture)
    }

    override func updateConstraints() {
        if let accessory = titleAccessoryView {
            accessory.snp.remakeConstraints { make in
                make.trailing.equalTo(container).offset(-StandardHorizontalMargin)
                make.centerY.equalTo(container)
            }
        }

        self.titleLabel.snp.remakeConstraints { (make) -> Void in
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
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return tapAction != nil
    }
    
    var titleText : String? {
        get {
            return self.titleLabel.text
        }
        set {
            self.titleLabel.attributedText = titleTextStyle.attributedString(withText: newValue)
            updateAcessibilityLabel()
        }
    }
    
    var detailText : String? {
        get {
            return self.detailLabel.text
        }
        set {
            self.detailLabel.attributedText = detailTextStyle.attributedString(withText: newValue)
            updateAcessibilityLabel()
        }
    }
    
    var bottomTrailingText : String? {
        get {
            return self.bottomTrailingLabel.text
        }
        
        set {
            self.bottomTrailingLabel.attributedText = detailTextStyle.attributedString(withText: newValue)
            self.bottomTrailingLabel.isHidden = !(newValue != nil && !newValue!.isEmpty)
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
    
    fileprivate func cardTapped() {
        self.tapAction?(self)
    }
    
    func wrapTitleLabel() {
        self.titleLabel.numberOfLines = 3
        self.titleLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        self.titleLabel.minimumScaleFactor = 0.5
        self.titleLabel.adjustsFontSizeToFitWidth = true
        self.layoutIfNeeded()
    }
    
    @discardableResult func updateAcessibilityLabel()-> String {
        var accessibilityString = ""
        
        if let title = titleText {
            accessibilityString = title
        }
        
        if let text = detailText {
         let formatedDetailText = text.replacingOccurrences(of: "|", with: "")
            accessibilityString = "\(accessibilityString),\(Strings.accessibilityBy) \(formatedDetailText)"
        }
        
        if let bottomText = bottomTrailingText {
            accessibilityString = "\(accessibilityString), \(bottomText)"
        }
        
        accessibilityLabel = accessibilityString
        return accessibilityString
    }
    
    func addCenteredOverlay(_ view : UIView) {
        addSubview(view)
        view.snp.makeConstraints {make in
            make.center.equalTo(overlayContainer)
        }
    }
}
