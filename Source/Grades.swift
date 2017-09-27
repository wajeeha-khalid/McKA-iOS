//
//  Grades.swift
//  edX
//
//  Created by Salman Jamil on 9/7/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation
import MckinseyXBlocks

enum AssessmentComponentResult {
    case mcq(MCQResult)
    case mrq(MRQResult)
}

extension AssessmentComponentResult: Evaluated {
    var evaluationResult: EvaluationResult {
        switch self {
        case .mcq(let result):
            return result.evaluationResult
        case .mrq(let result):
            return result.evaluationResult
        }
    }
    
    var questionID: String {
        switch self {
        case .mcq(let result):
            return result.questionId
        case .mrq(let result):
            return result.questionId
        }
    }
}

extension AssessmentComponentResult: Equatable {
    static func == (lhs: AssessmentComponentResult, rhs: AssessmentComponentResult) -> Bool {
        switch (lhs, rhs) {
        case let (.mcq(r1), .mcq(r2)):
            return r1 == r2
        case let (.mrq(r1), .mrq(r2)):
            return r1 == r2
        default:
            return false
        }
    }
}

struct MCQResult: Evaluated, Equatable {
    let evaluationResult: EvaluationResult
    let questionId: String
    let submissionId: String
    let message: String
    
    static func == (lhs: MCQResult, rhs: MCQResult) -> Bool {
        return lhs.questionId == rhs.questionId
    }
}

struct MRQSelectedChoice: MckinseyXBlocks.MRQSelectedChoice {
    let selected: Bool
    let result: SelectionResult
    let description: Statement
    let tip: Statement
    
    init(selected: Bool, result: SelectionResult, description: Statement, tip: Statement) {
        self.selected = selected
        self.result = result
        self.description = description
        self.tip = tip
    }
}

struct MCQResultAdapter: MckinseyXBlocks.MRQResult{
    let statement: Statement
    let message: Statement
    let title: String
    let selectedChoices: [MckinseyXBlocks.MRQSelectedChoice]
    
    /*init(question: MCQ, result: MCQResult) {
        self.statement = NSAttributedString(styled: question.question.styled(with: questionTemplate)) ?? NSAttributedString(string: question.question)
        self.message = NSAttributedString(styled: result.message.styled(with: questionTemplate), textAlignment: .center, color: UIColor(red:0.45, green:0.56, blue:0.65, alpha:1)) ?? NSAttributedString(string: result.message)
        self.title = question.title ?? ""
        let selectedChoice = MRQSelectedChoice(
            selected: true,
            result: result., description: <#T##Statement#>, tip: <#T##Statement#>)
    }*/
}

struct MRQResultAdapter: MckinseyXBlocks.MRQResult {
    let statement: Statement
    let message: Statement
    let title: String
    let selectedChoices: [MckinseyXBlocks.MRQSelectedChoice]
    
    init(question: MCQ, result: MRQResult) {
        self.statement = NSAttributedString(styled: question.question.styled(with: questionTemplate)) ?? NSAttributedString(string: question.question)
        self.message = NSAttributedString(styled: result.message.styled(with: questionTemplate), textAlignment: .center, color: UIColor(red:0.45, green:0.56, blue:0.65, alpha:1)) ?? NSAttributedString(string: result.message)
        self.title = question.title ?? ""
        self.selectedChoices = result.selectedChoices.flatMap { choice in
            question.choices.filter {
                $0.value == choice.value
                }.first.map {
                    MRQSelectedChoice(
                        selected: choice.selected,
                        result: choice.completed ? .correct : .incorrect,
                        description: $0.content,
                        tip: NSAttributedString(styled: $0.tip.styled(with: questionTemplate), textAlignment: .justified, color: .black) ?? NSAttributedString(string: $0.tip)
                    )
            }
        }
    }
}

struct MRQResult: Evaluated, Equatable {
    
    struct SelctedChoice {
        let completed: Bool
        let selected: Bool
        let value: String
    }
    
    let questionId: String
    let selectedChoices: [SelctedChoice]
    let evaluationResult: EvaluationResult
    let message: String
    
    static func == (lhs: MRQResult, rhs: MRQResult) -> Bool {
        return lhs.questionId == rhs.questionId
    }
}

final class FinalGrade: GradeProtocol {
    
    let correct: [QuestionLink]
    let incorrect: [QuestionLink]
    let partiallyCorrect: [QuestionLink]
    let modules: [Module]
    let score: Float
    
    init(results: [AssessmentComponentResult], assessment: Assessment) {
        
        let sorted = results.sorted { (lhs, rhs) -> Bool in
            assessment.indexOf(questionWithID: lhs.questionID)! < assessment.indexOf(questionWithID: rhs.questionID)!
        }.enumerated()
        
        modules = sorted.flatMap { (offset, result) in
            switch result {
            case .mcq:
                return MCQResultModule()
            case .mrq(let result):
                return MRQResultModule(
                    result: MRQResultAdapter(
                        question: assessment.questions[offset],
                        result: result
                    ),
                    selectedImage: StaticImages.mrqSelectedImage,
                    unselectedImage: StaticImages.mrqUnSelectedImage
                )
            }
        }
        
        correct = sorted.filter { (offset, result) in
            if case .correct = result.evaluationResult {
                return true
            }
            return false
            }.map { (offset, _) in
                QuestionLink(title: "Question \(offset + 1)", index: offset)
         }
        
        incorrect = sorted.filter { (offset, result) in
            if case .incorrect = result.evaluationResult {
                return true
            }
            return false
            }.map { (offset, _) in
                QuestionLink(title: "Question \(offset + 1)", index: offset)
        }
        
        partiallyCorrect = sorted.filter { (offset, result) in
            if case .partiallyCorrect = result.evaluationResult {
                return true
            }
            return false
            }.map { (offset, _) in
                QuestionLink(title: "Question \(offset + 1)", index: offset)
        }
        
        let obtained = results.reduce(Float(0)) {
            return $0 + $1.evaluationResult.score
        }
        score = (obtained * 100) / Float(results.count)
    }
    
    func makeCursor(startingAt link: QuestionLink) -> QuestionLinkCursor {
        return ArrayCursor(modules: modules, startingAt: link.index)
    }
}
