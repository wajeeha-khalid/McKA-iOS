//
//  TablePaginationController.swift
//  edX
//
//  Created by Akiva Leffert on 12/16/15.
//  Copyright © 2015 edX. All rights reserved.
//


extension UIScrollView {
    var scrolledNearBottom : Bool {
        // Rough guess for near bottom: One screen's worth of content away or less
        return self.bounds.maxY + self.bounds.height >= self.contentSize.height
    }
}


protocol ScrollingPaginationViewManipulator {
    func setFooter(_ footer: UIView, visible: Bool)
    var scrollView: UIScrollView? { get }
    var canPaginate: Bool { get }
}

private let footerHeight = 30

open class PaginationController<A> : NSObject, Paginator {
    typealias Element = A

    fileprivate let paginator : AnyPaginator<A>
    fileprivate let viewManipulator: ScrollingPaginationViewManipulator

    fileprivate let footer : UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: footerHeight))
        let activityIndicator = SpinnerView(size: .large, color: .primary)
        view.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { make in
            make.center.equalTo(view)
        }
        return view
    }()

    init<P: Paginator>(paginator: P, manipulator: ScrollingPaginationViewManipulator) where P.Element == A {
        self.paginator = AnyPaginator(paginator)
        self.viewManipulator = manipulator
        super.init()
        manipulator.setFooter(self.footer, visible: false)

        manipulator.scrollView?.oex_addObserver(self, forKeyPath: "bounds") { (controller, tableView, newValue) -> Void in
            controller.viewScrolled()
        }
    }

    var stream : edXCore.Stream<[A]> {
        return paginator.stream
    }

    func loadMore() {
        paginator.loadMore()
    }

    var hasNext: Bool {
        return paginator.hasNext
    }

    fileprivate func updateVisibility() {
        viewManipulator.setFooter(self.footer, visible: self.paginator.stream.active)
    }

    fileprivate func viewScrolled() {
        if !self.paginator.stream.active && (viewManipulator.scrollView?.scrolledNearBottom ?? false) && viewManipulator.canPaginate && self.paginator.hasNext {
            self.paginator.loadMore()
            self.updateVisibility()
        }
        else if !self.paginator.hasNext && (viewManipulator.scrollView?.scrolledNearBottom ?? false){
            self.updateVisibility()
        }
    }

}

