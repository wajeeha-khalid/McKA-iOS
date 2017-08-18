//
//  LoadStateViewController.swift
//  edX
//
//  Created by Akiva Leffert on 5/13/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

import edXCore

public enum LoadState {
    case initial
    case loaded
    case Empty(icon : Icon?, message : String?, attributedMessage : NSAttributedString?, accessibilityMessage : String?, buttonInfo : MessageButtonInfo?)
    // if attributed message is set then message is ignored
    // if message is set then the error is ignored
    case Failed(error : NSError?, icon : Icon?, message : String?, attributedMessage : NSAttributedString?, accessibilityMessage : String?, buttonInfo : MessageButtonInfo?)
    
    var accessibilityMessage : String? {
        switch self {
        case .initial: return nil
        case .loaded: return nil
        case let .Empty(info): return info.accessibilityMessage
        case let .Failed(info): return info.accessibilityMessage
        }
    }
    
    var isInitial : Bool {
        switch self {
        case .initial: return true
        default: return false
        }
    }
    
    var isLoaded : Bool {
        switch self {
        case .loaded: return true
        default: return false
        }
    }
    
    var isError : Bool {
        switch self {
        case .Failed(_): return true
        default: return false
        }
    }
    
    static func failed(_ error : NSError? = nil, icon : Icon? = .unknownError, message : String? = nil, attributedMessage : NSAttributedString? = nil, accessibilityMessage : String? = nil, buttonInfo : MessageButtonInfo? = nil) -> LoadState {
        return LoadState.Failed(error : error, icon : icon, message : message, attributedMessage : attributedMessage, accessibilityMessage : accessibilityMessage, buttonInfo : buttonInfo)
    }
    
    static func empty(icon : Icon?, message : String? = nil, attributedMessage : NSAttributedString? = nil, accessibilityMessage : String? = nil, buttonInfo : MessageButtonInfo? = nil) -> LoadState {
        return LoadState.Empty(icon: icon, message: message, attributedMessage: attributedMessage, accessibilityMessage : accessibilityMessage, buttonInfo : buttonInfo)
    }
}

class LoadStateViewController : UIViewController {
    
    fileprivate let loadingView : UIView
    fileprivate var contentView : UIView?
    fileprivate let messageView : IconMessageView
    
    fileprivate var madeInitialAppearance : Bool = false
    
    var state : LoadState = .initial {
        didSet {
            // this sets a background color so when the view is pushed in it doesn't have a black or weird background
            switch state {
            case .initial:
                view.backgroundColor = OEXStyles.shared.standardBackgroundColor()
            default:
                view.backgroundColor = UIColor.clear
            }
            updateAppearanceAnimated(madeInitialAppearance)
        }
    }
    
    var insets : UIEdgeInsets = UIEdgeInsets.zero {
        didSet {
            self.view.setNeedsUpdateConstraints()
        }
    }
    
    init() {
        messageView = IconMessageView()
        loadingView = SpinnerView(size: .large, color: .primary)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var messageStyle : OEXTextStyle {
        return messageView.messageStyle
    }
    
    override func loadView() {
        self.view = PassthroughView()
    }
    
    func setupInController(_ controller : UIViewController, contentView : UIView) {
        controller.addChildViewController(self)
        didMove(toParentViewController: controller)
        
        self.contentView = contentView
        contentView.alpha = 0
        
        controller.view.addSubview(loadingView)
        controller.view.addSubview(messageView)
        controller.view.addSubview(self.view)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messageView.alpha = 0
        view.addSubview(messageView)
        view.addSubview(loadingView)
        
        state = .initial
        
        self.view.setNeedsUpdateConstraints()
        self.view.isUserInteractionEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        madeInitialAppearance = true
    }
    
    override func updateViewConstraints() {
        loadingView.snp.updateConstraints {make in
            make.center.equalTo(view)
        }
        
        messageView.snp.updateConstraints {make in
            make.center.equalTo(view)
        }
        
        view.snp.updateConstraints { make in
            if let superview = view.superview {
                make.edges.equalTo(superview).inset(insets)
            }
        }
        super.updateViewConstraints()
    }
    
    fileprivate func updateAppearanceAnimated(_ animated : Bool) {
        var alphas : (loading : CGFloat, message : CGFloat, content : CGFloat, touchable : Bool) = (loading : 0, message : 0, content : 0, touchable : false)
        
        UIView.animate(withDuration: 0.3 * TimeInterval()) {
            switch self.state {
            case .initial:
                alphas = (loading : 1, message : 0, content : 0, touchable : false)
            case .loaded:
                alphas = (loading : 0, message : 0, content : 1, touchable : false)
            case let .Empty(info):
                self.messageView.buttonInfo = info.buttonInfo
                UIView.performWithoutAnimation {
                    if let message = info.attributedMessage {
                        self.messageView.attributedMessage = message
                    }
                    else {
                        self.messageView.message = info.message
                    }
                    self.messageView.icon = info.icon
                }
                alphas = (loading : 0, message : 1, content : 0, touchable : true)
            case let .Failed(info):
                self.messageView.buttonInfo = info.buttonInfo
                UIView.performWithoutAnimation {
                    if let error = info.error, error.oex_isNoInternetConnectionError {
                        self.messageView.showNoConnectionError()
                    }
                    else if let error = info.error as? OEXAttributedErrorMessageCarrying {
                        self.messageView.attributedMessage = error.attributedDescription(withBaseStyle: self.messageStyle)
                        self.messageView.icon = info.icon ?? .unknownError
                    }
                    else if let message = info.attributedMessage {
                        self.messageView.attributedMessage = message
                        self.messageView.icon = info.icon ?? .unknownError
                    }
                    else if let message = info.message {
                        self.messageView.message = message
                        self.messageView.icon = info.icon ?? .unknownError
                    }
                    else if let error = info.error, error.errorIsThisType(NSError.oex_unknownNetworkError()) {
                        self.messageView.message = Strings.unknownError
                        self.messageView.icon = info.icon ?? .unknownError
                    }
                    else if let error = info.error, error.errorIsThisType(NSError.oex_outdatedVersionError()) {
                        self.messageView.setupForOutdatedVersionError()
                    }
                    else {
                        self.messageView.message = info.error?.localizedDescription
                        self.messageView.icon = info.icon ?? .unknownError
                    }
                }
                alphas = (loading : 0, message : 1, content : 0, touchable : true)
            }
            
            self.messageView.accessibilityMessage = self.state.accessibilityMessage
            self.loadingView.alpha = alphas.loading
            self.messageView.alpha = alphas.message
            self.contentView?.alpha = alphas.content
            self.view.isUserInteractionEnabled = alphas.touchable
        } 
    }
    
}
