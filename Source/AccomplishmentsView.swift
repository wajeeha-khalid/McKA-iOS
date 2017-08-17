//
//  AccomplishmentsView.swift
//  edX
//
//  Created by Akiva Leffert on 4/5/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
import TZStackView

struct Accomplishment {
    let image: RemoteImage
    let title: String?
    let detail: String?
    let date: Date?
    let shareURL: URL
}

class AccomplishmentView : UIView {
    fileprivate let imageView = UIImageView()
    fileprivate let title = UILabel()
    fileprivate let detail = UILabel()
    fileprivate let date = UILabel()
    fileprivate let shareButton = UIButton()
    fileprivate let textStack = TZStackView()

    init(accomplishment: Accomplishment, shareAction: (() -> Void)?) {
        super.init(frame: CGRect.zero)
        textStack.axis = .vertical

        // horizontal: imageView - textStack(stretches) - shareButton
        addSubview(imageView)
        addSubview(textStack)
        let sharing = shareAction != nil

        if(sharing) {
            addSubview(shareButton)
        }
        // vertical stack in the center
        textStack.addArrangedSubview(title)
        textStack.addArrangedSubview(detail)
        textStack.addArrangedSubview(date)

        shareButton.setImage(UIImage(named: "share"), for: UIControlState())
        shareButton.tintColor = OEXStyles.shared.neutralLight()
        shareButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        shareButton.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
        shareButton.oex_addAction({ _ in
            shareAction?()
            }, for: .touchUpInside)

        imageView.snp.makeConstraints {make in
            make.size.equalTo(CGSize(width: 50, height: 50))
            make.leading.equalTo(self)
            make.top.equalTo(self).offset(StandardVerticalMargin)
            make.bottom.lessThanOrEqualTo(self).offset(-StandardVerticalMargin)
        }

        textStack.snp.makeConstraints {make in
            make.leading.equalTo(imageView.snp.trailing).offset(StandardHorizontalMargin)
            make.top.equalTo(self)
            make.bottom.lessThanOrEqualTo(self)
        }

        if sharing {
            shareButton.snp.makeConstraints {make in
                make.leading.equalTo(textStack.snp.trailing).offset(StandardHorizontalMargin)
                make.centerY.equalTo(imageView)
                make.trailing.equalTo(self)
            }
        }
        else {
            textStack.snp.makeConstraints {make in
                make.trailing.equalTo(self)
            }
        }

        title.numberOfLines = 0
        detail.numberOfLines = 0

        imageView.remoteImage = accomplishment.image

        let formattedDate = accomplishment.date.map { OEXDateFormatting.format(asMonthDayYearString: $0) }

        for (field, text, style) in [
            (title, accomplishment.title, titleStyle),
            (detail, accomplishment.detail, detailStyle),
            (date, formattedDate ?? "", dateStyle)
            ]
        {
            field.attributedText = style.attributedString(withText: text)
            field.isHidden = text?.isEmpty ?? true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate var titleStyle : OEXTextStyle {
        return OEXTextStyle(weight: .semiBold, size: .small, color: OEXStyles.shared.neutralDark())
    }

    fileprivate var detailStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .xSmall, color: OEXStyles.shared.neutralBase())
    }

    fileprivate var dateStyle : OEXTextStyle {
        return OEXTextStyle(weight: .light, size: .xSmall, color: OEXStyles.shared.neutralLight())
    }
}

class AccomplishmentsView : UIView {

    fileprivate let stack = TZStackView()
    fileprivate let shareAction: ((Accomplishment) -> Void)?

    fileprivate var accomplishments: [Accomplishment] = []
    fileprivate let paginationController: PaginationController<Accomplishment>

    // If shareAction is nil then don't show sharing buttons
    init(paginator: AnyPaginator<Accomplishment>, containingScrollView scrollView: UIScrollView, shareAction: ((Accomplishment) -> Void)?) {
        self.shareAction = shareAction
        paginationController = PaginationController(paginator: paginator, stackView: stack, containingScrollView: scrollView)

        super.init(frame: CGRect.zero)

        addSubview(stack)
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = StandardVerticalMargin
        stack.snp.makeConstraints {make in
            make.edges.equalTo(self)
        }
        paginator.stream.listen(self, success: {[weak self] accomplishments in
            let newAccomplishments = accomplishments.suffix(self?.accomplishments.count ?? 0)
            self?.addAccomplishments(newAccomplishments)
            }, failure: {_ in
                // We should only get here if we already have accomplishments and the paginator will try to
                // load again if it fails, so just do nothing
        })
    }

    func addAccomplishments<A: Sequence>(_ newAccomplishments: A) where A.Iterator.Element == Accomplishment {
        let action = shareAction
        for accomplishment in newAccomplishments {
            stack.addArrangedSubview(
                AccomplishmentView(accomplishment: accomplishment, shareAction: action.map {f in { f(accomplishment) }})
            )
        }
        accomplishments.append(contentsOf: newAccomplishments)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
