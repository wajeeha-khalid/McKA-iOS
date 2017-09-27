//
//  BrandingHeaderView.swift
//  edX
//
//  Created by Shafqat Muneer on 8/10/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit
import SnapKit

/**
    Create header view that will contain logo of the company. 
    It will be displayed at top of courses list screen
 */
class BrandingHeaderView: UIView {
    
    private let brandingLogoImageView:UIImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        self.addSubview(brandingLogoImageView)
        let companyBrandingLogo = BrandingThemes.shared.getLogoURL()
        brandingLogoImageView.image = UIImage(named: companyBrandingLogo)
        brandingLogoImageView.contentMode = .center
        brandingLogoImageView.snp.makeConstraints { maker in
            maker.top.equalTo(15)
            maker.bottom.equalTo(0)
            maker.left.equalToSuperview()
            maker.right.equalToSuperview()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
