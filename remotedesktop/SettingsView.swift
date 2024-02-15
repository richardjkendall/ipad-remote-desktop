//
//  SettingsView.swift
//  remotedesktop
//
//  Created by Kendall, Richard on 5/2/2024.
//

import Foundation
import SwiftUI
import CFNetwork
import OSLog

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var remoteServerHostName: String
    @State var hostError = false
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Application Server")) {
                        LabeledContent {
                            TextField(
                                "Server host name",
                                text: $remoteServerHostName
                            )
                        } label: {
                            Text("Server host name")
                        }
                    }
                    Button("Save") {
                        print("Settings save pressed")
                        Logger.settingsView.info("Saving settings")
                        if checkHostName(host: remoteServerHostName) {
                            Logger.settingsView.info("Server name has resolved")
                            print("DNS lookup is okay")
                            dismiss()
                        } else {
                            Logger.settingsView.info("Server name does not resolve")
                            hostError = true
                        }
                    }
                    Button("Reset to defaults") {
                        print("Reset settings")
                    }
                    Button("Close without changes") {
                        Logger.settingsView.info("Closing form without changes")
                        dismiss()
                    }
                }
                
                
            }
        }
        .interactiveDismissDisabled()
        .alert(isPresented: $hostError) {
            Alert(
                title: Text("DNS Error"),
                message: Text("Could not resolve the host name provided")
            )
        }
    }
    
    func checkHostName(host: String) -> Bool {
        let host = CFHostCreateWithName(nil, host as CFString).takeRetainedValue()
        CFHostStartInfoResolution(host, .addresses, nil)
        var success: DarwinBoolean = false
        if let addresses = CFHostGetAddressing(host, &success)?.takeUnretainedValue() as NSArray? {
            Logger.settingsView.info("Got IP addresses for host name")
            print("got IP addresses from DNS name")
            return true
        }
        Logger.settingsView.info("Did not get IP addresses for host name")
        print("did not get IP addresses from DNS name")
        return false
    }
}
