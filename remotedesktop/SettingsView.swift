//
//  SettingsView.swift
//  remotedesktop
//
//  Created by Kendall, Richard on 5/2/2024.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var remoteServerHostName: String
    
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
                }
                Button("Save") {
                    print("Settings save pressed")
                    dismiss()
                }
                .padding()
            }
        }
        .interactiveDismissDisabled()
    }
}
