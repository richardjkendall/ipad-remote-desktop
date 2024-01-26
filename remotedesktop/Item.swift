//
//  Item.swift
//  remotedesktop
//
//  Created by Kendall, Richard on 26/1/2024.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
