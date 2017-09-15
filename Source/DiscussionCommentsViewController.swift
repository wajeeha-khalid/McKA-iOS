//
//  DiscussionCommentsViewController.swift
//  edX
//
//  Created by Tang, Jeff on 5/28/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

private var commentTextStyle : OEXTextStyle {
    return OEXTextStyle(weight: .normal, size: .large, color : OEXStyles.shared.neutralDark())
}

private var smallTextStyle : OEXTextStyle {
    return OEXTextStyle(weight: .normal, size: .large, color : OEXStyles.shared.neutralDark())
}

private var smallIconStyle : OEXTextStyle {
    return OEXTextStyle(weight: .normal, size: .large, color: OEXStyles.shared.neutralDark())
}

private let smallIconSelectedStyle = smallIconStyle.withColor(OEXStyles.shared.primaryBaseColor())

private let UserProfileImageSize = CGSize(width: 40.0,height: 40.0)

class DiscussionCommentCell: UITableViewCell {
    
    fileprivate let bodyTextView = UITextView()
    fileprivate let authorButton = UIButton(type: .system)
    fileprivate let commentCountOrReportIconButton = UIButton(type: .system)
    fileprivate let divider = UIView()
    fileprivate let containerView = UIView()
    fileprivate let endorsedLabel = UILabel()
    fileprivate let authorProfileImage = UIImageView()
    fileprivate let authorNameLabel = UILabel()
    fileprivate let dateLabel = UILabel()
    
    fileprivate var endorsedTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared.utilitySuccessBase())
    }
    
    fileprivate func setEndorsed(_ endorsed : Bool) {
        endorsedLabel.isHidden = !endorsed
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
        applyStandardSeparatorInsets()
        addSubViews()
        setConstraints()
        bodyTextView.isEditable = false
        bodyTextView.dataDetectorTypes = UIDataDetectorTypes.all
        bodyTextView.isScrollEnabled = false
        bodyTextView.backgroundColor = UIColor.clear
        containerView.isUserInteractionEnabled = true
        commentCountOrReportIconButton.localizedHorizontalContentAlignment = .trailing
        contentView.backgroundColor = OEXStyles.shared.discussionsBackgroundColor
        divider.backgroundColor = OEXStyles.shared.discussionsBackgroundColor
        containerView.backgroundColor = OEXStyles.shared.neutralWhiteT()
        containerView.applyBorderStyle(BorderStyle())
        accessibilityTraits = UIAccessibilityTraitHeader
        bodyTextView.isAccessibilityElement = false
    }
    
    fileprivate func addSubViews() {
       contentView.addSubview(containerView)
        containerView.addSubview(bodyTextView)
        containerView.addSubview(authorButton)
        containerView.addSubview(endorsedLabel)
        containerView.addSubview(commentCountOrReportIconButton)
        containerView.addSubview(divider)
        containerView.addSubview(authorProfileImage)
        containerView.addSubview(authorNameLabel)
        containerView.addSubview(dateLabel)
    }
    
    fileprivate func setConstraints() {
        
        containerView.snp.makeConstraints { (make) -> Void in
            make.edges.equalTo(contentView).inset(UIEdgeInsetsMake(0, StandardHorizontalMargin, 0, StandardHorizontalMargin))
        }
        
        authorProfileImage.snp.makeConstraints { (make) in
            make.leading.equalTo(containerView).offset(StandardHorizontalMargin)
            make.top.equalTo(containerView).offset(StandardVerticalMargin)
            make.width.equalTo(UserProfileImageSize.width)
            make.height.equalTo(UserProfileImageSize.height)
        }
        
        authorNameLabel.snp.makeConstraints { (make) in
            make.top.equalTo(authorProfileImage)
            make.leading.equalTo(authorProfileImage.snp.trailing).offset(StandardHorizontalMargin)
        }
        
        dateLabel.snp.makeConstraints { (make) in
            make.top.equalTo(authorNameLabel.snp.bottom)
            make.leading.equalTo(authorNameLabel)
        }
        
        authorButton.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(authorProfileImage)
            make.leading.equalTo(contentView)
            make.bottom.equalTo(authorProfileImage)
            make.trailing.equalTo(dateLabel)
            make.trailing.equalTo(authorNameLabel)
        }
        
        endorsedLabel.snp.makeConstraints { (make) -> Void in
            make.leading.equalTo(dateLabel)
            make.top.equalTo(dateLabel.snp.bottom)
        }
        
        bodyTextView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(authorProfileImage.snp.bottom).offset(StandardVerticalMargin)
            make.leading.equalTo(authorProfileImage)
            make.trailing.equalTo(containerView).offset(-StandardHorizontalMargin)
        }
        
        commentCountOrReportIconButton.snp.makeConstraints { (make) -> Void in
            make.trailing.equalTo(containerView).offset(-OEXStyles.shared.standardHorizontalMargin())
            make.top.equalTo(authorNameLabel)
        }
        
        divider.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(bodyTextView.snp.bottom).offset(StandardVerticalMargin)
            make.leading.equalTo(containerView)
            make.trailing.equalTo(containerView)
            make.height.equalTo(StandardVerticalMargin)
            make.bottom.equalTo(containerView)
        }
    }
    
    func useResponse(_ response : DiscussionComment, viewController : DiscussionCommentsViewController) {
        divider.snp.updateConstraints { (make) in
            make.height.equalTo(StandardVerticalMargin)
        }
        bodyTextView.attributedText = commentTextStyle.markdownString(withText: response.renderedBody)
        DiscussionHelper.styleAuthorDetails(response.author, authorLabel: response.authorLabel, createdAt: response.createdAt, hasProfileImage: response.hasProfileImage, imageURL: response.imageURL, authoNameLabel: authorNameLabel, dateLabel: dateLabel, authorButton: authorButton, imageView: authorProfileImage, viewController: viewController, router: viewController.environment.router)
        
        let message = Strings.comment(count: response.childCount)
        let buttonTitle = NSAttributedString.joinInNaturalLayout([
            Icon.comment.attributedTextWithStyle(smallIconStyle),
            smallTextStyle.attributedString(withText: message)])
        commentCountOrReportIconButton.setAttributedTitle(buttonTitle, for: .normal)
        
        setEndorsed(response.endorsed)
        setNeedsLayout()
        layoutIfNeeded()
        
        DiscussionHelper.styleAuthorProfileImageView(authorProfileImage)
        
        setAccessiblity(commentCountOrReportIconButton.currentAttributedTitle?.string)
    }
    
    func useComment(_ comment : DiscussionComment, inViewController viewController : DiscussionCommentsViewController, index: NSInteger) {
        divider.snp.updateConstraints { (make) in
            make.height.equalTo(2)
        }
        bodyTextView.attributedText = commentTextStyle.markdownString(withText: comment.renderedBody)
        updateReportText(commentCountOrReportIconButton, report: comment.abuseFlagged)
        DiscussionHelper.styleAuthorDetails(comment.author, authorLabel: comment.authorLabel, createdAt: comment.createdAt, hasProfileImage: comment.hasProfileImage, imageURL: comment.imageURL, authoNameLabel: authorNameLabel, dateLabel: dateLabel, authorButton: authorButton, imageView: authorProfileImage, viewController: viewController, router: viewController.environment.router)
        
        commentCountOrReportIconButton.oex_removeAllActions()
        commentCountOrReportIconButton.oex_addAction({[weak viewController] _ -> Void in
            
            let apiRequest = DiscussionAPI.flagComment(!comment.abuseFlagged, commentID: comment.commentID)
            viewController?.environment.networkManager.taskForRequest(apiRequest) { result in
                if let response = result.data {
                    if (viewController?.comments.count)! > index && viewController?.comments[index].commentID == response.commentID {
                        viewController?.comments[index] = response
                        self.updateReportText(self.commentCountOrReportIconButton, report: response.abuseFlagged)
                        viewController?.tableView.reloadData()
                    }
                }
                else {
                    viewController?.showOverlayMessage(DiscussionHelper.messageForError(result.error))
                }
            }
            }, for: UIControlEvents.touchUpInside)
        
        
        setEndorsed(false)
        setNeedsLayout()
        layoutIfNeeded()
        DiscussionHelper.styleAuthorProfileImageView(authorProfileImage)
        
        setAccessiblity(nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func updateReportText(_ button: UIButton, report: Bool) {
        
        let iconStyle = report ? smallIconSelectedStyle : smallIconStyle
        let reportIcon = Icon.reportFlag.attributedTextWithStyle(iconStyle)
        let reportTitle = smallTextStyle.attributedString(withText: (report ? Strings.discussionUnreport : Strings.discussionReport ))
        
        let buttonTitle = NSAttributedString.joinInNaturalLayout([reportIcon, reportTitle])
        button.setAttributedTitle(buttonTitle, for: [])
        
        button.snp.remakeConstraints { (make) in
            make.top.equalTo(contentView).offset(StandardVerticalMargin)
            make.width.equalTo(buttonTitle.singleLineWidth() + StandardHorizontalMargin)
            make.trailing.equalTo(contentView).offset(-2*StandardHorizontalMargin)
        }
        
        button.accessibilityHint = report ? Strings.Accessibility.discussionUnreportHint : Strings.Accessibility.discussionReportHint
    }
    
    func setAccessiblity(_ commentCount : String?) {
        var accessibilityString = ""
        let sentenceSeparator = ", "
        
        let body = bodyTextView.attributedText.string
        accessibilityString.append(body + sentenceSeparator)
            
        if let date = dateLabel.text {
            accessibilityString.append(Strings.Accessibility.discussionPostedOn(date: date) + sentenceSeparator)
        }
        
        if let author = authorNameLabel.text {
            accessibilityString.append(Strings.accessibilityBy + " " + author + sentenceSeparator)
        }
        
        if let endorsed = endorsedLabel.text, !endorsedLabel.isHidden {
            accessibilityString.append(endorsed + sentenceSeparator)
        }
        
        if let comments = commentCount {
            accessibilityString.append(comments)
            commentCountOrReportIconButton.isAccessibilityElement = false
        }
        
        accessibilityLabel = accessibilityString
        
        if let authorName = authorNameLabel.text {
            self.authorButton.accessibilityLabel = authorName
            self.authorButton.accessibilityHint = Strings.accessibilityShowUserProfileHint
        }
    }
}

protocol DiscussionCommentsViewControllerDelegate: class {
    
    func discussionCommentsView(_ controller  : DiscussionCommentsViewController, updatedComment comment: DiscussionComment)
}

class DiscussionCommentsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DiscussionNewCommentViewControllerDelegate, InterfaceOrientationOverriding {
    
    typealias Environment = DataManagerProvider & NetworkManagerProvider & OEXRouterProvider & OEXAnalyticsProvider
    
    fileprivate enum TableSection : Int {
        case response = 0
        case comments = 1
    }
    
    fileprivate let identifierCommentCell = "CommentCell"
    fileprivate let environment: Environment
    fileprivate let courseID: String
    fileprivate let discussionManager : DiscussionDataManager
    fileprivate var loadController : LoadStateViewController
    fileprivate let contentView = UIView()
    fileprivate let addCommentButton = UIButton(type: .system)
    fileprivate var tableView: UITableView!
    fileprivate var comments : [DiscussionComment]  = []
    fileprivate var responseItem: DiscussionComment
    weak var delegate: DiscussionCommentsViewControllerDelegate?
    
    //Since didSet doesn't get called from within initialization context, we need to set it with another variable.
    fileprivate var commentsClosed : Bool = false {
        didSet {
            let styles = OEXStyles.shared
            
            addCommentButton.backgroundColor = commentsClosed ? styles.neutralBase() : styles.primaryXDarkColor()
            
            let textStyle = OEXTextStyle(weight : .normal, size: .large, color: OEXStyles.shared.neutralWhite())
            let icon = commentsClosed ? Icon.closed : Icon.create
            let buttonText = commentsClosed ? Strings.commentsClosed : Strings.addAComment
            let buttonTitle = NSAttributedString.joinInNaturalLayout([icon.attributedTextWithStyle(textStyle.withSize(.xSmall)), textStyle.attributedString(withText: buttonText)])
            
            addCommentButton.setAttributedTitle(buttonTitle, for: [])
            addCommentButton.isEnabled = !commentsClosed
            
            if (!commentsClosed) {
                addCommentButton.oex_addAction({[weak self] (_ : Any) in
                    if let owner = self {
                        guard let thread = owner.thread else { return }
                        
                        owner.environment.router?.showDiscussionNewCommentFromController(owner, courseID: owner.courseID, thread: thread, context: .comment(owner.responseItem))
                    }
                }, for: .touchUpInside)
            }
        }
    }
    
    fileprivate var commentID: String {
        return responseItem.commentID
    }
    
    var paginationController : PaginationController<DiscussionComment>?
    
    //Only used to set commentsClosed out of initialization context
    //TODO: Get rid of this variable when Swift improves
    fileprivate var closed : Bool = false
    fileprivate let thread: DiscussionThread?
    
    init(environment: Environment, courseID : String, responseItem: DiscussionComment, closed : Bool, thread: DiscussionThread?) {
        self.courseID = courseID
        self.environment = environment
        self.responseItem = responseItem
        self.thread = thread
        self.discussionManager = self.environment.dataManager.courseDataManager.discussionManagerForCourseWithID(self.courseID)
        self.closed = closed
        self.loadController = LoadStateViewController()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
 
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.register(DiscussionCommentCell.classForCoder(), forCellReuseIdentifier: identifierCommentCell)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        
        addSubviews()
        setStyles()
        setConstraints()
        
        loadController.setupInController(self, contentView: self.contentView)
        
        self.commentsClosed = self.closed
        
        initializePaginator()
        loadContent()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        logScreenEvent()
    }
    
    override var shouldAutorotate : Bool {
        return true
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    fileprivate func logScreenEvent() {
        self.environment.analytics.trackDiscussionScreen(withName: OEXAnalyticsScreenViewResponseComments, courseId: self.courseID, value: thread?.title, threadId: responseItem.threadID, topicId: nil, responseID: responseItem.commentID)
    }
    
    func addSubviews() {
        view.addSubview(contentView)
        contentView.addSubview(tableView)
        view.addSubview(addCommentButton)
    }
    
    func setStyles() {
        
        tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        tableView.applyStandardSeparatorInsets()
        tableView.backgroundColor = OEXStyles.shared.neutralXLight()
        tableView.contentInset = UIEdgeInsetsMake(10.0, 0, 0, 0)
        tableView.clipsToBounds = true
        
        self.navigationItem.title = Strings.comments
        view.backgroundColor = OEXStyles.shared.neutralXLight()
        self.contentView.backgroundColor = OEXStyles.shared.neutralXLight()
        
        addCommentButton.contentVerticalAlignment = .center
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
    }
    
    func setConstraints() {
        contentView.snp.makeConstraints { (make) -> Void in
            make.leading.equalTo(view.snp.leading)
            make.top.equalTo(view)
            make.trailing.equalTo(view.snp.trailing)
            make.bottom.equalTo(addCommentButton.snp.top)
        }
        
        addCommentButton.snp.makeConstraints{ (make) -> Void in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.height.equalTo(OEXStyles.shared.standardFooterHeight)
            make.bottom.equalTo(view.snp.bottom)
        }
        
        tableView.snp.makeConstraints { (make) -> Void in
            make.leading.equalTo(view.snp.leading)
            make.top.equalTo(view)
            make.trailing.equalTo(view.snp.trailing)
            make.bottom.equalTo(addCommentButton.snp.top)
        }
        
        
    }
    
    fileprivate func initializePaginator() {
        
        let commentID = self.commentID
        precondition(!commentID.isEmpty, "Shouldn't be showing comments for empty commentID")
        
        let paginator = WrappedPaginator(networkManager: self.environment.networkManager) { page in
            return DiscussionAPI.getComments(self.environment.router?.environment, commentID: commentID, pageNumber: page)
        }
        paginationController = PaginationController(paginator: paginator, tableView: self.tableView)
    }
    
    fileprivate func loadContent() {
        paginationController?.stream.listen(self, success:
            { [weak self] comments in
                self?.loadController.state = .loaded
                self?.comments = comments
                self?.tableView.reloadData()
                UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil)
            }, failure: { [weak self] (error) -> Void in
                self?.loadController.state = LoadState.failed(error)
        })
        
        paginationController?.loadMore()
    }
    
    fileprivate func showAddedComment(_ comment: DiscussionComment) {
        comments.append(comment)
        tableView.reloadData()
        let indexPath = IndexPath(row: comments.count - 1, section: TableSection.comments.rawValue)
        tableView.scrollToRow(at: indexPath, at: .top, animated: false)
    }
    
    // MARK - tableview delegate methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch TableSection(rawValue:section) {
        case .some(.response): return 1
        case .some(.comments): return comments.count
        case .none:
            assert(true, "Unexepcted table section")
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifierCommentCell, for: indexPath) as! DiscussionCommentCell
        
        switch TableSection(rawValue: indexPath.section) {
        case .some(.response):
            cell.useResponse(responseItem, viewController: self)
            if let thread = thread {
                DiscussionHelper.updateEndorsedTitle(thread, label: cell.endorsedLabel, textStyle: cell.endorsedTextStyle)
            }
            
            return cell
        case .some(.comments):
            cell.useComment(comments[indexPath.row], inViewController: self, index: indexPath.row)
            return cell
        case .none:
            assert(false, "Unknown table section")
            return UITableViewCell()
        }
    }
    
    // MARK- DiscussionNewCommentViewControllerDelegate method 
    
    func newCommentController(_ controller: DiscussionNewCommentViewController, addedComment comment: DiscussionComment) {
        responseItem.childCount += 1
        
        if !(paginationController?.hasNext ?? false) {
            showAddedComment(comment)
        }
        
        delegate?.discussionCommentsView(self, updatedComment: responseItem)
        showOverlayMessage(Strings.discussionCommentPosted)
    }
}

// Testing only
extension DiscussionCommentsViewController {
    var t_loaded : edXCore.Stream<()> {
        return self.paginationController!.stream.map {_ in
            return
        }
    }
}
