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
    let correct: Bool
    let description: Statement
    let tip: Statement
    let optionViewImage: UIImage?
    
    init(selected: Bool, correct: Bool, description: Statement, tip: Statement, optionViewImage: UIImage?) {
        self.selected = selected
        self.correct = correct
        self.description = description
        self.tip = tip
        self.optionViewImage = optionViewImage
    }
}

struct MCQResultAdapter: MckinseyXBlocks.MRQResult{
    let statement: Statement
    let message: Statement
    let title: String
    let selectedChoices: [MckinseyXBlocks.MRQSelectedChoice]
    
    init(question: MCQ, result: MCQResult) {
        self.statement = NSAttributedString(styled: question.question.styled(with: questionTemplate)) ?? NSAttributedString(string: question.question)
        self.message = NSAttributedString(styled: result.message.styled(with: questionTemplate), textAlignment: .center, color: UIColor(red:0.45, green:0.56, blue:0.65, alpha:1)) ?? NSAttributedString(string: result.message)
        self.title = question.title ?? ""
        
        guard let choice = question.choices.filter ({
            $0.value == result.submissionId
        }).first else {
            fatalError("Could not find the selected choice in question")
        }
        
        let correct: Bool = { 
            if case .correct = result.evaluationResult {
                return true
            } else {
                return false
            }
        }()
        let tipColor = correct ? UIColor(red:0.38, green:0.61, blue:0.17, alpha:1) : UIColor(red:1, green:0.08, blue:0.24, alpha:1)
        selectedChoices = [
            MRQSelectedChoice(
                selected: true,
                correct: correct,
                description: choice.content,
                tip: NSAttributedString(
                    styled: choice.tip.styled(with: questionTemplate),
                    textAlignment: .left,
                    color: tipColor) ?? NSAttributedString(string: choice.tip),
                optionViewImage: correct ? Images.correctImage : Images.incorrectImage
            )
        ]
    }
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
                    let tipColor = choice.completed ? UIColor(red:0.38, green:0.61, blue:0.17, alpha:1) : UIColor(red:1, green:0.08, blue:0.24, alpha:1)
                    return MRQSelectedChoice(
                        selected: choice.selected,
                        correct: choice.completed,
                        description: $0.content,
                        tip: NSAttributedString(
                            styled: $0.tip.styled(with: questionTemplate),
                            textAlignment: .justified,
                            color: tipColor) ?? NSAttributedString(string: $0.tip),
                        optionViewImage: choice.selected ? Images.mrqSelectedImage : Images.mrqUnSelectedImage
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
