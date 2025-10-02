//
//  EntryViewModel.swift
//  MeetMemento
//

import Foundation
import SwiftUI

@MainActor
class EntryViewModel: ObservableObject {
    @Published var entries: [Entry] = []
    
    // Add your entry management logic here
}

