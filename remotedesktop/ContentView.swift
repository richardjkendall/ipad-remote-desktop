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
    @State private var selectedHost: String? = ""

    init() {
        Logger.mainView.info("Init for view")
        //let defaults = UserDefaults.standard
        //defaults.setValue("", forKeyPath: "server_address")
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedHost) {
                if let config = configModel.config {
                    ForEach(config.availableHosts, id: \.hostName) { item in
                        Text("Host \(item.hostName)")
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
                ToolbarItem {
                    Button(action: closeHost) {
                        Label("Close", systemImage: "xmark")
                    }
                    .disabled(selectedHost!.isEmpty)
                }
            }
        } detail: {
            if !selectedHost!.isEmpty {
                // get host
                if let item = try? configModel.getHostByName(h: selectedHost!) {
                    GuacViewerWrapper(host: item.hostName, server: remoteServerHostName, config: configModel)
                        .id(item.hostName + item.host + item.port)
                } else {
                    Text("Error")
                }
            } else {
                VStack {
                    Image("cws_logo")
                        .resizable()
                        .frame(width: 256, height: 256)
                    Text("Select a host to connect")
                }
            }
        }        
        .sheet(isPresented: $showLoginPopup, onDismiss: {
            Logger.mainView.info("Login sheet has been dismissed")
            //print("login sheet dismissed")
            if configModel.needNewServer {
                //print("we need a new server")
                Logger.mainView.info("Login form has closed with a request for a new server...")
                configModel.setServer(server: "")
            }
        }) {
            LoginView(message: "This is a modal view", configObject: configModel, serverName: remoteServerHostName)
        }
        .sheet(isPresented: $showSettingsPopup, onDismiss: {
            Logger.mainView.info("Settings sheet has been dismissed")
            //print("settings closed")
            if remoteServerHostName.isEmpty {
                Logger.mainView.info("No server name provided on the settings sheet")
                showSettingsPopup = true
            } else {
                print("got server name from settings of \(remoteServerHostName), current value is \(configModel.serverHostName)")
                if remoteServerHostName != configModel.serverHostName {
                    print("server name has changed")
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
            Logger.mainView.info("Server host name changed has changed to \(configModel.serverHostName)")
            print("server host name is now = \(configModel.serverHostName)")
            // if the host name is blank, we need a new server host name so show settings, otherwise we try a load
            if configModel.serverHostName.isEmpty {
                print("as server host name is empty, we should show the settings box")
                Logger.mainView.info("Server host name is empty and we need one, so show the settings popup")
                remoteServerHostName = ""
                showSettingsPopup = true
            } else {
                print("we have the server name, we need to load config data")
                configModel.reset()
                configModel.initialLoad()
            }
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
    
    private func closeHost() {
        selectedHost = ""
    }
    
}

#Preview {
    ContentView()
}
