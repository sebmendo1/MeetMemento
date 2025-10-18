//
//  PreferencesService.swift
//  MeetMemento
//
//  Service for managing user preferences in UserDefaults
//

import Foundation

public enum AppThemePreference: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var displayName: String {
        return self.rawValue
    }
}

public class PreferencesService {
    public static let shared = PreferencesService()

    private let defaults = UserDefaults.standard

    // Keys
    private enum Keys {
        static let themePreference = "app_theme_preference"
    }

    private init() {}

    // MARK: - Theme Preference

    public var themePreference: AppThemePreference {
        get {
            guard let rawValue = defaults.string(forKey: Keys.themePreference),
                  let preference = AppThemePreference(rawValue: rawValue) else {
                return .system // Default to system
            }
            return preference
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.themePreference)
            NotificationCenter.default.post(name: .themePreferenceChanged, object: nil)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let themePreferenceChanged = Notification.Name("themePreferenceChanged")
}
