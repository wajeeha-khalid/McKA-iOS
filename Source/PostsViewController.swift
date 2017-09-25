//
//  PostsViewController.swift
//  edX
//
//  Created by Tang, Jeff on 5/19/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class PostsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, PullRefreshControllerDelegate, InterfaceOrientationOverriding, DiscussionNewPostViewControllerDelegate {

    typealias Environment = NetworkManagerProvider & OEXRouterProvider & OEXAnalyticsProvider
    
    enum Context {
        case Topic(DiscussionTopic)
        case following
        case search(String)
        case allPosts
        
        var allowsPosting : Bool {
            switch self {
            case .Topic: return true
            case .following: return true
            case .search: return false
            case .allPosts: return true
            }
        }
        
        var topic : DiscussionTopic? {
            switch self {
            case let .Topic(topic): return topic
            case .search(_): return nil
            case .following(_): return nil
            case .allPosts(_): return nil
            }
        }
        
        var navigationItemTitle : String? {
            switch self {
            case let .Topic(topic): return topic.name
            case .search(_): return Strings.searchResults
            case .following(_): return Strings.postsImFollowing
            case .allPosts(_): return Strings.allPosts
            }
        }

        //Strictly to be used to pass on to DiscussionNewPostViewController.
        var selectedTopic : DiscussionTopic? {
            switch self {
            case let .Topic(topic): return topic.isSelectable ? topic : topic.firstSelectableChild()
            case .search(_): return nil
            case .following(_): return nil
            case .allPosts(_): return nil
            }
        }
        
        var noResultsMessage : String {
            switch self {
            case .Topic(_): return Strings.noResultsFound
            case .allPosts: return Strings.noCourseResults
            case .following: return Strings.noFollowingResults
            case let .search(string) : return Strings.emptyResultset(queryString: string)
            }
        }
        
        fileprivate var queryString: String? {
            switch self {
            case .Topic(_): return nil
            case .allPosts: return nil
            case .following: return nil
            case let .search(string) : return string
            }
        }
        
    }
    var environment: Environment!
    fileprivate var paginationController : PaginationController<DiscussionThread>?
    
    fileprivate lazy var tableView = UITableView(frame: CGRect.zero, style: .plain)

    fileprivate let viewSeparator = UIView()
    fileprivate let loadController = LoadStateViewController()
    fileprivate let refreshController = PullRefreshController()
    fileprivate let insetsController = ContentInsetsController()
    
    fileprivate let refineLabel = UILabel()
    fileprivate let headerButtonHolderView = UIView()
    fileprivate let headerView = UIView()
    fileprivate var searchBar : UISearchBar?
    fileprivate let filterButton = PressableCustomButton()
    fileprivate let sortButton = PressableCustomButton()
    fileprivate let newPostButton = UIButton(type: .system)
    fileprivate let courseID: String
    
    fileprivate let contentView = UIView()
    
    fileprivate var context : Context?
    fileprivate let topicID: String?
    
    fileprivate var posts: [DiscussionThread] = []
    fileprivate var selectedFilter: DiscussionPostsFilter = .allPosts
    fileprivate var selectedOrderBy: DiscussionPostsSort = .recentActivity
    
    var searchBarDelegate : DiscussionSearchBarDelegate?
    
    fileprivate var queryString : String?
    fileprivate var refineTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared.neutralDark())
    }

    fileprivate var filterTextStyle : OEXTextStyle {
        return OEXTextStyle(weight : .normal, size: .base, color: OEXStyles.shared.primaryBaseColor())
    }
    
    fileprivate var hasResults:Bool = false
    
    required init(environment: Environment, courseID: String, topicID: String?, context: Context?) {
        self.courseID = courseID
        self.environment = environment
        self.topicID = topicID
        self.context = context
        
        super.init(nibName: nil, bundle: nil)
        
        configureSearchBar()
    }
    
    convenience init(environment: Environment, courseID: String, topicID: String?) {
        self.init(environment: environment, courseID : courseID, topicID: topicID, context: nil)
    }
    
    convenience init(environment: Environment, courseID: String, topic: DiscussionTopic) {
        self.init(environment: environment, courseID : courseID, topicID: nil, context: .Topic(topic))
    }
    
    convenience init(environment: Environment,courseID: String, queryString : String) {
        self.init(environment: environment, courseID : courseID, topicID: nil, context : .search(queryString))
    }
    
    ///Convenience initializer for All Posts and Followed posts
    convenience init(environment: Environment, courseID: String, following : Bool) {
        self.init(environment: environment, courseID : courseID, topicID: nil, context : following ? .following : .allPosts)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addSubviews()
        setConstraints()
        setStyles()
        
        tableView.register(PostTableViewCell.classForCoder(), forCellReuseIdentifier: PostTableViewCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.estimatedRowHeight = 150
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.applyStandardSeparatorInsets()
        if #available(iOS 9.0, *) {
            tableView.cellLayoutMarginsFollowReadableWidth = false
        }
        
        filterButton.oex_addAction(
            {[weak self] _ in
                self?.showFilterPicker()
            }, for: .touchUpInside)
        sortButton.oex_addAction(
            {[weak self] _ in
                self?.showSortPicker()
            }, for: .touchUpInside)
        newPostButton.oex_addAction(
            {[weak self] _ in
                if let owner = self {
                    owner.environment.router?.showDiscussionNewPostFromController(owner, courseID: owner.courseID, selectedTopic : owner.context?.selectedTopic)
                }
            }, for: .touchUpInside)

        loadController.setupInController(self, contentView: contentView)
        insetsController.setupInController(self, scrollView: tableView)
        refreshController.setupInScrollView(tableView)
        insetsController.addSource(refreshController)
        refreshController.delegate = self
        
        //set visibility of header view
        updateHeaderViewVisibility()
        
        loadContent()
        
        setAccessibility()
    }
    
    fileprivate func setAccessibility() {
        if let searchBar = searchBar {
            view.accessibilityElements = [searchBar, tableView]
        }
        else {
            view.accessibilityElements = [refineLabel, filterButton, sortButton, tableView, newPostButton]
        }
        
        updateAccessibility()
    }
    
    fileprivate func updateAccessibility() {
        
        filterButton.accessibilityLabel = Strings.Accessibility.discussionFilterBy(filterBy: titleForFilter(selectedFilter))
        filterButton.accessibilityHint = Strings.accessibilityShowsDropdownHint
        sortButton.accessibilityLabel = Strings.Accessibility.discussionSortBy(sortBy: titleForSort(selectedOrderBy))
        sortButton.accessibilityHint = Strings.accessibilityShowsDropdownHint
    }
    
    fileprivate func configureSearchBar() {
        guard let context = context, !context.allowsPosting else {
            return
        }
        
        searchBar = UISearchBar()
        searchBar?.applyStandardStyles(withPlaceholder: Strings.searchAllPosts)
        searchBar?.text = context.queryString
        searchBarDelegate = DiscussionSearchBarDelegate() { [weak self] text in
            self?.context = Context.search(text)
            self?.loadController.state = .initial
            self?.searchThreads(text)
            self?.searchBar?.delegate = self?.searchBarDelegate
        }
    }

    fileprivate func addSubviews() {
        view.addSubview(contentView)
        view.addSubview(headerView)
        if let searchBar = searchBar {
            view.addSubview(searchBar)
        }
        contentView.addSubview(tableView)
        headerView.addSubview(refineLabel)
        headerView.addSubview(headerButtonHolderView)
        headerButtonHolderView.addSubview(filterButton)
        headerButtonHolderView.addSubview(sortButton)
        view.addSubview(newPostButton)
        contentView.addSubview(viewSeparator)
    }
    
    fileprivate func setConstraints() {
        contentView.snp.remakeConstraints { (make) -> Void in
            if  context?.allowsPosting ?? false {
                make.top.equalTo(view)
            }
            //Else the top is equal to searchBar.snp.bottom
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            //The bottom is equal to newPostButton.snp.top
        }
        
        headerView.snp.remakeConstraints { (make) -> Void in
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.top.equalTo(contentView)
            make.height.equalTo(context?.allowsPosting ?? false ? 40 : 0)
        }
        
        searchBar?.snp.remakeConstraints({ (make) -> Void in
            make.top.equalTo(view)
            make.trailing.equalTo(contentView)
            make.leading.equalTo(contentView)
            make.bottom.equalTo(contentView.snp.top)
        })
        
        refineLabel.snp.remakeConstraints { (make) -> Void in
            make.leadingMargin.equalTo(headerView).offset(StandardHorizontalMargin)
            make.centerY.equalTo(headerView)
        }
        refineLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
        
        headerButtonHolderView.snp.remakeConstraints { (make) -> Void in
            make.leading.equalTo(refineLabel.snp.trailing)
            make.trailing.equalTo(headerView)
            make.bottom.equalTo(headerView)
            make.top.equalTo(headerView)
        }
        
        
        filterButton.snp.remakeConstraints{ (make) -> Void in
            make.leading.equalTo(headerButtonHolderView)
            make.trailing.equalTo(sortButton.snp.leading)
            make.centerY.equalTo(headerButtonHolderView)
        }
        
        sortButton.snp.remakeConstraints{ (make) -> Void in
            make.trailingMargin.equalTo(headerButtonHolderView)
            make.centerY.equalTo(headerButtonHolderView)
            make.width.equalTo(filterButton.snp.width)
        }
        newPostButton.snp.remakeConstraints{ (make) -> Void in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.height.equalTo(context?.allowsPosting ?? false ? OEXStyles.shared.standardFooterHeight : 0)
            make.top.equalTo(contentView.snp.bottom)
            make.bottom.equalTo(view)
        }
        
        tableView.snp.remakeConstraints { (make) -> Void in
            make.leading.equalTo(contentView)
            make.top.equalTo(viewSeparator.snp.bottom)
            make.trailing.equalTo(contentView)
            make.bottom.equalTo(newPostButton.snp.top)
        }
        
        viewSeparator.snp.remakeConstraints{ (make) -> Void in
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.height.equalTo(OEXStyles.dividerSize())
            make.top.equalTo(headerView.snp.bottom)
        }
    }

    fileprivate func setStyles() {
        
        let styles = OEXStyles.shared
        
        view.backgroundColor = OEXStyles.shared.standardBackgroundColor()
        
        self.refineLabel.attributedText = self.refineTextStyle.attributedString(withText: Strings.refine)
        
        var buttonTitle = NSAttributedString.joinInNaturalLayout(
            [Icon.filter.attributedTextWithStyle(filterTextStyle.withSize(.xSmall)),
                filterTextStyle.attributedString(withText: self.titleForFilter(self.selectedFilter))])
        filterButton.setAttributedTitle(buttonTitle, forState: [], animated : false)
        
        buttonTitle = NSAttributedString.joinInNaturalLayout([Icon.sort.attributedTextWithStyle(filterTextStyle.withSize(.xSmall)),
            filterTextStyle.attributedString(withText: Strings.recentActivity)])
        sortButton.setAttributedTitle(buttonTitle, forState: [], animated : false)
        
        newPostButton.backgroundColor = UIColor(colorLiteralRed:0.15, green:0.56, blue:0.94, alpha:1)
        
        let style = OEXTextStyle(weight : .normal, size: .large, color: styles.neutralWhite())
        buttonTitle = NSAttributedString.joinInNaturalLayout([Icon.create.attributedTextWithStyle(style.withSize(.small)),
            style.attributedString(withText: Strings.createANewPost)])
        newPostButton.setAttributedTitle(buttonTitle, for: [])
        
        newPostButton.contentVerticalAlignment = .center
        
        self.navigationItem.title = context?.navigationItemTitle
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        viewSeparator.backgroundColor = styles.neutralXLight()
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let selectedIndex = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndex, animated: false)
        }
    }
    
    override var shouldAutorotate : Bool {
        return true
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    fileprivate func logScreenEvent() {
        guard let context = context else {
            return
        }
        
        switch context {
        case let .Topic(topic):
            self.environment.analytics.trackDiscussionScreen(withName: OEXAnalyticsScreenViewTopicThreads, courseId: self.courseID, value: topic.name, threadId: nil, topicId: topic.id, responseID: nil)
        case let .search(query):
            self.environment.analytics.trackScreen(withName: OEXAnalyticsScreenSearchThreads, courseID: self.courseID, value: query, additionalInfo:["search_string":query])
        case .following:
            self.environment.analytics.trackDiscussionScreen(withName: OEXAnalyticsScreenViewTopicThreads, courseId: self.courseID, value: "posts_following", threadId: nil, topicId: "posts_following", responseID: nil)
        case .allPosts:
            self.environment.analytics.trackDiscussionScreen(withName: OEXAnalyticsScreenViewTopicThreads, courseId: self.courseID, value: "all_posts", threadId: nil, topicId: "all_posts", responseID: nil)
        }
    }
    
    fileprivate func loadTopic() {
        guard let topicID = topicID else {
            loadController.state = LoadState.failed(NSError.oex_unknownError())
            return
        }
        
        let apiRequest = DiscussionAPI.getTopicByID(courseID, topicID: topicID)
        self.environment.networkManager.taskForRequest(apiRequest) {[weak self] response in
            if let topics = response.data {
                //Sending signle topic id so always get a single topic
                self?.context = .Topic(topics[0])
                self?.navigationItem.title = self?.context?.navigationItemTitle
                self?.setConstraints()
                self?.loadContent()
            }
            else {
                self?.loadController.state = LoadState.failed(NSError.oex_unknownError())
            }
        }
    }
    
    fileprivate func loadContent() {
        guard let context = context else {
            // context is only nil in case if topic is selected
            loadTopic()
            return
        }
        
        logScreenEvent()
        
        switch context {
        case let .Topic(topic):
            loadPostsForTopic(topic, filter: selectedFilter, orderBy: selectedOrderBy)
        case let .search(query):
            searchThreads(query)
        case .following:
            loadFollowedPostsForFilter(selectedFilter, orderBy: selectedOrderBy)
        case .allPosts:
            loadPostsForTopic(nil, filter: selectedFilter, orderBy: selectedOrderBy)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        insetsController.updateInsets()
    }
    
    fileprivate func updateHeaderViewVisibility() {
        
        // if post has results then set hasResults yes
        hasResults = context?.allowsPosting ?? false && self.posts.count > 0
        
        headerView.isHidden = !hasResults
    }
    
    fileprivate func loadFollowedPostsForFilter(_ filter : DiscussionPostsFilter, orderBy: DiscussionPostsSort) {
        
        let paginator = WrappedPaginator(networkManager: self.environment.networkManager) { page in
            return DiscussionAPI.getFollowedThreads(courseID: self.courseID, filter: filter, orderBy: orderBy, pageNumber: page)
        }
        
        paginationController = PaginationController (paginator: paginator, tableView: self.tableView)
        
        loadThreads()
    }
    
    fileprivate func searchThreads(_ query : String) {
        
        let paginator = WrappedPaginator(networkManager: self.environment.networkManager) { page in
            return DiscussionAPI.searchThreads(courseID: self.courseID, searchText: query, pageNumber: page)
        }
        
        paginationController = PaginationController (paginator: paginator, tableView: self.tableView)
        
        loadThreads()
    }
    
    fileprivate func loadPostsForTopic(_ topic : DiscussionTopic?, filter: DiscussionPostsFilter, orderBy: DiscussionPostsSort) {
       
        var topicIDApiRepresentation : [String]?
        if let identifier = topic?.id {
            topicIDApiRepresentation = [identifier]
        }
            //Children's topic IDs if the topic is root node
        else if let discussionTopic = topic {
            topicIDApiRepresentation = discussionTopic.children.mapSkippingNils { $0.id }
        }
        
        let paginator = WrappedPaginator(networkManager: self.environment.networkManager) { page in
            return DiscussionAPI.getThreads(courseID: self.courseID, topicIDs: topicIDApiRepresentation, filter: filter, orderBy: orderBy, pageNumber: page)
        }
        
        paginationController = PaginationController (paginator: paginator, tableView: self.tableView)
        
        loadThreads()
    }
    
    
    fileprivate func loadThreads() {
        paginationController?.stream.listen(self, success:
            { [weak self] threads in
                self?.posts.removeAll()
                self?.updatePostsFromThreads(threads)
                self?.refreshController.endRefreshing()
            }, failure: { [weak self] (error) -> Void in
                self?.loadController.state = LoadState.failed(error)
            })
        
        paginationController?.loadMore()
    }
    
    fileprivate func updatePostsFromThreads(_ threads : [DiscussionThread]) {
        
        for thread in threads {
            self.posts.append(thread)
        }
        self.tableView.reloadData()
        let emptyState = LoadState.empty(icon : nil , message: errorMessage())
        
        self.loadController.state = self.posts.isEmpty ? emptyState : .loaded
        // set visibility of header view
        updateHeaderViewVisibility()
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil)
    }

    func titleForFilter(_ filter : DiscussionPostsFilter) -> String {
        switch filter {
        case .allPosts: return Strings.allPosts
        case .unread: return Strings.unread
        case .unanswered: return Strings.unanswered
        }
    }
    
    func titleForSort(_ filter : DiscussionPostsSort) -> String {
        switch filter {
        case .recentActivity: return Strings.recentActivity
        case .mostActivity: return Strings.mostActivity
        case .voteCount: return Strings.mostVotes
        }
    }
    
    func isFilterApplied() -> Bool {
            switch self.selectedFilter {
            case .allPosts: return false
            case .unread: return true
            case .unanswered: return true
        }
    }
    
    func errorMessage() -> String {
        guard let context = context else {
            return ""
        }
        
        if isFilterApplied() {
            return context.noResultsMessage + " " + Strings.removeFilter
        }
        else {
            return context.noResultsMessage
        }
    }
    
    func showFilterPicker() {
        let options = [.allPosts, .unread, .unanswered].map {
            return (title : self.titleForFilter($0), value : $0)
        }

        let controller = UIAlertController.actionSheetWithItems(options, currentSelection : self.selectedFilter) {filter in
            self.selectedFilter = filter
            self.loadController.state = .initial
            self.loadContent()
            
            let buttonTitle = NSAttributedString.joinInNaturalLayout([Icon.filter.attributedTextWithStyle(self.filterTextStyle.withSize(.xSmall)),
                self.filterTextStyle.attributedString(withText: self.titleForFilter(filter))])
            
            self.filterButton.setAttributedTitle(buttonTitle, forState: [], animated : false)
            self.updateAccessibility()
        }
        controller.addCancelAction()
        self.present(controller, animated: true, completion:nil)
    }
    
    func showSortPicker() {
        let options = [.recentActivity, .mostActivity, .voteCount].map {
            return (title : self.titleForSort($0), value : $0)
        }
        
        let controller = UIAlertController.actionSheetWithItems(options, currentSelection : self.selectedOrderBy) {sort in
            self.selectedOrderBy = sort
            self.loadController.state = .initial
            self.loadContent()
            
            let buttonTitle = NSAttributedString.joinInNaturalLayout([Icon.sort.attributedTextWithStyle(self.filterTextStyle.withSize(.xSmall)),
                self.filterTextStyle.attributedString(withText: self.titleForSort(sort))])
            
            self.sortButton.setAttributedTitle(buttonTitle, forState: [], animated: false)
            self.updateAccessibility()
        }
        
        controller.addCancelAction()
        self.present(controller, animated: true, completion:nil)
    }
    
    fileprivate func updateSelectedPostAttributes(_ indexPath: IndexPath) {
        posts[indexPath.row].read = true
        posts[indexPath.row].unreadCommentCount = 0
        tableView.reloadData()
    }
    
    //MARK :- DiscussionNewPostViewControllerDelegate method
    
    func newPostController(_ controller: DiscussionNewPostViewController, addedPost post: DiscussionThread) {
        loadContent()
    }
    
    // MARK - Pull Refresh
    
    func refreshControllerActivated(_ controller: PullRefreshController) {
        loadContent()
    }
    
    // MARK - Table View Delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    var cellTextStyle : OEXTextStyle {
        return OEXTextStyle(weight : .normal, size: .xLarge, color: OEXStyles.shared.primaryBaseColor())
    }
    
    var unreadIconTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .xLarge, color: OEXStyles.shared.primaryBaseColor())
    }
    
    var readIconTextStyle : OEXTextStyle {
        return OEXTextStyle(weight : .normal, size: .xLarge, color: OEXStyles.shared.neutralBase())
    }
    
    func styledCellTextWithIcon(_ icon : Icon, text : String?) -> NSAttributedString? {
        let style = cellTextStyle.withSize(.small)
        return text.map {text in
            return NSAttributedString.joinInNaturalLayout([icon.attributedTextWithStyle(style),
                style.attributedString(withText: text)])
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PostTableViewCell.identifier, for: indexPath) as! PostTableViewCell
        cell.useThread(posts[indexPath.row], selectedOrderBy : selectedOrderBy)
        cell.applyStandardSeparatorInsets()
            return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        updateSelectedPostAttributes(indexPath)
        environment.router?.showDiscussionResponsesFromViewController(self, courseID : courseID, threadID: posts[indexPath.row].threadID)
    }
}

//We want to make sure that only non-root node topics are selectable
public extension DiscussionTopic {
    var isSelectable : Bool {
        return self.depth != 0 || self.id != nil
    }
    
    func firstSelectableChild(forTopic topic : DiscussionTopic? = nil) -> DiscussionTopic? {
        let discussionTopic = topic ?? self
        if let matchedIndex = discussionTopic.children.firstIndexMatching({$0.isSelectable }) {
            return discussionTopic.children[matchedIndex]
        }
        if discussionTopic.children.count > 0 {
            return firstSelectableChild(forTopic : discussionTopic.children[0])
        }
        return nil
    }
}

extension UITableView {
    //Might be worth adding a section argument in the future
    func isLastRow(indexPath : IndexPath) -> Bool {
        return indexPath.row == self.numberOfRows(inSection: indexPath.section) - 1 && indexPath.section == self.numberOfSections - 1
    }
}

// Testing only
extension PostsViewController {
    var t_loaded : edXCore.Stream<()> {
        return self.paginationController!.stream.map {_ in
            return
        }
    }
}

