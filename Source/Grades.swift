//
//  Grades.swift
//  edX
//
//  Created by Salman Jamil on 9/7/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation
import MckinseyXBlocks

struct MCQResult: Evaluated, Equatable {
    let evaluationResult: EvaluationResult
    let questionId: String
    let submissionId: String
    
    static func == (lhs: MCQResult, rhs: MCQResult) -> Bool {
        return lhs.questionId == rhs.questionId
    }
}

struct MRQResult: Evaluated, Equatable {
    let questionId: String
    let submissionIds: [String]
    let evaluationResult: EvaluationResult
    
    static func == (lhs: MRQResult, rhs: MRQResult) -> Bool {
        return lhs.questionId == rhs.questionId
    }
}

