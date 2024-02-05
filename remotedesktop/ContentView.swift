//
//  ContentView.swift
//  remotedesktop
//
//  Created by Kendall, Richard on 26/1/2024.
//

import SwiftUI
import SwiftData
import WebKit


struct LoginWebView: UIViewRepresentable {
    let webView: WKWebView
    let remoteDesktopServerHost: String
    let navHandler: NavHandler
    
    var tokenCallback: ((HTTPCookie) -> ())!
    
    init(server: String, callback: @escaping (HTTPCookie) -> ()) {
        remoteDesktopServerHost = server
        navHandler = NavHandler(server: server)
        tokenCallback = callback

        let webConfig = WKWebViewConfiguration()
        webConfig.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        webView = WKWebView(frame: .zero, configuration: webConfig)
        webView.navigationDelegate = navHandler
    }
    
    func makeUIView(context: Context) -> WKWebView {
        webView.allowsBackForwardNavigationGestures = false
        navHandler.authTokenCallback = authToken
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let url = URL(string: "https://\(remoteDesktopServerHost)/workstation-0.0.1/clientconfig")!
        webView.load(URLRequest(url: url))
    }
    
    func authToken(token: HTTPCookie) {
        print("got token back from nav handler of \(token.value)")
        tokenCallback(token)
    }
    
    class NavHandler: NSObject, WKNavigationDelegate {
        let remoteDesktopServerHost: String
        var authTokenCallback: ((HTTPCookie) -> ())!
        
        init(server: String) {
            remoteDesktopServerHost = server
        }
        
        func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
            if let url = webView.url {
                print("redirect to url = \(url.absoluteString)")
                if url.host() == remoteDesktopServerHost {
                    if url.path() == "/workstation-0.0.1/clientconfig" {
                        // this is a redirect back to the clientconfig API, so login is done
                        // we need to get the auth cookie out
                        print("redirect back to clientconfig API")
                                                
                        // get token if present
                        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                            for cookie in cookies {
                                print("cookie: \(cookie.name) = \(cookie.value)")
                                if cookie.name == "mod_auth_openidc_session" {
                                    print("callback auth cookie")
                                    if self.authTokenCallback != nil {
                                        // we trigger the callback if we got the token we wanted
                                        self.authTokenCallback(cookie)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            print("nav to \(navigationAction.request.url?.absoluteString ?? "no url")")
            
            // we are not doing anything here yet

            decisionHandler(.allow)
        }
    }
}

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

struct LoginView: View {
    @Environment(\.dismiss) var dismiss
    let message: String
    
    let configObject: ConfigModel
    let serverName: String
    
    var body: some View {
        VStack {
            LoginWebView(server: serverName, callback: gotAuthToken)
        }
        .padding()
        .interactiveDismissDisabled()
    }
    
    func gotAuthToken(token: HTTPCookie) {
        print("LoginView: in gotAuthToken")
        configObject.authToken = token
        configObject.refresh()
    }
}

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
