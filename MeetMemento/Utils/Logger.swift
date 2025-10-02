//
//  Logger.swift
//  MeetMemento
//

import Foundation
import os.log

struct AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.meetmemento"
    
    static let general = os.Logger(subsystem: subsystem, category: "general")
    static let network = os.Logger(subsystem: subsystem, category: "network")
    static let ui = os.Logger(subsystem: subsystem, category: "ui")
    static let data = os.Logger(subsystem: subsystem, category: "data")
    
    static func log(_ message: String, category: os.Logger? = nil, type: OSLogType = .default) {
        let logger = category ?? general
        logger.log(level: type, "\(message)")
    }
}

