//
//  CourseProgressAPI.swift
//  edX
//
//  Created by Talha Babar on 9/16/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation
import edXCore
import SwiftyJSON
import Alamofire

extension Float {
    var roundTo2f: Float {return Float(roundf(100*self)/100)}
}

public struct CourseProgressCompletion {
    let completed: Bool
    
    init() {
        completed = true
    }
}

public struct ProgressStats {
    struct Fields {
        static let courseID = "course_key"
        static let earned = "earned"
        static let possible = "possible"
        static let ratio = "ratio"
        static let cohortAvg = "mean"
        static let lessonsProgress = "chapter"
        static let modulesProgress = "vertical"
        static let blockID = "block_key"
    }
    
    let courseID: String
    let blockID: String?
    let cohortAvg: Double?
    let lessonsProgress: [ProgressStats]?
    let modulesProgress: [ProgressStats]?
    let earned: Int
    let possible: Int
    let ratio: Float
    let progress: CourseProgress
    let componentProgress: ComponentProgressState
    
    init(courseID: String, earned: Int, possible: Int, ratio: Float, cohortAvg: Double? = nil, lessonsProgress: [ProgressStats]? = nil, modulesProgress: [ProgressStats]? = nil, blockID: String? = nil) {
        self.courseID = courseID
        self.earned = earned
        self.possible = possible
        self.ratio = ratio
        self.cohortAvg = cohortAvg
        self.lessonsProgress = lessonsProgress
        self.modulesProgress = modulesProgress
        self.blockID = blockID
        let percentageRatio = Int(ratio.roundTo2f * 100)
        switch percentageRatio {
        case 100:
            progress = .completed
            componentProgress = .complete
        case 0:
            progress = .notStarted
            componentProgress = .notStarted
        default:
            progress = .inPorgress(progress: percentageRatio)
            componentProgress = .inProgress
        }
        
    }
    
    init?(dictionary: [String: Any]) {
        self.courseID = dictionary[Fields.courseID] as? String ?? ""
        self.earned = dictionary[Fields.earned] as? Int ?? 0
        self.possible = dictionary[Fields.possible] as? Int ?? 0
        self.ratio = dictionary[Fields.ratio] as? Float ?? 0.0
        self.cohortAvg = dictionary[Fields.cohortAvg] as? Double
        self.lessonsProgress = dictionary[Fields.lessonsProgress] as? [ProgressStats]
        self.modulesProgress = dictionary[Fields.modulesProgress] as? [ProgressStats]
        self.blockID = dictionary[Fields.blockID] as? String
        let percentageRatio = Int(ratio * 100)
        switch percentageRatio {
        case 100:
            progress = .completed
            componentProgress = .complete
        case 0:
            progress = .notStarted
            componentProgress = .notStarted
        default:
            progress = .inPorgress(progress: percentageRatio)
            componentProgress = .inProgress
        }
    }
    
    init?(json: JSON) {
        let responseDic = json.dictionary
        var progressDic: [String:Any] = [:]
        progressDic[Fields.courseID] = responseDic?[Fields.courseID]?.stringValue
        progressDic[Fields.blockID] = responseDic?[Fields.blockID]?.stringValue
        guard let completion = responseDic?["completion"]?.dictionary else {
            self.init(dictionary: progressDic)
            return nil
        }
        
        progressDic[Fields.earned] = completion[Fields.earned]?.intValue
        progressDic[Fields.possible] = completion[Fields.possible]?.intValue
        progressDic[Fields.ratio] = completion[Fields.ratio]?.floatValue
        progressDic[Fields.cohortAvg] = responseDic?[Fields.cohortAvg]?.doubleValue
        
        if let lessonsDicArray = responseDic?[Fields.lessonsProgress]?.arrayValue {
            var lessons: [ProgressStats] = []
            _ = lessonsDicArray.map({ lessons.append(ProgressStats(json: $0)!)})
            progressDic[Fields.lessonsProgress] = lessons
        }
        
        if let modulesDicArray = responseDic?[Fields.modulesProgress]?.arrayValue {
            var modules: [ProgressStats] = []
            _ = modulesDicArray.map({ modules.append(ProgressStats(json: $0)!)})
            progressDic[Fields.modulesProgress] = modules
            
        }
        
        self.init(dictionary: progressDic)
    }
}


struct CourseProgressAPI {
    struct Fields {
        static let completion = "completion"
        static let results = "results"
        static let courseKey = "course_key"
        static let earned = "earned"
        static let possible = "possible"
        static let ratio = "ratio"
        static let blockKeys = "block_key"
        static let cohortAvg = "mean"
        static let lessons = "chapter"
        static let modules = "vertical"
    }
    
    static func allCoursesProgressResponseDeserializer(_ response: HTTPURLResponse, json: JSON) -> edXCore.Result<[ProgressStats]> {
        return .success(
            json[Fields.results].arrayValue.map { json  -> ProgressStats in
                let courseID = json[Fields.courseKey].stringValue
                let progressStatDic = json[Fields.completion]
                let earned = progressStatDic[Fields.earned].intValue
                let possible = progressStatDic[Fields.possible].intValue
                let ratio = progressStatDic[Fields.ratio].floatValue
                return ProgressStats(courseID: courseID, earned: earned, possible: possible, ratio: ratio)
            }
        )
    }
    
    static func completeCourseProgressResponseDeserializer(_ response: HTTPURLResponse, json: JSON) -> edXCore.Result<ProgressStats> {
        if let courseProgress = ProgressStats(json: json) {
            return .success(courseProgress)
        } else {
            return .failure(NSError())
        }
    }
    
    static func updateCourseProgressResponseDeserializer(_ response: HTTPURLResponse) -> edXCore.Result<CourseProgressCompletion> {
        if response.statusCode == 200 || response.statusCode == 201 {
            return .success(CourseProgressCompletion())
        } else {
            return .failure(NSError())
        }
    }
    
    static func getAllCoursesProgress() -> NetworkRequest<[ProgressStats]> {
        let path = "api/completion/v0/course/?page_size={page_size}".oex_format(withParameters: ["page_size": 30])
        return NetworkRequest(method: .GET,
                              path: path,
                              requiresAuth: true,
                              deserializer: .jsonResponse(allCoursesProgressResponseDeserializer)
        )
    }
    
    static func getProgressFor(courseId: String) -> NetworkRequest<ProgressStats> {
        let path = "api/completion/v0/course/{course_id}/?requested_fields=mean,chapter,vertical&page_size=30".oex_format(withParameters: ["course_id": courseId])
        return NetworkRequest(method: .GET,
                              path: path,
                              requiresAuth: true,
                              deserializer: .jsonResponse(completeCourseProgressResponseDeserializer)
        )
    }

    static func updateProgressRequestFor(courseId: String, blockId: String) -> NetworkRequest<CourseProgressCompletion> {
        let path = "api/completion/v0/course/{course_id}/blocks/{block_id}/".oex_format(withParameters: ["course_id": courseId, "block_id": blockId])
        let requestBody = ["completion": 1]
        return NetworkRequest(method: .POST,
                              path: path,
                              requiresAuth: true,
                              body: .jsonBody(JSON(requestBody)),
                              deserializer: .noContent(updateCourseProgressResponseDeserializer))
    }
    
    static func updateProgressFor(environment: NetworkManagerProvider, owner: NSObject, courseId: String, blockId: String) {
        let updateProgressStream = environment.networkManager.streamForRequest(CourseProgressAPI.updateProgressRequestFor(courseId: courseId, blockId: blockId))
        updateProgressStream.extendLifetimeUntilFirstResult { result in
            result.ifSuccess { _ in
            }
            result.ifFailure { _ in
            }
        }
    }
}
