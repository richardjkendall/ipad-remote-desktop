//
//  GuacViewer.swift
//  remotedesktop
//
//  Created by Kendall, Richard on 6/2/2024.
//

import SwiftUI
import SwiftData
import WebKit
import OSLog

struct GuacViewer: UIViewRepresentable {
    let webView: WKWebView
    let hostName: String
    let serverName: String
    let configObject: ConfigModel
    let messageHandler = MessageHandler()
    
    @State var firstShow = 0
    
    init(host: String, server: String, config: ConfigModel) {
        Logger.guacViewer.info("Loading webview for remote host \(host)")
        
        hostName = host
        serverName = server
        configObject = config
        
        let webConfig = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        
        let userScript = """
        var app_host_name = "\(hostName)";
        var app_server_name = "\(serverName)";
        var app_path = "\(ConfigModel.APP_PATH)";
        """
        let wkUserScript = WKUserScript(source: userScript, injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: false)
        userContentController.addUserScript(wkUserScript)
        webConfig.userContentController = userContentController
        webConfig.userContentController.add(messageHandler, name: "console")
        
        let authCookie = HTTPCookie(properties: [
            .domain: serverName,
            .path: "/",
            .name: ConfigModel.AUTH_COOKIE_NAME,
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
        if firstShow == 0 {
            Logger.guacViewer.info("First appearance for host \(hostName)")
            if let url = Bundle.main.url(forResource: "viewer", withExtension: "html") {
                Logger.guacViewer.info("Loading HTML file \(url)")
                webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
                firstShow = 1
            } else {
                Logger.guacViewer.warning("HTML file not found")
            }
        } else {
            Logger.guacViewer.info("Not first appearance for \(hostName)")
        }
    }
    
    class MessageHandler: NSObject, WKScriptMessageHandler {
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "console" {
                print("JS console: \(message.body)")
            }
        }
    }
    
}
