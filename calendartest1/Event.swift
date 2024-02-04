//
//  Event.swift
//  calendartest1
//
//  Created by KK on 2024/01/21.
//

import Foundation

// Event.swift
struct Event: Identifiable {
    let id = UUID()
    var title: String
    var date: Date
}
