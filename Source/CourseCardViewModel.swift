//
//  CourseCardViewModel.swift
//  edX
//
//  Created by Michael Katz on 8/31/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

enum CourseProgress {
    case completed
    case inPorgress(progress: Int)
    case notStarted
}

class CourseCardViewModel : NSObject {
    
    fileprivate let detailText: String
    fileprivate let bottomTrailingText: String?
    fileprivate let persistImage: Bool
    fileprivate let wrapTitle: Bool
    fileprivate let course: OEXCourse
    
    fileprivate init(course: OEXCourse, detailText: String, bottomTrailingText: String?, persistImage: Bool, wrapTitle: Bool = false) {
        self.detailText = detailText
        self.bottomTrailingText = bottomTrailingText
        self.persistImage = persistImage
        self.course = course
        self.wrapTitle = wrapTitle
    }
    
    var title : String? {
        return course.name
    }
    
    var courseImageURL: String? {
        return course.courseImageURL
    }
    
    static func onMyVideos(_ course: OEXCourse, collectionInfo: String) -> CourseCardViewModel {
        return CourseCardViewModel(course: course, detailText: course.courseRun, bottomTrailingText: collectionInfo, persistImage: true)
    }
    
    static func onHome(_ course: OEXCourse) -> CourseCardViewModel {
        return CourseCardViewModel(course: course, detailText: course.courseRun, bottomTrailingText: course.nextRelevantDateUpperCaseString, persistImage: true)
    }
    
    static func onDashboard(_ course: OEXCourse) -> CourseCardViewModel {
        return CourseCardViewModel(course: course, detailText: course.courseRunIncludingNextDate, bottomTrailingText: nil, persistImage: true, wrapTitle: true)
    }
    
    static func onCourseCatalog(_ course: OEXCourse, wrapTitle: Bool = false) -> CourseCardViewModel {
        return CourseCardViewModel(course: course, detailText: course.courseRun, bottomTrailingText: course.nextRelevantDateUpperCaseString, persistImage: false, wrapTitle: wrapTitle)
    }
    
    func apply(_ card : CourseCardView, networkManager: NetworkManager) {
        
        
        card.titleText = title
        card.detailText = detailText
        card.bottomTrailingText = bottomTrailingText
        card.course = self.course
        
        if wrapTitle {
            card.wrapTitleLabel()
        }
        
        let remoteImage : RemoteImage
        let placeholder = UIImage(named: "placeholderCourseCardImage")
        if let relativeImageURL = courseImageURL,
            let imageURL = URL(string: relativeImageURL, relativeTo: networkManager.baseURL)
        {
            remoteImage = RemoteImageImpl(
                url: imageURL.absoluteString,
                networkManager: networkManager,
                placeholder: placeholder,
                persist: persistImage)
        }
        else {
            remoteImage = RemoteImageJustImage(image: placeholder)
        }

        card.coverImage = remoteImage
    }
}

extension OEXCourse {
    
    var courseRun : String {
        return String.joinInNaturalLayout([self.org, self.number], separator : " | ")
    }
    
    var courseRunIncludingNextDate : String {
        return String.joinInNaturalLayout([self.org, self.number, self.nextRelevantDateUpperCaseString], separator : " | ")
    }
    
    var nextRelevantDate : String?  {
        // If start date is older than current date
        if self.isStartDateOld {
            guard let end = self.end else {
                return nil
            }
            let formattedEndDate = OEXDateFormatting.format(asMonthDayString: end)
            
            // If Old date is older than current date
            if self.isEndDateOld {
                
                return formattedEndDate.map {Strings.courseEnded(endDate: $0)}
            }
            else{
                return formattedEndDate.map { Strings.courseEnding(endDate: $0) }
            }
        }
        else {  // Start date is newer than current date
            switch self.start_display_info.type {
            case .string where self.start_display_info.displayDate != nil:
                return Strings.starting(startDate: self.start_display_info.displayDate!)
            case .timestamp where self.start_display_info.date != nil:
                let formattedStartDate = OEXDateFormatting.format(asMonthDayString: self.start_display_info.date!)
                return formattedStartDate.map { Strings.starting(startDate: $0) }
            case .none, .timestamp, .string:
                return Strings.starting(startDate: Strings.soon)
            }
        }
    }
    
    fileprivate var nextRelevantDateUpperCaseString : String? {
        return nextRelevantDate?.oex_uppercaseStringInCurrentLocale()
    }
}
