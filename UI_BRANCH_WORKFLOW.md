# UI Development Branch Workflow

## ✅ Setup Complete!

Your project is now on GitHub with proper version control:

- **Main branch**: https://github.com/sebmendo1/MeetMemento/tree/main
- **UI branch**: https://github.com/sebmendo1/MeetMemento/tree/ui-development

**Current branch**: `ui-development` (you're ready for UI work!)

---

## 🎨 Daily UI Development Workflow

### Starting UI Work

```bash
# Make sure you're on the UI branch
git checkout ui-development

# Pull latest changes (if working across devices)
git pull origin ui-development

# Open Xcode with UIPlayground scheme
open MeetMemento.xcodeproj
# Then select "UIPlayground" from the scheme selector
```

### Making UI Changes

```bash
# 1. Edit your components in UIPlayground/
#    - Components will preview in 1-3 seconds ⚡️
#    - No backend dependencies loaded

# 2. Save and test in Canvas

# 3. Commit your UI work
git add UIPlayground/Showcases/NewComponent.swift
git commit -m "Add NewComponent with interactive states"

# 4. Push to GitHub
git push origin ui-development
```

### Merging UI Work Back to Main

When your UI components are ready:

```bash
# 1. Switch to main
git checkout main

# 2. Pull latest main changes
git pull origin main

# 3. Merge UI work
git merge ui-development

# 4. Test that everything works with backend
# Build and run the main MeetMemento scheme

# 5. Push to main
git push origin main

# 6. Switch back to UI work
git checkout ui-development
```

---

## 🔄 Branch Strategy

### `main` branch
**Purpose**: Production-ready code with full authentication and backend

**Use for**:
- Backend development
- Authentication work
- Database integration
- API connections
- Full app testing

**Build time**: 25-35 seconds
**Preview time**: 15-25 seconds

### `ui-development` branch
**Purpose**: Fast UI iteration with UIPlayground

**Use for**:
- Designing components
- Testing animations
- Building layouts
- Styling views
- Preview optimization

**Build time**: 3-5 seconds ⚡️
**Preview time**: 1-3 seconds ⚡️

---

## 🚀 Quick Commands Reference

```bash
# Switch to UI work
git checkout ui-development

# Switch to backend work
git checkout main

# See which branch you're on
git branch

# See status
git status

# Commit UI changes
git add UIPlayground/
git commit -m "Your message"
git push origin ui-development

# Update from GitHub
git pull origin ui-development

# See recent commits
git log --oneline -10
```

---

## 📊 Performance Benefits

| Task | Main Branch | UI Branch + UIPlayground |
|------|-------------|-------------------------|
| Initial build | 30-35s | 3-5s |
| Preview load | 20-30s | 1-3s |
| Hot reload | 8-12s | 0.5-1s |
| **Total speedup** | Baseline | **15-30x faster** 🚀 |

---

## 💡 Best Practices

### DO ✅
- Use `ui-development` for all UI/design work
- Commit frequently (small, focused changes)
- Use descriptive commit messages
- Test components in UIPlayground before merging
- Keep UIPlayground lightweight (no Services/ViewModels)

### DON'T ❌
- Don't add backend code to UIPlayground
- Don't merge untested UI work directly to main
- Don't work on authentication in ui-development branch
- Don't forget to switch branches!

---

## 🎯 Current Project Structure

```
MeetMemento/
├── MeetMemento/ (Main app)
│   ├── Components/ ← Design here, use in both branches
│   ├── Services/ ← Backend only (not in UIPlayground)
│   ├── ViewModels/ ← Backend only
│   ├── Views/ ← Full views with data
│   └── Resources/ (Theme, Typography)
│
└── UIPlayground/ (UI development)
    ├── ComponentGallery.swift
    ├── FastPreviewHelpers.swift
    └── Showcases/
        ├── ButtonShowcase.swift
        ├── JournalCardShowcase.swift
        ├── InsightCardShowcase.swift
        └── ...
```

---

## 🔗 Quick Links

- **Repository**: https://github.com/sebmendo1/MeetMemento
- **Main branch**: https://github.com/sebmendo1/MeetMemento/tree/main
- **UI branch**: https://github.com/sebmendo1/MeetMemento/tree/ui-development

---

## 🎉 You're Ready!

Start designing with instant previews:

```bash
# You're already on ui-development branch!
open MeetMemento.xcodeproj

# Select "UIPlayground" scheme
# Open any Showcase file
# Enable Canvas (⌥⌘↩)
# See changes in 1-2 seconds! ⚡️
```

Happy UI development! 🎨✨

