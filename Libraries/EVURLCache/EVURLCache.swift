//
//  EVURLCache.swift
//  EVURLCache
//
//  Created by Edwin Vermeer on 11/7/15.
//  Copyright © 2015 evict. All rights reserved.
//

import Foundation
import UIKit

#if os(iOS)
    import MobileCoreServices
#elseif os(OSX)
    import CoreServices
#endif

struct MD5Digester {
    // return MD5 digest of string provided
    static func digest(string: String) -> String? {

        guard let data = string.dataUsingEncoding(NSUTF8StringEncoding) else { return nil }

        var digest = [UInt8](count: Int(CC_MD5_DIGEST_LENGTH), repeatedValue: 0)

        CC_MD5(data.bytes, CC_LONG(data.length), &digest)

        return (0..<Int(CC_MD5_DIGEST_LENGTH)).reduce("") { $0 + String(format: "%02x", digest[$1]) }
    }
}

public class EVURLCache: NSURLCache {

    public static var URLCACHE_CACHE_KEY = "MobileAppCacheKey" // Add this header variable to the response if you want to save the response using this key as the filename.
    public static var MAX_AGE = "604800" // The default maximum age of a cached file in seconds. (1 week)
    public static var PRE_CACHE_FOLDER = "PreCache"  // The folder in your app with the prefilled cache content
    public static var CACHE_FOLDER = "Cache" // The folder in the Documents folder where cached files will be saved
    public static var MAX_FILE_SIZE = 24 // The maximum file size that will be cached (2^24 = 16MB)
    public static var MAX_CACHE_SIZE = 30 // The maximum file size that will be cached (2^30 = 256MB)
    public static var LOGGING = false // Set this to true to see all caching action in the output log
    public static var FORCE_LOWERCASE = true // Set this to false if you want to use case insensitive filename compare
    public static var _cacheDirectory: String!
    public static var _preCacheDirectory: String!
    public static var RECREATE_CACHE_RESPONSE = true // There is a difrence between unarchiving and recreating. I have to find out what.
    private static var _filter = { _ in return true } as ((request: NSURLRequest) -> Bool)

    // Activate EVURLCache
    public class func activate() {
        // set caching paths
        _cacheDirectory = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]).URLByAppendingPathComponent(CACHE_FOLDER)!.absoluteString
        _preCacheDirectory = NSURL(fileURLWithPath: NSBundle.mainBundle().resourcePath!).URLByAppendingPathComponent(PRE_CACHE_FOLDER)!.absoluteString

        let urlCache = EVURLCache(memoryCapacity: 1<<MAX_FILE_SIZE, diskCapacity: 1<<MAX_CACHE_SIZE, diskPath: _cacheDirectory)

        NSURLCache.setSharedURLCache(urlCache)
    }

    public class func filter (filterFor: ((request: NSURLRequest) -> Bool)) {
        _filter = filterFor
    }

    // Log a message with info if enabled
    public static func debugLog<T>(object: T, filename: String = #file, line: Int = #line, funcname: String = #function) {
        if LOGGING {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy HH:mm:ss:SSS"
            let process = NSProcessInfo.processInfo()
            let threadId = "." //NSThread.currentThread().threadDictionary
            print("\(dateFormatter.stringFromDate(NSDate())) \(process.processName))[\(process.processIdentifier):\(threadId)] \((filename as NSString).lastPathComponent)(\(line)) \(funcname):\r\t\(object)\n")
        }
    }

    // Will be called by a NSURLConnection when it's wants to know if there is something in the cache.
    public override func cachedResponseForRequest(request: NSURLRequest) -> NSCachedURLResponse? {

        guard let url = request.URL else {
            EVURLCache.debugLog("CACHE not allowed for nil URLs")
            return nil
        }

        if url.absoluteString!.isEmpty {
            EVURLCache.debugLog("CACHE not allowed for empty URLs")
            return nil
        }

        if !EVURLCache._filter(request: request) {
            EVURLCache.debugLog("CACHE skipped because of filter: \(request.URLString)") // \nHeaders: \(request.allHTTPHeaderFields)")
            return nil
        }

        // is caching allowed
        if ((request.cachePolicy == NSURLRequestCachePolicy.ReloadIgnoringCacheData || url.absoluteString!.hasPrefix("file:/") || url.absoluteString!.hasPrefix("data:")) && EVURLCache.networkAvailable()) {
            EVURLCache.debugLog("CACHE not allowed for \(url)")
            return nil
        }

        let storagePath = EVURLCache.storagePathForRequest(request, rootPath: EVURLCache._cacheDirectory) ?? ""
        if !NSFileManager.defaultManager().fileExistsAtPath(storagePath) {
            EVURLCache.debugLog("PRECACHE not found \(storagePath)")
            let storagePath = EVURLCache.storagePathForRequest(request, rootPath: EVURLCache._preCacheDirectory) ?? ""
            if !NSFileManager.defaultManager().fileExistsAtPath(storagePath) {
                EVURLCache.debugLog("CACHE not found \(storagePath)")
                return nil
            }
        }

        // Check file status only if we have network, otherwise return it anyway.
        if EVURLCache.networkAvailable() {
            if cacheItemExpired(request, storagePath: storagePath) {
                let maxAge: String = request.valueForHTTPHeaderField("Access-Control-Max-Age") ?? EVURLCache.MAX_AGE
                EVURLCache.debugLog("CACHE item older than \(maxAge) seconds")
                return nil
            }
        }

        // Read object from file
        if let response = NSKeyedUnarchiver.unarchiveObjectWithFile(storagePath) as? NSCachedURLResponse {
            EVURLCache.debugLog("Returning cached data from \(storagePath)") //\nHeaders: \(request.allHTTPHeaderFields)")

            // I have to find out the difrence. For now I will let the developer checkt which version to use
            if EVURLCache.RECREATE_CACHE_RESPONSE {
                // This works for most sites, but aperently not for the game as in the alternate url you see in ViewController
                let r = NSURLResponse(URL: response.response.URL!, MIMEType: response.response.MIMEType, expectedContentLength: response.data.length, textEncodingName: response.response.textEncodingName)
                return NSCachedURLResponse(response: r, data: response.data, userInfo: response.userInfo, storagePolicy: .Allowed)
            }
            // This works for the game, but not for my site.
            return response
        } else {
            EVURLCache.debugLog("The file is probably not put in the local path using NSKeyedArchiver \(storagePath)")
        }
        return nil
    }

    // Will be called by NSURLConnection when a request is complete.
    public override func storeCachedResponse(cachedResponse: NSCachedURLResponse, forRequest request: NSURLRequest) {
        if !EVURLCache._filter(request: request) {
            return
        }
        if let httpResponse = cachedResponse.response as? NSHTTPURLResponse {
            if httpResponse.statusCode >= 400 {
                EVURLCache.debugLog("CACHE Do not cache error \(httpResponse.statusCode) page for : \(request.URL) \(httpResponse.debugDescription)")
                return
            }
        }

        var shouldSkipCache: String? = nil

        // check if caching is allowed according to the request
        if request.cachePolicy == NSURLRequestCachePolicy.ReloadIgnoringCacheData {
            shouldSkipCache = "request cache policy"
        }

        // check if caching is allowed according to the response Cache-Control or Pragma header
        if let httpResponse = cachedResponse.response as? NSHTTPURLResponse {
            if let cacheControl = httpResponse.allHeaderFields["Cache-Control"] as? String {
                if cacheControl.lowercaseString.containsString("no-cache")  || cacheControl.lowercaseString.containsString("no-store") {
                    shouldSkipCache = "response cache control"
                }
            }

            if let cacheControl = httpResponse.allHeaderFields["Pragma"] as? String {
                if cacheControl.lowercaseString.containsString("no-cache") {
                    shouldSkipCache = "response pragma"
                }
            }
        }

        if shouldSkipCache != nil {
            // If the file is in the PreCache folder, then we do want to save a copy in case we are without internet connection
            let storagePath = EVURLCache.storagePathForRequest(request, rootPath: EVURLCache._preCacheDirectory) ?? ""
            if !NSFileManager.defaultManager().fileExistsAtPath(storagePath) {
                EVURLCache.debugLog("CACHE not storing file, it's not allowed by the \(shouldSkipCache) : \(request.URL)")
                return
            }
            EVURLCache.debugLog("CACHE file in PreCache folder, overriding \(shouldSkipCache) : \(request.URL)")
        }

        // create storrage folder
        let storagePath: String = EVURLCache.storagePathForRequest(request, rootPath: EVURLCache._cacheDirectory) ?? ""
        if var storageDirectory: String = NSURL(fileURLWithPath: "\(storagePath)").URLByDeletingLastPathComponent?.absoluteString!.stringByRemovingPercentEncoding {
            do {
                if storageDirectory.hasPrefix("file:") {
                    storageDirectory = storageDirectory.substringFromIndex(storageDirectory.startIndex.advancedBy(5))
                }
                try NSFileManager.defaultManager().createDirectoryAtPath(storageDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                EVURLCache.debugLog("Error creating cache directory \(storageDirectory)")
                EVURLCache.debugLog("Error \(error.debugDescription)")
            }
        }

        if let previousResponse = NSKeyedUnarchiver.unarchiveObjectWithFile(storagePath) as? NSCachedURLResponse {
            if previousResponse.data == cachedResponse.data && !cacheItemExpired(request, storagePath: storagePath) {
                EVURLCache.debugLog("CACHE not rewriting stored file")

                return
            }
        }

        // save file
        EVURLCache.debugLog("Writing data to \(storagePath)")

        if !NSKeyedArchiver.archiveRootObject(cachedResponse, toFile: storagePath) {
            EVURLCache.debugLog("Could not write file to cache")
        } else {
            EVURLCache.debugLog("CACHE save file to Cache  : \(storagePath)")
            // prevent iCloud backup
            if !EVURLCache.addSkipBackupAttributeToItemAtURL(NSURL(fileURLWithPath: storagePath)) {
                EVURLCache.debugLog("Could not set the do not backup attribute")
            }
        }
    }
    
    /// Clear cache
    public static func clearPersistentCache() {
        do {
            if let cacheDirectroryURL = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]).URLByAppendingPathComponent(CACHE_FOLDER) {
                
                try NSFileManager.defaultManager().removeItemAtURL(cacheDirectroryURL)
            }
        } catch {
            debugPrint("Error cleaning EVURLCache: \(error)")
        }
    }
    
    private func cacheItemExpired(request: NSURLRequest, storagePath: String) -> Bool {
        // Max cache age for request
        let maxAge: String = request.valueForHTTPHeaderField("Access-Control-Max-Age") ?? EVURLCache.MAX_AGE
        
        guard let maxAgeInterval: NSTimeInterval = Double(maxAge) else {
            EVURLCache.debugLog("MAX_AGE value string is incorrect")
            return false
        }
        
        return EVURLCache.fileExpired(storagePath, maxAge: maxAgeInterval)
    }
    
    private static func fileExpired(storagePath: String, maxAge: Double) -> Bool {
        do {
            let attributes = try NSFileManager.defaultManager().attributesOfItemAtPath(storagePath)
            if let modDate: NSDate = attributes[NSFileModificationDate] as? NSDate {
                // Test if the file is older than the max age
                if let threshold: NSTimeInterval = Double(maxAge) {
                    let modificationTimeSinceNow: NSTimeInterval? = -modDate.timeIntervalSinceNow
                    return modificationTimeSinceNow > threshold
                }
            }
        } catch {}
        
        return false
    }
    
    private static func cleanupPath(path: String) -> String {
        var result = path
        
        if path.hasPrefix("file:") {
            result = path.substringFromIndex(path.startIndex.advancedBy(5))
            var prevPath = String()
            
            while prevPath != result {
                prevPath = result
                result = result.stringByReplacingOccurrencesOfString("//", withString: "/")
            }
        }
        
        return result
    }
    
    // return the path if the file for the request is in the PreCache or Cache.
    public static func storagePathForRequest(request: NSURLRequest) -> String? {
        guard let _ = EVURLCache._cacheDirectory else { return nil }
        
        var storagePath: String? = EVURLCache.storagePathForRequest(request, rootPath: EVURLCache._cacheDirectory)
        if !NSFileManager.defaultManager().fileExistsAtPath(storagePath ?? "") {
            storagePath = EVURLCache.storagePathForRequest(request, rootPath: EVURLCache._preCacheDirectory)
        }
        if !NSFileManager.defaultManager().fileExistsAtPath(storagePath ?? "") {
            storagePath = nil
        }
        return storagePath
    }

    // build up the complete storrage path for a request plus root folder.
    public static func storagePathForRequest(request: NSURLRequest, rootPath: String, useMD: Bool = true) -> String? {
        var localUrl: String!
        let host: String = request.URL?.host ?? "default"

        let urlString = request.URL?.absoluteString ?? ""
        if urlString.hasPrefix("data:") {
            return nil
        }

        // The filename could be forced by the remote server. This could be used to force multiple url's to the same cache file
        if let cacheKey = request.valueForHTTPHeaderField(URLCACHE_CACHE_KEY) {
            localUrl = "\(host)/\(cacheKey)"
        } else {
            if let path = request.URL?.path {
                localUrl = "\(host)\(path)"
            } else {
                NSLog("WARNING: Unable to get the path from the request: \(request)")
                return nil
            }
        }

        // Without an extension it's treated as a folder and the file will be called index.html
        if let storageFile: String = localUrl.componentsSeparatedByString("/").last {
            if !storageFile.containsString(".") {
                localUrl = "/\(localUrl)/index.html"
            }
        }

        if let query = request.URL?.query {
            localUrl = "\(localUrl)_\(query)"
        }

        // Force case insensitive compare (OSX filesystem can be case sensitive)
        if useMD {
            if FORCE_LOWERCASE {
                localUrl = "\(rootPath)/\(MD5Digester.digest(localUrl.lowercaseString)!)"
            } else {
                localUrl = "\(rootPath)/\(MD5Digester.digest(localUrl)!)"
            }
        } else {
            if FORCE_LOWERCASE {
                localUrl = "\(rootPath)/\(localUrl.lowercaseString)"
            } else {
                localUrl = "\(rootPath)/\(localUrl)"
            }

        }

        // Cleanup
        if localUrl.hasPrefix("file:") {
            localUrl = localUrl.substringFromIndex(localUrl.startIndex.advancedBy(5))
        }
        localUrl = localUrl.stringByReplacingOccurrencesOfString("//", withString: "/")
        localUrl = localUrl.stringByReplacingOccurrencesOfString("//", withString: "/")


        return localUrl
    }

    public static func addSkipBackupAttributeToItemAtURL(url: NSURL) -> Bool {
        do {
            try url.setResourceValue(NSNumber(bool: true), forKey: NSURLIsExcludedFromBackupKey)
            return true
        } catch _ as NSError {
            debugLog("ERROR: Could not set 'exclude from backup' attribute for file \(url.absoluteString)")
        }
        return false
    }
    
    // Removes all files from _cacheDirectory with modification date more than MAX_AGE ago
    static func cleanExpiredCaches() {
        let defaultFileManager = NSFileManager.defaultManager()
        
        let storagePath = EVURLCache._cacheDirectory
        let storageDirectory: String = cleanupPath(storagePath)
        
        guard let fileEnumerator = defaultFileManager.enumeratorAtPath(storageDirectory) else { return }
        guard let maxAge: NSTimeInterval = Double(EVURLCache.MAX_AGE) else {
            EVURLCache.debugLog("MAX_AGE value string is incorrect")
            return
        }
        
        for url in fileEnumerator {
            if let filePath = url as? String {
                let fullPath = storageDirectory + filePath
                var isDirectory = ObjCBool(false)
                defaultFileManager.fileExistsAtPath(fullPath, isDirectory: &isDirectory)
                
                if !isDirectory.boolValue && fileExpired(fullPath, maxAge: maxAge) {
                    do {
                        try defaultFileManager.removeItemAtPath(fullPath)
                        EVURLCache.debugLog("Removed expired cache file: \(fullPath)")
                    } catch {
                        EVURLCache.debugLog("Failed to remove expired cache file: \(fullPath)")
                    }
                }
            }
        }
    }
    
    // Check if we have a network connection
    private static func networkAvailable() -> Bool {
        let appDelegate = UIApplication.sharedApplication().delegate as! OEXAppDelegate
        return appDelegate.reachability.isReachable()
    }
}
