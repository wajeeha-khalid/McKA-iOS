//
//  DiscussionNewPostViewController.swift
//  edX
//
//  Created by Tang, Jeff on 6/1/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

struct DiscussionNewThread {
    let courseID: String
    let topicID: String
    let type: DiscussionThreadType
    let title: String
    let rawBody: String
}

protocol DiscussionNewPostViewControllerDelegate : class {
    func newPostController(_ controller  : DiscussionNewPostViewController, addedPost post: DiscussionThread)
}

open class DiscussionNewPostViewController: UIViewController, UITextViewDelegate, MenuOptionsViewControllerDelegate, InterfaceOrientationOverriding {
 
    public typealias Environment = DataManagerProvider & NetworkManagerProvider & OEXRouterProvider & OEXAnalyticsProvider
    
    fileprivate let minBodyTextHeight : CGFloat = 66 // height for 3 lines of text

    fileprivate let environment: Environment
    
    fileprivate let growingTextController = GrowingTextViewController()
    fileprivate let insetsController = ContentInsetsController()
    
    @IBOutlet fileprivate var scrollView: UIScrollView!
    @IBOutlet fileprivate var backgroundView: UIView!
    @IBOutlet fileprivate var contentTextView: OEXPlaceholderTextView!
    @IBOutlet fileprivate var titleTextField: UITextField!
    @IBOutlet fileprivate var discussionQuestionSegmentedControl: UISegmentedControl!
    @IBOutlet fileprivate var bodyTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate var topicButton: UIButton!
    @IBOutlet fileprivate var postButton: SpinnerButton!
    @IBOutlet weak var contentTitleLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    fileprivate let loadController = LoadStateViewController()
    fileprivate let courseID: String
    fileprivate let topics = BackedStream<[DiscussionTopic]>()
    fileprivate var selectedTopic: DiscussionTopic?
    fileprivate var optionsViewController: MenuOptionsViewController?
    weak var delegate: DiscussionNewPostViewControllerDelegate?
    fileprivate let tapButton = UIButton()
    
    var titleTextStyle : OEXTextStyle{
        return OEXTextStyle(weight : .normal, size: .base, color: OEXStyles.shared.neutralDark())
    }
    
    fileprivate var selectedThreadType: DiscussionThreadType = .Discussion {
        didSet {
            switch selectedThreadType {
            case .Discussion:
                self.contentTitleLabel.attributedText = NSAttributedString.joinInNaturalLayout([titleTextStyle.attributedString(withText: Strings.courseDashboardDiscussion), titleTextStyle.attributedString(withText: Strings.asteric)])
                postButton.applyButtonStyle(OEXStyles.shared.filledPrimaryButtonStyle,withTitle: Strings.postDiscussion)
                contentTextView.accessibilityLabel = Strings.courseDashboardDiscussion
            case .Question:
                self.contentTitleLabel.attributedText = NSAttributedString.joinInNaturalLayout([titleTextStyle.attributedString(withText: Strings.question), titleTextStyle.attributedString(withText: Strings.asteric)])
                postButton.applyButtonStyle(OEXStyles.shared.filledPrimaryButtonStyle, withTitle: Strings.postQuestion)
                contentTextView.accessibilityLabel = Strings.question
            }
        }
    }
    
    public init(environment: Environment, courseID: String, selectedTopic : DiscussionTopic?) {
        self.environment = environment
        self.courseID = courseID
        
        super.init(nibName: "DiscussionNewPostViewController", bundle: nil)
        
        let stream = environment.dataManager.courseDataManager.discussionManagerForCourseWithID(courseID).topics
        topics.backWithStream(stream.map {
            return DiscussionTopic.linearizeTopics($0)
            }
        )
        
        self.selectedTopic = selectedTopic
    }
    
    fileprivate var firstSelectableTopic : DiscussionTopic? {
        
        let selectablePredicate = { (topic : DiscussionTopic) -> Bool in
            topic.isSelectable
        }
        
        guard let topics = self.topics.value, let selectableTopicIndex = topics.firstIndexMatching(selectablePredicate) else {
            return nil
        }
        return topics[selectableTopicIndex]
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func postTapped(_ sender: AnyObject) {
        postButton.isEnabled = false
        postButton.showProgress = true
        // create new thread (post)

        if let topic = selectedTopic, let topicID = topic.id {
            let newThread = DiscussionNewThread(courseID: courseID, topicID: topicID, type: selectedThreadType, title: titleTextField.text ?? "", rawBody: contentTextView.text)
            let apiRequest = DiscussionAPI.createNewThread(newThread)
            environment.networkManager.taskForRequest(apiRequest) {[weak self] result in
                self?.postButton.isEnabled = true
                self?.postButton.showProgress = false
                
                if let post = result.data {
                    self?.delegate?.newPostController(self!, addedPost: post)
                    self?.dismiss(animated: true, completion: nil)
                }
                else {
                 self?.showOverlayMessage(DiscussionHelper.messageForError(result.error))
                }
            }
        }
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = Strings.post
        let cancelItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
        cancelItem.oex_setAction { [weak self]() -> Void in
            self?.dismiss(animated: true, completion: nil)
        }
        self.navigationItem.leftBarButtonItem = cancelItem
        contentTitleLabel.isAccessibilityElement = false
        titleLabel.isAccessibilityElement = false
        titleLabel.attributedText = NSAttributedString.joinInNaturalLayout([titleTextStyle.attributedString(withText: Strings.title), titleTextStyle.attributedString(withText: Strings.asteric)])
        contentTextView.textContainer.lineFragmentPadding = 0
        contentTextView.textContainerInset = OEXStyles.shared.standardTextViewInsets
        contentTextView.typingAttributes = OEXStyles.shared.textAreaBodyStyle.attributes
        contentTextView.placeholderTextColor = OEXStyles.shared.neutralLight()
        contentTextView.applyBorderStyle(OEXStyles.shared.entryFieldBorderStyle)
        contentTextView.delegate = self
        titleTextField.accessibilityLabel = Strings.title
        
        self.view.backgroundColor = OEXStyles.shared.neutralXXLight()
        
        configureSegmentControl()
        titleTextField.defaultTextAttributes = OEXStyles.shared.textAreaBodyStyle.attributes
        setTopicsButtonTitle()
        let insets = OEXStyles.shared.standardTextViewInsets
        topicButton.titleEdgeInsets = UIEdgeInsetsMake(0, insets.left, 0, insets.right)
        topicButton.accessibilityHint = Strings.accessibilityShowsDropdownHint
        
        topicButton.applyBorderStyle(OEXStyles.shared.entryFieldBorderStyle)
        topicButton.localizedHorizontalContentAlignment = .leading
        
        let dropdownLabel = UILabel()
        dropdownLabel.attributedText = Icon.dropdown.attributedTextWithStyle(titleTextStyle)
        topicButton.addSubview(dropdownLabel)
        dropdownLabel.snp.makeConstraints { (make) -> Void in
            make.trailing.equalTo(topicButton).offset(-insets.right)
            make.top.equalTo(topicButton).offset(topicButton.frame.size.height / 2.0 - 5.0)
        }
        
        topicButton.oex_addAction({ [weak self] (_ : Any) in
            self?.showTopicPicker()
        } , for: UIControlEvents.touchUpInside)
        
        postButton.isEnabled = false
        
        titleTextField.oex_addAction({[weak self] _ in
            self?.validatePostButton()
            }, for: .editingChanged)

        self.growingTextController.setupWithScrollView(scrollView, textView: contentTextView, bottomView: postButton)
        self.insetsController.setupInController(self, scrollView: scrollView)
        
        // Force setting it to call didSet which is only called out of initialization context
        self.selectedThreadType = .Question
        
        loadController.setupInController(self, contentView: self.scrollView)
        
        topics.listen(self, success : {[weak self]_ in
            self?.loadedData()
            }, failure : {[weak self] error in
                self?.loadController.state = LoadState.failed(error)
            })
        
        backgroundView.addSubview(tapButton)
        backgroundView.sendSubview(toBack: tapButton)
        tapButton.backgroundColor = UIColor.clear
        tapButton.frame = CGRect(x: 0, y: 0, width: backgroundView.frame.size.width, height: backgroundView.frame.size.height)
        tapButton.isAccessibilityElement = false
        tapButton.accessibilityLabel = Strings.accessibilityHideKeyboard
        tapButton.oex_addAction({[weak self] (sender) in
            self?.view.endEditing(true)
            }, for: .touchUpInside)
    }
    
    fileprivate func configureSegmentControl() {
        discussionQuestionSegmentedControl.removeAllSegments()
        let questionIcon = Icon.question.attributedTextWithStyle(titleTextStyle)
        let questionTitle = NSAttributedString.joinInNaturalLayout([questionIcon,
            titleTextStyle.attributedString(withText: Strings.question)])
        
        let discussionIcon = Icon.comments.attributedTextWithStyle(titleTextStyle)
        let discussionTitle = NSAttributedString.joinInNaturalLayout([discussionIcon,
            titleTextStyle.attributedString(withText: Strings.discussion)])
        
        let segmentOptions : [(title : NSAttributedString, value : DiscussionThreadType)] = [
            (title : questionTitle, value : .Question),
            (title : discussionTitle, value : .Discussion),
            ]
        
        for i in 0..<segmentOptions.count {
            discussionQuestionSegmentedControl.insertSegmentWithAttributedTitle(segmentOptions[i].title, index: i, animated: false)
            discussionQuestionSegmentedControl.subviews[i].accessibilityLabel = segmentOptions[i].title.string
        }
        
        discussionQuestionSegmentedControl.oex_addAction({ [weak self] (control:Any) -> Void in
            if let segmentedControl = control as? UISegmentedControl {
                let index = segmentedControl.selectedSegmentIndex
                let threadType = segmentOptions[index].value
                self?.selectedThreadType = threadType
                self?.updateSelectedTabColor()
            }
            else {
                assert(true, "Invalid Segment ID, Remove this segment index OR handle it in the ThreadType enum")
            }
            } , for: UIControlEvents.valueChanged)
        discussionQuestionSegmentedControl.tintColor = UIColor(red:0.15, green:0.56, blue:0.94, alpha:1)//OEXStyles.shared.neutralDark()
        discussionQuestionSegmentedControl.setTitleTextAttributes([NSForegroundColorAttributeName: OEXStyles.shared.neutralWhite()], for: UIControlState.selected)
        discussionQuestionSegmentedControl.selectedSegmentIndex = 0
        
        updateSelectedTabColor()
    }
    
    fileprivate func updateSelectedTabColor() {
        // //UIsegmentControl don't Multiple tint color so updating tint color of subviews to match desired behaviour
        discussionQuestionSegmentedControl.subviews.forEach { subView in
            if (subView as? UIControl)?.isSelected == true {
                subView.tintColor = OEXStyles.shared.primaryBaseColor()
            } else {
                subView.tintColor = UIColor(red:0.15, green:0.56, blue:0.94, alpha:1)//OEXStyles.shared.neutralDark()
            }
        }
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.environment.analytics.trackDiscussionScreen(withName: OEXAnalyticsScreenCreateTopicThread, courseId: self.courseID, value: selectedTopic?.name, threadId: nil, topicId: selectedTopic?.id, responseID: nil)
    }
    
    override open var shouldAutorotate : Bool {
        return true
    }
    
    override open var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    fileprivate func loadedData() {
        loadController.state = topics.value?.count == 0 ? LoadState.empty(icon: .noTopics, message : Strings.unableToLoadCourseContent) : .loaded
        
        if selectedTopic == nil {
            selectedTopic = firstSelectableTopic
        }
        
        setTopicsButtonTitle()
    }
    
    fileprivate func setTopicsButtonTitle() {
        if let topic = selectedTopic, let name = topic.name {
            let title = Strings.topic(topic: name)
            topicButton.setAttributedTitle(OEXTextStyle(weight : .normal, size: .base, color: OEXStyles.shared.neutralDark()).attributedString(withText: title), for: .normal)
        }
    }
    
    func showTopicPicker() {
        if self.optionsViewController != nil {
            return
        }
        
        view.endEditing(true)
        
        self.optionsViewController = MenuOptionsViewController()
        self.optionsViewController?.delegate = self
        
        guard let courseTopics = topics.value else  {
            //Don't need to configure an empty state here because it's handled in viewDidLoad()
            return
        }
        
        self.optionsViewController?.options = courseTopics.map {
            return MenuOptionsViewController.MenuOption(depth : $0.depth, label : $0.name ?? "")
        }
        
        self.optionsViewController?.selectedOptionIndex = self.selectedTopicIndex()
        self.view.addSubview(self.optionsViewController!.view)
        
        self.optionsViewController!.view.snp.makeConstraints { (make) -> Void in
            make.trailing.equalTo(self.topicButton)
            make.leading.equalTo(self.topicButton)
            make.top.equalTo(self.topicButton.snp.bottom).offset(-3)
            make.bottom.equalTo(self.view.snp.bottom)
        }
        
        self.optionsViewController?.view.alpha = 0.0
        UIView.animate(withDuration: 0.3, animations: {
            self.optionsViewController?.view.alpha = 1.0
        }) 
    }
    
    fileprivate func selectedTopicIndex() -> Int? {
        guard let selected = selectedTopic else {
            return 0
        }
        return self.topics.value?.firstIndexMatching {
                return $0.id == selected.id
        }
    }
    
    open func textViewDidChange(_ textView: UITextView) {
        validatePostButton()
        growingTextController.handleTextChange()
    }
    
    open func menuOptionsController(_ controller : MenuOptionsViewController, canSelectOptionAtIndex index : Int) -> Bool {
        return self.topics.value?[index].isSelectable ?? false
    }
    
    fileprivate func validatePostButton() {
        self.postButton.isEnabled = !(titleTextField.text ?? "").isEmpty && !contentTextView.text.isEmpty && self.selectedTopic != nil
    }

    func menuOptionsController(_ controller : MenuOptionsViewController, selectedOptionAtIndex index: Int) {
        selectedTopic = self.topics.value?[index]
        
        if let topic = selectedTopic, topic.id != nil {
            setTopicsButtonTitle()
            UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, titleTextField);
            UIView.animate(withDuration: 0.3, animations: {
                self.optionsViewController?.view.alpha = 0.0
                }, completion: {[weak self](finished: Bool) in
                    self?.optionsViewController?.view.removeFromSuperview()
                    self?.optionsViewController = nil
            })
        }
    }
    
    open override func viewDidLayoutSubviews() {
        self.insetsController.updateInsets()
        growingTextController.scrollToVisible()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        tapButton.isAccessibilityElement = true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        tapButton.isAccessibilityElement = false
    }
    
    open func textViewDidBeginEditing(_ textView: UITextView) {
        tapButton.isAccessibilityElement = true
    }
    
    open func textViewDidEndEditing(_ textView: UITextView) {
        tapButton.isAccessibilityElement = false
    }
}

extension UISegmentedControl {
    //UIsegmentControl didn't support attributedTitle by default
    func insertSegmentWithAttributedTitle(_ title: NSAttributedString, index: NSInteger, animated: Bool) {
        let segmentLabel = UILabel()
        segmentLabel.backgroundColor = UIColor.clear
        segmentLabel.textAlignment = .center
        segmentLabel.attributedText = title
        segmentLabel.sizeToFit()
        self.insertSegment(with: segmentLabel.toImage(), at: 1, animated: false)
    }
}

extension UILabel {
    func toImage()-> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 0)
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext();
        return image;
    }
}

// For use in testing only
extension DiscussionNewPostViewController {
    public func t_topicsLoaded() -> edXCore.Stream<[DiscussionTopic]> {
        return topics
    }
}
