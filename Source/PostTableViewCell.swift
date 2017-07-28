//
//  PostTableViewCell.swift
//  edX
//
//  Created by Tang, Jeff on 5/13/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit


class PostTableViewCell: UITableViewCell {
    
    static let identifier = "PostCell"
    
    fileprivate let typeLabel = UILabel()
    fileprivate let infoLabel = UILabel()
    fileprivate let titleLabel = UILabel()
    fileprivate let countLabel = UILabel()
    
    fileprivate var postReadStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().neutralXDark())
    }
    
    fileprivate var postUnreadStyle : OEXTextStyle {
        return OEXTextStyle(weight: .bold, size: .base, color: OEXStyles.shared().neutralXDark())
    }
    
    fileprivate var questionStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().secondaryDarkColor())
    }
    
    fileprivate var answerStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().utilitySuccessDark())
    }
    
    fileprivate var infoTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .xSmall, color: OEXStyles.shared().neutralDark())
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = OEXStyles.shared().neutralWhite()
        
        contentView.addSubview(typeLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(infoLabel)
        contentView.addSubview(countLabel)
        
        addConstraints()
        
        titleLabel.numberOfLines = 2
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func addConstraints() {
        typeLabel.snp.makeConstraints { (make) -> Void in
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.top.equalTo(titleLabel)
        }
        
        titleLabel.snp.makeConstraints { (make) -> Void in
            make.leading.equalTo(typeLabel.snp.trailing).offset(StandardHorizontalMargin)
            make.top.equalTo(contentView).offset(StandardVerticalMargin)
        }
        
        countLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(titleLabel)
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).offset(-StandardHorizontalMargin)
        }
        
        infoLabel.snp.makeConstraints { (make) -> Void in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom)
            make.bottom.equalTo(contentView).offset(-StandardVerticalMargin)
        }
    }
    
    fileprivate var titleTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color : OEXStyles.shared().neutralXDark())
    }
    
    fileprivate var activeCountStyle : OEXTextStyle {
        return OEXTextStyle(weight: .bold, size: .base, color : OEXStyles.shared().primaryBaseColor())
    }
    
    fileprivate var inactiveCountStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color : OEXStyles.shared().neutralDark())
    }
    
    fileprivate var typeText : NSAttributedString? {
        get {
            return typeLabel.attributedText
        }
        set {
            typeLabel.attributedText = newValue
        }
    }

    fileprivate func updateThreadCount(_ count : String) {
        countLabel.attributedText = activeCountStyle.attributedString(withText: count)
    }
    
    func useThread(_ thread : DiscussionThread, selectedOrderBy : DiscussionPostsSort) {
        self.typeText = threadTypeText(thread)
        
        titleLabel.attributedText = thread.read ? postReadStyle.attributedString(withText: thread.title) : postUnreadStyle.attributedString(withText: thread.title)
        
        var options = [NSAttributedString]()
        
        if thread.closed { options.append(Icon.closed.attributedTextWithStyle(infoTextStyle, inline : true)) }
        if thread.pinned { options.append(Icon.pinned.attributedTextWithStyle(infoTextStyle, inline : true)) }
        if thread.following { options.append(Icon.followStar.attributedTextWithStyle(infoTextStyle)) }
        if options.count > 0 { options.append(infoTextStyle.attributedString(withText: Strings.pipeSign)) }
        options.append(infoTextStyle.attributedString(withText: Strings.Discussions.repliesCount(count: formatdCommentsCount(thread.commentCount))))
        
        if let updatedAt = thread.updatedAt {
            options.append(infoTextStyle.attributedString(withText: Strings.pipeSign))
            options.append(infoTextStyle.attributedString(withText: Strings.Discussions.lastPost(date: updatedAt.displayDate)))
        }
        
        infoLabel.attributedText = NSAttributedString.joinInNaturalLayout(options)
        
        let count = formatdCommentsCount(thread.unreadCommentCount)
        countLabel.attributedText = activeCountStyle.attributedString(withText: count)
        countLabel.isHidden = !NSNumber(value: thread.unreadCommentCount).boolValue
        
        setAccessibility(thread)
    }
    
    fileprivate func styledCellTextWithIcon(_ icon : Icon, text : String?) -> NSAttributedString? {
        return text.map {text in
            let style = infoTextStyle
            return NSAttributedString.joinInNaturalLayout([icon.attributedTextWithStyle(style),
                style.attributedString(withText: text)])
        }
    }
    
    fileprivate func formatdCommentsCount(_ count: NSInteger) -> String {
        if count > 99 {
            return "99+"
        }
        
        return String(count)
    }
    
    fileprivate func threadTypeText(_ thread : DiscussionThread) -> NSAttributedString {
        switch thread.type {
        case .Discussion:
            return (thread.unreadCommentCount > 0) ? Icon.comments.attributedTextWithStyle(activeCountStyle) : Icon.comments.attributedTextWithStyle(inactiveCountStyle)
        case .Question:
            return thread.hasEndorsed ? Icon.answered.attributedTextWithStyle(answerStyle) : Icon.question.attributedTextWithStyle(questionStyle)
        }
    }
    
    fileprivate func setAccessibility(_ thread : DiscussionThread) {
        var accessibilityString = ""
        
        switch thread.type {
        case .Discussion:
            accessibilityString = Strings.discussion
        case .Question:
            thread.hasEndorsed ? (accessibilityString = Strings.answeredQuestion) : (accessibilityString = Strings.question)
        }
        
        accessibilityString = accessibilityString+","+(thread.title ?? "")
        
        if thread.closed {
            accessibilityString = accessibilityString+","+Strings.Accessibility.discussionClosed
        }
        
        if thread.pinned {
            accessibilityString = accessibilityString+","+Strings.Accessibility.discussionPinned
        }
        
        if thread.following {
            accessibilityString = accessibilityString+","+Strings.Accessibility.discussionFollowed
        }
        
        accessibilityString = accessibilityString+","+Strings.Discussions.repliesCount(count: formatdCommentsCount(thread.commentCount))
        
        
        if let updatedAt = thread.updatedAt {
            accessibilityString = accessibilityString+","+Strings.Accessibility.discussionLastPostOn(date: updatedAt.displayDate)
        }
        
        if thread.unreadCommentCount > 0 {
            accessibilityString = accessibilityString+","+Strings.Accessibility.discussionUnreadReplies(count: formatdCommentsCount(thread.unreadCommentCount));
        }
        
        accessibilityLabel = accessibilityString
        accessibilityHint = Strings.Accessibility.discussionThreadHint
        
    }
}

extension DiscussionPostsSort {
    var canHide : Bool {
        switch self {
        case .recentActivity, .mostActivity:
            return true
        case .voteCount:
            return false
        }
    }
}
