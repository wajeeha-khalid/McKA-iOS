//
//  CourseDashboardCell.swift
//  edX
//
//  Created by Jianfeng Qiu on 13/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class CourseDashboardCell: UITableViewCell {

    static let identifier = "CourseDashboardCellIdentifier"
    
    //TODO: all these should be adjusted once the final UI is ready
    fileprivate let ICON_SIZE : CGFloat = OEXTextStyle.pointSize(for: OEXTextSize.xxLarge)
    fileprivate let ICON_MARGIN : CGFloat = 30.0
    fileprivate let LABEL_MARGIN : CGFloat = 75.0
    fileprivate let LABEL_SIZE_HEIGHT = 20.0
    fileprivate let CONTAINER_SIZE_HEIGHT = 60.0
    fileprivate let CONTAINER_MARGIN_BOTTOM = 15.0
    fileprivate let INDICATOR_SIZE_WIDTH = 10.0
    
    fileprivate let container = UIView()
    fileprivate let iconView = UIImageView()
    fileprivate let titleLabel = UILabel()
    fileprivate let detailLabel = UILabel()
    fileprivate let bottomLine = UIView()
    
    fileprivate var titleTextStyle : OEXTextStyle {
        return OEXTextStyle(weight : .normal, size: .base, color : OEXStyles.shared.neutralXDark())
    }
    fileprivate var detailTextStyle : OEXTextStyle {
        return OEXTextStyle(weight : .normal, size: .xxSmall, color : OEXStyles.shared.neutralBase())
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        configureViews()
    }

    func useItem(_ item : StandardCourseDashboardItem) {
        self.titleLabel.attributedText = titleTextStyle.attributedString(withText: item.title)
        self.detailLabel.attributedText = detailTextStyle.attributedString(withText: item.detail)
        self.iconView.image = item.icon.imageWithFontSize(ICON_SIZE)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func configureViews() {
        self.bottomLine.backgroundColor = OEXStyles.shared.neutralXLight()
        
        applyStandardSeparatorInsets()
        
        self.container.addSubview(iconView)
        self.container.addSubview(titleLabel)
        self.container.addSubview(detailLabel)
        
        self.contentView.addSubview(container)
        
        self.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
        
        iconView.tintColor = OEXStyles.shared.neutralLight()
        
        container.snp.makeConstraints { make -> Void in
            make.edges.equalTo(contentView)
        }
        
        iconView.snp.makeConstraints { (make) -> Void in
            make.leading.equalTo(container).offset(ICON_MARGIN)
            make.centerY.equalTo(container)
        }
        
        titleLabel.snp.makeConstraints { (make) -> Void in
            make.leading.equalTo(container).offset(LABEL_MARGIN)
            make.trailing.lessThanOrEqualTo(container)
            make.top.equalTo(container).offset(LABEL_SIZE_HEIGHT)
            make.height.equalTo(LABEL_SIZE_HEIGHT)
        }
        detailLabel.snp.makeConstraints { (make) -> Void in
            make.leading.equalTo(titleLabel)
            make.trailing.lessThanOrEqualTo(container)
            make.top.equalTo(titleLabel.snp.bottom)
            make.height.equalTo(LABEL_SIZE_HEIGHT)
        }
    }
}
