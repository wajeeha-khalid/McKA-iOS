//
//  SpinnerView.swift
//  edX
//
//  Created by Akiva Leffert on 6/3/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

private var startTime : TimeInterval?

private let animationKey = "org.edx.spin"

open class SpinnerView : UIView {
    
    public enum Size {
        case small
        case medium
        case large
    }
    
    public enum Color {
        case primary
        case white
        
        fileprivate var value : UIColor {
            switch self {
            case .primary: return OEXStyles.shared().piqueGreenColor()
            case .white: return OEXStyles.shared().neutralWhite()
            }
        }
    }
    
    fileprivate let content = UIImageView()
    fileprivate let size : Size
    fileprivate var stopped : Bool = false {
        didSet {
            if hidesWhenStopped {
                self.isHidden = stopped
            }
        }
    }

    open var hidesWhenStopped = false
    
    public init(size : Size, color : Color) {
        self.size = size
        super.init(frame : CGRect.zero)
        addSubview(content)
        content.image = Icon.spinner.imageWithFontSize(30)
        content.tintColor = color.value
        content.contentMode = .scaleAspectFit
    }

    public override init(frame: CGRect) {
        self.size = Size.small
        super.init(frame : frame)
        addSubview(content)
        content.image = Icon.spinner.imageWithFontSize(30)
        content.tintColor = UIColor.white
        content.contentMode = .scaleAspectFit
    }
    
    open override class var requiresConstraintBasedLayout : Bool {
        return true
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        content.frame = self.bounds
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func didMoveToWindow() {
        if !stopped {
            addSpinAnimation()
        }
        else {
            removeSpinAnimation()
        }
    }
    
    open override var intrinsicContentSize : CGSize {
        switch size {
        case .small:
            return CGSize(width: 12, height: 12)
        case .medium:
            return CGSize(width: 18, height: 18)
        case .large:
            return CGSize(width: 24, height: 24)
        }
    }
    
    fileprivate func addSpinAnimation() {
        if let window = self.window {
            let animation = CAKeyframeAnimation(keyPath: "transform.rotation")
            let dots = 8
            let direction : Double = UIApplication.shared.userInterfaceLayoutDirection == .leftToRight ? 1 : -1
            animation.keyTimes = Array(count: dots) {
                return (Double($0) / Double(dots)) as NSNumber
            }
            animation.values = Array(count: dots) {
                return (direction * Double($0) / Double(dots)) * 2.0 * Double.pi as NSNumber
            }
            animation.repeatCount = Float.infinity
            animation.duration = 0.6
            animation.isAdditive = true
            animation.calculationMode = kCAAnimationDiscrete
            /// Set time to zero so they all sync up
            animation.beginTime = window.layer.convertTime(0, to: self.layer)
            self.content.layer.add(animation, forKey: animationKey)
        }
        else {
            removeSpinAnimation()
        }
    }
    
    fileprivate func removeSpinAnimation() {
        self.content.layer.removeAnimation(forKey: animationKey)
    }
    
    open func startAnimating() {
        if stopped {
            addSpinAnimation()
        }
        stopped = false
    }
    
    open func stopAnimating() {
        removeSpinAnimation()
        stopped = true
    }
}
