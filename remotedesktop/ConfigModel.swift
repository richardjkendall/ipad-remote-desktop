//
//  ConfigModel.swift
//  remotedesktop
//
//  Created by Kendall, Richard on 27/1/2024.
//

import Foundation
import WebKit
import OSLog

class ConfigModel: ObservableObject {
    enum ConfigModelError: LocalizedError {
        case hostNotFound
    }
    
    @Published private(set) var config: Config?
    @Published var gotConfig = false
    @Published var needLogin = false
    @Published var gotError = false
    @Published var needNewServer = false
    
    var authToken = HTTPCookie()
    @Published var serverHostName = ""
    
    static let AUTH_COOKIE_NAME = "mod_auth_openidc_session"
    static let APP_PATH = "workstation-0.0.1"
    
    init() {
        
    }
    
    func getHostByName(h: String) throws -> Host? {
        print("getting host details for \(h)")
        if let c = config {
            for host in c.availableHosts {
                if host.hostName == h {
                    return host
                }
            }
        }
        throw ConfigModelError.hostNotFound
    }
    
    func setServer(server: String) {
        Logger.configModel.info("Setting remote app server to \(server)")
        self.needNewServer = false
        self.serverHostName = server
    }
    
    func setNewServerNeeded() {
        self.needNewServer = true
    }
    
    func reset() {
        config = nil
        gotConfig = false
        needLogin = false
        gotError = false
    }
    
    func initialLoad() {
        // need to get the auth token which is saved in the keychain if there is one
        let gotCookie = GetAuthCookie()
        if gotCookie {
            // we should try to load the data as we have a cookie
            refresh()
        } else {
            // set need login so we can get
            needLogin = true
        }
    }
    
    func refresh() {
        Logger.configModel.info("ConfigModel call to refresh")
        Task.init {
            await fetchData()
        }
    }
    
    private func GetAuthCookie() -> Bool {
        do {
            Logger.configModel.info("Trying to get token from keychain")
            let authTokenFromKeychain = try KeychainHelper.shared.getToken(identifier: "cookie-token_\(serverHostName)")
            Logger.configModel.info("Got token from keychain")
            authToken = HTTPCookie(properties: [
                .domain: "dummy.local",
                .path: "/",
                .name: ConfigModel.AUTH_COOKIE_NAME,
                .value: authTokenFromKeychain
            ])!
            Logger.configModel.info("Created the httpcookie from the saved token")
            return true
        } catch {
            Logger.configModel.info("No saved auth token in keychain")
            return false
        }
    }
    
    private func SaveAuthCookie() {
        let authTokenVal = authToken.value
        do {
            try KeychainHelper.shared.upsertToken(Data(authTokenVal.utf8), identifier: "cookie-token_\(serverHostName)")
            Logger.configModel.info("Saved token in keychain")
        } catch {
            print("Error saving token \(error)")
            Logger.configModel.error("Error saving token \(error)")
        }
    }
    
    func fetchData() async {
        do {
            Logger.configModel.info("Calling client config api data running for server \(self.serverHostName)")
            guard let url = URL(string: "https://\(serverHostName)/\(ConfigModel.APP_PATH)/clientconfig") else { fatalError("Missing URL") }
            
            let urlSessionDelegate = SessionDelegate()
            let urlSession = URLSession(configuration: .default, delegate: urlSessionDelegate, delegateQueue: nil)
            
            var urlRequest = URLRequest(url: url)
            urlRequest.setValue("\(ConfigModel.AUTH_COOKIE_NAME)=\(authToken.value)", forHTTPHeaderField: "Cookie")
            
            let (data, response) = try await urlSession.data(for: urlRequest)
            
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                Logger.configModel.info("Clientconfig API did not respond with a 200")
                
                if (response as? HTTPURLResponse)?.statusCode == 302 {
                    Logger.configModel.info("Got a 302 which means token has expired, so we need to login")
                    
                    DispatchQueue.main.async {
                        self.gotConfig = false
                        self.gotError = false
                        self.needLogin = true
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self.gotConfig = false
                    self.gotError = true
                    self.needLogin = false
                }
                return
            }
            
            let decoder = JSONDecoder()
            let decodedData = try decoder.decode(Config.self, from: data)
            
            self.SaveAuthCookie()
            
            DispatchQueue.main.async {
                self.config = decodedData
                self.gotConfig = true
                self.needLogin = false
                self.gotError = false
            }
            
        } catch {
            Logger.configModel.error("Error getting data from clientconfig API \(error)")
        }
    }
    
    class SessionDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
        func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
            // Stops the redirection, and returns (internally) the response body.
            completionHandler(nil)
        }
    }
}
