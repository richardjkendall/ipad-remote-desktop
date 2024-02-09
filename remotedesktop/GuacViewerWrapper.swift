//
//  GuacViewerWrapper.swift
//  remotedesktop
//
//  Created by Kendall, Richard on 6/2/2024.
//

import Foundation
import SwiftUI
import OSLog

struct GuacViewerWrapper: View {
    var host: String
    var server: String
    var config: ConfigModel
    
    var body: some View {
        VStack {
            GuacViewer(host: host, server: server, config: config)
            .onAppear {
                print("wrapper onappear")
                Logger.guacViewerWrapper.info("Onappear for guac view wrapper")
            }
        }
        .ignoresSafeArea()
    }
}
