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
    var closeProgressBox: () -> Void
            
    init(host: String, server: String, config: ConfigModel, closeProgressBoxCallback: @escaping () -> Void, handleStateUpdate: @escaping (String) -> Void) {
        Logger.guacViewer.info("Loading webview for remote host \(host)")
        
        hostName = host
        serverName = server
        configObject = config
        closeProgressBox = closeProgressBoxCallback
        
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
        
        let messageHandler = MessageHandler() {
            (state) -> () in
                print("got state from messageHandler \(state)")
                handleStateUpdate(state)
                if state == "S3" {
                    closeProgressBoxCallback()
                }
        }
        
        webConfig.userContentController.add(messageHandler, name: "console")
        webConfig.userContentController.add(messageHandler, name: "connState")
        
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
        
        if let url = Bundle.main.url(forResource: "viewer", withExtension: "html") {
            Logger.guacViewer.info("Loading HTML file \(url)")
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            Logger.guacViewer.warning("HTML file not found")
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {

    }
    
    class MessageHandler: NSObject, WKScriptMessageHandler {
        var handleStateChange: (String) -> Void
        
        init(handleStateChangeCallback: @escaping (String) -> Void) {
            handleStateChange = handleStateChangeCallback
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "console" {
                print("JS console: \(message.body)")
            }
            if message.name == "connState" {
                print("Got updated state value from guacviewer: \(message.body)")
                handleStateChange(message.body as! String)
            }
        }
    }
    
}
