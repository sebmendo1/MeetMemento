//
//  InsightViewModel.swift
//  MeetMemento
//

import Foundation
import SwiftUI

@MainActor
class InsightViewModel: ObservableObject {
    @Published var insights: [Insight] = []
    
    // Add your insights management logic here
}

