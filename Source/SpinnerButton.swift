//
//  SpinnerButton.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 16/09/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit



class SpinnerButton: UIButton {
    fileprivate let SpinnerViewTrailingMargin : CGFloat = 10
    fileprivate let VerticalContentMargin : CGFloat = 5
    fileprivate let SpinnerHorizontalMargin : CGFloat = 10
    fileprivate var SpinnerViewWidthWithMargins : CGFloat {
        return spinnerView.intrinsicContentSize.width + 2 * SpinnerHorizontalMargin
    }
    
    fileprivate let spinnerView = SpinnerView(size: .large, color: .white)
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutSpinnerView()
    }
    
    fileprivate func layoutSpinnerView() {
        self.addSubview(spinnerView)
        self.titleLabel?.adjustsFontSizeToFitWidth = true
        
        spinnerView.snp.updateConstraints { (make) -> Void in
            make.centerY.equalTo(self)
            make.width.equalTo(spinnerView.intrinsicContentSize.width)
            if let label = titleLabel {
                make.leading.equalTo(label.snp.trailing).offset(SpinnerHorizontalMargin).priority(.low)
            }
            make.trailing.equalTo(self.snp.trailing).offset(-SpinnerHorizontalMargin).priority(.high)
        }
        self.setNeedsUpdateConstraints()
        if !showProgress { spinnerView.isHidden = true }
    }
    
    override var intrinsicContentSize : CGSize {
        let width = self.titleLabel?.intrinsicContentSize.width ?? 0 + SpinnerViewTrailingMargin + self.spinnerView.intrinsicContentSize.width
        let height = max(super.intrinsicContentSize.height, spinnerView.intrinsicContentSize.height + 2 * VerticalContentMargin)
        return CGSize(width: width, height: height)
    }
    
    var showProgress : Bool = false {
        didSet {
            if showProgress {
                spinnerView.isHidden = false
                spinnerView.startAnimating()
            }
            else {
                spinnerView.isHidden = true
                spinnerView.stopAnimating()
            }
        }
    }
}
