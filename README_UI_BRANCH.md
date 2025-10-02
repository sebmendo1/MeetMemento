# MeetMemento - UI Development Branch

## 🎨 Purpose

This is a **lightweight UI-only branch** for rapid component development and design iteration.

**No backend. No authentication. No database. Just pure UI.** ⚡️

---

## 📦 What's Included

### ✅ UI Components
```
MeetMemento/Components/
├── Buttons/
│   ├── PrimaryButton.swift
│   ├── IconButton.swift
│   ├── SocialButton.swift
│   ├── GoogleSignInButton.swift
│   └── AppleSignInButton.swift
├── Cards/
│   ├── JournalCard.swift
│   └── InsightCard.swift
├── Inputs/
│   └── AppTextField.swift
└── Navigation/
    ├── TabSwitcher.swift
    ├── TopTabNav.swift
    └── TabPill.swift
```

### ✅ Design System
```
MeetMemento/Resources/
├── Theme.swift (Light/Dark mode colors)
├── Theme+Optimized.swift (Fast preview colors)
├── Typography.swift (Font system)
├── Constants.swift (App constants)
└── Strings.swift (Localized strings)
```

### ✅ Extensions
```
MeetMemento/Extensions/
├── Color+Theme.swift (Color utilities)
└── Date+Format.swift (Date formatting)
```

### ✅ UIPlayground (Fast Development Environment)
```
UIPlayground/
├── UIPlaygroundApp.swift (Entry point)
├── ComponentGallery.swift (Component browser)
├── FastPreviewHelpers.swift (Preview utilities)
└── Showcases/
    ├── ButtonShowcase.swift
    ├── SocialButtonShowcase.swift
    ├── JournalCardShowcase.swift
    ├── InsightCardShowcase.swift
    ├── TabSwitcherShowcase.swift
    ├── TopNavShowcase.swift
    └── TextFieldShowcase.swift
```

### ✅ Documentation
- `PREVIEW_OPTIMIZATION_GUIDE.md` - Preview performance tips
- `OPTIMIZATION_SUMMARY.md` - What's been optimized
- `PREVIEW_FIXES_APPLIED.md` - Applied fixes
- `UIPLAYGROUND_SETUP.md` - UIPlayground setup guide

---

## ❌ What's NOT Included (Kept on `main` only)

- ❌ Authentication (Services/Auth/)
- ❌ Database (Services/SupabaseService)
- ❌ ViewModels (AuthViewModel, EntryViewModel, etc.)
- ❌ Backend Views (WelcomeView, SignInView, etc.)
- ❌ Models (User, Entry, Insight)
- ❌ Utilities (Logger, MockData)
- ❌ Tests
- ❌ Apple Sign-in extension

**Result**: This branch builds in **3-5 seconds** vs 30+ on main! 🚀

---

## 🚀 Quick Start

### 1. Switch to UI Branch
```bash
git checkout ui-development
```

### 2. Open Xcode
```bash
open MeetMemento.xcodeproj
```

### 3. Select UIPlayground Scheme
In Xcode toolbar, change scheme from "MeetMemento" to **"UIPlayground"**

### 4. Build (3-5 seconds!)
Press **⌘B**

### 5. Open Canvas
- Open any file in `UIPlayground/Showcases/`
- Press **⌥⌘↩** to open Canvas
- See changes in **1-2 seconds**! ⚡️

---

## 🎯 Workflow

### Creating a New Component

1. **Create component**:
   ```
   MeetMemento/Components/Cards/MyNewCard.swift
   ```

2. **Add preview**:
   ```swift
   #Preview("Light") {
       MyNewCard()
           .useTheme()
           .previewLayout(.sizeThatFits)
   }
   ```

3. **Create showcase** (optional):
   ```
   UIPlayground/Showcases/MyNewCardShowcase.swift
   ```

4. **Add to gallery**:
   Update `ComponentGallery.swift` to include link

### Committing Changes

```bash
# Stage UI files
git add MeetMemento/Components/
git add UIPlayground/Showcases/

# Commit
git commit -m "Add NewCard component with interactive states"

# Push to GitHub
git push origin ui-development
```

### Merging to Main

When components are ready for integration:

```bash
# Switch to main
git checkout main

# Merge UI work
git merge ui-development

# Resolve any conflicts
# Test with backend
# Push to main
git push origin main

# Switch back to UI work
git checkout ui-development
```

---

## ⚡️ Performance

| Metric | Main Branch | UI Branch |
|--------|-------------|-----------|
| Build time | 30-45s | **3-5s** |
| Preview load | 20-30s | **1-3s** |
| Hot reload | 8-12s | **0.5-1s** |
| **Speedup** | Baseline | **10-30x faster** 🚀 |

---

## 📚 Documentation

All optimization guides are in the root:
- `PREVIEW_OPTIMIZATION_GUIDE.md` - Complete guide
- `OPTIMIZATION_SUMMARY.md` - Quick reference
- `UIPLAYGROUND_SETUP.md` - Setup instructions

---

## 🔄 Syncing with Main

To get new components from main:

```bash
# On ui-development branch
git fetch origin main
git merge origin/main

# Resolve conflicts if any
# Keep only UI-related files
```

---

## 🎨 What You Can Do Here

✅ Design new components
✅ Test animations
✅ Iterate on layouts
✅ Adjust colors and spacing
✅ Build showcases
✅ Perfect interactions
✅ Get instant visual feedback

❌ Don't add backend code
❌ Don't import Services
❌ Don't add authentication
❌ Don't connect to database

---

## 🚀 Get Started

```bash
git checkout ui-development
open MeetMemento.xcodeproj
# Select UIPlayground scheme
# Open ComponentGallery.swift
# Press ⌘R to run
```

**Start designing at lightning speed!** ⚡️🎨

---

## 📞 Need Backend?

Switch to main branch:

```bash
git checkout main
# Full app with auth, database, etc.
```

---

**Happy UI development!** 🎉

