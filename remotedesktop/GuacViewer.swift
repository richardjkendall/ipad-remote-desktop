//
//  GuacViewer.swift
//  remotedesktop
//
//  Created by Kendall, Richard on 6/2/2024.
//

import SwiftUI
import SwiftData
import WebKit

struct GuacViewer: UIViewRepresentable {
    let webView: WKWebView
    let hostName: String
    let serverName: String
    
    let configObject: ConfigModel
    
    let messageHandler = MessageHandler()
    
    init(host: String, server: String, config: ConfigModel) {
        print("Loading webview for \(host)")
        
        hostName = host
        serverName = server
        configObject = config
        
        let webConfig = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        
        let userScript = """
        var app_host_name = "\(hostName)";
        var app_server_name = "\(serverName)";
        """
        let wkUserScript = WKUserScript(source: userScript, injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: false)
        userContentController.addUserScript(wkUserScript)
        webConfig.userContentController = userContentController
        webConfig.userContentController.add(messageHandler, name: "console")
        
        let authCookie = HTTPCookie(properties: [
            .domain: serverName,
            .path: "/",
            .name: "mod_auth_openidc_session",
            .value: configObject.authToken.value
        ])!
        webConfig.websiteDataStore.httpCookieStore.setCookie(authCookie)
        
        webView = WKWebView(frame: .zero, configuration: webConfig)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        webView.allowsBackForwardNavigationGestures = false
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = Bundle.main.url(forResource: "viewer", withExtension: "html") {
            print("inside updateUIView for \(hostName)")
            print("file \(url) path \(url.deletingLastPathComponent())")
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            print("HTML file not found")
        }
    }
    
    class MessageHandler: NSObject, WKScriptMessageHandler {
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "console" {
                print("js console: \(message.body)")
            }
        }
    }
    
}
