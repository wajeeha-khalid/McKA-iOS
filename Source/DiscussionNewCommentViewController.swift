//
//  DiscussionNewCommentViewController.swift
//  edX
//
//  Created by Tang, Jeff on 6/5/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

protocol DiscussionNewCommentViewControllerDelegate : class {
    func newCommentController(_ controller  : DiscussionNewCommentViewController, addedComment comment: DiscussionComment)
}

open class DiscussionNewCommentViewController: UIViewController, UITextViewDelegate, InterfaceOrientationOverriding {
    
    public typealias Environment = DataManagerProvider & NetworkManagerProvider & OEXRouterProvider & OEXAnalyticsProvider & OEXStylesProvider
    
    public enum Context {
        case thread(DiscussionThread)
        case comment(DiscussionComment)
        
        var threadID: String {
            switch self {
            case let .thread(thread): return thread.threadID
            case let .comment(comment): return comment.threadID
            }
        }
        
        var rawBody: String? {
            switch self {
            case let .thread(thread): return thread.rawBody
            case let .comment(comment): return comment.rawBody
            }
        }
        
        var renderedBody: String? {
            switch self {
            case let .thread(thread): return thread.renderedBody
            case let .comment(comment): return comment.renderedBody
            }
        }
        
        var newCommentParentID: String? {
            switch self {
            case .thread(_): return nil
            case let .comment(comment): return comment.commentID
            }
        }
        
        var author: String? {
            switch self {
            case let .thread(thread): return thread.author
            case let .comment(comment): return comment.author
            }
        }
    }

    fileprivate let environment: Environment
    
    weak var delegate: DiscussionNewCommentViewControllerDelegate?
    
    @IBOutlet fileprivate var containerView: UIView!
    @IBOutlet fileprivate var scrollView: UIScrollView!
    @IBOutlet fileprivate var responseTitle: UILabel!
    @IBOutlet fileprivate var answerLabel: UILabel!
    @IBOutlet fileprivate var responseTextView: UITextView!
    @IBOutlet fileprivate var contentTextView: OEXPlaceholderTextView!
    @IBOutlet fileprivate var addCommentButton: SpinnerButton!
    @IBOutlet fileprivate var contentTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentTitleLabel: UILabel!
    @IBOutlet fileprivate var authorButton: UIButton!
    @IBOutlet weak var authorNamelabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var authorProfileImage: UIImageView!
    
    fileprivate let insetsController = ContentInsetsController()
    fileprivate let growingTextController = GrowingTextViewController()
    
    fileprivate let context: Context
    fileprivate let courseID : String
    fileprivate let thread: DiscussionThread?
    
    fileprivate var editingStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(weight: OEXTextWeight.normal, size: .base, color: OEXStyles.shared.neutralDark())
        style.lineBreakMode = .byWordWrapping
        return style
    }
    
    fileprivate var isEndorsed : Bool = false {
        didSet {
            containerView.applyBorderStyle(BorderStyle())
            answerLabel.isHidden = !isEndorsed
            responseTitle.snp.updateConstraints { (make) -> Void in
                make.top.equalTo(authorProfileImage.snp.bottom).offset(StandardVerticalMargin)
            }
        }
    }
    
    public init(environment: Environment, courseID : String, thread: DiscussionThread?, context: Context) {
        self.environment = environment
        self.context = context
        self.courseID = courseID
        self.thread = thread
        super.init(nibName: "DiscussionNewCommentViewController", bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    @IBAction func addCommentTapped(_ sender: AnyObject) {
        // TODO convert to a spinner
        addCommentButton.isEnabled = false
        addCommentButton.showProgress = true
        // create new response or comment
        
        let apiRequest = DiscussionAPI.createNewComment(context.threadID, text: contentTextView.text, parentID: context.newCommentParentID)
        
        environment.networkManager.taskForRequest(apiRequest) {[weak self] result in
            self?.addCommentButton.showProgress = false
            if let comment = result.data,
                let courseID = self?.courseID {
                    let dataManager = self?.environment.dataManager.courseDataManager.discussionManagerForCourseWithID(courseID)
                    dataManager?.commentAddedStream.send((threadID: comment.threadID, comment: comment))
                    self?.delegate?.newCommentController(self!, addedComment: comment)
                    self?.dismiss(animated: true, completion: nil)
            }
            else {
                self?.addCommentButton.isEnabled = true
                self?.showOverlayMessage(DiscussionHelper.messageForError(result.error))
            }
        }
    }
    
    fileprivate var responseTitleStyle : OEXTextStyle {
        return OEXTextStyle(weight : .normal, size : .large, color : OEXStyles.shared.neutralXDark())
    }
    
    fileprivate var answerLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .small, color: OEXStyles.shared.utilitySuccessBase())
    }
    
    fileprivate var responseTextViewStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared.neutralDark())
    }
    
    fileprivate var personTimeLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .xxSmall, color: OEXStyles.shared.neutralBase())
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = OEXStyles.shared.discussionsBackgroundColor
        
        setupContext()
        
        contentTextView.textContainer.lineFragmentPadding = 0
        contentTextView.textContainerInset = environment.styles.standardTextViewInsets
        contentTextView.typingAttributes = environment.styles.textAreaBodyStyle.attributes
        contentTextView.placeholderTextColor = environment.styles.neutralBase()
        contentTextView.textColor = environment.styles.neutralDark()
        contentTextView.applyBorderStyle(environment.styles.entryFieldBorderStyle)
        contentTextView.delegate = self
        
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addAction {[weak self] _ in
            self?.contentTextView.endEditing(true)
        }
        self.view.addGestureRecognizer(tapGesture)
        
        let cancelItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
        cancelItem.oex_setAction { [weak self]() -> Void in
            self?.dismiss(animated: true, completion: nil)
        }
        self.navigationItem.leftBarButtonItem = cancelItem

        self.addCommentButton.isEnabled = false
        
        self.insetsController.setupInController(self, scrollView: scrollView)
        self.growingTextController.setupWithScrollView(scrollView, textView: contentTextView, bottomView: addCommentButton)
        
        DiscussionHelper.styleAuthorProfileImageView(authorProfileImage)
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        logScreenEvent()
        authorDetails()
    }
    
    override open var shouldAutorotate : Bool {
        return true
    }
    
    override open var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    fileprivate func logScreenEvent(){
        switch context {
        case let .thread(thread):
            self.environment.analytics.trackDiscussionScreen(withName: OEXAnalyticsScreenAddThreadResponse, courseId: self.courseID, value: thread.title, threadId: thread.threadID, topicId: thread.topicId, responseID: nil)
        case let .comment(comment):
            self.environment.analytics.trackDiscussionScreen(withName: OEXAnalyticsScreenAddResponseComment, courseId: self.courseID, value: thread?.title, threadId: comment.threadID, topicId: nil, responseID: comment.commentID)
        }
        
    }
    
    fileprivate func authorDetails() {
        switch context {
        case let .comment(comment):
            DiscussionHelper.styleAuthorDetails(comment.author, authorLabel: comment.authorLabel, createdAt: comment.createdAt, hasProfileImage: comment.hasProfileImage, imageURL: comment.imageURL, authoNameLabel: authorNamelabel, dateLabel: dateLabel, authorButton: authorButton, imageView: authorProfileImage, viewController: self, router: environment.router)
            setAuthorAccessibility(comment.author, date: comment.createdAt)
        case let .thread(thread):
            DiscussionHelper.styleAuthorDetails(thread.author, authorLabel: thread.authorLabel, createdAt: thread.createdAt, hasProfileImage: thread.hasProfileImage, imageURL: thread.imageURL, authoNameLabel: authorNamelabel, dateLabel: dateLabel, authorButton: authorButton, imageView: authorProfileImage, viewController: self, router: environment.router)
            setAuthorAccessibility(thread.author, date: thread.createdAt)
        }
    }
    
    fileprivate func setAuthorAccessibility(_ author: String?, date: Date?) {
        if let author = author, let date = date {
            authorButton.accessibilityLabel = "\(Strings.byAuthor(authorName: author)), \(date.displayDate)"
            authorButton.accessibilityHint = Strings.accessibilityShowUserProfileHint
        }
        
        dateLabel.isAccessibilityElement = false
        authorNamelabel.isAccessibilityElement = false
    }
    
    open func textViewDidChange(_ textView: UITextView) {
        
        self.validateAddButton()
        self.growingTextController.handleTextChange()
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.insetsController.updateInsets()
        self.growingTextController.scrollToVisible()
    }
    
    fileprivate func validateAddButton() {
        addCommentButton.isEnabled = !contentTextView.text.isEmpty
    }
    
    // For determining the context of the screen and also manipulating the relevant elements on screen
    fileprivate func setupContext() {
        let buttonTitle : String
        let titleText : String
        let navigationItemTitle : String
        
        switch context {
        case let .thread(thread):
            buttonTitle = Strings.addResponse
            titleText = Strings.addAResponse
            navigationItemTitle = Strings.addResponse
            responseTitle.attributedText = responseTitleStyle.attributedString(withText: thread.title)
            contentTextView.accessibilityLabel = Strings.addAResponse
            self.isEndorsed = false
        case let .comment(comment):
            buttonTitle = Strings.addComment
            titleText = Strings.addAComment
            navigationItemTitle = Strings.addComment
            contentTextView.accessibilityLabel = Strings.addAComment
            responseTitle.snp.makeConstraints{ (make) -> Void in
                make.height.equalTo(0)
            }
            self.isEndorsed = comment.endorsed
        }
        
        
        responseTextView.attributedText = responseTextViewStyle.markdownString(withText: context.renderedBody ?? "")
        
        addCommentButton.applyButtonStyle(environment.styles.filledPrimaryButtonStyle, withTitle: buttonTitle)
        self.contentTitleLabel.attributedText = NSAttributedString.joinInNaturalLayout([responseTextViewStyle.attributedString(withText: titleText), responseTextViewStyle.attributedString(withText: Strings.asteric)])
        self.contentTitleLabel.isAccessibilityElement = false
        self.navigationItem.title = navigationItemTitle
            
        if case .comment(_) = self.context, let thread = thread{
            DiscussionHelper.updateEndorsedTitle(thread, label: answerLabel, textStyle: answerLabelStyle)
        }
    }

}

extension DiscussionNewCommentViewController {
    
    public func currentContext() -> Context {
        return context
    }
}
