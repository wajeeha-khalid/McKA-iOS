//
//  DebugMenuLogger.swift
//  edX
//
//  Created by Michael Katz on 11/19/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation



class DebugMenuLogger: NSObject, LoggerSink {

    let filename: String
    fileprivate var filehandle: FileHandle!

    var alwaysPrint = true

    fileprivate class var filename: String {
        let cachesDir = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        let debugdir = (cachesDir as NSString).appendingPathComponent("debug")
        if !FileManager.default.fileExists(atPath: debugdir) {
            _ = try? FileManager.default.createDirectory(atPath: debugdir, withIntermediateDirectories: true, attributes: nil)
        }
        return debugdir + "/debuglog.txt"
    }

    static let instance = DebugMenuLogger()

    class func setup() {
        if OEXConfig.shared().shouldShowDebug() {
            Logger.sharedLogger.addSink(instance)
        }
    }

    override init() {
        filename = DebugMenuLogger.filename
        super.init()

        createFile()
        writeToday()
    }

    fileprivate func writeToday() {
        let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .long)
        writeString("-- " + dateStr + " --")
    }

    fileprivate func writeString(_ message: String) {
        let data = (message + "\n").data(using: String.Encoding.utf8)!
        filehandle.write(data)
    }

    deinit {
        filehandle.closeFile()
    }

    func log(_ level : Logger.Level, domain : String, message : String, file : String, line : UInt) {
        let url = URL(fileURLWithPath: file)
        writeString("[\(level.rawValue)|\(domain)] @ \(url.lastPathComponent):\(line) - \(message)")
    }

    fileprivate func createFile() {
        if !FileManager.default.fileExists(atPath: filename) {
            FileManager.default.createFile(atPath: filename, contents: nil, attributes: nil)
        }
        filehandle = FileHandle(forWritingAtPath: filename)!
        filehandle.seekToEndOfFile()
    }

    fileprivate func deleteFile() {
        filehandle.closeFile()
        _ = try? FileManager.default.removeItem(atPath: filename)
    }

    func clear() {
        deleteFile()
        createFile()
        writeToday()
    }
}
