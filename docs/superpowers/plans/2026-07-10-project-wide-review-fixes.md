# BeanLedger Project-Wide Review Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the correctness, data-consistency, security, and state-management defects found by a full review of the BeanLedger Swift codebase while preserving the current product identity and visual direction.

**Architecture:** Keep the existing SwiftUI plus store/view-model structure. Add regression coverage to the standalone Swift test harness, centralize shared AI settings at the app root, keep AI draft editing in-memory until explicit confirmation, and add rollback behavior at cross-store write boundaries.

**Tech Stack:** Swift 5, SwiftUI, Foundation, Security/Keychain, UIKit/PhotosUI, XcodeBuildMCP, standalone `swiftc` regression tests.

---

### Task 1: Lock Core Validation And Category Contracts

**Files:**
- Modify: `Tests/Stage2LedgerLogicTests.swift`
- Modify: `BeanLedger/Models/LedgerType.swift`
- Modify: `BeanLedger/Models/AIParseResult.swift`
- Modify: `BeanLedger/ViewModels/LedgerViewModel.swift`
- Modify: `BeanLedger/Services/AIService.swift`

- [x] Add failing tests proving `燃气费` and `电费` are valid expense categories and non-finite amounts are rejected by AI validation and all record/template/budget entry points.
- [x] Run the standalone test executable and confirm the new assertions fail for the expected missing validation/category behavior.
- [x] Add the two utility categories to the shared category contract and AI prompt, then require `Double.isFinite` wherever an amount enters persisted state.
- [x] Re-run the standalone tests and confirm they pass.

### Task 2: Prevent Partial Destructive Writes And Recurring Duplicates

**Files:**
- Modify: `Tests/Stage2LedgerLogicTests.swift`
- Modify: `BeanLedger/Services/LedgerStore.swift`
- Modify: `BeanLedger/Services/BudgetStore.swift`
- Modify: `BeanLedger/Services/RecurringStore.swift`
- Modify: `BeanLedger/ViewModels/LedgerViewModel.swift`
- Modify: `BeanLedger/Views/RecurringRecordsView.swift`

- [x] Add a failing test where the second store cannot be cleared and verify the first store is restored instead of leaving a partial clear.
- [x] Add a failing test where recurring-template advancement fails and verify the generated ledger record is rolled back.
- [x] Add a failing test proving a disabled recurring template can be enabled again.
- [x] Add internal store restore operations and coordinated rollback in `clearAllData()`.
- [x] Roll back a newly generated recurring record when template advancement fails, and replace the one-way disable action with an enabled-state setter.
- [x] Re-run the standalone tests and confirm all transaction and toggle cases pass.

### Task 3: Fix AI Draft Editing And Shared Settings State

**Files:**
- Modify: `Tests/Stage2LedgerLogicTests.swift`
- Create: `Tests/UIStateSourceTests.swift`
- Modify: `BeanLedger/ViewModels/AIEntryViewModel.swift`
- Modify: `BeanLedger/Views/AppRootView.swift`
- Modify: `BeanLedger/Views/HomeView.swift`
- Modify: `BeanLedger/Views/AIEntryView.swift`
- Modify: `BeanLedger/Views/AIParseConfirmationView.swift`
- Modify: `BeanLedger/Views/SettingsView.swift`
- Modify: `BeanLedger/Views/AISettingsView.swift`
- Modify: `BeanLedger/Services/AISettingsStore.swift`

- [x] Add failing tests proving one parsed draft can be updated in memory without creating ledger records, AI settings are root-owned, and reset API-key state propagates back to the secure-field draft.
- [x] Add an in-memory AI draft editor sheet; the `调整` action updates the selected draft rather than opening the save-to-ledger sheet.
- [x] Own one `AISettingsStore` in `AppRootView` and inject it into Settings and AI Entry flows.
- [x] Trim API keys before Keychain persistence, preserve the last successful in-memory key when persistence fails, and synchronize external key resets into the UI draft.
- [x] Re-run logic and source regression tests.

### Task 4: Correct Statistics And Export Behavior

**Files:**
- Modify: `Tests/Stage2LedgerLogicTests.swift`
- Modify: `BeanLedger/ViewModels/LedgerViewModel.swift`
- Modify: `BeanLedger/Views/TrendChartView.swift`
- Modify: `BeanLedger/Views/StatsView.swift`
- Modify: `BeanLedger/Views/BudgetView.swift`
- Modify: `BeanLedger/Services/ExportService.swift`

- [x] Add failing tests for month-to-date daily averages, type-specific recorded-day counts, and CSV spreadsheet-formula neutralization.
- [x] Make trend metrics follow the selected type and exclude future days from current-month averages/charts.
- [x] Remove artificial non-zero progress bars and preserve decimal budget values when syncing fields.
- [x] Prefix dangerous user-controlled CSV cells so Excel/Numbers do not interpret notes or categories as formulas.
- [x] Re-run all standalone tests.

### Task 5: Harden Parsing, Feedback, And Image Loading

**Files:**
- Modify: `Tests/Stage2LedgerLogicTests.swift`
- Modify: `BeanLedger/Models/AIParseResult.swift`
- Modify: `BeanLedger/Views/AppRootView.swift`
- Modify: `BeanLedger/Views/SettingsView.swift`
- Modify: `BeanLedger/Services/RecordImageStore.swift`
- Modify: `BeanLedger/Views/Components/PhotoLibraryPicker.swift`

- [x] Add a failing parser test with prose/brackets around valid JSON and trailing brace text.
- [x] Replace first/last-bracket slicing with a balanced, string-aware candidate scanner validated by `JSONSerialization`.
- [x] Make toast dismissal cancellable so an older toast timer cannot dismiss a newer message.
- [x] Report share-sheet presentation failure and partial AI-key clearing accurately.
- [x] Downsample picked photos before preview/storage, cache loaded thumbnails, and reject unsafe image filenames.
- [x] Re-run all standalone tests and an Xcode analyzer build.

### Task 6: End-To-End Verification

**Files:**
- Verify: all modified files

- [x] Run `QuickEntryPresetTests`, `UIDecorationSourceTests`, `UIStateSourceTests`, and the full `Stage2LedgerLogicTests` executable.
- [x] Run `git diff --check`, scan tracked source for secrets/private endpoints, and inspect the complete diff.
- [x] Run Xcode static analysis and a fresh iPhone 17 Simulator build/run.
- [x] Exercise Home, AI Entry, Settings, Stats, and recurring-record UI paths in Simulator and capture screenshots/runtime state.
- [x] Request a final focused code review, address any Critical or Important findings, then repeat verification.
