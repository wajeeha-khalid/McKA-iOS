//
//  Assessment.swift
//  edX
//
//  Created by Salman Jamil on 9/6/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation
import SwiftyJSON
import MckinseyXBlocks
import Result

public struct Choice {
    public let content: String
    public let value: String
    public let tip: String
}

extension edX.Choice: Equatable {
    public static func == (lhs: Choice, rhs: Choice) -> Bool {
        return lhs.value == rhs.value
    }
}

extension edX.Choice : MckinseyXBlocks.Choice {
    
    public var description: String {
        return content
    }
}

public struct MCQ {
    public let id: String
    public let choices: [Choice]
    public let question: String
    public let title: String?
    public let message: String?
    public let allowsMultipleSelection: Bool
    
    init(json: JSON) {
        question = json["question"].stringValue
        title = json["display_name"].stringValue
        var choiceToTipMap: [String: String] = [:]
        json["tips"].arrayValue.forEach { tip in
            for choiceID in tip["for_choices"].arrayValue where choiceID.string != nil {
                choiceToTipMap[choiceID.stringValue] = tip["content"].stringValue
            }
        }
        choices = json["choices"].arrayValue.map { option -> Choice in
            let choiceID = option["value"].stringValue
            return Choice(content: option["content"].stringValue, value: choiceID, tip: choiceToTipMap[choiceID] ?? "")
        }
        id = json["id"].stringValue
        message = json["message"].string
        allowsMultipleSelection = json["type"].stringValue == "pb-mrq"
    }
}

extension MCQ: Equatable {
    public static func == (lhs: MCQ, rhs: MCQ) -> Bool {
        return lhs.id == rhs.id
    }
}

protocol Evaluator {
    func evaluateQuestionWithID(_ questionId: String, stepId: Int, choices: [String], courseId: String, blockId: String, completion:@escaping (SubmissionResult) -> Void)
}

struct MCQEvaluator: Evaluator {
    let networkManager: NetworkManager
    
    static func resultFromResponse(_ response: HTTPURLResponse, json: JSON) -> edXCore.Result<EvaluationResult> {
        guard let resultJSON = json["results"].arrayValue.first?.arrayValue[1],
              let status = resultJSON["status"].string else {
            return .failure( NSError(domain: "", code: 0, userInfo: nil))
        }
        if status == "correct" {
            return .success(.correct)
        } else if status == "incorrect" {
            return .success(.incorrect)
        } else {
            let score = resultJSON["score"].floatValue
            return .success(.partiallyCorrect(percentage: score))
        }
    }
    
    func evaluateQuestionWithID(_ questionId: String, stepId: Int, choices: [String], courseId: String, blockId: String, completion: @escaping (SubmissionResult) -> Void) {
        let path = "/courses/{course_id}/xblock/{block_id}/handler/submit".oex_format(withParameters: ["course_id": courseId, "block_id": blockId])
        let requestBody: [String : Any] = [
            questionId : [
                "value": choices[0]
            ],
            "active_step" : stepId
        ]
        let deserializer = MCQEvaluator.resultFromResponse(_:json:)
        let request = NetworkRequest(method: .POST,
                                     path: path,
                                     requiresAuth: true,
                                     body: .jsonBody(JSON(requestBody)),
                                     deserializer: .jsonResponse(deserializer))
        networkManager.streamForRequest(request)
            .extendLifetimeUntilFirstResult { result in
            
                result.ifSuccess { r in
                    completion(SubmissionResult.success(r))
                }
                result.ifFailure {
                    completion(SubmissionResult.failure($0))
                }
        }
    }
}

struct MRQEvaluator: Evaluator {
    let networkManager: NetworkManager
    func evaluateQuestionWithID(_ questionId: String, stepId: Int, choices: [String], courseId: String, blockId: String, completion: @escaping (SubmissionResult) -> Void) {
        let path = "/courses/{course_id}/xblock/{block_id}/handler/submit".oex_format(withParameters: ["course_id": courseId, "block_id": blockId])
        let requestBody: [String : Any] = [
            questionId: choices,
            "active_step" : stepId
            ]
        let deserializer = MCQEvaluator.resultFromResponse(_:json:)
        let request = NetworkRequest(method: .POST,
                                     path: path,
                                     requiresAuth: true,
                                     body: .jsonBody(JSON(requestBody)),
                                     deserializer: .jsonResponse(deserializer))
        networkManager.streamForRequest(request)
            .extendLifetimeUntilFirstResult { result in
                result.ifSuccess { r in
                    completion(SubmissionResult.success(r))
                }
                result.ifFailure {
                    completion(SubmissionResult.failure($0))
                }
        }
    }
}

public struct MultipleChoiceQuestion: MckinseyXBlocks.MultipleChoiceQuestion {
    public var choices: [MckinseyXBlocks.Choice] {
        return question.choices
    }

    let stepID: Int
    let courseID: String
    let blockID: String
    let question: MCQ
    let evaluator: Evaluator
    
    init(stepID: Int, courseID: String, blockID: String, question: MCQ, evaluator: Evaluator) {
        self.stepID = stepID
        self.courseID = courseID
        self.blockID = blockID
        self.question = question
        self.evaluator = evaluator
        self.statement = NSAttributedString(styled: question.question.styled(with: questionTemplate)) ?? NSAttributedString(string: question.question)
    }
    
    public var alowsMultipleSelection: Bool {
        return question.allowsMultipleSelection
    }
    
    public var title: String? {
        return question.title
    }
    public let statement: Statement
    
    public func evaluate(with choices: [MckinseyXBlocks.Choice], completion: @escaping (SubmissionResult) -> Void) {
        let indices = choices.flatMap { selectedChoice in
            question.choices.index { choice in
                selectedChoice.isEqual(to: choice)
            }
        }
        let selectedChoices = indices.map {question.choices[$0]}.map {$0.value}
        evaluator.evaluateQuestionWithID(question.id, stepId: stepID, choices: selectedChoices, courseId: courseID, blockId: blockID, completion: completion)
    }
}

public struct Assessment {
    
    public let maximumAttempts: Int
    public let questions: [MCQ]
    public let id: String
    
    public init(id: String, json: JSON) {
        self.id = id
        maximumAttempts = json["max_attempts"].intValue
        let stepsJSON = json["components"].arrayValue.filter {
            $0["type"].string == "sb-step"
        }
        let questionJSON = stepsJSON.flatMap { json -> JSON? in
            json["components"].arrayValue
                .filter{ ["pb-mrq", "pb-mcq"]
                    .contains($0["type"].stringValue)}.first
            
        }
        questions = questionJSON.map {
            MCQ(json: $0)
        }
    }
    
    func indexOf(questionWithID questionID: String) -> Int? {
        return questions.index {
            $0.id == questionID
        }
    }
}


struct AssessmentState {
    var numberOfAttemptsMade: Int
    let activeStep: Int?
    let userResults: [AssessmentComponentResult]
}

struct AssessmentStateAPI {
    
    static func assessmentState(from reponse: HTTPURLResponse, json: JSON) -> edXCore.Result<AssessmentState> {
        guard let numberOfAttempts = json["num_attempts"].int else {
            return .failure(
                NSError(domain: "", code: 0, userInfo: nil)
            )
        }
        
        let step = json["active_step"].intValue
        let components = json["components"].dictionaryValue
        let results = components.flatMap { (_,componentJSON) -> AssessmentComponentResult?  in
            if let studentResults = componentJSON["student_results"].arrayValue.first?.arrayValue,
                let id = studentResults.first?.string {
                let resultDict = studentResults[1]
                let statusString = resultDict["status"].string
                guard let status = statusString.flatMap ({ str -> EvaluationResult? in
                        switch str {
                        case "correct":
                            return EvaluationResult.correct
                        case "incorrect":
                            return EvaluationResult.incorrect
                        case "partial":
                            let score = resultDict["score"].floatValue
                            return EvaluationResult.partiallyCorrect(percentage: score)
                        default: return nil
                        }
                }) else {
                    return nil
                }
               
                if let choicesArray = resultDict["choices"].array {
                    let choices = choicesArray.map { json in
                        return MRQResult.SelctedChoice(
                            completed: json["completed"].boolValue,
                            selected: json["selected"].boolValue,
                            value: json["value"].stringValue
                        )
                    }
                    return AssessmentComponentResult.mrq(MRQResult(questionId: id, selectedChoices: choices, evaluationResult: status, message: resultDict["message"].stringValue))
                } else  {
                    let submission = resultDict["submission"].stringValue
                    return AssessmentComponentResult.mcq(MCQResult(evaluationResult: status, questionId: id, submissionId: submission, message: resultDict["message"].stringValue))
                }
            } else {
                return nil
            }
        }
        let state = AssessmentState(numberOfAttemptsMade: numberOfAttempts, activeStep: step == -1 ? nil : step, userResults: results)
        return .success(state)
    }
    
    static func fetchUserStateForAssessmentWithID(_ assessmentID: String, courseID: String, networkManager: NetworkManager) -> edXCore.Stream<AssessmentState> {
        let path = "/courses/{course_id}/xblock/{block_id}/handler/student_view_user_state"
            .oex_format(withParameters: [
                "course_id" : courseID,
                "block_id": assessmentID
                ])
        let assessementStateDeserializer = assessmentState(from:json:)
        let request = NetworkRequest(method: .POST,
                                     path: path,
                                     requiresAuth: true,
                                     deserializer:.jsonResponse(assessementStateDeserializer))
        return networkManager.streamForRequest(request)
    }
}

struct RetakeAssessmentAPI {
    
    static func stepId(from response: HTTPURLResponse, json: JSON) -> edXCore.Result<Int> {
        guard let step = json["active_step"].int else {
            let error = NSError(domain: "", code: 0, userInfo: nil)
            return .failure(error)
        }
        
        return .success(step)
    }
    
    static func retakeAssessmentWithID(_ assessmentID: String, courseID: String, networkManager: NetworkManager) -> edXCore.Stream<Int> {
        
        let path = "/courses/{course_id}/xblock/{block_id}/handler/try_again"
            .oex_format(withParameters: [
                "course_id" : courseID,
                "block_id": assessmentID
                ])
        let requestBody: [String : Any] = [:]
        let deserializer = RetakeAssessmentAPI.stepId(from:json:)
        let request = NetworkRequest(method: .POST,
                                     path: path,
                                     requiresAuth: true,
                                     body: .jsonBody(JSON(requestBody)),
                                     deserializer: .jsonResponse(deserializer))
        return networkManager.streamForRequest(request)
    }
}

public class AssessmentAdapter: MckinseyXBlocks.Assessment {
    
    typealias AssesmentModuleDelegate = MultipleChoiceQuestionModuleDelegate & ProvisionalResultModuleDelegate
    
    private var assessmentState: AssessmentState?
    let assessment: Assessment
    let courseID: String
    let blockID: String
    let networkManager: NetworkManager
    var currentIndex = 0
    weak var moduleDelegate: AssesmentModuleDelegate?
    
    init(courseID: String, blockID: String, assessment: Assessment, networkManager: NetworkManager) {
        self.assessment = assessment
        self.courseID = courseID
        self.blockID = blockID
        self.networkManager = networkManager
    }
    
    
    public var isAtFinalQuestion: Bool {
        return currentIndex == (assessment.questions.count - 1)
    }
    
    public func next(completion: @escaping (AssessmentResult) -> Void) {
        currentIndex = currentIndex + 1
        if currentIndex < assessment.questions.count {
            
            self.makeQuestionModuleFor(index: self.currentIndex) { module in
                completion(.success(module))
            }
            
        } else {
            currentIndex = 0
            self.start(completion: completion)
        }
    }
    
    public func start(completion: @escaping (AssessmentResult) -> Void) {
        AssessmentStateAPI.fetchUserStateForAssessmentWithID(
            assessment.id,
            courseID: courseID,
            networkManager: networkManager
        ).extendLifetimeUntilFirstResult { result in
            result.ifSuccess{ (state) in
                self.assessmentState = state
                if state.numberOfAttemptsMade < self.assessment.maximumAttempts, let currentStep = state.activeStep {
                    self.currentIndex = currentStep
                    self.makeQuestionModuleFor(index: self.currentIndex) { m in
                        completion(.success(m))
                    }
                } else if state.numberOfAttemptsMade < self.assessment.maximumAttempts {
                    let module = ProvisionalResultModule(
                        grade: Grade(
                            evaluated: state.userResults,
                            totalAttempts: self.assessment.maximumAttempts,
                            availedAttempts: state.numberOfAttemptsMade
                        )
                    )
                    module.delegate = self.moduleDelegate
                    completion(.success(module))
                } else {
                    let finalGrade = FinalGrade(results: state.userResults, assessment: self.assessment)
                    let module = ReviewGradeViewController(grade: finalGrade)
                    completion(.success(module))
                }
            }
            result.ifFailure{ error in
                completion(.failure(error))
            }
        }
    }
    
    
    
    private func makeQuestionModuleFor(index: Int, completion:@escaping (MultipleChoiceQuestionModule) -> Void) {
        DispatchQueue.global().async {
            let current = self.assessment.questions[self.currentIndex]
            let evaluator: Evaluator
            if current.allowsMultipleSelection {
                evaluator = MRQEvaluator(networkManager: self.networkManager)
            } else {
                evaluator = MCQEvaluator(networkManager: self.networkManager)
            }
            let adapter = MultipleChoiceQuestion(stepID: self.currentIndex, courseID: self.courseID, blockID: self.blockID, question: current, evaluator: evaluator)
            let module = MultipleChoiceQuestionModule(question: adapter)
            module.delegate = self.moduleDelegate
            DispatchQueue.main.async {
                completion(module)
            }
        }
    }
    
    public func retake(completion: @escaping (AssessmentResult) -> Void) {
        RetakeAssessmentAPI.retakeAssessmentWithID(
            assessment.id
            , courseID: courseID,
              networkManager: networkManager
        ).extendLifetimeUntilFirstResult { result in
            result.ifSuccess{ stepId in
                self.currentIndex = stepId
                if var state = self.assessmentState {
                    state.numberOfAttemptsMade += 1
                    self.assessmentState = state
                }
                self.makeQuestionModuleFor(index: self.currentIndex) { m in
                    completion(.success(m))
                }
            }
            result.ifFailure { error in
                completion(.failure(error))
            }
        }
    }
}
