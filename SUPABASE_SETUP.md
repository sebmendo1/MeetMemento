# Supabase Setup Guide

## ✅ Installation Complete

The Supabase Swift SDK (v2.5.1+) has been successfully installed and configured in your project!

## 📦 What Was Installed

- **Package**: `supabase-swift` from GitHub
- **Version**: 2.5.1 or later
- **Product**: Supabase (includes Auth, Database, Storage, Realtime, Functions)

## 🔧 Configuration Steps

### 1. Get Your Supabase Credentials

1. Go to your Supabase project dashboard: https://app.supabase.com
2. Navigate to **Settings** → **API**
3. Copy your:
   - **Project URL** (e.g., `https://xxxxx.supabase.co`)
   - **Anon/Public Key** (the `anon` `public` key)

### 2. Update Configuration File

Open `MeetMemento/Resources/SupabaseConfig.swift` and replace the placeholder values:

```swift
struct SupabaseConfig {
    static let url = "https://your-project.supabase.co"  // ← Your Project URL
    static let anonKey = "your-anon-key-here"            // ← Your Anon Key
}
```

⚠️ **Security Note**: For production apps, consider using:
- Environment variables
- Secure key storage (Keychain)
- A `.gitignore`d configuration file

### 3. Test the Connection

The `SupabaseService` is already set up as a singleton. You can test it like this:

```swift
import SwiftUI

struct TestSupabaseView: View {
    @State private var message = "Testing..."
    
    var body: some View {
        VStack {
            Text(message)
            Button("Test Supabase") {
                testSupabase()
            }
        }
    }
    
    func testSupabase() {
        Task {
            do {
                // Try to get current user (will fail if not logged in, but tests connection)
                let user = try await SupabaseService.shared.getCurrentUser()
                message = user == nil ? "Connected! (No user logged in)" : "Connected and authenticated!"
            } catch {
                message = "Error: \(error.localizedDescription)"
            }
        }
    }
}
```

## 📚 Available Methods

The `SupabaseService` includes:

### Authentication
- `signIn(email:password:)` - Sign in existing user
- `signUp(email:password:)` - Create new user
- `signOut()` - Sign out current user
- `getCurrentUser()` - Get current authenticated user

### Database & Storage
- Add your custom methods in the marked sections

## 🔍 Verify Installation

To verify that Supabase is properly installed, you should be able to:

1. Build the project without errors ✅
2. Import Supabase in any Swift file:
   ```swift
   import Supabase
   ```
3. See initialization logs in the console when the app launches

## 📖 Documentation

- [Supabase Swift Docs](https://supabase.com/docs/reference/swift)
- [Supabase Auth](https://supabase.com/docs/guides/auth)
- [Supabase Database](https://supabase.com/docs/guides/database)

## 🐛 Troubleshooting

### Build Errors
If you see build errors:
1. Clean build folder: **Product** → **Clean Build Folder** (Cmd+Shift+K)
2. Close and reopen Xcode
3. Verify Package: **File** → **Packages** → **Resolve Package Versions**

### Import Not Working
If `import Supabase` shows an error:
1. Check that the package is listed in **File** → **Packages**
2. Verify target membership in project settings
3. Try resolving packages again

### Runtime Errors
Check the console for the initialization log:
- ✅ `"✅ Supabase client initialized"` - Success!
- ⚠️ `"⚠️ Supabase not configured"` - Update SupabaseConfig.swift

---

**Next Steps**: Update your `SupabaseConfig.swift` with real credentials and start building! 🚀

