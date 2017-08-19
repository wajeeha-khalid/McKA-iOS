//
//  CourseCertificateCell.swift
//  edX
//
//  Created by Michael Katz on 11/12/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

class CourseCertificateCell: UITableViewCell {

    static let identifier = "CourseCertificateCellIdentifier"

    let certificateImageView = UIImageView()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let getButton = UIButton()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        configureViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func configureViews() {
        self.backgroundColor =  OEXStyles.shared.neutralXLight()

        applyStandardSeparatorInsets()

        contentView.addSubview(certificateImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(getButton)

        certificateImageView.contentMode = .scaleAspectFit
        certificateImageView.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)

        getButton.backgroundColor = UIColor.green

        titleLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .horizontal)
        subtitleLabel.adjustsFontSizeToFitWidth = true

        certificateImageView.snp.makeConstraints({ (make) -> Void in
            make.top.equalTo(contentView).offset(15)
            make.bottom.equalTo(contentView).inset(15)
            make.leading.equalTo(contentView.snp.leading).offset(10)
        })

        titleLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(certificateImageView)
            make.leading.equalTo(certificateImageView.snp.trailing).offset(14)
            make.trailing.equalTo(contentView.snp.trailingMargin)
        }

        subtitleLabel.snp.makeConstraints { (make) -> Void in
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom)
        }

        getButton.snp.makeConstraints { (make) -> Void in
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(titleLabel)
            make.bottom.equalTo(certificateImageView)
        }
    }

    func useItem(_ item: CertificateDashboardItem) {
        certificateImageView.image = item.certificateImage

        let titleStyle = OEXTextStyle(weight: .normal, size: .large, color: OEXStyles.shared.primaryXDarkColor())
        let subtitleStyle = OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared.neutralDark())

        titleLabel.attributedText = titleStyle.attributedString(withText: Strings.Certificates.courseCompletionTitle)
        subtitleLabel.attributedText = subtitleStyle.attributedString(withText: Strings.Certificates.courseCompletionSubtitle)
        getButton.applyButtonStyle(OEXStyles.shared.filledPrimaryButtonStyle, withTitle: Strings.Certificates.getCertificate)

        getButton.oex_addAction({ _ in
            item.action()
            }, for: .touchUpInside)
    }
}
