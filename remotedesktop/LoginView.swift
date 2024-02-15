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
    
    @State private var showSettingsPopup = false
    @State private var newRemoteServerHostName = ""
    
    let message: String
    let configObject: ConfigModel
    @State var serverName: String
    
    var body: some View {
        VStack {
            LoginWebView(server: $serverName, callback: gotAuthToken)
            Button("Use a different server") {
                // blank server and close login screen
                // configObject.setServer(server: "")
                configObject.setNewServerNeeded()
                dismiss()
            }
        }
        .padding()
        .interactiveDismissDisabled()
        /*.sheet(isPresented: $showSettingsPopup, onDismiss: {
            print("close settings from login view")
            if newRemoteServerHostName.isEmpty {
                showSettingsPopup = true
            } else {
                if newRemoteServerHostName != configObject.serverHostName {
                    print("server name has changed")
                    let defaults = UserDefaults.standard
                    defaults.setValue(newRemoteServerHostName, forKeyPath: "server_address")
                    configObject.setServer(server: newRemoteServerHostName)
                    serverName = newRemoteServerHostName
                    //dismiss()
                }
            }
        }) {
            SettingsView(remoteServerHostName: $newRemoteServerHostName)
        }*/
        .onAppear() {
            newRemoteServerHostName = serverName
        }
    }
    
    func gotAuthToken(token: HTTPCookie) {
        Logger.loginView.info("gotAuthToken")
        configObject.authToken = token
        configObject.refresh()
    }
}
