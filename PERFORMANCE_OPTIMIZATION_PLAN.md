# 🚀 Performance Optimization Plan

## Issues Identified

### 1. **Blocking Auth Check on Launch** ⚠️
**Problem:**
```swift
init() {
    Task {
        await checkAuthState()  // Blocks UI
    }
}
```
- `AuthViewModel.init()` makes async network call
- UI appears frozen until Supabase responds
- Could timeout or delay 3-5 seconds

**Solution:**
- Set default non-loading state immediately
- Defer auth check until after UI renders
- Add timeout to prevent infinite waiting

### 2. **Synchronous Auth Observer Setup** ⚠️
**Problem:**
```swift
AuthService.shared.observeAuthChanges { ... }
```
- May block during initialization
- Sets up listeners before UI is ready

**Solution:**
- Defer observer setup
- Use `Task.detached` for background work

### 3. **Potential Supabase Timeout** ⚠️
**Problem:**
```swift
try await client.auth.session.user
```
- No timeout configured
- Could hang indefinitely
- No retry logic

**Solution:**
- Add 5-second timeout
- Fail gracefully
- Show UI immediately, auth check in background

## Implementation

### Fix 1: Optimize AuthViewModel

**Before:**
```swift
init() {
    Task {
        await checkAuthState()  // BLOCKING
    }
    AuthService.shared.observeAuthChanges { ... }
}
```

**After:**
```swift
init() {
    // Start with optimistic state
    isLoading = false  // UI shows immediately
    
    // Check auth in background (non-blocking)
    Task.detached(priority: .background) { [weak self] in
        await self?.checkAuthState()
    }
    
    // Defer observer setup
    Task {
        AuthService.shared.observeAuthChanges { ... }
    }
}
```

### Fix 2: Add Timeout to Auth Check

**Before:**
```swift
currentUser = try await SupabaseService.shared.getCurrentUser()
```

**After:**
```swift
currentUser = try await withTimeout(seconds: 5) {
    try await SupabaseService.shared.getCurrentUser()
}
```

### Fix 3: Optimize EntryViewModel

- Remove mock data from init
- Lazy load on first access
- Background thread for data processing

### Fix 4: Lazy Load Heavy Components

- Theme/Typography computed on demand
- Defer view model creation
- Use `@StateObject` only when needed

## Priority

1. **High**: AuthViewModel optimization (biggest impact)
2. **Medium**: Timeout handling
3. **Low**: EntryViewModel optimization (already fast)

