//
//  ContentView.swift
//  remotedesktop
//
//  Created by Kendall, Richard on 26/1/2024.
//

import SwiftUI
import SwiftData
import WebKit

struct ContentView: View {
    @StateObject var configModel = ConfigModel()
    @State private var showLoginPopup = false
    @State private var showSettingsPopup = false
    @State private var remoteServerHostName = ""

    init() {
        print("init for main view")
        //let defaults = UserDefaults.standard
        //defaults.setValue("", forKeyPath: "server_address")
    }
    
    var body: some View {
        NavigationSplitView {
            List {
                if let config = configModel.config {
                    ForEach(config.availableHosts) { item in
                        NavigationLink {
                            GuacViewer(host: item.hostName, server: remoteServerHostName, config: configModel)
                                .onAppear {
                                    print("on appear for \(item.hostName)")
                                }
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
                    Button("Settings") {
                        showSettingsPopup.toggle()
                    }
                }
            }
        } detail: {
            Text("Select a host to connect")
        }
        .sheet(isPresented: $showLoginPopup, onDismiss: {
            print("login popup has been dismissed")
        }) {
            LoginView(message: "This is a modal view", configObject: configModel, serverName: remoteServerHostName)
        }
        .sheet(isPresented: $showSettingsPopup, onDismiss: {
            print("settings popup has been dismissed")
            print("new server value \(remoteServerHostName)")
            if remoteServerHostName.isEmpty {
                print("new server name empty")
                showSettingsPopup = true
            } else {
                if remoteServerHostName != configModel.serverHostName {
                    print("server name has changed")
                    let defaults = UserDefaults.standard
                    defaults.setValue(remoteServerHostName, forKeyPath: "server_address")
                    configModel.setServer(server: remoteServerHostName)
                }
            }
        }) {
            SettingsView(remoteServerHostName: $remoteServerHostName)
        }
        .onChange(of: configModel.gotConfig) {
            print("gotConfig bool has changed to \(configModel.gotConfig)")
            if configModel.gotConfig {
                showLoginPopup = false
            }
        }
        .onChange(of: configModel.needLogin) {
            if configModel.needLogin {
                showLoginPopup = true
            }
        }
        .onChange(of: configModel.serverHostName) {
            print("doing init load")
            configModel.initialLoad()
        }
        .onAppear() {
            print("appeared")
            let defaults = UserDefaults.standard
            if let serverHostNameFromDefaults = defaults.string(forKey: "server_address") {
                print("got server name from user defaults \(serverHostNameFromDefaults)")
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

    private func refreshHosts() {
        withAnimation {
            configModel.refresh()
        }
    }
    
}

#Preview {
    ContentView()
}
