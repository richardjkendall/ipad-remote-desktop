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
    let logger = Logger()
    
    @Published private(set) var config: Config?
    @Published var gotConfig = false
    @Published var needLogin = false
    
    var authToken = HTTPCookie()
    @Published var serverHostName = ""
    
    let AUTH_COOKIE_NAME = "mod_auth_openidc_session"
    
    init() {
        /*self.gotConfig = false
        self.serverHostName = server
         
        // need to get the auth token which is saved in the keychain if there is one
        let gotCookie = GetAuthCookie()
        if gotCookie {
        // we should try to load the data as we have a cookie
            refresh()
        }*/
        
    }
    
    func setServer(server: String) {
        print("setting server to \(server)")
        self.serverHostName = server
    }
    
    func initialLoad() {
        // need to get the auth token which is saved in the keychain if there is one
        let gotCookie = GetAuthCookie()
        if gotCookie {
            // we should try to load the data as we have a cookie
            refresh()
        }
    }
    
    func refresh() {
        print("ConfigModel call to refresh")
        Task.init {
            await fetchData()
        }
    }
    
    private func GetAuthCookie() -> Bool {
        do {
            print("trying to get token")
            let authTokenFromKeychain = try KeychainHelper.shared.getToken(identifier: "cookie-token")
            print("got token, value \(authTokenFromKeychain)")
            authToken = HTTPCookie(properties: [
                .domain: "dummy.local",
                .path: "/",
                .name: AUTH_COOKIE_NAME,
                .value: authTokenFromKeychain
            ])!
            print("created the httpcookie from the saved token")
            return true
        } catch {
            print("no saved auth token in keychain")
            return false
        }
    }
    
    private func SaveAuthCookie() {
        let authTokenVal = authToken.value
        do {
            try KeychainHelper.shared.upsertToken(Data(authTokenVal.utf8), identifier: "cookie-token")
            print("Saved token in keychain")
            logger.info("Saved token in keychain")
        } catch {
            print("Error saving token \(error)")
            logger.error("Error saving token \(error)")
        }
    }
    
    func fetchData() async {
        do {
            print("fetch data running for host \(serverHostName)")
            guard let url = URL(string: "https://\(serverHostName)/workstation-0.0.1/clientconfig") else { fatalError("Missing URL") }
            
            let urlSessionDelegate = SessionDelegate()
            let urlSession = URLSession(configuration: .default, delegate: urlSessionDelegate, delegateQueue: nil)
            
            var urlRequest = URLRequest(url: url)
            urlRequest.setValue("\(AUTH_COOKIE_NAME)=\(authToken.value)", forHTTPHeaderField: "Cookie")
            
            let (data, response) = try await urlSession.data(for: urlRequest)
            
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                print("did not get a 200 back from API")
                self.gotConfig = false
                self.needLogin = true
                return
            }
            
            let decoder = JSONDecoder()
            let decodedData = try decoder.decode(Config.self, from: data)
            
            self.SaveAuthCookie()
            
            DispatchQueue.main.async {
                self.config = decodedData
                self.gotConfig = true
            }
            
        } catch {
            print("Error getting data \(error)")
        }
    }
    
    class SessionDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
        func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
            // Stops the redirection, and returns (internally) the response body.
            completionHandler(nil)
        }
    }
}
