//
//  AddEntryView.swift
//  MeetMemento
//

import SwiftUI

struct AddEntryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var entryText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Add your entry creation UI here
            }
            .navigationTitle("New Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Add save logic
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AddEntryView()
}

