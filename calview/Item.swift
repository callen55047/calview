//
//  Item.swift
//  calview
//
//  Created by Callen Egan on 2026-06-19.
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
