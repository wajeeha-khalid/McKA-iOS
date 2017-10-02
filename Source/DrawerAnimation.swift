//
//  DrawerAnimation.swift
//  edX
//
//  Created by Salman Jamil on 8/28/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation

fileprivate let animationDuration = 0.5

///Implements a slide up animation. In order to create the slide up effect the `view to animate`
///is lowered to the maximum y (orgin.y + size.height) cooridnate of its final frame in container
///and then animated up to create the slide up effect
final class SlideUpPresentationAnimator: NSObject , UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return animationDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let toViewController = transitionContext.viewController(forKey: .to)
        
        let toView = transitionContext.view(forKey: .to)
        
        let containerView = transitionContext.containerView
        // force unwrap is safe here since we are in the middle of a transition...
        containerView.addSubview(toView!)
        
        let toFrame = transitionContext.finalFrame(for: toViewController!)
        var fromFrame = toFrame
        fromFrame.origin.y = toFrame.maxY
        toView?.frame = fromFrame
        
        UIView.animate(withDuration: animationDuration,
                       delay: 0,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 6.0,
                       options: .curveEaseIn,
                       animations: {
            toView?.frame = toFrame
        }) { _ in
            transitionContext.completeTransition(true)
        }
    }
}


/// Implements a slide down dismissal animation.
final class SlideDownDismissalAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return animationDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let dismissingView = transitionContext.view(forKey: .from)
        
        let dismissingViewController = transitionContext.viewController(forKey: .from)
        let fromFrame = dismissingViewController.map {
            transitionContext.initialFrame(for: $0)
        }
        
        let toFrame = fromFrame.map { initial -> CGRect in
            var frame = initial
            frame.origin.y = frame.maxY
            return frame
        }
        
        UIView.animate(withDuration: animationDuration,
                       animations: {
            dismissingView?.frame = toFrame!
        }) { _ in
            // since the dismissal can be interactive so it can be cancelled...
            let completed = !transitionContext.transitionWasCancelled
            transitionContext.completeTransition(completed)
        }
    }
}

/// Uset this class to
/// 1. Add an inset at the top of presented view controller
/// 2. Add a dimming view behind the presented view
/// 3. Rounding the corners of presented view
class DrawerPresentationController: UIPresentationController {
    private let maskLayer = CAShapeLayer()
    private let insetFromTop: CGFloat = 30.0
    private let visualEffectView = UIVisualEffectView()
    
    override var frameOfPresentedViewInContainerView: CGRect {
        guard var frame = containerView?.frame else {
            return .zero
        }
        
        frame.size.height = frame.size.height - insetFromTop
        frame.origin.y = frame.origin.y + insetFromTop
        
        return frame
    }
    
    override func presentationTransitionWillBegin() {
        let coordinator = presentingViewController.transitionCoordinator
        
        func applyCornerRadius() {
            var frame = frameOfPresentedViewInContainerView
            frame.origin = CGPoint.zero
            let path = UIBezierPath(roundedRect: frame, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 12.0, height: 12.0))
            maskLayer.path = path.cgPath
            coordinator?.view(forKey: .to)?.layer.mask = maskLayer
        }
        
        func addBlur() {
            containerView?.addSubview(visualEffectView)
            visualEffectView.frame = containerView!.bounds
            coordinator?.animate(alongsideTransition: { (context) in
                self.visualEffectView.effect = UIBlurEffect(style: .dark)
            }, completion: nil)
        }
        
        addBlur()
        applyCornerRadius()
    }
    
    override func presentationTransitionDidEnd(_ completed: Bool) {
        // if the presentation isn't completed remove the visual effect view from self
        if !completed {
            let coordinator = presentingViewController.transitionCoordinator
            coordinator?.view(forKey: .to)?.layer.mask = nil
            visualEffectView.removeFromSuperview()
        }
    }
    
    override func dismissalTransitionWillBegin() {
        let coordinator = presentingViewController.transitionCoordinator
        coordinator?.animate(alongsideTransition: { (context) in
            self.visualEffectView.effect = nil
        }, completion: nil)
    }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            let coordinator = presentingViewController.transitionCoordinator
            coordinator?.view(forKey: .from)?.layer.mask = nil
            self.visualEffectView.removeFromSuperview()
        }
    }
}

/// A convenience wrapper to wrap a view controller to present as a drawer that can be opened from 
/// bottom. Also implements a pan gesture for interactive dismissal. This class also set's itself
/// as it's own transitioning delegate to return the appropraite objects for animating presentation
/// and dismissal. 
/// if the wrapped view controller has a scroll view in it pass it into the initializer. this class
/// add dependencies b/w the scroll view pan gesture recognizer and it's pan gesture recoginzer to
/// resolve conflicts...
class BottomDrawerViewController: UIViewController {
    
    fileprivate let gestureRecognizer = UIPanGestureRecognizer()
    fileprivate let interactiveController = UIPercentDrivenInteractiveTransition()
    fileprivate let scrollToManage: UIScrollView?

    /// Parameter: childViewController - the wrapped view controller
    /// Parameter: scrollView          - the scroll view if any of wrapped view to resolve conflicts
    /// b/w gesture recognizers...
    init(childViewController: UIViewController, scrollView: UIScrollView? = nil ) {
        self.scrollToManage = scrollView
        super.init(nibName: nil, bundle: nil)
        addChildViewController(childViewController)
        view.addSubview(childViewController.view)
        childViewController.view.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
        childViewController.didMove(toParentViewController: self)
        view.addGestureRecognizer(gestureRecognizer)
        view.isUserInteractionEnabled = true
        if let scrollView = scrollView {
            scrollView.panGestureRecognizer.require(toFail: gestureRecognizer)
        }
        gestureRecognizer.addTarget(self, action: #selector(self.handlePan(_:)))
        gestureRecognizer.delegate = self
        modalPresentationStyle = .custom
        transitioningDelegate = self
        
        let collapseButton = UIButton()
        collapseButton.setImage(UIImage(named: "ic.CollapseOverlay"), for: .normal)
        collapseButton.addTarget(self, action: #selector(self.collapseTapped(_:)), for: .touchUpInside)
        view.addSubview(collapseButton)
        collapseButton.snp.makeConstraints { make in
            make.centerX.equalTo(self.view)
            make.top.equalTo(self.view).offset(10.0)
            make.width.equalTo(35.0)
            make.height.equalTo(11.0)
        }
    }
    
    @objc private func collapseTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func handleSwipe(_ sender: UISwipeGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }
 
    @objc private func handlePan(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: sender.view!)
        let normalizedTranslation =  translation.y / sender.view!.bounds.height
        switch sender.state {
        case .began:
            dismiss(animated: true, completion: nil)
        case .changed:
            interactiveController.update(normalizedTranslation)
        case .ended:
            let view = sender.view!
            let verticalVelocity = sender.velocity(in: view).y
            let time = translation.y / verticalVelocity
            if normalizedTranslation < 0.4 {
                interactiveController.cancel()
            } else {
                let timeRequiredToComplete = time / interactiveController.percentComplete
                let proposedSpeed = (1 - interactiveController.percentComplete) / timeRequiredToComplete
                if proposedSpeed > interactiveController.completionSpeed {
                    interactiveController.completionSpeed = proposedSpeed
                }
                interactiveController.finish()
            }
        case _:
            interactiveController.cancel()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension BottomDrawerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let scrollToManage = scrollToManage else {
            return true
        }
        let translation = (gestureRecognizer as! UIPanGestureRecognizer)
            .translation(in: gestureRecognizer.view!)
        //if the direction of gesture is up we don't want to begin our pan
        if translation.y < 0 {
            return false
        } else {
            // only begin when the scrollView can't scroll up...
            return scrollToManage.contentOffset.y <= CGFloat(0)
        }
    }
}

extension BottomDrawerViewController: UIViewControllerTransitioningDelegate {
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideUpPresentationAnimator()
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideDownDismissalAnimator()
    }
    
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return DrawerPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        let isGestureActive = gestureRecognizer.state != .possible
        return isGestureActive ? interactiveController : nil
    }
}
