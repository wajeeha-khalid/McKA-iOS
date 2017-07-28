//
//  CourseCatalogDetailView.swift
//  edX
//
//  Created by Akiva Leffert on 12/7/15.
//  Copyright © 2015 edX. All rights reserved.
//

private let margin : CGFloat = 20

import TZStackView
import edXCore

class CourseCatalogDetailView : UIView, UIWebViewDelegate {

    fileprivate struct Field {
        let name : String
        let value : String
        let icon : Icon
    }
    
    typealias Environment = NetworkManagerProvider
    
    fileprivate let environment : Environment
    
    fileprivate let courseCard = CourseCardView()
    fileprivate let blurbLabel = UILabel()
    fileprivate let actionButton = SpinnerButton(type: .system)
    fileprivate let container : TZStackView
    fileprivate let insetContainer : TZStackView
    fileprivate let descriptionView = UIWebView()
    fileprivate let fieldsList = TZStackView()
    fileprivate let playButton = UIButton(type: .system)
    
    let insetsController = ContentInsetsController()
    // used to offset the overview webview content which is at the bottom
    // below the rest of the content
    fileprivate let topContentInsets = ConstantInsetsSource(insets: UIEdgeInsets.zero, affectsScrollIndicators: false)
    
    var action: ((_ completion : @escaping () -> Void) -> Void)?
    
    fileprivate var _loaded = Sink<()>()
    var loaded : edXCore.Stream<()> {
        return _loaded
    }
    
    init(frame: CGRect, environment: Environment) {
        self.insetContainer = TZStackView(arrangedSubviews: [blurbLabel, actionButton, fieldsList])
        self.container = TZStackView(arrangedSubviews: [courseCard, insetContainer])
        self.environment = environment
        
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        addSubview(descriptionView)
        descriptionView.scrollView.addSubview(container)
        descriptionView.snp.makeConstraints {make in
            make.edges.equalTo(self)
        }
        container.snp.makeConstraints { make in
            make.top.equalTo(descriptionView)
            make.leading.equalTo(descriptionView)
            make.trailing.equalTo(descriptionView)
        }
        container.spacing = margin
        for stack in [container, fieldsList, insetContainer] {
            stack.axis = .vertical
            stack.alignment = .fill
        }
        
        insetContainer.layoutMarginsRelativeArrangement = true
        insetContainer.layoutMargins = UIEdgeInsetsMake(0, margin, 0, margin)
        insetContainer.spacing = margin
        
        insetsController.addSource(topContentInsets)
        
        fieldsList.layoutMarginsRelativeArrangement = true
        
        blurbLabel.numberOfLines = 0
        
        actionButton.oex_addAction({[weak self] _ in
            self?.actionButton.showProgress = true
            self?.action?( { self?.actionButton.showProgress = false } )
            }, for: .touchUpInside)
        
        descriptionView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal
        descriptionView.delegate = self
        descriptionView.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        
        playButton.setImage(Icon.courseVideoPlay.imageWithFontSize(60), for: UIControlState())
        playButton.tintColor = OEXStyles.shared().neutralWhite()
        playButton.layer.shadowOpacity = 0.5
        playButton.layer.shadowRadius = 3
        playButton.layer.shadowOffset = CGSize.zero
        courseCard.addCenteredOverlay(playButton)

        descriptionView.scrollView.oex_addObserver(self, forKeyPath: "bounds") { (observer, scrollView, _) -> Void in
            let offset = scrollView.contentOffset.y + scrollView.contentInset.top
            // Even though it's in the webview's scrollview,
            // the container view doesn't offset when the content scrolls.
            // As such, we manually offset it here
            observer.container.transform = CGAffineTransform(translationX: 0, y: -offset)
        }
    }
    
    func setupInController(_ controller: UIViewController) {
        insetsController.setupInController(controller, scrollView: descriptionView.scrollView)
    }
    
    fileprivate var blurbStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().neutralXDark())
    }
    
    fileprivate var descriptionHeaderStyle : OEXTextStyle {
        return OEXTextStyle(weight: .bold, size: .large, color: OEXStyles.shared().neutralXDark())
    }
    
    fileprivate func fieldSeparator() -> UIView {
        let view = UIView()
        view.backgroundColor = OEXStyles.shared().neutralLight()
        view.snp.makeConstraints {make in
            make.height.equalTo(OEXStyles.dividerSize())
        }
        return view
    }
    
    var blurbText : String? {
        didSet {
            if let blurb = blurbText, !blurb.isEmpty {
                self.blurbLabel.attributedText = blurbStyle.attributedString(withText: blurb)
                self.blurbLabel.isHidden = false
            }
            else {
                self.blurbLabel.isHidden = true
            }
        }
    }
    
    var descriptionHTML : String? {
        didSet {
            guard let html = OEXStyles.shared().styleHTMLContent(descriptionHTML, stylesheet: "inline-content") else {
                self.descriptionView.loadHTMLString("", baseURL: environment.networkManager.baseURL)
                return
            }
            
            self.descriptionView.loadHTMLString(html, baseURL: environment.networkManager.baseURL)
        }
    }
    
    fileprivate var fields : [Field] = [] {
        didSet {
            for view in self.fieldsList.arrangedSubviews {
                view.removeFromSuperview()
            }
            let views = fields.map{ viewForField($0) }.interpose { fieldSeparator() }
            
            for view in views {
                fieldsList.addArrangedSubview(view)
            }
        }
    }
    
    fileprivate func viewForField(_ field : Field) -> UIView {
        let view = ChoiceLabel()
        view.titleText = field.name
        view.valueText = field.value
        view.icon = field.icon
        return view
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        self.setNeedsLayout()
        self.layoutIfNeeded()
        webView.scrollView.contentOffset = CGPoint(x: 0, y: -webView.scrollView.contentInset.top)
        _loaded.send(())
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let URL = request.url, navigationType != .other {
            UIApplication.shared.openURL(URL)
            return false
        }
        return true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.topContentInsets.currentInsets = UIEdgeInsets(top: self.container.frame.height + StandardVerticalMargin, left: 0, bottom: 0, right: 0)
    }
    
    var actionText: String? {
        get {
            return self.actionButton.attributedTitle(for: UIControlState())?.string
        }
        set {
            actionButton.applyButtonStyle(OEXStyles.shared().filledEmphasisButtonStyle, withTitle: newValue)
        }
    }
}

extension CourseCatalogDetailView {
    
    fileprivate func fieldsForCourse(_ course : OEXCourse) -> [Field] {
        var result : [Field] = []
        if let effort = course.effort, !effort.isEmpty {
            result.append(Field(name: Strings.CourseDetail.effort, value: effort, icon: .courseEffort))
        }
        if let endDate = course.end, !course.isStartDateOld {
            let date = OEXDateFormatting.format(asMonthDayYearString: endDate)
            result.append(Field(name: Strings.CourseDetail.endDate, value: date, icon: .courseEnd))
        }
        return result
    }
    
    func applyCourse(_ course : OEXCourse) {
        CourseCardViewModel.onCourseCatalog(course, wrapTitle: true).apply(courseCard, networkManager: self.environment.networkManager)
        self.blurbText = course.short_description
        self.descriptionHTML = course.overview_html
        let fields = fieldsForCourse(course)
        self.fields = fields
        self.playButton.isHidden = course.courseVideoMediaInfo?.uri?.isEmpty ?? true
        self.playButton.oex_removeAllActions()
        self.playButton.oex_addAction(
            {[weak self] _ in
                if let
                    path = course.courseVideoMediaInfo?.uri,
                    let url = URL(string: path, relativeTo: self?.environment.networkManager.baseURL)
                {
                    UIApplication.shared.openURL(url)
                }
            }, for: .touchUpInside)
    }
}

// Testing
extension CourseCatalogDetailView {
    var t_showingEffort : Bool {
        return self.fields.contains {(field : Field) in field.icon == .courseEffort }
    }
    
    var t_showingEndDate : Bool {
        return self.fields.contains {(field : Field) in field.icon == .courseEnd }
    }
    
    var t_showingPlayButton : Bool {
        return !self.playButton.isHidden
    }
    
    var t_showingShortDescription : Bool {
        return !self.blurbLabel.isHidden
    }
}

