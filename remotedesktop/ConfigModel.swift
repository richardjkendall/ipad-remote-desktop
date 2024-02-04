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
    @Published var gotConfig: Bool
    
    var authToken = HTTPCookie()
    var serverHostName = ""
    
    let AUTH_COOKIE_NAME = "mod_auth_openidc_session"
    
    init(server: String) {
        self.serverHostName = server
        self.gotConfig = false
        
        // need to get the auth token which is saved in the keychain if there is one
        let gotCookie = GetAuthCookie()
        
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
            print("got token")
            print("token value \(authTokenFromKeychain.utf8)")
            /*authToken = HTTPCookie(properties: [
                .domain: "dummy.local",
                .path: "/",
                .name: AUTH_COOKIE_NAME,
                .value: authTokenFromKeychain.utf8
            ])!*/
            print("got saved auth token from keychain")
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
            guard let url = URL(string: "https://\(serverHostName)/workstation-0.0.1/clientconfig") else { fatalError("Missing URL") }
            
            var urlRequest = URLRequest(url: url)
            urlRequest.setValue("\(AUTH_COOKIE_NAME)=\(authToken.value)", forHTTPHeaderField: "Cookie")
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { fatalError("Error while fetching data") }
            
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
}
