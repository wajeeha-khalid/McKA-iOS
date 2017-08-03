//
//  DownloadsAccessoryView.swift
//  edX
//
//  Created by Akiva Leffert on 9/24/15.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit


class DownloadsAccessoryView : UIView {
    
    enum State {
        case available
        case downloading
        case done
    }
    
    fileprivate let downloadButton = UIButton(type: .system)
    fileprivate let downloadSpinner = SpinnerView(size: .medium, color: .primary)
    fileprivate let iconFontSize : CGFloat = 15
    fileprivate let countLabel : UILabel = UILabel()
    
    override init(frame : CGRect) {
        state = .available
        itemCount = nil
        
        super.init(frame: frame)
        
        downloadButton.tintColor = OEXStyles.shared().neutralBase()
        downloadButton.contentEdgeInsets = UIEdgeInsetsMake(15, 10, 15, 10)
        downloadButton.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        countLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        downloadSpinner.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        
        self.addSubview(downloadButton)
        self.addSubview(downloadSpinner)
        self.addSubview(countLabel)
        
        // This view is atomic from an accessibility point of view
        self.isAccessibilityElement = true
        downloadSpinner.accessibilityTraits = UIAccessibilityTraitNotEnabled;
        countLabel.accessibilityTraits = UIAccessibilityTraitNotEnabled;
        downloadButton.accessibilityTraits = UIAccessibilityTraitNotEnabled;
        
        downloadSpinner.stopAnimating()
        
        downloadSpinner.snp.makeConstraints {make in
            make.center.equalTo(self)
        }
        
        downloadButton.snp.makeConstraints {make in
            make.trailing.equalTo(self)
            make.top.equalTo(self)
            make.bottom.equalTo(self)
        }
        
        countLabel.snp.makeConstraints {make in
            make.leading.equalTo(self)
            make.centerY.equalTo(self)
            make.trailing.equalTo(downloadButton.imageView!.snp.leading).offset(-6)
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func useIcon(_ icon : Icon?) {
        downloadButton.setImage(icon?.imageWithFontSize(iconFontSize), for:UIControlState())
    }
    
    var downloadAction : (() -> Void)? = nil {
        didSet {
            downloadButton.oex_removeAllActions()
            downloadButton.oex_addAction({ _ in self.downloadAction?() }, for: .touchUpInside)
        }
    }
    
    var itemCount : Int? {
        didSet {
            let count = itemCount ?? 0
            let text = (count > 0 ? "\(count)" : "")
            let styledText = CourseOutlineItemView.detailFontStyle.attributedString(withText: text)
            countLabel.attributedText = styledText
        }
    }
    
    var state : State {
        didSet {
            switch state {
            case .available:
                useIcon(.contentCanDownload)
                downloadSpinner.isHidden = true
                downloadButton.isUserInteractionEnabled = true
                downloadButton.isHidden = false
                self.isUserInteractionEnabled = true
                countLabel.isHidden = false
                
                if let count = itemCount {
                    let message = Strings.downloadManyVideos(videoCount: count)
                    self.accessibilityLabel = message
                }
                else {
                    self.accessibilityLabel = Strings.download
                }
                self.accessibilityTraits = UIAccessibilityTraitButton
            case .downloading:
                downloadSpinner.startAnimating()
                downloadSpinner.isHidden = false
                downloadButton.isUserInteractionEnabled = true
                self.isUserInteractionEnabled = true
                downloadButton.isHidden = true
                countLabel.isHidden = true
                
                self.accessibilityLabel = Strings.downloading
                self.accessibilityTraits = UIAccessibilityTraitButton
            case .done:
                useIcon(.contentDidDownload)
                downloadSpinner.isHidden = true
                self.isUserInteractionEnabled = false
                downloadButton.isHidden = false
                countLabel.isHidden = false
                
                if let count = itemCount {
                    let message = Strings.downloadManyVideos(videoCount: count)
                    self.accessibilityLabel = message
                }
                else {
                    self.accessibilityLabel = Strings.downloaded
                }
                self.accessibilityTraits = UIAccessibilityTraitStaticText
            }
        }
    }
}
