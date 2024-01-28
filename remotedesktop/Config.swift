//
//  Config.swift
//  remotedesktop
//
//  Created by Kendall, Richard on 27/1/2024.
//

struct Host: Decodable, Identifiable {
    var `protocol`: String
    var host: String
    var port: String
    var hostName: String
    
    var id: String {
        host + port + hostName
    }
}

struct Config: Decodable {
    var mode: String
    var availableHosts: [Host]
}
