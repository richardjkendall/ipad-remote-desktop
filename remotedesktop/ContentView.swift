//
//  ContentView.swift
//  remotedesktop
//
//  Created by Kendall, Richard on 26/1/2024.
//

import SwiftUI
import SwiftData
import WebKit
import OSLog

struct ContentView: View {
    @StateObject var configModel = ConfigModel()
    @State private var showLoginPopup = false
    @State private var showSettingsPopup = false
    @State private var remoteServerHostName = ""
    @State private var showErrorAlert = false

    init() {
        Logger.mainView.info("Init for view")
    }
    
    var body: some View {
        NavigationSplitView {
            List {
                if let config = configModel.config {
                    ForEach(config.availableHosts) { item in
                        NavigationLink {
                            GuacViewerWrapper(host: item.hostName, server: remoteServerHostName, config: configModel)
                                .id(item.hostName + item.host + item.port)
                        } label: {
                            Text("Host \(item.hostName)")
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem {
                    Button(action: refreshHosts) {
                        Label("Refresh Host List", systemImage: "arrow.clockwise.circle")
                    }
                }
                ToolbarItem {
                    Button(action: openSettings) {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
        } detail: {
            Text("Select a host to connect")
        }
        .sheet(isPresented: $showLoginPopup, onDismiss: {
            Logger.mainView.info("Login sheet has been dismissed")
        }) {
            LoginView(message: "This is a modal view", configObject: configModel, serverName: remoteServerHostName)
        }
        .sheet(isPresented: $showSettingsPopup, onDismiss: {
            Logger.mainView.info("Settings sheet has been dismissed")
            if remoteServerHostName.isEmpty {
                Logger.mainView.info("No server name provided on the settings sheet")
                showSettingsPopup = true
            } else {
                if remoteServerHostName != configModel.serverHostName {
                    Logger.mainView.info("Server name has changed to \(remoteServerHostName)")
                    let defaults = UserDefaults.standard
                    defaults.setValue(remoteServerHostName, forKeyPath: "server_address")
                    configModel.setServer(server: remoteServerHostName)
                }
            }
        }) {
            SettingsView(remoteServerHostName: $remoteServerHostName)
        }
        .alert(isPresented: $configModel.gotError) {
            Alert(
                title: Text("Error getting hosts"),
                message: Text("Got non standard response from server")
            )
        }
        .onChange(of: configModel.gotConfig) {
            if configModel.gotConfig {
                Logger.mainView.info("We have config information")
                showLoginPopup = false
            }
        }
        .onChange(of: configModel.needLogin) {
            if configModel.needLogin {
                Logger.mainView.info("Need to show login sheet")
                showLoginPopup = true
            }
        }
        .onChange(of: configModel.serverHostName) {
            Logger.mainView.info("Performing config initial load")
            configModel.initialLoad()
        }
        .onAppear() {
            let defaults = UserDefaults.standard
            if let serverHostNameFromDefaults = defaults.string(forKey: "server_address") {
                Logger.mainView.info("Got server name from user defaults \(serverHostNameFromDefaults)")
                if serverHostNameFromDefaults == "" {
                    showSettingsPopup = true
                } else {
                    remoteServerHostName = serverHostNameFromDefaults
                    configModel.setServer(server: serverHostNameFromDefaults)
                }
            } else {
                showSettingsPopup = true
            }
        }
    }
    
    private func openSettings() {
        showSettingsPopup.toggle()
    }

    private func refreshHosts() {
        withAnimation {
            configModel.refresh()
        }
    }
    
}

#Preview {
    ContentView()
}
