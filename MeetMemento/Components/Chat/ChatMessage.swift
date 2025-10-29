//
//  ChatMessage.swift
//  MeetMemento
//
//  Created by Sebastian Mendo on 10/24/25.
//

import Foundation

enum MessageSender: Equatable {
    case user
    case assistant
    case system
}

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let sender: MessageSender
    let timestamp: Date
}
