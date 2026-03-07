//
//  Item.swift
//  WanderLog
//
//  Created by mars on 2026/3/7.
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
