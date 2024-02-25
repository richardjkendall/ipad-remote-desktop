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
    var handleStateChange: ((String) -> Void)
    
    @State var showLoadingBox = false
    
    var body: some View {
        ZStack {
            GuacViewer(host: host, server: server, config: config, closeProgressBoxCallback: CloseProgressView, handleStateUpdate: HandleStateUpdate)
            .onAppear {
                print("wrapper onappear")
                Logger.guacViewerWrapper.info("Onappear for guac view wrapper")
            }
            if showLoadingBox {
                ProgressAlert(closeAction: {
                    print("close")
                })
            }
        }
    }
    
    func HandleStateUpdate(_ state: String) {
        //connectionState = state
        handleStateChange(state)
    }
    
    func CloseProgressView() {
        print("in close progress view")
        showLoadingBox = false
    }
}
