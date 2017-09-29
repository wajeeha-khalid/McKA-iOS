//
//  FinalResultsModule.swift
//  edX
//
//  Created by Salman Jamil on 9/28/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation
import MckinseyXBlocks

class ResultsModule: Module {
    let pageViewController: UIPageViewController
    let results: Grade
    let assessment: Assessment
    var activeIndex: Int?
    var activeModule: MRQResultModule?

    
    init(results: Grade, assessment: Assessment) {
        self.assessment = assessment
        self.results = results
        pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil
        )
        showFinalResultsViewController(animated: false)
    }
    
    public lazy var reviewGradeButton: UIButton = {
        let button = UIButton()
        button.setTitle("Review Grade", for: .normal)
        button.layer.cornerRadius = 14.0
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 15, bottom: 5, right: 15)
        button.setBackgroundColor(UIColor(colorLiteralRed: 42/255.0, green: 138/255.0, blue: 226/225.0, alpha: 1.0), for: .normal)
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(self.reviewGradeTapped(_:)), for: .touchUpInside)
        button.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
        return button
    }()
    
    @objc func reviewGradeTapped(_ sender: UIButton) {
        showFinalResultsViewController(animated: true)
    }
    
    func showFinalResultsViewController(animated: Bool) {
        let finalResultsViewController = FinalResultsViewController(grade: results)
        finalResultsViewController.delegate = self
        activeIndex = nil
        reviewGradeButton.removeFromSuperview()
        pageViewController.setViewControllers(
            [finalResultsViewController],
            direction: .forward, animated: animated,
            completion: nil
        )
    }
    
    lazy var containerView: UIView = {
        let containerView = UIView()
        return containerView
    }()
    
    var viewController: UIViewController {
        return pageViewController
    }
    
    var primaryActionView: UIView? {
        return containerView
    }
    
    func makeModule(for index: Int) -> MRQResultModule {
        
        let options: NavigationOptions
        
        switch index {
        case 0:
            options = NavigationOptions.forward
        case (assessment.questions.count - 1):
            options = NavigationOptions.reverse
        case _:
            options = [NavigationOptions.forward, NavigationOptions.reverse]
        }
        
        let result = results[index]
        switch result {
        case .mrq(let value):
            return MRQResultModule(
                result: MRQResultAdapter(
                    question: assessment.questions[index],
                    result: value
                ),
                navigationOptions: options
            )
        case let .mcq(value):
            return MRQResultModule(
                result: MCQResultAdapter(
                    question: assessment.questions[index],
                    result: value
                ),
                navigationOptions: options
            )
        }
    }
    
    func showModule(for index: Int, navigationDirection: UIPageViewControllerNavigationDirection) {
        let module = makeModule(for: index)
        module.delegate = self
        activeIndex = index
        activeModule = module
        pageViewController.setViewControllers(
            [module.viewController],
            direction: navigationDirection,
            animated: true,
            completion: nil
        )
    }
}

extension ResultsModule : MRQResultModuleDelegate {
    func mrqResultModuleDidTapOnNext(_ module: MRQResultModule) {
        guard let current = activeIndex else {
            return
        }
        let next = results.index(after: current)
        activeIndex = next
        showModule(for: next, navigationDirection: .forward)
    }
    
    func mrqResultModuleDidTapOnPrevious(_ module: MRQResultModule) {
        guard let current = activeIndex else {
            return
        }
        let previous = results.index(before: current)
        activeIndex = previous
        showModule(for: previous, navigationDirection: .reverse)
    }
}

extension ResultsModule: FinalResultViewControllerDelegate {
    func finalResultViewController(_ viewController: FinalResultsViewController, didTapOn link: QuestionLink) {
        showModule(for: link.index, navigationDirection: .reverse)
        containerView.addSubview(reviewGradeButton)
        reviewGradeButton.snp.makeConstraints{ $0.edges.equalTo(containerView) }
    }
}

extension Grade: GradeProtocol {
    var totalAttempts: Int {
        return assessment.maximumAttempts
    }
    
    var availedAttempts: Int {
        return state.numberOfAttemptsMade
    }

    var correct: [QuestionLink] {
        return results.enumerated().filter { (offset, result) in
            if case .correct = result.evaluationResult {
                return true
            } else {
                return false
            }
            }.map { (offset, _) in
               QuestionLink(title: "Question \(offset + 1)", index: offset)
        }
    }
    
    var incorrect: [QuestionLink] {
        return results.enumerated().filter { (offset, result) in
            if case .incorrect = result.evaluationResult {
                return true
            } else {
                return false
            }
            }.map { (offset, _) in
                QuestionLink(title: "Question \(offset + 1)", index: offset)
        }
    }
    
    var partiallyCorrect: [QuestionLink] {
        return results.enumerated().filter { (offset, result) in
            if case .partiallyCorrect = result.evaluationResult {
                return true
            } else {
                return false
            }
            }.map { (offset, _) in
                QuestionLink(title: "Question \(offset + 1)", index: offset)
        }
    }
}

struct Grade {
    
    fileprivate let results: [AssessmentComponentResult]
    fileprivate let assessment: Assessment
    fileprivate let state: AssessmentState
    
    init(state: AssessmentState, assessment: Assessment) {
        self.state = state
        self.results = state.userResults.sorted { (lhs, rhs) -> Bool in
            assessment.indexOf(questionWithID: lhs.questionID)! < assessment.indexOf(questionWithID: rhs.questionID)!
        }
        self.assessment = assessment
    }
    
    var score: Float {
        guard results.count > 0 else {
            return 0
        }
        let obtained = results.reduce(Float(0)) {
            return $0 + $1.evaluationResult.score
        }
        return (obtained * 100) / Float(results.count)
    }
}

extension Grade: Sequence {
    func makeIterator() -> AnyIterator<AssessmentComponentResult> {
        return AnyIterator(results.makeIterator())
    }
}

extension Grade: BidirectionalCollection {
    func index(after i: Int) -> Int {
        return results.index(after:i)
    }
    
    func index(before i: Int) -> Int {
        return results.index(before:i)
    }
    
    var startIndex: Int {
        return results.startIndex
    }
    
    var endIndex: Int {
        return results.endIndex
    }
    
    subscript(i: Int) -> AssessmentComponentResult {
        return results[i]
    }
}
