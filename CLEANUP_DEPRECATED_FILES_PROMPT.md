# Claude Code Prompt: Review and Delete Deprecated Files

## Objective
Systematically identify and delete all deprecated files from the MeetMemento codebase that are no longer referenced by any active code or services.

## Definition: Deprecated File
A file is considered **deprecated** if it meets ALL of the following criteria:

1. **No Code References**: Not imported, referenced, or called by any active Swift file
2. **No Backend References**: Not invoked by any edge function, migration, or service
3. **No Runtime Usage**: Not dynamically loaded or referenced at runtime (e.g., via string literals)
4. **Not Part of Active Features**: Belongs to a feature that has been removed from the app flow
5. **Not Infrastructure**: Not a configuration, build, or tooling file (e.g., .xcconfig, Package.swift)

## Scope: Files to Analyze

### Swift Files
- All `.swift` files in `MeetMemento/` directory
- Focus on: Views, ViewModels, Models, Services, Components

### Backend Files
- Edge functions in `supabase/functions/`
- Database migrations in `supabase/migrations/`
- TypeScript types and utilities

### Exclude from Analysis
- Configuration files (`.xcconfig`, `Info.plist`, `Package.swift`)
- Build files (`.xcodeproj`, `.pbxproj`)
- Documentation files (`.md` files in docs/)
- Test files (keep even if unreferenced, unless explicitly deprecated)
- Git files (`.gitignore`, `.gitattributes`)

## Tasks

### Phase 1: Discovery & Analysis (DO NOT DELETE YET)

1. **Create comprehensive inventory**
   - List ALL Swift files in `MeetMemento/`
   - List ALL edge functions in `supabase/functions/`
   - List ALL files added or modified in commit `622e5c9` (Memento-v1.1)

2. **For each Swift file, determine:**
   - What files import/reference it? (Use `grep` to search for class/struct/enum names)
   - Is it referenced in any Xcode project files?
   - Is it used in any SwiftUI view hierarchy?
   - Is it instantiated or called anywhere?

3. **For each edge function, determine:**
   - Is it invoked by any Swift code? (Search for function name in `.swift` files)
   - Is it referenced in any Supabase configuration?
   - Is it a scheduled cron job? (Check for cron comments/setup)

4. **For each database migration, determine:**
   - Does it create tables/columns that are actively used?
   - Are the created tables queried by Swift code or edge functions?

5. **Create a detailed report with THREE categories:**
   - **SAFE TO DELETE**: Zero references found, confirmed deprecated
   - **REVIEW REQUIRED**: Ambiguous status, may have dynamic references
   - **KEEP**: Has active references or is infrastructure

### Phase 2: Generate Deletion Plan

For each file in "SAFE TO DELETE" category:

1. **Document why it's deprecated:**
   - What feature did it belong to?
   - When was it deprecated? (commit hash)
   - Why was it removed from active use?

2. **Identify dependencies:**
   - What other deprecated files does it reference?
   - Should they be deleted together?

3. **Check for residual value:**
   - Does documentation suggest keeping it for future use?
   - Is there a plan to re-enable this feature?

4. **Create deletion order:**
   - Group related files together
   - Delete leaf dependencies first (files with no dependents)

### Phase 3: Execution (REQUIRES CONFIRMATION)

**BEFORE DELETING ANYTHING:**
1. Create a backup branch: `git checkout -b backup/pre-cleanup-$(date +%Y%m%d)`
2. Present the deletion plan to the user for review
3. Get explicit confirmation for each file or batch of files

**For each confirmed deletion:**
1. Use `git rm <file>` to properly remove from version control
2. Log the deletion with reason in commit message
3. Update any documentation that references the deleted file

**After all deletions:**
1. Verify the app still compiles: `swift build` or Xcode build
2. Run tests if available
3. Create a summary commit message listing all deleted files

## Expected Output Format

### Phase 1 Report
```markdown
# Deprecated Files Analysis Report
Generated: [DATE]
Branch: Memento-v1.1 (commit 622e5c9)

## Summary
- Total files analyzed: X
- Safe to delete: Y
- Review required: Z
- Keep (active): W

## SAFE TO DELETE (Y files, ~N lines)

### Theme Analysis Feature (Removed in commit 622e5c9)
1. `MeetMemento/Views/Onboarding/ThemesIdentifiedView.swift` (192 lines)
   - Reason: Theme selection removed from onboarding flow
   - References: NONE
   - Last used: v1.0
   - Dependencies: ThemeCardFullScreen, ThemeAnalysis models

2. `MeetMemento/Components/ThemeCardFullScreen.swift` (77 lines)
   - Reason: Only used by ThemesIdentifiedView (deprecated)
   - References: Only from ThemesIdentifiedView.swift
   - Dependencies: ThemeAnalysis.swift

[... continue for all files ...]

## REVIEW REQUIRED (Z files)

1. `supabase/migrations/20250119000001_create_themes_table.sql`
   - Status: Migration applied, table exists but unused
   - Risk: Removing migration may break database state
   - Recommendation: Keep migration, document as unused
   - Alternative: Add comment to migration file

[... continue ...]

## KEEP (W files)

1. `supabase/functions/weekly-question-generator/index.ts`
   - Reason: Scheduled cron job (runs independently of app)
   - Usage: Background task, not called by Swift code
   - Status: ACTIVE

[... continue ...]
```

### Phase 2 Deletion Plan
```markdown
# Deletion Plan

## Batch 1: Theme Analysis UI Components (3 files)
- [ ] MeetMemento/Components/ThemeCardFullScreen.swift
- [ ] MeetMemento/Views/Onboarding/ThemesIdentifiedView.swift
- [ ] MeetMemento/Components/QuestionCounterView.swift

Dependencies: None (leaf nodes)
Rationale: UI components with no active references
Commit message: "Remove deprecated theme analysis UI components"

## Batch 2: Theme Analysis Business Logic (2 files)
- [ ] MeetMemento/Services/ThemeAnalysisService.swift
- [ ] MeetMemento/Models/ThemeAnalysis.swift

Dependencies: Batch 1 (UI components reference these)
Rationale: Business logic for removed feature
Commit message: "Remove deprecated theme analysis service and models"

## Batch 3: Theme Analysis Backend (2 files)
- [ ] supabase/functions/new-user-insights/index.ts
- [ ] supabase/functions/new-user-insights/types.ts

Dependencies: ThemeAnalysisService.swift (Swift client)
Rationale: Edge function no longer called by app
Commit message: "Remove deprecated new-user-insights edge function"
Note: Consider keeping if planning to re-enable feature

## Summary
Total files to delete: 7
Total lines removed: ~1,181
Estimated time: 15 minutes
Risk level: LOW (all files confirmed unreferenced)
```

### Phase 3 Execution Summary
```bash
# Commands executed:
git checkout -b cleanup/remove-deprecated-theme-analysis
git rm MeetMemento/Components/ThemeCardFullScreen.swift
git rm MeetMemento/Views/Onboarding/ThemesIdentifiedView.swift
git rm MeetMemento/Components/QuestionCounterView.swift
git commit -m "Remove deprecated theme analysis UI components"

[... continue for each batch ...]

# Final summary commit:
git commit --allow-empty -m "Summary: Removed 7 deprecated files (~1,181 lines)

Files removed:
- Theme analysis UI components (3 files)
- Theme analysis business logic (2 files)
- Theme analysis backend (2 files)

Reason: Theme selection feature removed from onboarding flow in commit 622e5c9
See: SIMPLIFIED_ONBOARDING.md for context

Related migrations kept:
- 20250119000001_create_themes_table.sql (table exists but unused)
- 20250119000002_add_user_profiles_themes.sql (columns exist but unused)
"
```

## Safety Checks

Before marking any file as "SAFE TO DELETE", verify:

- [ ] No string literal references (e.g., `"ThemeAnalysisService"` in dynamic loading)
- [ ] No Objective-C bridging references
- [ ] No XIB/Storyboard references (if applicable)
- [ ] No Info.plist or configuration references
- [ ] No test files that import it (even if tests are unreferenced)
- [ ] No documentation that should be updated
- [ ] File is not in `.gitignore` (shouldn't delete ignored files)

## Special Cases

### Database Migrations
- **DO NOT DELETE** applied migrations (breaks database state)
- Instead: Document as unused in migration file comments
- Consider: Adding `-- DEPRECATED: Not used by current app version` comment

### Cron Jobs / Background Tasks
- **DO NOT DELETE** edge functions with cron setup
- Verify: Check for cron comments, scheduled task configuration
- Example: `weekly-question-generator` is a cron job, keep it

### Swift Protocol Extensions
- May not show up in simple grep searches
- Check for protocol conformance, not just explicit references

### SwiftUI View Modifiers
- May be used via chaining, hard to detect
- Example: `.customModifier()` may not show up as reference to `CustomModifier` struct

## Error Handling

If Phase 3 execution results in:

1. **Build errors**: Immediately restore from backup branch, re-analyze
2. **Runtime crashes**: File may have been used dynamically, restore and mark as "REVIEW REQUIRED"
3. **Missing references in logs**: May indicate reflection or dynamic usage

## Post-Cleanup Tasks

After successful deletion:

1. **Update documentation:**
   - Remove references from README.md
   - Update architecture docs
   - Remove from SIMPLIFIED_ONBOARDING.md "Files Not Modified" section

2. **Clean up related code:**
   - Remove import statements for deleted files
   - Remove comments referencing deleted features
   - Update code comments that mention deleted files

3. **Database cleanup (optional):**
   - Consider dropping unused `themes` table
   - Consider removing unused columns from `user_profiles`
   - Document in migration: `-- Table deprecated but kept for rollback compatibility`

4. **Notify team:**
   - Document what was removed and why
   - Update sprint notes or changelog
   - Ensure no one has pending work on deleted files

## Final Checklist

- [ ] Phase 1 report generated and reviewed
- [ ] Phase 2 deletion plan created and confirmed
- [ ] Backup branch created
- [ ] All deletions executed with proper git commits
- [ ] App builds successfully
- [ ] Tests pass (if applicable)
- [ ] Documentation updated
- [ ] Changes pushed to feature branch
- [ ] PR created with summary of deletions

---

## Execution Instructions

**Copy this entire prompt and paste into Claude Code terminal:**

```
Please execute the "Review and Delete Deprecated Files" task as defined in CLEANUP_DEPRECATED_FILES_PROMPT.md.

Start with Phase 1 (Discovery & Analysis) and present the report.
DO NOT proceed to Phase 2 or Phase 3 without my explicit approval.

Use the following search strategy:
1. For Swift files: grep -r "ClassName" MeetMemento/ --include="*.swift"
2. For edge functions: grep -r "function-name" MeetMemento/ supabase/ --include="*.swift" --include="*.ts"
3. For models: grep -r "StructName\|class StructName" MeetMemento/ --include="*.swift"

Focus on files added or modified in commit 622e5c9 (Memento-v1.1 branch) as identified in the previous review.

Present findings in the specified report format.
```

---

## Notes

- This prompt is designed for systematic cleanup, not exploratory analysis
- Always err on the side of caution - mark ambiguous files as "REVIEW REQUIRED"
- Database migrations should almost never be deleted once applied
- Consider creating an `archived/` directory instead of deleting, for easy restoration
- Keep a paper trail: detailed commit messages are essential for rollback

## Related Documentation

- See: `SIMPLIFIED_ONBOARDING.md` - Context for theme analysis removal
- See: Previous review output - Identifies 9 deprecated files (~1,450 lines)
- See: commit `622e5c9` - Where theme analysis was added then deprecated
