//
//  ConfigModel.swift
//  remotedesktop
//
//  Created by Kendall, Richard on 27/1/2024.
//

import Foundation

class ConfigModel: ObservableObject {
    @Published private(set) var config: Config?
    
    init() {
        Task.init {
            await fetchData()
        }
    }
    
    func refresh() {
        Task.init {
            await fetchData()
        }
    }
    
    func fetchData() async {
        do {
            guard let url = URL(string: "http://localhost:8080/workstation-0.0.1/clientconfig") else { fatalError("Missing URL") }
            
            var urlRequest = URLRequest(url: url)
            urlRequest.setValue("rjk", forHTTPHeaderField: "X-Remote-User")
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { fatalError("Error while fetching data") }
            
            let decoder = JSONDecoder()
            let decodedData = try decoder.decode(Config.self, from: data)
            
            DispatchQueue.main.async {
                self.config = decodedData
            }
            
        } catch {
            print("Error getting data \(error)")
        }
    }
}
