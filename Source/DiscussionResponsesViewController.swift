//
//  DiscussionResponsesViewController.swift
//  edX
//
//  Created by Lim, Jake on 5/12/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

private let GeneralPadding: CGFloat = 8.0

private let cellButtonStyle = OEXTextStyle(weight:.normal, size:.large, color: OEXStyles.shared.neutralDark())
private let cellIconSelectedStyle = cellButtonStyle.withColor(OEXStyles.shared.primaryBaseColor())
private let responseMessageStyle = OEXTextStyle(weight: .normal, size: .large, color: OEXStyles.shared.neutralDark())

class DiscussionCellButton: UIButton {
    var indexPath: IndexPath?
    
}

class DiscussionPostCell: UITableViewCell {
    static let identifier = "DiscussionPostCell"

    @IBOutlet fileprivate var titleLabel: UILabel!
    @IBOutlet fileprivate var bodyTextLabel: UILabel!
    @IBOutlet fileprivate var visibilityLabel: UILabel!
    @IBOutlet fileprivate var authorButton: UIButton!
    @IBOutlet fileprivate var responseCountLabel:UILabel!
    @IBOutlet fileprivate var voteButton: DiscussionCellButton!
    @IBOutlet fileprivate var followButton: DiscussionCellButton!
    @IBOutlet fileprivate var reportButton: DiscussionCellButton!
    @IBOutlet fileprivate var separatorLine: UIView!
    @IBOutlet fileprivate var separatorLineHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var authorProfileImage: UIImageView!
    @IBOutlet weak var authorNameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        
        for elem in [
                (voteButton, Icon.upVote, nil as String?),
                (followButton, Icon.followStar, Strings.discussionFollow),
                (reportButton, Icon.reportFlag, Strings.discussionReport)
            ] {
            let buttonText = NSAttributedString.joinInNaturalLayout([elem.1.attributedTextWithStyle(cellButtonStyle, inline: true),
                cellButtonStyle.attributedString(withText: elem.2 ?? "")])
            elem.0.setAttributedTitle(buttonText, for:[])
        }
        
        separatorLine.backgroundColor = OEXStyles.shared.standardDividerColor
        separatorLineHeightConstraint.constant = OEXStyles.dividerSize()

        voteButton.localizedHorizontalContentAlignment = .leading
        followButton.localizedHorizontalContentAlignment = .center
        reportButton.localizedHorizontalContentAlignment = .trailing
        authorButton.localizedHorizontalContentAlignment = .leading
        DiscussionHelper.styleAuthorProfileImageView(authorProfileImage)
    }
    
    func setAccessibility(_ thread: DiscussionThread) {
        
        var accessibilityString = ""
        let sentenceSeparator = ", "
        
        if let title = thread.title {
            accessibilityString.append(title + sentenceSeparator)
        }
        
        if let body = thread.rawBody {
            accessibilityString.append(body + sentenceSeparator)
        }
        
        if let date = dateLabel.text {
            accessibilityString.append(Strings.Accessibility.discussionPostedOn(date: date) + sentenceSeparator)
        }
        
        if let author = authorNameLabel.text {
            accessibilityString.append(Strings.accessibilityBy + " " + author + sentenceSeparator)
        }
        
        if let visibility = visibilityLabel.text {
            accessibilityString.append(visibility)
        }
        
        if let responseCount = responseCountLabel.text {
            accessibilityString.append(responseCount)
        }
        
        self.accessibilityLabel = accessibilityString
        
        if let authorName = authorNameLabel.text {
            self.authorButton.accessibilityLabel = authorName
            self.authorButton.accessibilityHint = Strings.accessibilityShowUserProfileHint
        }
    }
}

class DiscussionResponseCell: UITableViewCell {
    static let identifier = "DiscussionResponseCell"
    
    fileprivate static let margin : CGFloat = 8.0
    
    @IBOutlet fileprivate var containerView: UIView!
    @IBOutlet fileprivate var bodyTextView: UITextView!
    @IBOutlet fileprivate var authorButton: UIButton!
    @IBOutlet fileprivate var voteButton: DiscussionCellButton!
    @IBOutlet fileprivate var reportButton: DiscussionCellButton!
    @IBOutlet fileprivate var commentButton: DiscussionCellButton!
    @IBOutlet fileprivate var commentBox: UIView!
    @IBOutlet fileprivate var endorsedLabel: UILabel!
    @IBOutlet fileprivate var separatorLine: UIView!
    @IBOutlet fileprivate var separatorLineHeightConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate var endorsedByButton: UIButton!
    @IBOutlet weak var authorProfileImage: UIImageView!
    @IBOutlet weak var authorNameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .none
        
        for (button, icon, text) in [
            (reportButton!, Icon.reportFlag, Strings.discussionReport)]
        {
            let iconString = icon.attributedTextWithStyle(cellButtonStyle, inline: true)
            let buttonText = NSAttributedString.joinInNaturalLayout([iconString,
                cellButtonStyle.attributedString(withText: text)])
            button.setAttributedTitle(buttonText, for:[])
        }
        
        commentBox.backgroundColor = OEXStyles.shared.neutralXXLight()
        
        separatorLine.backgroundColor = OEXStyles.shared.standardDividerColor
        separatorLineHeightConstraint.constant = OEXStyles.dividerSize()

        voteButton.localizedHorizontalContentAlignment = .leading
        reportButton.localizedHorizontalContentAlignment = .trailing
        authorButton.localizedHorizontalContentAlignment = .leading
        endorsedByButton.localizedHorizontalContentAlignment = .leading

        containerView.applyBorderStyle(BorderStyle())
        
        accessibilityTraits = UIAccessibilityTraitHeader
        bodyTextView.isAccessibilityElement = false
        endorsedByButton.isAccessibilityElement = false
    }
    
    var endorsed : Bool = false {
        didSet {
            endorsedLabel.isHidden = !endorsed
            endorsedByButton.isHidden = !endorsed
        }
    }
    
    var endorsedTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared.utilitySuccessBase())
    }
    
    override func updateConstraints() {
        if endorsedByButton.isHidden {
            bodyTextView.snp.updateConstraints({ (make) in
                make.bottom.equalTo(separatorLine.snp.top).offset(-StandardVerticalMargin)
            })
        }
        
        super.updateConstraints()
        
    }
    
    func setAccessibility(_ response: DiscussionComment) {
        
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
        
        if endorsedByButton.isHidden == false {
            if let endorsed = endorsedByButton.attributedTitle(for: UIControlState())?.string  {
                accessibilityString.append(endorsed + sentenceSeparator)
            }
        }
        
        if response.childCount > 0 {
            accessibilityString.append(Strings.commentsToResponse(count: response.childCount))
        }
        
        self.accessibilityLabel = accessibilityString
        
        if let authorName = authorNameLabel.text {
            self.authorButton.accessibilityLabel = authorName
            self.authorButton.accessibilityHint = Strings.accessibilityShowUserProfileHint
        }
    }
}


class DiscussionResponsesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DiscussionNewCommentViewControllerDelegate, DiscussionCommentsViewControllerDelegate, InterfaceOrientationOverriding {
    typealias Environment = NetworkManagerProvider & OEXRouterProvider & OEXConfigProvider & OEXAnalyticsProvider

    enum TableSection : Int {
        case post = 0
        case endorsedResponses = 1
        case responses = 2
    }
    
    var environment: Environment!
    var courseID: String!
    var threadID: String!
    
    var loadController : LoadStateViewController?
    var paginationController : PaginationController<DiscussionComment>?
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var contentView: UIView!
    
    fileprivate let addResponseButton = UIButton(type: .system)
    fileprivate let responsesDataController = DiscussionResponsesDataController()
    var thread: DiscussionThread?
    var postFollowing = false

    func loadedThread(_ thread : DiscussionThread) {
        let hadThread = self.thread != nil
        self.thread = thread
        if !hadThread {
            loadResponses()
            logScreenEvent()
        }
        let styles = OEXStyles.shared
        let footerStyle = OEXTextStyle(weight: .normal, size: .large, color: OEXStyles.shared.neutralWhite())
        
        let icon = postClosed ? Icon.closed : Icon.create
        let text = postClosed ? Strings.responsesClosed : Strings.addAResponse
        
        let buttonTitle = NSAttributedString.joinInNaturalLayout([icon.attributedTextWithStyle(footerStyle.withSize(.xSmall)),
            footerStyle.attributedString(withText: text)])
        
        addResponseButton.setAttributedTitle(buttonTitle, for: [])
        addResponseButton.backgroundColor = postClosed ? styles.neutralBase() : styles.primaryXDarkColor()
        addResponseButton.isEnabled = !postClosed
        
        addResponseButton.oex_removeAllActions()
        if !thread.closed {
            addResponseButton.oex_addAction({ [weak self] (action : Any) -> Void in
                if let owner = self, let thread = owner.thread {
                    owner.environment.router?.showDiscussionNewCommentFromController(owner, courseID: owner.courseID, thread: thread, context: .thread(thread))
                }
                } , for: UIControlEvents.touchUpInside)
        }
        
        self.navigationItem.title = navigationItemTitleForThread(thread)
        
        tableView.reloadSections(IndexSet(integer: TableSection.post.rawValue) , with: .fade)
    }
    
    var titleTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .large, color: OEXStyles.shared.neutralXDark())
    }
    
    var detailTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .large, color: OEXStyles.shared.neutralXDark())
    }
    
    var infoTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .large, color: OEXStyles.shared.neutralDark())

    }
    
    override func viewDidLoad() {
        assert(environment != nil)
        assert(courseID != nil)
        
        super.viewDidLoad()
        
        self.view.backgroundColor = OEXStyles.shared.discussionsBackgroundColor
        self.contentView.backgroundColor = OEXStyles.shared.neutralXLight()
        tableView.backgroundColor = UIColor.clear
        tableView.delegate = self
        tableView.dataSource = self
        
        loadController = LoadStateViewController()
        
        addResponseButton.contentVerticalAlignment = .center
        view.addSubview(addResponseButton)
        addResponseButton.snp.makeConstraints{ (make) -> Void in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.height.equalTo(OEXStyles.shared.standardFooterHeight)
            make.bottom.equalTo(view.snp.bottom)
            make.top.equalTo(tableView.snp.bottom)
        }
        
        tableView.estimatedRowHeight = 160.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        loadController?.setupInController(self, contentView: contentView)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        markThreadAsRead()
    }
    
    override var shouldAutorotate : Bool {
        return true
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    fileprivate func logScreenEvent(){
        if let thread = thread {
            
            self.environment.analytics.trackDiscussionScreen(withName: OEXAnalyticsScreenViewThread, courseId: self.courseID, value: thread.title, threadId: thread.threadID, topicId: thread.topicId, responseID: nil)
        }
    }
    
    func navigationItemTitleForThread(_ thread : DiscussionThread) -> String {
        switch thread.type {
        case .Discussion:
            return Strings.discussion
        case .Question:
            return thread.hasEndorsed ? Strings.answeredQuestion : Strings.unansweredQuestion
        }
    }
    
    fileprivate var postClosed : Bool {
        return thread?.closed ?? false
    }
    
    fileprivate func markThreadAsRead() {
        let apiRequest = DiscussionAPI.readThread(true, threadID: threadID)
        self.environment.networkManager.taskForRequest(apiRequest) {[weak self] result in
            if let thread = result.data {
                self?.loadedThread(thread)
                self?.tableView.reloadSections(NSIndexSet(index: TableSection.post.rawValue) as IndexSet , with: .fade)
            }
        }
    }
    
    fileprivate func loadResponses() {
        if let thread = thread {
            if thread.type == .Question {
                // load answered responses
                loadAnsweredResponses()
            }
            else {
                loadUnansweredResponses()
            }
        }
    }
    
    fileprivate func loadAnsweredResponses() {
        
        guard let thread = thread else { return }
        
        postFollowing = thread.following
        
        let paginator = WrappedPaginator(networkManager: self.environment.networkManager) { page in
            return DiscussionAPI.getResponses(self.environment.router?.environment, threadID: thread.threadID, threadType: thread.type, endorsedOnly: true, pageNumber: page)
        }
        
        paginationController = PaginationController (paginator: paginator, tableView: self.tableView)
        
        paginationController?.stream.listen(self, success:
            { [weak self] responses in
                self?.loadController?.state = .loaded
                self?.responsesDataController.endorsedResponses = responses
                self?.tableView.reloadData()
                UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil)
                if self?.paginationController?.hasNext ?? false { }
                else {
                    // load unanswered responses
                    self?.loadUnansweredResponses()
                }
                
            }, failure: { [weak self] (error) -> Void in
                self?.loadController?.state = LoadState.failed(error)
                
            })
        
        paginationController?.loadMore()
    }
    
    fileprivate func loadUnansweredResponses() {
        
        guard let thread = thread else { return }
        
        let paginator = WrappedPaginator(networkManager: self.environment.networkManager) { page in
            return DiscussionAPI.getResponses(self.environment.router?.environment, threadID: thread.threadID, threadType: thread.type, pageNumber: page)
        }
        
        paginationController = PaginationController (paginator: paginator, tableView: self.tableView)
        
        paginationController?.stream.listen(self, success:
            { [weak self] responses in
                self?.loadController?.state = .loaded
                self?.responsesDataController.responses = responses
                self?.tableView.reloadData()
                UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil)
                
            }, failure: { [weak self] (error) -> Void in
                // endorsed responses are loaded in separate request and also populated in different section
                if (self?.responsesDataController.endorsedResponses.count)! <= 0 {
                    self?.loadController?.state = LoadState.failed(error)
                }
                else {
                    self?.loadController?.state = .loaded
                }
            })
        
        paginationController?.loadMore()
    }
    
    @IBAction func commentTapped(_ sender: AnyObject) {
        if let button = sender as? DiscussionCellButton, let indexPath = button.indexPath {
            
            let aResponse:DiscussionComment?
            
            switch TableSection(rawValue: indexPath.section) {
            case .some(.endorsedResponses):
                aResponse = responsesDataController.endorsedResponses[indexPath.row]
            case .some(.responses):
                aResponse = responsesDataController.responses[indexPath.row]
            default:
                aResponse = nil
            }
            
            if let response = aResponse {
                if response.childCount == 0{
                    if !postClosed {
                        guard let thread = thread else { return }
                        
                        environment.router?.showDiscussionNewCommentFromController(self, courseID: courseID, thread:thread, context: .comment(response))
                    }
                } else {
                    guard let thread = thread else { return }
                    
                    environment.router?.showDiscussionCommentsFromViewController(self, courseID : courseID, response: response, closed : postClosed, thread: thread)
                }
            }
        }
    }
    
    // Mark - tableview delegate methods

    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch TableSection(rawValue: section) {
        case .some(.post): return 1
        case .some(.endorsedResponses): return responsesDataController.endorsedResponses.count
        case .some(.responses): return responsesDataController.responses.count
        case .none:
            assert(false, "Unknown table section")
            return 0
        }
    }
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        switch TableSection(rawValue: indexPath.section) {
        case .some(.post):
            cell.backgroundColor = UIColor.white
        case .some(.endorsedResponses):
            cell.backgroundColor = UIColor.clear
        case .some(.responses):
            cell.backgroundColor = UIColor.clear
        default:
            assert(false, "Unknown table section")
        }
    }
    
    func applyThreadToCell(_ cell: DiscussionPostCell) -> UITableViewCell {
        if let thread = self.thread {
            cell.titleLabel.attributedText = titleTextStyle.attributedString(withText: thread.title)
            
            cell.bodyTextLabel.attributedText = detailTextStyle.attributedString(withText: thread.rawBody)
            
            let visibilityString : String
            if let cohortName = thread.groupName {
                visibilityString = Strings.postVisibility(cohort: cohortName)
            }
            else {
                visibilityString = Strings.postVisibilityEveryone
            }
            cell.visibilityLabel.attributedText = infoTextStyle.attributedString(withText: visibilityString)
            
            DiscussionHelper.styleAuthorDetails(thread.author, authorLabel: thread.authorLabel, createdAt: thread.createdAt, hasProfileImage: thread.hasProfileImage, imageURL: thread.imageURL, authoNameLabel: cell.authorNameLabel, dateLabel: cell.dateLabel, authorButton: cell.authorButton, imageView: cell.authorProfileImage, viewController: self, router: environment.router)

            if let responseCount = thread.responseCount {
                let icon = Icon.comment.attributedTextWithStyle(infoTextStyle)
                let countLabelText = infoTextStyle.attributedString(withText: Strings.response(count: responseCount))
                
                let labelText = NSAttributedString.joinInNaturalLayout([icon,countLabelText])
                cell.responseCountLabel.attributedText = labelText
            }
            else {
                cell.responseCountLabel.attributedText = nil
            }
            
            updateVoteText(cell.voteButton, voteCount: thread.voteCount, voted: thread.voted)
            updateFollowText(cell.followButton, following: thread.following)
        }
        
        // vote a post (thread) - User can only vote on post and response not on comment.
        cell.voteButton.oex_removeAllActions()
        cell.voteButton.oex_addAction({[weak self] (action : Any) -> Void in
            if let owner = self, let button = action as? DiscussionCellButton, let thread = owner.thread {
                button.isEnabled = false
                
                let apiRequest = DiscussionAPI.voteThread(thread.voted, threadID: thread.threadID)
                
                owner.environment.networkManager.taskForRequest(apiRequest) {[weak self] result in
                    button.isEnabled = true
                    
                    if let thread: DiscussionThread = result.data {
                        self?.loadedThread(thread)
                        owner.updateVoteText(cell.voteButton, voteCount: thread.voteCount, voted: thread.voted)
                    }
                    else {
                        self?.showOverlayMessage(DiscussionHelper.messageForError(result.error))
                    }
                }
            }
            } , for: UIControlEvents.touchUpInside)
        
        // follow a post (thread) - User can only follow original post, not response or comment.
        cell.followButton.oex_removeAllActions()
        cell.followButton.oex_addAction({[weak self] (sender : Any) -> Void in
            if let owner = self, let thread = owner.thread {
                let apiRequest = DiscussionAPI.followThread(owner.postFollowing, threadID: thread.threadID)
                
                owner.environment.networkManager.taskForRequest(apiRequest) { result in
                    if let thread: DiscussionThread = result.data {
                        owner.updateFollowText(cell.followButton, following: thread.following)
                        owner.postFollowing = thread.following
                    }
                    else {
                        self?.showOverlayMessage(DiscussionHelper.messageForError(result.error))
                    }
                }
            }
            } , for: UIControlEvents.touchUpInside)
        
        if let item = self.thread {
            updateVoteText(cell.voteButton, voteCount: item.voteCount, voted: item.voted)
            updateFollowText(cell.followButton, following: item.following)
            updateReportText(cell.reportButton, report: thread!.abuseFlagged)
        }
        
        // report (flag) a post (thread) - User can report on post, response, or comment.
        cell.reportButton.oex_removeAllActions()
        cell.reportButton.oex_addAction({[weak self] (action : Any) -> Void in
            if let owner = self, let item = owner.thread {
                let apiRequest = DiscussionAPI.flagThread(!item.abuseFlagged, threadID: item.threadID)
                
                owner.environment.networkManager.taskForRequest(apiRequest) { result in
                    if let thread = result.data {
                        self?.thread?.abuseFlagged = thread.abuseFlagged
                        owner.updateReportText(cell.reportButton, report: thread.abuseFlagged)
                    }
                    else {
                        self?.showOverlayMessage(DiscussionHelper.messageForError(result.error))
                    }
                }
            }
            } , for: UIControlEvents.touchUpInside)
        
        if let thread = self.thread {
            cell.setAccessibility(thread)
        }
        
        
        return cell

    }
    
    func cellForResponseAtIndexPath(_ indexPath : IndexPath, response: DiscussionComment) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DiscussionResponseCell.identifier, for: indexPath) as! DiscussionResponseCell
        
        cell.bodyTextView.attributedText = detailTextStyle.markdownString(withText: response.renderedBody)
        
        if let thread = thread {
            let formatedTitle = response.formattedUserLabel(response.endorsedBy, date: response.endorsedAt,label: response.endorsedByLabel ,endorsedLabel: true, threadType: thread.type, textStyle: infoTextStyle)
            
            cell.endorsedByButton.setAttributedTitle(formatedTitle, for: [])
            
            cell.endorsedByButton.snp.updateConstraints({ (make) in
                make.width.equalTo(formatedTitle.singleLineWidth() + StandardHorizontalMargin)
            })
        }
        
        DiscussionHelper.styleAuthorDetails(response.author, authorLabel: response.authorLabel, createdAt: response.createdAt, hasProfileImage: response.hasProfileImage, imageURL: response.imageURL, authoNameLabel: cell.authorNameLabel, dateLabel: cell.dateLabel, authorButton: cell.authorButton, imageView: cell.authorProfileImage, viewController: self, router: environment.router)
        
        DiscussionHelper.styleAuthorProfileImageView(cell.authorProfileImage)
        
        let profilesEnabled = self.environment.config.profilesEnabled
        
        if profilesEnabled && response.endorsed {
            cell.endorsedByButton.oex_removeAllActions()
            cell.endorsedByButton.oex_addAction({ [weak self] _ in
                
                guard let endorsedBy = response.endorsedBy else { return }
                
                self?.environment.router?.showProfileForUsername(self, username: endorsedBy, editable: false)
                }, for: .touchUpInside)
        }

        let prompt : String
        let icon : Icon
        
        if response.childCount == 0 {
            prompt = postClosed ? Strings.commentsClosed : Strings.addAComment
            icon = postClosed ? Icon.closed : Icon.comment
        }
        else {
            prompt = Strings.commentsToResponse(count: response.childCount)
            icon = Icon.comment
        }
        
        let iconText = icon.attributedTextWithStyle(responseMessageStyle, inline : true)
        let styledPrompt = responseMessageStyle.attributedString(withText: prompt)
        let title =
        NSAttributedString.joinInNaturalLayout([iconText,styledPrompt])
        UIView.performWithoutAnimation {
            cell.commentButton.setAttributedTitle(title, for: [])
        }
        
        let voteCount = response.voteCount
        let voted = response.voted
        cell.commentButton.indexPath = indexPath

        updateVoteText(cell.voteButton, voteCount: voteCount, voted: voted)
        updateReportText(cell.reportButton, report: response.abuseFlagged)
        
        cell.voteButton.indexPath = indexPath
        // vote/unvote a response - User can vote on post and response not on comment.
        cell.voteButton.oex_removeAllActions()
        cell.voteButton.oex_addAction({[weak self] (action : Any) -> Void in
            
            let apiRequest = DiscussionAPI.voteResponse(response.voted, responseID: response.commentID)
            
            self?.environment.networkManager.taskForRequest(apiRequest) { result in
                if let comment: DiscussionComment = result.data {
                    self?.responsesDataController.updateResponsesWithComment(comment)
                    self?.updateVoteText(cell.voteButton, voteCount: comment.voteCount, voted: comment.voted)
                    self?.tableView.reloadData()
                }
                else {
                    self?.showOverlayMessage(DiscussionHelper.messageForError(result.error))
                }
            }
            } , for: UIControlEvents.touchUpInside)
        
        cell.reportButton.indexPath = indexPath
        // report (flag)/unflag a response - User can report on post, response, or comment.
        cell.reportButton.oex_removeAllActions()
        cell.reportButton.oex_addAction({[weak self] (action : Any) -> Void in
            let apiRequest = DiscussionAPI.flagComment(!response.abuseFlagged, commentID: response.commentID)
            
            self?.environment.networkManager.taskForRequest(apiRequest) { result in
                if let comment = result.data {
                    self?.responsesDataController.updateResponsesWithComment(comment)
                    
                    self?.updateReportText(cell.reportButton, report: comment.abuseFlagged)
                    self?.tableView.reloadData()
                }
                else {
                    self?.showOverlayMessage(DiscussionHelper.messageForError(result.error))
                }
            }
            } , for: UIControlEvents.touchUpInside)
        
        cell.endorsed = response.endorsed
        
        if let thread = thread {
            DiscussionHelper.updateEndorsedTitle(thread, label: cell.endorsedLabel, textStyle: cell.endorsedTextStyle)
            cell.setAccessibility(response)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch TableSection(rawValue: indexPath.section) {
        case .some(.post):
            let cell = tableView.dequeueReusableCell(withIdentifier: DiscussionPostCell.identifier, for: indexPath) as! DiscussionPostCell
            return applyThreadToCell(cell)
        case .some(.endorsedResponses):
            return cellForResponseAtIndexPath(indexPath, response: responsesDataController.endorsedResponses[indexPath.row])
        case .some(.responses):
            return cellForResponseAtIndexPath(indexPath, response: responsesDataController.responses[indexPath.row])
        case .none:
            assert(false, "Unknown table section")
            return UITableViewCell()
        }
    }

    fileprivate func updateVoteText(_ button: DiscussionCellButton, voteCount: Int, voted: Bool) {
        // TODO: show upvote and downvote depending on voted?
        let iconStyle = voted ? cellIconSelectedStyle : cellButtonStyle
        let buttonText = NSAttributedString.joinInNaturalLayout([
            Icon.upVote.attributedTextWithStyle(iconStyle, inline : true),
            cellButtonStyle.attributedString(withText: Strings.vote(count: voteCount))])
        button.setAttributedTitle(buttonText, for:.normal)
        button.accessibilityHint = voted ? Strings.Accessibility.discussionUnvoteHint : Strings.Accessibility.discussionVoteHint
    }
    
    fileprivate func updateFollowText(_ button: DiscussionCellButton, following: Bool) {
        let iconStyle = following ? cellIconSelectedStyle : cellButtonStyle
        let buttonText = NSAttributedString.joinInNaturalLayout([Icon.followStar.attributedTextWithStyle(iconStyle, inline : true),
            cellButtonStyle.attributedString(withText: following ? Strings.discussionUnfollow : Strings.discussionFollow )])
        button.setAttributedTitle(buttonText, for:[])
        button.accessibilityHint = following ? Strings.Accessibility.discussionUnfollowHint : Strings.Accessibility.discussionFollowHint
    }
    
    fileprivate func updateReportText(_ button: DiscussionCellButton, report: Bool) {
        let iconStyle = report ? cellIconSelectedStyle : cellButtonStyle
        let buttonText = NSAttributedString.joinInNaturalLayout([Icon.reportFlag.attributedTextWithStyle(iconStyle, inline : true),
            cellButtonStyle.attributedString(withText: report ? Strings.discussionUnreport : Strings.discussionReport )])
        button.setAttributedTitle(buttonText, for:[])
        button.accessibilityHint = report ? Strings.Accessibility.discussionUnreportHint : Strings.Accessibility.discussionReportHint
    }
    
    func increaseResponseCount() {
        let count = thread?.responseCount ?? 0
        thread?.responseCount = count + 1
    }
    
    fileprivate func showAddedResponse(_ comment: DiscussionComment) {
        responsesDataController.responses.append(comment)
        tableView.reloadData()
        let indexPath = IndexPath(row: responsesDataController.responses.count - 1, section: TableSection.responses.rawValue)
        tableView.scrollToRow(at: indexPath, at: .top, animated: false)
    }
    
    // MARK:- DiscussionNewCommentViewControllerDelegate method
    
    func newCommentController(_ controller: DiscussionNewCommentViewController, addedComment comment: DiscussionComment) {
        
        switch controller.currentContext() {
        case .thread(_):
            if !(paginationController?.hasNext ?? false) {
                showAddedResponse(comment)
            }
            
            increaseResponseCount()
            showOverlayMessage(Strings.discussionThreadPosted)
        case .comment(_):
            responsesDataController.addedChildComment(comment)
            self.showOverlayMessage(Strings.discussionCommentPosted)
        }
        
        self.tableView.reloadData()
    }
    
    // MARK:- DiscussionCommentsViewControllerDelegate
    
    func discussionCommentsView(_ controller: DiscussionCommentsViewController, updatedComment comment: DiscussionComment) {
        responsesDataController.updateResponsesWithComment(comment)
        self.tableView.reloadData()
    }
}

extension Date {
    
    fileprivate var shouldDisplayTimeSpan : Bool {
        let currentDate = Date()
        return (currentDate as NSDate).days(from: self) < 7
    }
    
    public var displayDate : String {
        let date = self as NSDate
        return shouldDisplayTimeSpan ? date.timeAgoSinceNow() : OEXDateFormatting.formatAsDateMonthYearStringWithDate(date)
    }
}

extension NSDate {
    fileprivate var shouldDisplayTimeSpan : Bool {
        return (self as Date).shouldDisplayTimeSpan
    }
    
    public var displayDate : String {
        return (self as Date).displayDate
    }
}

protocol AuthorLabelProtocol {
    var createdAt : Date? { get }
    var author : String? { get }
    var authorLabel : String? { get }
}


extension DiscussionComment : AuthorLabelProtocol {}
extension DiscussionThread : AuthorLabelProtocol {}

extension AuthorLabelProtocol {
    
    func formattedUserLabel(_ textStyle: OEXTextStyle) -> NSAttributedString {
        return formattedUserLabel(author, date: createdAt, label: authorLabel, threadType: nil, textStyle: textStyle)
    }
    
    func formattedUserLabel(_ name: String?, date: Date?, label: String?, endorsedLabel:Bool = false, threadType:DiscussionThreadType?, textStyle : OEXTextStyle) -> NSAttributedString {
        var attributedStrings = [NSAttributedString]()
        
        if let threadType = threadType {
            switch threadType {
            case .Question where endorsedLabel:
                attributedStrings.append(textStyle.attributedString(withText: Strings.markedAnswer))
            case .Discussion where endorsedLabel:
                attributedStrings.append(textStyle.attributedString(withText: Strings.endorsed))
            default: break
            }
        }
        
        if let displayDate = date {
            attributedStrings.append(textStyle.attributedString(withText: displayDate.displayDate))
        }
        
        let highlightStyle = OEXMutableTextStyle(textStyle: textStyle)
        
        if let _ = name, OEXConfig.shared().profilesEnabled {
            highlightStyle.color = OEXStyles.shared.primaryBaseColor()
            highlightStyle.weight = .semiBold
        }
        else {
            highlightStyle.color = OEXStyles.shared.neutralBase()
            highlightStyle.weight = textStyle.weight
        }
            
        let formattedUserName = highlightStyle.attributedString(withText: name ?? Strings.anonymous.oex_lowercaseStringInCurrentLocale())
        
        let byAuthor =  textStyle.apply(Strings.byAuthorLowerCase) (formattedUserName)
        
        attributedStrings.append(byAuthor)
        
        if let authorLabel = label {
            attributedStrings.append(textStyle.attributedString(withText: Strings.parenthesis(text: authorLabel)))
        }
        
        return NSAttributedString.joinInNaturalLayout(attributedStrings)
    }
}
