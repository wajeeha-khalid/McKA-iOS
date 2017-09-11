//
//  CourseOutline.swift
//  edX
//
//  Created by Akiva Leffert on 4/29/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import edXCore
import SwiftyJSON

public typealias CourseBlockID = String

public struct CourseOutline {
    
    enum Fields : String, RawStringExtractable {
        case Root = "root"
        case Blocks = "blocks"
        case BlockCounts = "block_counts"
        case BlockType = "type"
        case Descendants = "descendants"
        case DisplayName = "display_name"
        case Format = "format"
        case Graded = "graded"
        case LMSWebURL = "lms_web_url"
        case StudentViewMultiDevice = "student_view_multi_device"
        case StudentViewURL = "student_view_url"
        case StudentViewData = "student_view_data"
        case Question = "question"
        case Choices = "choices"
        case OptionContent = "content"
        case OptionValue = "value"
        case Summary = "summary"
        case Viewed = "is_viewed"
        case Title = "title"
        case Message = "message"
        case Tips = "tips"
        case QuestionId = "id"
        case partnerCode = "partner_code"
        case contentId = "content_id"
        case html = "html"
    }
    
    public let root : CourseBlockID
    public let blocks : [CourseBlockID:CourseBlock]
    fileprivate let parents : [CourseBlockID:CourseBlockID]
    
    public init(root : CourseBlockID, blocks : [CourseBlockID:CourseBlock]) {
        self.root = root
        self.blocks = blocks
        
        var parents : [CourseBlockID:CourseBlockID] = [:]
        for (blockID, block) in blocks {
            for child in block.children {
                parents[child] = blockID
            }
        }
        self.parents = parents
    }
    
    public init?(json : JSON) {
        if let root = json[Fields.Root].string, let blocks = json[Fields.Blocks].dictionaryObject {
            var validBlocks : [CourseBlockID:CourseBlock] = [:]
            for (blockID, blockBody) in blocks {
                let body = JSON(blockBody)
                let webURL = NSURL(string: body[Fields.LMSWebURL].stringValue)
                let children = body[Fields.Descendants].arrayObject as? [String] ?? []
                let name = body[Fields.DisplayName].string
                let blockURL = body[Fields.StudentViewURL].string.flatMap { NSURL(string:$0) }
                let format = body[Fields.Format].string
                let typeName = body[Fields.BlockType].string ?? ""
                let multiDevice = body[Fields.StudentViewMultiDevice].bool ?? false
                let blockCounts : [String:Int] = (body[Fields.BlockCounts].object as? NSDictionary)?.mapValues {
                    $0 as? Int ?? 0
                    } ?? [:]
                let graded = body[Fields.Graded].bool ?? false
                let viewed = body[Fields.Viewed].bool ?? false
                var type : CourseBlockType
                if let category = CourseBlock.Category(rawValue: typeName) {
                    switch category {
                    case CourseBlock.Category.Course:
                        type = .course
                    case CourseBlock.Category.Chapter:
                        type = .chapter
                    case CourseBlock.Category.Section:
                        type = .section
                    case CourseBlock.Category.Unit:
                        type = .unit
                    case .ProblemBuilder:
                        var data = body[Fields.StudentViewData]
                        let components = data["components"]
                        
                        guard let requiredComponent = components.arrayValue.filter ({
                            $0.dictionaryValue.keys.contains("type")
                        }).first else {
                            type = .unknown("problem-builder")
                            continue
                        }
                        
                        if requiredComponent["type"].string == "pb-mcq" {
                            let studentViewData = requiredComponent
                            let question = studentViewData[Fields.Question]
                            let title = studentViewData[Fields.Title]
                            let questionID = studentViewData[Fields.QuestionId]
                            let message = studentViewData[Fields.Message]
                            var choiceToTipMap: [String: String] = [:]
                            studentViewData[Fields.Tips].arrayValue.forEach { tip in
                                for choiceID in tip["for_choices"].arrayValue where choiceID.string != nil {
                                    choiceToTipMap[choiceID.stringValue] = tip["content"].stringValue
                                }
                            }
                            let choices = studentViewData[Fields.Choices].arrayValue.map { option -> Choice in
                                let choiceID = option["value"].stringValue
                                return Choice(content: option["content"].stringValue, value: choiceID, tip: choiceToTipMap[choiceID] ?? "")
                            }
                            let mcq = MCQ(id: questionID.stringValue, choices: choices, question: question.stringValue, title: title.string, message: message.string)
                            type = .mcq(mcq)
                        } else if requiredComponent["type"].string == "pb-mrq" {
                            let studentViewData = requiredComponent
                            let question = studentViewData[Fields.Question]
                            let title = studentViewData[Fields.Title]
                            let questionID = studentViewData[Fields.QuestionId]
                            let message = studentViewData[Fields.Message]
                            var choiceToTipMap: [String: String] = [:]
                            studentViewData[Fields.Tips].arrayValue.forEach { tip in
                                for choiceID in tip["for_choices"].arrayValue where choiceID.string != nil {
                                    choiceToTipMap[choiceID.stringValue] = tip["content"].stringValue
                                }
                            }
                            let choices = studentViewData[Fields.Choices].arrayValue.map { option -> Choice in
                                let choiceID = option["value"].stringValue
                                return Choice(content: option["content"].stringValue, value: choiceID, tip: choiceToTipMap[choiceID] ?? "")
                            }
                            let mcq = MCQ(id: questionID.stringValue, choices: choices, question: question.stringValue, title: title.string, message: message.string)
                            type = .mrq(mcq)
                        } else if requiredComponent["type"].string == "pb-answer" {
                            let studentViewData = data
                            let message = studentViewData["messages"].dictionaryObject
                            var completionMsg = ""
                            if let completedMsg = message?["completed"] as? String {
                                completionMsg = completedMsg
                            }
                            
                            let title = body[Fields.DisplayName].stringValue
                            let question = requiredComponent[Fields.Question]
                            let id = requiredComponent["id"]
                            let freeText = FreeText(id: id.stringValue, title: title, question: question.stringValue, message: completionMsg)
                            type = .freeText(freeText)
                        } else {
                            type = .unknown("problem-builder")
                            continue
                        }
                    case CourseBlock.Category.HTML:
                        let studentViewData = body[Fields.StudentViewData]
                        let content = studentViewData[Fields.html].stringValue
                        type = .html(content)
                    case CourseBlock.Category.Problem:
                        type = .problem
                    case .OOYALA:
                        guard let contentId = body[Fields.StudentViewData][Fields.contentId].string else {
                            fatalError("unable to find content id of ooyala player")
                        }
                        let playerCode = body[Fields.StudentViewData][Fields.partnerCode].stringValue
                        type = .ooyalaVideo(
                            contentID: contentId,
                            playerCode: playerCode,
                            htmlDescription: nil
                        )
                    case CourseBlock.Category.Video :
                        let bodyData = (body[Fields.StudentViewData].object as? NSDictionary).map { [Fields.Summary.rawValue : $0 ] }
                        let summary = OEXVideoSummary(dictionary: bodyData ?? [:], videoID: blockID, name : name ?? Strings.untitled)
                        type = .video(summary)
                    //Added By Ravi on 22Jan'17 to Implement AudioPodcast
                    case CourseBlock.Category.Audio:
                        let bodyData = (body[Fields.StudentViewData].object as? NSDictionary).map { [Fields.Summary.rawValue : $0 ] }
                        let summary = OEXAudioSummary(dictionary: bodyData ?? [:], studentUrl:blockID ,name : name ?? Strings.untitled )
                        type = .audio(summary)
                    case CourseBlock.Category.Discussion:
                        // Inline discussion is in progress feature. Will remove this code when it's ready to ship
                        
                        if OEXConfig.shared().discussionsEnabled {
                            let bodyData = body[Fields.StudentViewData].object as? NSDictionary
                            let discussionModel = DiscussionModel(dictionary: bodyData ?? [:])
                            type = .discussion(discussionModel)
                        } else {
                            type = .unknown(typeName)
                            continue
                        }
                    }
                }
                else {
                    type = .unknown(typeName)
                    continue
                }
                
                validBlocks[blockID] = CourseBlock(
                    type: type,
                    children: children,
                    blockID: blockID,
                    name: name,
                    blockCounts : blockCounts,
                    blockURL : blockURL as URL?,
                    webURL: webURL as URL?,
                    format : format,
                    multiDevice : multiDevice,
                    viewed : viewed,
                    graded : graded
                )
            }
            self = CourseOutline(root: root, blocks: validBlocks)
        }
        else {
            return nil
        }
    }
    
    func parentOfBlockWithID(_ blockID : CourseBlockID) -> CourseBlockID? {
        return self.parents[blockID]
    }
}

public enum CourseBlockType {
    case unknown(String)
    case course
    case chapter // child of course
    case section // child of chapter
    case unit // child of section
    case video(OEXVideoSummary)
    case mcq(MCQ)
    case mrq(MCQ)
    case freeText(FreeText)
    case ooyalaVideo(contentID: String, playerCode: String, htmlDescription: String?)
    case problem
    case html(String)
    case discussion(DiscussionModel)
    case audio(OEXAudioSummary)// Added by Ravi on 18/01/17 to implement Audio Podcasts.
    
    public var asVideo : OEXVideoSummary? {
        switch self {
        case let .video(summary):
            return summary
        default:
            return nil
        }
    }
    
    // Added by Ravi on 18/01/17 to implement Audio Podcasts.
    public var asAudio : OEXAudioSummary? {
        switch self {
        case let .audio(summary):
            return summary
        default:
            return nil
        }
    }
    
    public var asDiscussion : DiscussionModel? {
        
        switch self {
        case let .discussion(discussionModel):
            return discussionModel
        default :
            return nil
        }
    }
    
}

open class CourseBlock {
    
    /// Simple list of known block categories strings
    public enum Category : String {
        case Chapter = "chapter"
        case Course = "course"
        case HTML = "html"
        case OOYALA = "ooyala-player"
        case Problem = "problem"
        case Section = "sequential"
        case Unit = "vertical"
        case Video = "video"
        case ProblemBuilder = "problem-builder"
        case Discussion = "discussion-forum"
        case Audio = "audio"    // Added by Ravi on 18/01/17 to implement Audio Podcasts.
    }
    
    open var type : CourseBlockType
    open let blockID : CourseBlockID
    
    /// Children in the navigation hierarchy.
    /// Note that this may be different than the block's list of children, server side
    /// Since we flatten out the hierarchy for display
    open var children : [CourseBlockID]
    
    /// Title of block. Keep this private so people don't use it as the displayName by accident
    fileprivate let name : String?
    
    /// Actual title of the block. Not meant to be user facing - see displayName
    open var internalName : String? {
        return name
    }
    
    /// User visible name of the block.
    open var displayName : String {
        guard let name = name, !name.isEmpty else {
            return Strings.untitled
        }
        return name
    }
    
    ///Discussion Block for Unit
    open var discussionBlock : CourseBlock?
    
    /// TODO: Match final API name
    /// The type of graded component
    open let format : String?
    
    /// Mapping between block types and number of blocks of that type in this block's
    /// descendants (recursively) for example ["video" : 3]
    open let blockCounts : [String:Int]
    
    /// Just the block content itself as a web page.
    /// Suitable for embedding in a web view.
    open let blockURL : URL?
    
    /// If this is web content, can we actually display it.
    open let multiDevice : Bool
    
    /// A full web page for the block.
    /// Suitable for opening in a web browser.
    open let webURL : URL?
    
    /// Whether or not the block is graded.
    /// TODO: Match final API name
    open let graded : Bool?
    open var viewedState : CellType?
    open let viewed : Bool?
    public init(type : CourseBlockType,
                children : [CourseBlockID],
                blockID : CourseBlockID,
                name : String?,
                blockCounts : [String:Int] = [:],
                blockURL : URL? = nil,
                webURL : URL? = nil,
                format : String? = nil,
                multiDevice : Bool,
                viewed : Bool = false,
                graded : Bool = false) {
        self.type = type
        self.children = children
        self.name = name
        self.blockCounts = blockCounts
        self.blockID = blockID
        self.blockURL = blockURL
        self.webURL = webURL
        self.graded = graded
        self.format = format
        self.multiDevice = multiDevice
        self.viewed = viewed
    }
}

//MARK: MCQ
public struct FreeText {
    public let id: String
    public let title: String
    public let question: String
    public let message: String
}
public struct Choice {
    public let content: String
    public let value: String
    public let tip: String
}

public struct MCQ {
    public let id: String
    public let choices: [Choice]
    public let question: String
    public let title: String?
    public let message: String?
}
