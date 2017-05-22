//
//  DownloadController.swift
//  edX
//
//  Created by Konstantinos Angistalis on 02/03/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit


public enum UnitDownloadState {
    case Available
    case Active
    case Complete
    case NotAvailable
}

public struct DownloadState {
    let state: UnitDownloadState
    let progress: Double
}


/// Used to track the download status of a course
public class DownloadController: NSObject {

    private let analytics: OEXAnalytics
    private let courseQuerier : CourseOutlineQuerier

    
    init(courseQuerier: CourseOutlineQuerier, analytics: OEXAnalytics) {
        
        self.courseQuerier = courseQuerier
        self.analytics = analytics
        
        super.init()
        
        NSNotificationCenter.defaultCenter().oex_addObserver(self, name: OEXVideoStateChangedNotification) { (notification, observer, _) -> Void in
//            print("OEXVideoStateChangedNotification: \(notification.description)")
        }
        
        NSNotificationCenter.defaultCenter().oex_addObserver(self, name: OEXDownloadProgressChangedNotification) { (notification, observer, _) -> Void in
//            print("OEXDownloadProgressChangedNotification: \(notification.description)")
        }
        
        NSNotificationCenter.defaultCenter().oex_addObserver(self, name: OEXDownloadEndedNotification) { (notification, observer, _) -> Void in
//            print("OEXDownloadEndedNotification: \(notification.description)")
        }
    }
    
    
    public func stateForUnitWithID(unitID: CourseBlockID) -> DownloadState {
        
        // Video Download State
        var numberOfCompletedDownloads = 0
        var numberOfActiveDownloads = 0
        var totalNumberOfDownloads = 0
        var activeDownloadProgress = 0.0
        
        Logger.logInfo("DOWNLOADS", "#########################################################################")
        Logger.logInfo("DOWNLOADS", "stateForUnitWithID: \(unitID)")
        
        // Videos state
        videoHelpersForUnitWithID(unitID) { (downloadHelpers) in
            
            downloadHelpers.forEach { (helper) in
                
                totalNumberOfDownloads += 1
                
                switch helper.downloadState {
                    
                case .Complete:
                    numberOfCompletedDownloads += 1
                    
                case .New:
                    break
                    
                case .Partial:
                    //if (helper.isVideoDownloading) {
                    numberOfActiveDownloads += 1
                    activeDownloadProgress += helper.downloadProgress
                    //}
                }
                
                Logger.logInfo("DOWNLOADS", "Video Helper: \(helper.isVideoDownloading) - \(helper.downloadState.rawValue) - \(helper.downloadProgress) - \(helper.completedDate)")
            }
        }
        
        // Audios state
        audioHelpersForUnitWithID(unitID) { (audioHelpers) in
            
            audioHelpers.forEach { (helper) in
                
                totalNumberOfDownloads += 1
                
                switch helper.downloadState {
                case .Complete:
                    numberOfCompletedDownloads += 1
                    
                case .New:
                    break
                    
                case .Partial:
                    //if (helper.isVideoDownloading) {
                    numberOfActiveDownloads += 1
                    activeDownloadProgress += helper.downloadProgress
                    //}
                }
                
                Logger.logInfo("DOWNLOADS", "Audio Helper: \(helper.isAudioDownloading) - \(helper.downloadState.rawValue) - \(helper.downloadProgress) - \(helper.completedDate)")
            }
        }
        
        
        // HTML state
        webContentForUnitWitID(unitID) { (urls) in
            
            let webContentStates = PrefillCacheController.sharedController.stateOfWebContent(urls)
            
            guard webContentStates.count > 0 else { return }
            
            webContentStates.forEach { (stateObject) in
                
                totalNumberOfDownloads += 1

                switch stateObject.state {
                case .Complete:
                    numberOfCompletedDownloads += 1
                    
                case .Available:
                    break
                    
                case .Active:
                    numberOfActiveDownloads += 1
                    activeDownloadProgress += stateObject.progress
                    
                case .NotAvailable:
                    break
                }
                
                Logger.logInfo("DOWNLOADS", "HTML Helper: \(stateObject.state) - \(stateObject.progress)")
            }
        }
        
        var resultState: DownloadState
        
        // Calculate the combined state
        if totalNumberOfDownloads == 0 {
            resultState = DownloadState(state: .NotAvailable, progress: 0.0)
            
        } else if numberOfCompletedDownloads == totalNumberOfDownloads {
            resultState = DownloadState(state: .Complete, progress: 100.0)
            
        } else if numberOfActiveDownloads > 0 {
            
            //Calculate the total progress
            var totalProgress = 0.0
            let partition = ceil(100.0 / Double(totalNumberOfDownloads))
            
            // Add the completed downloads 
            totalProgress += ceil(partition * Double(numberOfCompletedDownloads))
    
            // Add the active progress
            var scaledActiveProgress = 0.0
            scaledActiveProgress = ceil((partition * Double(numberOfActiveDownloads) * activeDownloadProgress) / (Double(numberOfActiveDownloads) * 100.0))
            
            totalProgress += scaledActiveProgress
            
            Logger.logInfo("DOWNLOADS", "Calculating progress: \(totalProgress) - \(numberOfActiveDownloads) - \(activeDownloadProgress) - \(numberOfCompletedDownloads) of \(totalNumberOfDownloads)")
            
            resultState = DownloadState(state: .Active, progress: min(100.0, totalProgress))
            
        } else {
            resultState = DownloadState(state: .Available, progress: 0.0)
        }
        
        Logger.logInfo("DOWNLOADS", "Result state: \(resultState.state) - \(resultState.progress)")
        Logger.logInfo("DOWNLOADS", "#########################################################################")
        
        return resultState
    }
    
    public func downloadMediaForUnitWithID(unitID: CourseBlockID) {
        
        let courseID = courseQuerier.courseID
        
        courseQuerier.blockWithID(unitID).listenOnce(self, success: { (unit) in
            
            // Trigger the video downloads
            self.videoHelpersForUnitWithID(unitID) { (videoHelpers) in
                
                OEXInterface.sharedInterface().downloadVideos(videoHelpers)
                
                // Analytics tracking
                self.courseQuerier.parentOfBlockWithID(unit.blockID).listenOnce(self, success: { (parentID) in
                    
                    self.analytics.trackSubSectionBulkVideoDownload(parentID, subsection: unit.blockID, courseID: courseID, videoCount: videoHelpers.count)
                    
                    }, failure: {error in
                        Logger.logError("DOWNLOADS", "Unable to find parent of block: \(unit). Error: \(error.localizedDescription)")
                    }
                )
            }
            
            // Trigger the audio downloads
            self.audioHelpersForUnitWithID(unitID) { (audioHelpers) in
                
                OEXInterface.sharedInterface().downloadAudios(audioHelpers)
                
                // Analytics tracking
                // TODO: Bulk tracking for audios
            }
            
            
            // Trigger the HTML downloads
            self.webContentForUnitWitID(unitID) { (urls) in
                
                PrefillCacheController.sharedController.cacheWebContent(urls)
                
                // Analytics tracking
                // TODO: Bulk tracking for HTML content
            }
            
            }, failure: {error in
                Logger.logError("ANALYTICS", "Unable to find parent of block: \(unitID). Error: \(error.localizedDescription)")
            }
        )
    }
    
    public func cancelDownloadForUnitWithID(unitID: CourseBlockID) {
        
        // Cancel video
        videoHelpersForUnitWithID(unitID) { (videoHelpers) in
            
            videoHelpers.forEach({ (helper) in
                OEXInterface.sharedInterface().cancelDownloadForVideo(helper) { (success) in
                    if (success == false) {
                        Logger.logError("DOWNLOADS", "Unable to cancel video download for block: \(unitID).")
                    }
                }
            })
        }
        
        // Cancel audio
        audioHelpersForUnitWithID(unitID) { (audioHelpers) in
            
            audioHelpers.forEach({ (helper) in
                OEXInterface.sharedInterface().cancelDownloadForAudio(helper) { (success) in
                    if (success == false) {
                        Logger.logError("DOWNLOADS", "Unable to cancel audio download for block: \(unitID).")
                    }
                }
            })
        }
        
        // Cancel HTML
        webContentForUnitWitID(unitID) { (urls) in
            PrefillCacheController.sharedController.cancelDownload(urls)
        }
        
        //Post download update notification
        dispatch_async(dispatch_get_main_queue(), {
            NSNotificationCenter.defaultCenter().postNotificationName(OEXDownloadEndedNotification, object: nil)
        })
    }
    
    public func deleteDownloadsForUnitWithID(unitID: CourseBlockID) {
        
        // Delete video
        videoHelpersForUnitWithID(unitID) { (videoHelpers) in
            
            
            
            videoHelpers.forEach { (helper) in
                
                if let videoID = helper.summary?.videoID {
                    OEXInterface.sharedInterface().deleteDownloadedVideoForVideoId(videoID) { (success) in
                        if (success == false) {
                            Logger.logError("DOWNLOADS", "Unable to delete video download for block: \(unitID).")
                        }
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            NSNotificationCenter.defaultCenter().postNotificationName(OEXDownloadEndedNotification, object: nil)
                        }
                    }
                }
            }
        }
        
        // Delete Audio
        audioHelpersForUnitWithID(unitID) { (audioHelpers) in
            
            audioHelpers.forEach { (helper) in
                
                if let audioID = helper.summary?.studentViewUrl {
                    
                    OEXInterface.sharedInterface().deleteDownloadedAudioWithURL(audioID) { (success) in
                        
                        if (success == false) {
                            Logger.logError("DOWNLOADS", "Unable to delete audio download for block: \(unitID).")
                        }
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            NSNotificationCenter.defaultCenter().postNotificationName(OEXDownloadEndedNotification, object: nil)
                        }
                    }
                }
            }
        }
        
        // Delete HTML
        webContentForUnitWitID(unitID) { (urls) in

            urls.forEach { (componentURL) in
                
                do {
                    if let filePath = EVURLCache.storagePathForRequest(NSURLRequest(URL: componentURL)) {
                        try NSFileManager.defaultManager().removeItemAtPath(filePath)
                    }
                } catch {
                    Logger.logError("DOWNLOADS", "Unable to delete HTML download \(componentURL).\n\(error)")
                }
            }
        }
        
        // Post an update notification
        dispatch_async(dispatch_get_main_queue(), {
            NSNotificationCenter.defaultCenter().postNotificationName(OEXDownloadEndedNotification, object: nil)
        })
    }
    
    
    //MARK - Helper Methods
    
    private func videoHelpersForUnitWithID(unitID: CourseBlockID, completion: ([OEXHelperVideoDownload]) -> () ) {
        
        let videoStream = courseQuerier.flatMapRootedAtBlockWithID(unitID) { block in
            (block.type.asVideo != nil) ? block.blockID : nil
        }
        
        let courseID = courseQuerier.courseID
        
        let videosDownloadHelpersStream: Stream<[OEXHelperVideoDownload]> = videoStream.map( { (videoIDs) in
            
            return OEXInterface.sharedInterface().statesForVideosWithIDs(videoIDs, courseID: courseID).filter { video in
                (!video.summary!.onlyOnWeb && !video.summary!.isYoutubeVideo)}
            }
        )
        
        let queryStream = BackedStream<[OEXHelperVideoDownload]>()
        queryStream.backWithStream(videosDownloadHelpersStream)

        queryStream.listenOnce(self) { (result) in

            if let error = result.error {
                Logger.logError("DOWNLOADS", "Unable to fetch video helpers \(error.description)")
                completion([])
            } else if let downloadHelpers = result.value {
                completion(downloadHelpers)
            } else {
                completion([])
            }
        }
    }
    
    private func audioHelpersForUnitWithID(unitID: CourseBlockID, completion: ([OEXHelperAudioDownload]) -> () ) {

        let audioStream = courseQuerier.flatMapRootedAtBlockWithID(unitID) { block in
            (block.type.asAudio != nil) ? block.blockID : nil
        }
        
        let audioDownloadHelpersStream: Stream<[OEXHelperAudioDownload]> = audioStream.map({ (audioIDs) in
            return OEXInterface.sharedInterface().statesForAudiosWithIDs(audioIDs)
        })
        
        let queryStream = BackedStream<[OEXHelperAudioDownload]>()
        queryStream.backWithStream(audioDownloadHelpersStream)
        
        queryStream.listenOnce(self) { (result) in
            
            if let error = result.error {
                Logger.logError("DOWNLOADS", "Unable to fetch audio helpers \(error.description)")
                completion([])
            } else if let audioHelpers = result.value {
                completion(audioHelpers)
            } else {
                completion([])
            }
        }
    }
    
    private func webContentForUnitWitID(unitID: CourseBlockID, completion: ([NSURL]) -> () ) {
        
        courseQuerier.childrenOfBlockWithID(unitID).listenOnce(self) { (result) in
            
            if let components = result.value {
                
                let urls:[NSURL] = components.children.flatMap({ (component) in
                    
                    switch component.type {
                    case .HTML:
                        return component.blockURL
                    case let .Unknown(type) where type == "chat":
                        return component.blockURL
                    default:
                        return nil
                    }
                })
                
                completion(urls)
                
            } else {
                completion([])
            }
        }        
    }
}
