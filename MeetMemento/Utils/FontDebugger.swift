//
//  FontDebugger.swift
//  MeetMemento
//
//  Utility to debug and identify available fonts in the app.
//  Use this to verify font installation and get correct PostScript names.
//

import SwiftUI
import UIKit

struct FontDebugger {
    /// Prints all available font families and their fonts to console
    static func printAllFonts() {
        print("🔍 Available Font Families:")
        print("=" * 50)
        
        for family in UIFont.familyNames.sorted() {
            print("\n📁 Family: \(family)")
            let fonts = UIFont.fontNames(forFamilyName: family)
            for font in fonts {
                print("  📝 Font: \(font)")
            }
        }
        
        print("\n" + "=" * 50)
        print("✅ Font debugging complete")
    }
    
    /// Checks if specific fonts are available
    static func checkFontAvailability() {
        let requiredFonts = [
            "Recoleta-Black",
            "RecoletaAlt-SemiBold",
            "Manrope-Regular",
            "Manrope-Medium",
            "Manrope-Bold"
        ]
        
        print("🔍 Checking required fonts:")
        print("=" * 30)
        
        for fontName in requiredFonts {
            let isAvailable = UIFont(name: fontName, size: 16) != nil
            let status = isAvailable ? "✅" : "❌"
            print("\(status) \(fontName)")
        }
        
        print("=" * 30)
    }
    
    /// Creates a preview view showing all fonts
    static func createFontPreviewView() -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                Text("Available Fonts")
                    .font(.largeTitle)
                    .padding(.bottom)
                
                ForEach(UIFont.familyNames.sorted(), id: \.self) { family in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(family)
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        ForEach(UIFont.fontNames(forFamilyName: family), id: \.self) { fontName in
                            Text("Sample text in \(fontName)")
                                .font(.custom(fontName, size: 16))
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
        .onAppear {
            printAllFonts()
            checkFontAvailability()
        }
    }
}

// MARK: - String Extension for Easy Repetition
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

// MARK: - Preview
#Preview("Font Debugger") {
    FontDebugger.createFontPreviewView()
}
