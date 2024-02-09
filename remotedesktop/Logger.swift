//
//  Logger.swift
//  remotedesktop
//
//  Created by Kendall, Richard on 6/2/2024.
//

import OSLog

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    
    static let mainView = Logger(subsystem: subsystem, category: "mainView")
    static let configModel = Logger(subsystem: subsystem, category: "configModel")
    static let loginWebView = Logger(subsystem: subsystem, category: "loginWebView")
    static let loginView = Logger(subsystem: subsystem, category: "loginView")
    static let guacViewer = Logger(subsystem: subsystem, category: "guacViewer")
    static let guacViewerWrapper = Logger(subsystem: subsystem, category: "guacViewerWrapper")
    static let settingsView = Logger(subsystem: subsystem, category: "settingsView")
}
