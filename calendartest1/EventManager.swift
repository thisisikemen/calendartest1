//
//  EventManager.swift
//  calendartest1
//
//  Created by KK on 2024/01/21.
//

import Foundation

// EventManager.swift
class EventManager: ObservableObject {
    @Published var events: [Event] = []
}
