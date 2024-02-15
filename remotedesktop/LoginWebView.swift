//
//  LoginWebView.swift
//  remotedesktop
//
//  Created by Kendall, Richard on 6/2/2024.
//

import SwiftUI
import SwiftData
import WebKit
import OSLog

struct LoginWebView: UIViewRepresentable {
    var remoteDesktopServerHost: Binding<String>
    var webView: WKWebView
    var navHandler: NavHandler
    var tokenCallback: ((HTTPCookie) -> ())!
    
    init(server: Binding<String>, callback: @escaping (HTTPCookie) -> ()) {
        remoteDesktopServerHost = server
        navHandler = NavHandler(server: server.wrappedValue)
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
        //print("in loginwebview updateUIView... server val \(remoteDesktopServerHost.wrappedValue)")
        let url = URL(string: "https://\(remoteDesktopServerHost.wrappedValue)/\(ConfigModel.APP_PATH)/clientconfig")!
        //print("new url is \(url)")
        navHandler.updateServerName(remoteDesktopServerHost.wrappedValue)
        uiView.navigationDelegate = navHandler
        uiView.load(URLRequest(url: url))
    }
    
    func authToken(token: HTTPCookie) {
        Logger.loginWebView.info("Got auth token back from NavHandler")
        tokenCallback(token)
    }
    
    class NavHandler: NSObject, WKNavigationDelegate {
        var remoteDesktopServerHost: String
        var authTokenCallback: ((HTTPCookie) -> ())!
        
        init(server: String) {
            remoteDesktopServerHost = server
        }
        
        func updateServerName(_ server: String) {
            print("setting updated server value in nav handler to = \(server)")
            remoteDesktopServerHost = server
        }
        
        func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
            if let url = webView.url {
                Logger.loginWebView.info("NavHandler: redirect to URL = \(url.absoluteString)")
                //print("NavHandler: redirect to URL = \(url.absoluteString)")
                //print("looking for server = \(remoteDesktopServerHost)")
                if url.host() == remoteDesktopServerHost {
                    if url.path() == "/\(ConfigModel.APP_PATH)/clientconfig" {
                        // this is a redirect back to the clientconfig API, so login is done
                        // we need to get the auth cookie out
                        Logger.loginWebView.info("NavHandler: redirecting back to clientconfig API")
                                                
                        // get token if present
                        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                            for cookie in cookies {
                                Logger.loginWebView.debug("NavHandler: got cookie \(cookie.name) = \(cookie.value)")
                                if cookie.name == ConfigModel.AUTH_COOKIE_NAME {
                                    Logger.loginWebView.info("NavHandler: calling back for auth cookie")
                                    if self.authTokenCallback != nil {
                                        // we trigger the callback if we got the token we wanted
                                        //print("sending auth token callback")
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
            Logger.loginWebView.info("NavHandler: navigating to \(navigationAction.request.url?.absoluteString ?? "no url")")
            // we are not doing anything here yet
            decisionHandler(.allow)
        }
    }
}
