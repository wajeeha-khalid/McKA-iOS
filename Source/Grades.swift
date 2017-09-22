//
//  Grades.swift
//  edX
//
//  Created by Salman Jamil on 9/7/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation
import MckinseyXBlocks

enum AssessmentComponentResut {
    case mcq(MCQResult)
    case mrq(MRQResult)
}

extension AssessmentComponentResut: Evaluated {
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

extension AssessmentComponentResut: Equatable {
    static func == (lhs: AssessmentComponentResut, rhs: AssessmentComponentResut) -> Bool {
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
    
    static func == (lhs: MCQResult, rhs: MCQResult) -> Bool {
        return lhs.questionId == rhs.questionId
    }
}

struct MRQResult: Evaluated, Equatable {
    
    struct SelctedChoice {
        let completed: Bool
        let selected: Bool
        let value: String
    }
    
    let questionId: String
    let submissionIds: [String]
    let evaluationResult: EvaluationResult
    
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
    
    init(results: [AssessmentComponentResut], assessment: Assessment) {
        modules = results.map {
            switch $0 {
            case .mcq:
                return MCQResultModule()
            case .mrq:
                return MRQResultModule()
            }
        }
        
        let indexComparator: (QuestionLink, QuestionLink) -> Bool = { $0.index < $1.index }
        correct = results.filter {
            if case .correct = $0.evaluationResult {
                return true
            }
            return false
            }.flatMap {
                assessment.indexOf(questionWithID: $0.questionID).map { index in
                    QuestionLink(title: "Question \(index + 1)", index: index)
                }
        }.sorted(by: indexComparator)
        
        incorrect = results.filter {
            if case .incorrect = $0.evaluationResult {
                return true
            }
            return false
            }.flatMap {
                assessment.indexOf(questionWithID: $0.questionID).map { index in
                    QuestionLink(title: "Question \(index + 1)", index: index)
                }
        }.sorted(by: indexComparator)
        
        partiallyCorrect = results.filter {
            if case .partiallyCorrect = $0.evaluationResult {
                return true
            }
            return false
            }.flatMap {
                assessment.indexOf(questionWithID: $0.questionID).map { index in
                    QuestionLink(title: "Question \(index + 1)", index: index)
                }
        }.sorted(by: indexComparator)
        
        let obtained = results.reduce(Float(0)) {
            return $0 + $1.evaluationResult.score
        }
        score = (obtained * 100) / Float(results.count)
    }
    
    func makeCursor(startingAt link: QuestionLink) -> QuestionLinkCursor {
        return ArrayCursor(modules: modules, startingAt: link.index)
    }
}
