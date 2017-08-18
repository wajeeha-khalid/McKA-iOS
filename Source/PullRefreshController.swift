//
//  PullRefreshController.swift
//  edX
//
//  Created by Akiva Leffert on 8/26/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

private let StandardRefreshHeight : CGFloat = 80

open class PullRefreshView : UIView {
    fileprivate let spinner = SpinnerView(size: .large, color: .primary)
    
    public init() {
        spinner.stopAnimating()
        super.init(frame : CGRect.zero)
        addSubview(spinner)
        spinner.snp.makeConstraints {make in
            make.centerX.equalTo(self)
            make.centerY.equalTo(self).offset(10)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override var intrinsicContentSize : CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: StandardRefreshHeight)
    }
    
    open var percentage : CGFloat = 1 {
        didSet {
            let totalAngle = CGFloat(2 * Float.pi * 2) // two full rotations
            let scale = (percentage * 0.9) + 0.1 // don't start from 0 scale because it looks weird
            spinner.transform = CGAffineTransform(rotationAngle: percentage * totalAngle).concatenating(CGAffineTransform(scaleX: scale, y: scale))
        }
    }
}

public protocol PullRefreshControllerDelegate : class {
    func refreshControllerActivated(_ controller : PullRefreshController)
}

open class PullRefreshController: NSObject, ContentInsetsSource {
    open weak var insetsDelegate : ContentInsetsSourceDelegate?
    open weak var delegate : PullRefreshControllerDelegate?
    fileprivate let view : PullRefreshView
    fileprivate var shouldStartOnTouchRelease : Bool = false
    
    fileprivate(set) var refreshing : Bool = false
    
    public override init() {
        view = PullRefreshView()
        super.init()
    }
    
    open func setupInScrollView(_ scrollView : UIScrollView) {
        scrollView.addSubview(self.view)
        self.view.snp.makeConstraints {make in
            make.bottom.equalTo(scrollView.snp.top)
            make.leading.equalTo(scrollView)
            make.trailing.equalTo(scrollView)
            make.width.equalTo(scrollView)
        }
        scrollView.oex_addObserver(self, forKeyPath: "bounds") { (observer, scrollView, _) -> Void in
            observer.scrollViewDidScroll(scrollView)
        }
    }
    
    fileprivate func triggered() {
        if !refreshing {
            refreshing = true
            view.spinner.startAnimating()
            self.insetsDelegate?.contentInsetsSourceChanged(self)
            self.delegate?.refreshControllerActivated(self)
        }
    }
    
    open var affectsScrollIndicators : Bool {
        return false
    }
    
    open func endRefreshing() {
        refreshing = false
        UIView.animate(withDuration: 0.3, animations: {
            self.insetsDelegate?.contentInsetsSourceChanged(self)
        }) 
        view.spinner.stopAnimating()
    }
    
    open var currentInsets : UIEdgeInsets {
        return UIEdgeInsetsMake(refreshing ? view.frame.height : 0, 0, 0, 0)
    }
    
    open func scrollViewDidScroll(_ scrollView : UIScrollView) {
        let pct = max(0, min(1, -scrollView.bounds.minY / view.frame.height))
        if !refreshing && scrollView.isDragging {
            self.view.percentage = pct
        }
        else {
            self.view.percentage = 1
        }
        if pct >= 1 && scrollView.isDragging {
            shouldStartOnTouchRelease = true
        }
        if shouldStartOnTouchRelease && !scrollView.isDragging {
            triggered()
            shouldStartOnTouchRelease = false
        }
    }
    
}
