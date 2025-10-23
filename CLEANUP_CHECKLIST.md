# Deprecated Files Cleanup Checklist

## Pre-Cleanup

- [ ] Review `CLEANUP_DEPRECATED_FILES_PROMPT.md` for full context
- [ ] Ensure working directory is clean: `git status`
- [ ] Confirm you're on the correct branch: `claude/review-memento-v1-1-011CUPGmHRj5QKMriR2sQCVw`
- [ ] Create backup branch: `git checkout -b backup/pre-cleanup-$(date +%Y%m%d)`
- [ ] Return to working branch: `git checkout claude/review-memento-v1-1-011CUPGmHRj5QKMriR2sQCVw`

## Phase 1: Analysis

### Files to Analyze (from commit 622e5c9)

#### Swift - Views
- [ ] `MeetMemento/Views/Onboarding/ThemesIdentifiedView.swift`
  - Search: `grep -r "ThemesIdentifiedView" MeetMemento/ --include="*.swift" | wc -l`
  - Status: _____
  - Decision: _____

#### Swift - Components
- [ ] `MeetMemento/Components/ThemeCardFullScreen.swift`
  - Search: `grep -r "ThemeCardFullScreen" MeetMemento/ --include="*.swift" | wc -l`
  - Status: _____
  - Decision: _____

- [ ] `MeetMemento/Components/QuestionCounterView.swift`
  - Search: `grep -r "QuestionCounterView" MeetMemento/ --include="*.swift" | wc -l`
  - Status: _____
  - Decision: _____

#### Swift - Services
- [ ] `MeetMemento/Services/ThemeAnalysisService.swift`
  - Search: `grep -r "ThemeAnalysisService" MeetMemento/ --include="*.swift" | wc -l`
  - Status: _____
  - Decision: _____

#### Swift - Models
- [ ] `MeetMemento/Models/ThemeAnalysis.swift`
  - Search: `grep -r "IdentifiedTheme\|ThemeAnalysisResponse\|ThemeAnalysisRequest" MeetMemento/ --include="*.swift" | wc -l`
  - Status: _____
  - Decision: _____

#### Edge Functions
- [ ] `supabase/functions/new-user-insights/index.ts`
  - Search: `grep -r "new-user-insights" MeetMemento/ --include="*.swift"`
  - Status: _____
  - Decision: _____

- [ ] `supabase/functions/new-user-insights/types.ts`
  - Search: (depends on index.ts)
  - Status: _____
  - Decision: _____

#### Database Migrations (REVIEW ONLY - DO NOT DELETE)
- [ ] `supabase/migrations/20250119000001_create_themes_table.sql`
  - Action: Add deprecation comment to file
  - Status: _____

- [ ] `supabase/migrations/20250119000002_add_user_profiles_themes.sql`
  - Action: Add deprecation comment to file
  - Status: _____

### Analysis Report Completed
- [ ] Phase 1 report generated
- [ ] Report reviewed and approved by team
- [ ] "SAFE TO DELETE" list confirmed (expected: 5-7 files)
- [ ] "REVIEW REQUIRED" list addressed
- [ ] "KEEP" list verified

## Phase 2: Deletion Plan

### Batch 1: UI Components (Leaf Dependencies)
- [ ] Plan created for UI components deletion
- [ ] Dependencies verified: None
- [ ] Commit message drafted: "Remove deprecated theme analysis UI components"
- [ ] Files in batch:
  - [ ] `MeetMemento/Components/ThemeCardFullScreen.swift`
  - [ ] `MeetMemento/Views/Onboarding/ThemesIdentifiedView.swift`
  - [ ] `MeetMemento/Components/QuestionCounterView.swift` (if deprecated)

### Batch 2: Business Logic (Depends on Batch 1)
- [ ] Plan created for services/models deletion
- [ ] Dependencies verified: Only used by Batch 1 files
- [ ] Commit message drafted: "Remove deprecated theme analysis services and models"
- [ ] Files in batch:
  - [ ] `MeetMemento/Services/ThemeAnalysisService.swift`
  - [ ] `MeetMemento/Models/ThemeAnalysis.swift`

### Batch 3: Backend (Depends on Batch 2)
- [ ] Plan created for edge function deletion
- [ ] Dependencies verified: Only invoked by ThemeAnalysisService
- [ ] Commit message drafted: "Remove deprecated new-user-insights edge function"
- [ ] Files in batch:
  - [ ] `supabase/functions/new-user-insights/index.ts`
  - [ ] `supabase/functions/new-user-insights/types.ts`
- [ ] Alternative considered: Archive instead of delete
- [ ] Decision documented: _____

### Deletion Plan Approved
- [ ] All batches reviewed
- [ ] Deletion order confirmed
- [ ] Commit messages approved
- [ ] Backup branch verified
- [ ] Ready to execute

## Phase 3: Execution

### Batch 1 Execution
- [ ] Delete: `git rm MeetMemento/Components/ThemeCardFullScreen.swift`
- [ ] Delete: `git rm MeetMemento/Views/Onboarding/ThemesIdentifiedView.swift`
- [ ] Delete: `git rm MeetMemento/Components/QuestionCounterView.swift`
- [ ] Commit: `git commit -m "Remove deprecated theme analysis UI components"`
- [ ] Build test: Xcode build succeeds
- [ ] Status: _____ (✅ or ❌)

### Batch 2 Execution
- [ ] Delete: `git rm MeetMemento/Services/ThemeAnalysisService.swift`
- [ ] Delete: `git rm MeetMemento/Models/ThemeAnalysis.swift`
- [ ] Commit: `git commit -m "Remove deprecated theme analysis services and models"`
- [ ] Build test: Xcode build succeeds
- [ ] Status: _____ (✅ or ❌)

### Batch 3 Execution
- [ ] Delete: `git rm supabase/functions/new-user-insights/index.ts`
- [ ] Delete: `git rm supabase/functions/new-user-insights/types.ts`
- [ ] Remove directory if empty: `git rm -r supabase/functions/new-user-insights/`
- [ ] Commit: `git commit -m "Remove deprecated new-user-insights edge function"`
- [ ] Status: _____ (✅ or ❌)

### Summary Commit
- [ ] Create summary commit message:
```
Summary: Removed N deprecated theme analysis files (~X lines)

Files removed:
- Theme analysis UI components (3 files)
- Theme analysis business logic (2 files)
- Theme analysis backend (2 files)

Reason: Theme selection feature removed from onboarding flow in commit 622e5c9
See: SIMPLIFIED_ONBOARDING.md for context

Database migrations kept (with deprecation comments):
- 20250119000001_create_themes_table.sql
- 20250119000002_add_user_profiles_themes.sql
```
- [ ] Execute: `git commit --allow-empty -m "..."`

## Post-Cleanup

### Documentation Updates
- [ ] Update `SIMPLIFIED_ONBOARDING.md` - remove "Files Not Modified" section
- [ ] Update `README.md` if it references theme analysis
- [ ] Remove theme analysis from architecture docs
- [ ] Update any flowcharts or diagrams
- [ ] Document cleanup in `CHANGELOG.md` or release notes

### Code Cleanup
- [ ] Search for orphaned imports: `grep -r "import.*Theme" MeetMemento/ --include="*.swift"`
- [ ] Remove comments referencing deleted files
- [ ] Update code comments mentioning theme analysis

### Database Comments (Optional)
- [ ] Add comment to `20250119000001_create_themes_table.sql`:
```sql
-- DEPRECATED (2025-10-22): Table created but no longer used by app
-- Theme analysis feature removed from onboarding flow
-- Kept for potential future use or rollback compatibility
```
- [ ] Add comment to `20250119000002_add_user_profiles_themes.sql`:
```sql
-- DEPRECATED (2025-10-22): Columns created but no longer populated
-- Theme selection feature removed from onboarding flow
```

### Final Verification
- [ ] Run full build: `xcodebuild -scheme MeetMemento build`
- [ ] Check for warnings about missing files
- [ ] Verify no broken references in project navigator
- [ ] Test app launch (if possible)
- [ ] Run tests: `xcodebuild test -scheme MeetMemento` (if tests exist)

### Git Operations
- [ ] Review all commits: `git log --oneline -10`
- [ ] Check diff summary: `git diff HEAD~N..HEAD --stat`
- [ ] Push to remote: `git push -u origin claude/review-memento-v1-1-011CUPGmHRj5QKMriR2sQCVw`
- [ ] Verify backup branch still exists: `git branch | grep backup`

### Team Communication
- [ ] Document what was removed and why
- [ ] Update sprint notes or issue tracker
- [ ] Notify team members who worked on theme analysis
- [ ] Create PR with summary of changes
- [ ] Add cleanup notes to PR description

## Rollback Plan (If Needed)

If anything goes wrong during cleanup:

1. **Immediate rollback:**
   ```bash
   git reset --hard HEAD~N  # N = number of commits to undo
   ```

2. **Restore from backup:**
   ```bash
   git checkout backup/pre-cleanup-YYYYMMDD
   git checkout -b recovery/restore-theme-analysis
   # Cherry-pick specific files if needed
   ```

3. **Restore specific file:**
   ```bash
   git checkout HEAD~N -- path/to/deleted/file.swift
   ```

## Success Criteria

- [ ] All deprecated files identified and removed
- [ ] App builds successfully without errors
- [ ] No warnings about missing references
- [ ] All commits have clear, descriptive messages
- [ ] Documentation updated to reflect changes
- [ ] Team notified of cleanup
- [ ] Backup branch preserved for rollback
- [ ] Net code reduction: ~1,450 lines (expected)

## Notes

- Total files expected to delete: 5-7
- Total lines expected to remove: ~1,180 - 1,450
- Estimated time: 30-60 minutes
- Risk level: LOW (all files confirmed unreferenced)

## Emergency Contacts

If you encounter issues:
- Check `CLEANUP_DEPRECATED_FILES_PROMPT.md` for detailed guidance
- Review commit `622e5c9` for context on what was deprecated
- Consult `SIMPLIFIED_ONBOARDING.md` for feature removal rationale
