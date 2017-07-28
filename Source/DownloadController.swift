//
//  DownloadController.swift
//  edX
//
//  Created by Konstantinos Angistalis on 02/03/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit


public enum UnitDownloadState {
    case available
    case active
    case complete
    case notAvailable
}

public struct DownloadState {
    let state: UnitDownloadState
    let progress: Double
}


/// Used to track the download status of a course
open class DownloadController: NSObject {

    fileprivate let analytics: OEXAnalytics
    fileprivate let courseQuerier : CourseOutlineQuerier

    
    init(courseQuerier: CourseOutlineQuerier, analytics: OEXAnalytics) {
        
        self.courseQuerier = courseQuerier
        self.analytics = analytics
        
        super.init()
        
        NotificationCenter.default.oex_addObserver(self, name: NSNotification.Name.OEXVideoStateChanged.rawValue) { (notification, observer, _) -> Void in
//            print("OEXVideoStateChangedNotification: \(notification.description)")
        }
        
        NotificationCenter.default.oex_addObserver(self, name: NSNotification.Name.OEXDownloadProgressChanged.rawValue) { (notification, observer, _) -> Void in
//            print("OEXDownloadProgressChangedNotification: \(notification.description)")
        }
        
        NotificationCenter.default.oex_addObserver(self, name: NSNotification.Name.OEXDownloadEnded.rawValue) { (notification, observer, _) -> Void in
//            print("OEXDownloadEndedNotification: \(notification.description)")
        }
    }
    
    
    open func stateForUnitWithID(_ unitID: CourseBlockID) -> DownloadState {
        
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
                    
                case .complete:
                    numberOfCompletedDownloads += 1
                    
                case .new:
                    break
                    
                case .partial:
                    //if (helper.isVideoDownloading) {
                    numberOfActiveDownloads += 1
                    activeDownloadProgress += helper.downloadProgress
                    //}
                }
                
                Logger.logInfo("DOWNLOADS", "Video Helper: \(helper.isVideoDownloading) - \(helper.downloadState.rawValue) - \(helper.downloadProgress) - \(String(describing: helper.completedDate))")
            }
        }
        
        // Audios state
        audioHelpersForUnitWithID(unitID) { (audioHelpers) in
            
            audioHelpers.forEach { (helper) in
                
                totalNumberOfDownloads += 1
                
                switch helper.downloadState {
                case .complete:
                    numberOfCompletedDownloads += 1
                    
                case .new:
                    break
                    
                case .partial:
                    //if (helper.isVideoDownloading) {
                    numberOfActiveDownloads += 1
                    activeDownloadProgress += helper.downloadProgress
                    //}
                }
                
                Logger.logInfo("DOWNLOADS", "Audio Helper: \(helper.isAudioDownloading) - \(helper.downloadState.rawValue) - \(helper.downloadProgress) - \(String(describing: helper.completedDate))")
            }
        }
        
        
        // HTML state
        webContentForUnitWitID(unitID) { (urls) in
            
            let webContentStates = PrefillCacheController.sharedController.stateOfWebContent(urls)
            
            guard webContentStates.count > 0 else { return }
            
            webContentStates.forEach { (stateObject) in
                
                totalNumberOfDownloads += 1

                switch stateObject.state {
                case .complete:
                    numberOfCompletedDownloads += 1
                    
                case .available:
                    break
                    
                case .active:
                    numberOfActiveDownloads += 1
                    activeDownloadProgress += stateObject.progress
                    
                case .notAvailable:
                    break
                }
                
                Logger.logInfo("DOWNLOADS", "HTML Helper: \(stateObject.state) - \(stateObject.progress)")
            }
        }
        
        var resultState: DownloadState
        
        // Calculate the combined state
        if totalNumberOfDownloads == 0 {
            resultState = DownloadState(state: .notAvailable, progress: 0.0)
            
        } else if numberOfCompletedDownloads == totalNumberOfDownloads {
            resultState = DownloadState(state: .complete, progress: 100.0)
            
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
            
            resultState = DownloadState(state: .active, progress: min(100.0, totalProgress))
            
        } else {
            resultState = DownloadState(state: .available, progress: 0.0)
        }
        
        Logger.logInfo("DOWNLOADS", "Result state: \(resultState.state) - \(resultState.progress)")
        Logger.logInfo("DOWNLOADS", "#########################################################################")
        
        return resultState
    }
    
    open func downloadMediaForUnitWithID(_ unitID: CourseBlockID) {
        
        let courseID = courseQuerier.courseID
        
        courseQuerier.blockWithID(unitID).listenOnce(self, success: { (unit) in
            
            // Trigger the video downloads
            self.videoHelpersForUnitWithID(unitID) { (videoHelpers) in
                
                OEXInterface.shared().downloadVideos(videoHelpers)
                
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
                
                OEXInterface.shared().downloadAudios(audioHelpers)
                
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
    
    open func cancelDownloadForUnitWithID(_ unitID: CourseBlockID) {
        
        // Cancel video
        videoHelpersForUnitWithID(unitID) { (videoHelpers) in
            
            videoHelpers.forEach({ (helper) in
                OEXInterface.shared().cancelDownload(forVideo: helper) { (success) in
                    if (success == false) {
                        Logger.logError("DOWNLOADS", "Unable to cancel video download for block: \(unitID).")
                    }
                }
            })
        }
        
        // Cancel audio
        audioHelpersForUnitWithID(unitID) { (audioHelpers) in
            
            audioHelpers.forEach({ (helper) in
                OEXInterface.shared().cancelDownload(forAudio: helper) { (success) in
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
        DispatchQueue.main.async(execute: {
            NotificationCenter.default.post(name: NSNotification.Name.OEXDownloadEnded, object: nil)
        })
    }
    
    open func deleteDownloadsForUnitWithID(_ unitID: CourseBlockID) {
        
        // Delete video
        videoHelpersForUnitWithID(unitID) { (videoHelpers) in
            
            
            
            videoHelpers.forEach { (helper) in
                
                if let videoID = helper.summary?.videoID {
                    OEXInterface.shared().deleteDownloadedVideo(forVideoId: videoID) { (success) in
                        if (success == false) {
                            Logger.logError("DOWNLOADS", "Unable to delete video download for block: \(unitID).")
                        }
                        
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: NSNotification.Name.OEXDownloadEnded, object: nil)
                        }
                    }
                }
            }
        }
        
        // Delete Audio
        audioHelpersForUnitWithID(unitID) { (audioHelpers) in
            
            audioHelpers.forEach { (helper) in
                
                if let audioID = helper.summary?.studentViewUrl {
                    
                    OEXInterface.shared().deleteDownloadedAudio(withURL: audioID) { (success) in
                        
                        if (success == false) {
                            Logger.logError("DOWNLOADS", "Unable to delete audio download for block: \(unitID).")
                        }
                        
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: NSNotification.Name.OEXDownloadEnded, object: nil)
                        }
                    }
                }
            }
        }
        
        // Delete HTML
        webContentForUnitWitID(unitID) { (urls) in

            urls.forEach { (componentURL) in
                
                do {
                    if let filePath = EVURLCache.storagePathForRequest(URLRequest(url: componentURL)) {
                        try FileManager.default.removeItem(atPath: filePath)
                    }
                } catch {
                    Logger.logError("DOWNLOADS", "Unable to delete HTML download \(componentURL).\n\(error)")
                }
            }
        }
        
        // Post an update notification
        DispatchQueue.main.async(execute: {
            NotificationCenter.default.post(name: NSNotification.Name.OEXDownloadEnded, object: nil)
        })
    }
    
    
    //MARK - Helper Methods
    
    fileprivate func videoHelpersForUnitWithID(_ unitID: CourseBlockID, completion: @escaping ([OEXHelperVideoDownload]) -> () ) {
        
        let videoStream = courseQuerier.flatMapRootedAtBlockWithID(unitID) { block in
            (block.type.asVideo != nil) ? block.blockID : nil
        }
        
        let courseID = courseQuerier.courseID
        
        let videosDownloadHelpersStream: edXCore.Stream<[OEXHelperVideoDownload]> = videoStream.map( { (videoIDs) in
            
            return OEXInterface.shared().statesForVideos(withIDs: videoIDs, courseID: courseID).filter { video in
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
    
    fileprivate func audioHelpersForUnitWithID(_ unitID: CourseBlockID, completion: @escaping ([OEXHelperAudioDownload]) -> () ) {

        let audioStream = courseQuerier.flatMapRootedAtBlockWithID(unitID) { block in
            (block.type.asAudio != nil) ? block.blockID : nil
        }
        
        let audioDownloadHelpersStream: edXCore.Stream<[OEXHelperAudioDownload]> = audioStream.map({ (audioIDs) in
            return OEXInterface.shared().statesForAudios(withIDs: audioIDs)
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
    
    fileprivate func webContentForUnitWitID(_ unitID: CourseBlockID, completion: @escaping ([URL]) -> () ) {
        
        courseQuerier.childrenOfBlockWithID(unitID).listenOnce(self) { (result) in
            
            if let components = result.value {
                
                let urls:[URL] = components.children.flatMap({ (component) in
                    
                    switch component.type {
                    case .html:
                        return component.blockURL
                    case let .unknown(type) where type == "chat":
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
