//
//  ContentView.swift
//  remotedesktop
//
//  Created by Kendall, Richard on 26/1/2024.
//

import SwiftUI
import SwiftData
import WebKit

struct GuacViewer: UIViewRepresentable {
    let webView: WKWebView
    let hostName: String
    
    init(host: String) {
        print("Loading webview for \(host)")
        
        hostName = host
        
        let webConfig = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        
        let userScript = """
        var app_host_name = "\(hostName)";
        """
        let wkUserScript = WKUserScript(source: userScript, injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: false)
        userContentController.addUserScript(wkUserScript)
        webConfig.userContentController = userContentController
        
        webView = WKWebView(frame: .zero, configuration: webConfig)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        webView.allowsBackForwardNavigationGestures = false
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = Bundle.main.url(forResource: "viewer", withExtension: "html") {
            print("inside updateUIView for \(hostName)")
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            print("HTML file not found")
        }
    }
    
    
    
}

struct ContentView: View {
    @StateObject var configModel = ConfigModel()

    var body: some View {
        NavigationSplitView {
            List {
                if let config = configModel.config {
                    ForEach(config.availableHosts) { item in
                        NavigationLink {
                            GuacViewer(host: item.hostName)
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: refreshHosts) {
                        Label("Refresh Host List", systemImage: "arrow.clockwise.circle")
                    }
                }
            }
        } detail: {
            Text("Select an item")
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
        .modelContainer(for: Item.self, inMemory: true)
}
