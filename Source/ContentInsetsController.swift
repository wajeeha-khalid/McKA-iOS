//
//  ContentInsetsController.swift
//  edX
//
//  Created by Akiva Leffert on 5/18/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public protocol ContentInsetsSourceDelegate : class {
    func contentInsetsSourceChanged(_ source : ContentInsetsSource)
}

public protocol ContentInsetsSource : class {
    var currentInsets : UIEdgeInsets { get }
    weak var insetsDelegate : ContentInsetsSourceDelegate? { get set }
    var affectsScrollIndicators : Bool { get }
}


open class ConstantInsetsSource : ContentInsetsSource {
    open var currentInsets : UIEdgeInsets {
        didSet {
            self.insetsDelegate?.contentInsetsSourceChanged(self)
        }
    }
    
    open let affectsScrollIndicators : Bool
    open weak var insetsDelegate : ContentInsetsSourceDelegate?

    public init(insets : UIEdgeInsets, affectsScrollIndicators : Bool) {
        self.currentInsets = insets
        self.affectsScrollIndicators = affectsScrollIndicators
    }
}

/// General solution to the problem of edge insets that can change and need to
/// match a scroll view. When we drop iOS 7 support there may be a way to simplify this
/// by using the new layout margins API.
///
/// Other things like pull to refresh can be supported by creating a class that implements `ContentInsetsSource`
/// and providing a way to add it to the `insetsSources` list.
///
/// To use:
///  #. Call `setupInController:scrollView:` in the `viewDidLoad` method of your controller
///  #. Call `updateInsets` in the `viewDidLayoutSubviews` method of your controller
open class ContentInsetsController: NSObject, ContentInsetsSourceDelegate {
    
    fileprivate var scrollView : UIScrollView?
    fileprivate weak var owner : UIViewController?
    
    fileprivate var insetSources : [ContentInsetsSource] = []

    // Keyboard is separated out since it isn't a simple sum, but instead overrides other
    // insets when present
    fileprivate var keyboardSource : ContentInsetsSource?
    
    open func setupInController(_ owner : UIViewController, scrollView : UIScrollView) {
        self.owner = owner
        self.scrollView = scrollView
        keyboardSource = KeyboardInsetsSource(scrollView: scrollView)
        keyboardSource?.insetsDelegate = self
    }
    
    fileprivate var controllerInsets : UIEdgeInsets {
        let topGuideHeight = self.owner?.topLayoutGuide.length ?? 0
        let bottomGuideHeight = self.owner?.bottomLayoutGuide.length ?? 0
        return UIEdgeInsets(top : topGuideHeight, left : 0, bottom : bottomGuideHeight, right : 0)
    }
    
    open func contentInsetsSourceChanged(_ source: ContentInsetsSource) {
        updateInsets()
    }
    
    open func addSource(_ source : ContentInsetsSource) {
        source.insetsDelegate = self
        insetSources.append(source)
        updateInsets()
    }
    
    open func updateInsets() {
        var regularInsets = insetSources
            .map { $0.currentInsets }
            .reduce(controllerInsets, +)
        let indicatorSources = insetSources
            .filter { $0.affectsScrollIndicators }
            .map { $0.currentInsets }
        var indicatorInsets = indicatorSources.reduce(controllerInsets, +)
        
        if let keyboardHeight = keyboardSource?.currentInsets.bottom {
            regularInsets.bottom = max(keyboardHeight, regularInsets.bottom)
            indicatorInsets.bottom = max(keyboardHeight, indicatorInsets.bottom)
        }
        self.scrollView?.contentInset = regularInsets
        
        self.scrollView?.scrollIndicatorInsets = indicatorInsets
    }
}
