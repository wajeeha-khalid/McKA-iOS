//
//  Assessment.swift
//  edX
//
//  Created by Salman Jamil on 9/6/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation
import SwiftyJSON


public struct MCQ {
    public let id: String
    public let choices: [Choice]
    public let question: String
    public let title: String?
    public let message: String?
    public let allowsMultipleSelection: Bool
    
    init(json: JSON) {
        question = json["question"].stringValue
        title = json["title"].stringValue
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

public struct Assessment {
    
    public let maximumAttempts: Int
    public let questions: [MCQ]
    public let id: String
    
    public init(id: String, json: JSON) {
        self.id = id
        maximumAttempts = json["max_attempts"].intValue
        let stepsJSON = json["components"].arrayValue
            .filter {
                $0.dictionaryValue["type"] == "sb-step"
            }
            .flatMap {
            $0.dictionaryValue["components"]?.arrayValue.first
        }
        questions = stepsJSON.map {
            MCQ(json: $0)
        }
    }
}
