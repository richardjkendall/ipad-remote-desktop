//
//  LoginView.swift
//  remotedesktop
//
//  Created by Kendall, Richard on 6/2/2024.
//

import SwiftUI
import SwiftData
import WebKit
import OSLog

struct LoginView: View {
    @Environment(\.dismiss) var dismiss
    let message: String
    
    let configObject: ConfigModel
    let serverName: String
    
    var body: some View {
        VStack {
            LoginWebView(server: serverName, callback: gotAuthToken)
        }
        .padding()
        .interactiveDismissDisabled()
    }
    
    func gotAuthToken(token: HTTPCookie) {
        Logger.loginView.info("gotAuthToken")
        configObject.authToken = token
        configObject.refresh()
    }
}
