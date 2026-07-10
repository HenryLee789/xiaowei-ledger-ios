# BeanLedger Dark Mode And Safe Area Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add complete semantic Light/Dark Mode colors and prevent page content from overlapping the iPhone status bar without changing BeanLedger business behavior.

**Architecture:** Move every interface color into Any/Dark asset color sets and keep `AppTheme` as the only semantic access layer. Add a reusable SwiftUI top-safe-area modifier in `AppTheme.swift`, apply it only to navigation-hidden root screens, and restrict all background safe-area expansion to explicit edges.

**Tech Stack:** Swift 5, SwiftUI, Xcode asset catalogs, standalone Swift source tests, XcodeBuildMCP, iPhone 17 Simulator on iOS 26.3.

**Constraints:** Do not alter models, stores, view models, persistence formats, AppIcon, app name, URL scheme, or business logic. Do not commit, push, create a release, or export an IPA.

---

### Task 1: Add Failing Theme And Safe Area Contract Tests

**Files:**
- Create: `Tests/DarkModeSafeAreaSourceTests.swift`

- [x] **Step 1: Write a source-level regression test**

Create a standalone Swift test that:

```swift
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let requiredColors = [
    "AppBackground", "SoftBackground", "CardBackground", "ElevatedSurface",
    "PrimaryText", "SecondaryText", "Border", "Shadow", "OnAccentText",
    "OverlayScrim", "IllustrationSurface", "BrandPrimary", "BrandPrimaryDeep",
    "BrandCherry", "BrandLavender", "BrandLemon", "BrandSky", "BrandMint",
    "HeaderGradientEnd", "DangerStart", "DangerEnd", "ExpensePrimary",
    "ExpenseSoftBackground", "ExpenseProgress", "IncomePrimary",
    "IncomeSoftBackground", "IncomeProgress", "SavingPrimary",
    "SavingSoftBackground", "SavingProgress", "DebtPrimary",
    "DebtSoftBackground", "DebtProgress", "NeutralAmount", "BudgetWarning",
    "BudgetOverLimit", "BudgetSafe"
]

for name in requiredColors {
    let url = root.appendingPathComponent("BeanLedger/Assets.xcassets/\(name).colorset/Contents.json")
    let data = try Data(contentsOf: url)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    let colors = json?["colors"] as? [[String: Any]] ?? []
    precondition(colors.contains { $0["appearances"] == nil }, "\(name) needs an Any appearance")
    precondition(colors.contains { ($0["appearances"] as? [[String: String]])?.contains { $0["value"] == "dark" } == true }, "\(name) needs a Dark appearance")
}
```

The same test must scan `BeanLedger/Utilities` and `BeanLedger/Views` and reject:

```swift
let forbiddenTokens = ["Color(hex:", "Color.white", "Color.black", ".ignoresSafeArea()"]
```

It must also require `.protectsTopSafeArea()` in `HomeView.swift`, `RecordsView.swift`, `StatsView.swift`, `SettingsView.swift`, and `AIEntryView.swift`.

- [x] **Step 2: Run the test and confirm RED**

Run:

```bash
swift Tests/DarkModeSafeAreaSourceTests.swift
```

Expected: failure because semantic color assets and the top-safe-area modifier are not present.

---

### Task 2: Create Dynamic Color Assets And Refactor AppTheme

**Files:**
- Create: `BeanLedger/Assets.xcassets/*.colorset/Contents.json`
- Modify: `BeanLedger/Utilities/AppTheme.swift`

- [x] **Step 1: Generate the semantic Any/Dark assets**

Create the required color sets from Task 1. Core C-direction values are:

```text
AppBackground          FFF7FA / 1A1118
SoftBackground         FFEAF2 / 251821
CardBackground         FFFFFF / 2C1C27
ElevatedSurface        FFF1F6 / 35222F
PrimaryText            44363C / FFF3F7
SecondaryText          8A747C / C9B5BE
Border                 FFD3E0 / 67384E
Shadow                 FF8FB3 / 120B10
OnAccentText           FFFFFF / FFF7FA
OverlayScrim           24131B / 09070B
IllustrationSurface    FFFDF7 / 3A2730
BrandPrimary           FFB6C9 / FF9FBE
BrandPrimaryDeep       FF8FB3 / F26A9B
BrandCherry            E94B70 / FF729C
BrandLavender          D7C6FF / C8A8FF
BrandLemon             FFE6A6 / FFE08A
BrandSky               BFE9FF / 72C1FF
BrandMint              C9F4DE / 76D8A4
HeaderGradientEnd      FFDCE8 / 4B2335
DangerStart            FF7D9D / FF789B
DangerEnd              D9435B / F05573
ExpensePrimary         D99A00 / FFD166
ExpenseSoftBackground  FFF4D6 / 40321B
ExpenseProgress        E0A800 / FFD166
IncomePrimary          4A90E2 / 72C1FF
IncomeSoftBackground   EAF4FF / 1E3142
IncomeProgress         4A90E2 / 72C1FF
SavingPrimary          C65BCF / F08CFF
SavingSoftBackground   FCEBFF / 3E2442
SavingProgress         C65BCF / F08CFF
DebtPrimary            8B5CF6 / B79AFF
DebtSoftBackground     F0EAFF / 312444
DebtProgress           8B5CF6 / B79AFF
NeutralAmount          44363C / FFF3F7
BudgetWarning          E88A2A / FFAD66
BudgetOverLimit        E95B73 / FF7894
BudgetSafe             69B885 / 7ED9A0
```

Each `Contents.json` must contain one universal `Any` entry and one universal luminosity `Dark` entry using sRGB components.

- [x] **Step 2: Replace hard-coded theme values**

In `AppTheme.swift`, map existing public names to assets:

```swift
static let background = Color("AppBackground")
static let softBackground = Color("SoftBackground")
static let card = Color("CardBackground")
static let elevatedSurface = Color("ElevatedSurface")
static let text = Color("PrimaryText")
static let secondaryText = Color("SecondaryText")
static let onAccentText = Color("OnAccentText")
static let overlayScrim = Color("OverlayScrim")
static let illustrationSurface = Color("IllustrationSurface")
```

Map all brand, semantic ledger, budget, border, and shadow properties the same way. Rebuild gradients from named assets and remove `Color.init(hex:alpha:)` entirely.

- [x] **Step 3: Re-run the source test**

Expected: it still fails on hard-coded view colors and missing Safe Area protection, while all required asset assertions pass.

---

### Task 3: Replace Hard-Coded Colors Across SwiftUI Views

**Files:**
- Modify: `BeanLedger/Views/AddRecordView.swift`
- Modify: `BeanLedger/Views/AIEntryView.swift`
- Modify: `BeanLedger/Views/AIParseConfirmationView.swift`
- Modify: `BeanLedger/Views/AISettingsView.swift`
- Modify: `BeanLedger/Views/BudgetView.swift`
- Modify: `BeanLedger/Views/DayRecordListSheet.swift`
- Modify: `BeanLedger/Views/FilterPanelView.swift`
- Modify: `BeanLedger/Views/HomeView.swift`
- Modify: `BeanLedger/Views/LedgerCalendarView.swift`
- Modify: `BeanLedger/Views/QuickEntryView.swift`
- Modify: `BeanLedger/Views/RecordsView.swift`
- Modify: `BeanLedger/Views/RecurringRecordEditorView.swift`
- Modify: `BeanLedger/Views/RecurringRecordsView.swift`
- Modify: `BeanLedger/Views/SettingsView.swift`
- Modify: `BeanLedger/Views/StatsView.swift`
- Modify: `BeanLedger/Views/TrendChartView.swift`
- Modify: `BeanLedger/Views/Components/CategoryPill.swift`
- Modify: `BeanLedger/Views/Components/CuteButton.swift`
- Modify: `BeanLedger/Views/Components/CuteMascotView.swift`
- Modify: `BeanLedger/Views/Components/RecordThumbnailView.swift`
- Modify: `BeanLedger/Views/Components/ToastView.swift`

- [x] **Step 1: Replace surface and text colors**

Use `AppTheme.card`, `AppTheme.elevatedSurface`, `AppTheme.text`, and `AppTheme.secondaryText` for cards, inputs, calendar cells, chart containers, and secondary copy. Preserve existing opacity values where they express visual hierarchy.

- [x] **Step 2: Replace saturated-control contrast colors**

Replace all white text/strokes on selected pills, buttons, toast, and gradient icons with `AppTheme.onAccentText`. Replace the settings overlay black scrim with `AppTheme.overlayScrim.opacity(0.52)`.

- [x] **Step 3: Replace illustration literals**

Map thumbnail/cartoon literals to semantic colors:

```text
white / FFFDF7 -> IllustrationSurface
FFF8DC / FFE6A6 -> BrandLemon
FFD6E4 / FF8FA3 -> BrandPrimary / BrandPrimaryDeep
EAF4FF / BFE9FF -> IncomeSoftBackground / BrandSky
FCEBFF -> SavingSoftBackground
F0EAFF -> DebtSoftBackground
```

- [x] **Step 4: Run the source test**

Expected: no hard-coded color failures remain; Safe Area assertions are the only remaining failures.

---

### Task 4: Add Top Safe Area Protection

**Files:**
- Modify: `BeanLedger/Utilities/AppTheme.swift`
- Modify: `BeanLedger/Views/HomeView.swift`
- Modify: `BeanLedger/Views/RecordsView.swift`
- Modify: `BeanLedger/Views/StatsView.swift`
- Modify: `BeanLedger/Views/SettingsView.swift`
- Modify: `BeanLedger/Views/AIEntryView.swift`
- Modify: every screen containing unqualified `.ignoresSafeArea()`

- [x] **Step 1: Add the reusable modifier**

Add to `AppTheme.swift`:

```swift
private struct TopSafeAreaProtection: ViewModifier {
    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .top, spacing: 0) {
            AppTheme.background
                .frame(height: 8)
                .frame(maxWidth: .infinity)
                .background(AppTheme.background.ignoresSafeArea(edges: .top))
        }
    }
}

extension View {
    func protectsTopSafeArea() -> some View {
        modifier(TopSafeAreaProtection())
    }
}
```

- [x] **Step 2: Apply it to navigation-hidden root screens**

Apply `.protectsTopSafeArea()` after the root `ZStack` and before `.hideNavigationBarForPrototype()` in Home, Records, Stats, Settings, and AI Entry.

- [x] **Step 3: Qualify every background safe-area expansion**

Replace each `.ignoresSafeArea()` with explicit background-only edges, normally:

```swift
DottedBackground()
    .ignoresSafeArea(edges: [.top, .bottom])
```

Do not apply `ignoresSafeArea` to `ScrollView`, header, form content, or interactive controls.

- [x] **Step 4: Run the source test and require GREEN**

Run:

```bash
swift Tests/DarkModeSafeAreaSourceTests.swift
```

Expected: `DarkModeSafeAreaSourceTests passed`.

---

### Task 5: Run Regression Tests And Debug Build

**Files:**
- Verify: all modified files

- [x] **Step 1: Run standalone tests**

```bash
swift Tests/QuickEntryPresetTests.swift
swift Tests/UIDecorationSourceTests.swift
swift Tests/UIStateSourceTests.swift
swift Tests/DarkModeSafeAreaSourceTests.swift
```

Compile and run `Tests/Stage2LedgerLogicTests.swift` with the existing `xcrun swiftc -warnings-as-errors` command.

- [x] **Step 2: Check the diff**

```bash
git diff --check
rg -n 'Color\(hex:|Color\.white|Color\.black|\.ignoresSafeArea\(\)' BeanLedger
```

Expected: clean diff check and no forbidden color/safe-area matches.

- [x] **Step 3: Build Debug**

```bash
xcodebuild -project BeanLedger.xcodeproj -scheme BeanLedger -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,id=B8A211DE-B2FA-49A8-A0D1-956BCB7C4961' \
  build CODE_SIGNING_ALLOWED=NO
```

Expected: `BUILD SUCCEEDED`.

---

### Task 6: Verify Light/Dark UI And Capture Screenshots

**Files:**
- Create: `Screenshots/01_dark_home.png`
- Create: `Screenshots/02_dark_add_record.png`
- Create: `Screenshots/03_dark_stats.png`
- Create: `Screenshots/04_dark_budget.png`
- Create: `Screenshots/05_safearea_home_scroll.png`

- [x] **Step 1: Build and run on iPhone 17**

Use XcodeBuildMCP `build_run_sim`, confirm the root UI snapshot, and keep Simulator visible.

- [x] **Step 2: Verify Light Mode**

```bash
xcrun simctl ui B8A211DE-B2FA-49A8-A0D1-956BCB7C4961 appearance light
```

Inspect Home, Add Record, Records, Stats, Budget, Calendar, AI Entry, AI Settings, and AI confirmation for regressions.

- [x] **Step 3: Verify Dark Mode**

```bash
xcrun simctl ui B8A211DE-B2FA-49A8-A0D1-956BCB7C4961 appearance dark
```

Inspect the same pages for bright white surfaces, low-contrast text, incorrect semantic amount colors, and system-bar gaps.

- [x] **Step 4: Verify rapid Home scrolling**

Swipe Home up and down repeatedly. Confirm the header starts below the Dynamic Island, scrolling content is masked before the status bar, the tab bar does not jump, and no black edge appears.

- [x] **Step 5: Save exact screenshots**

Navigate to each requested state, then use:

```bash
xcrun simctl io B8A211DE-B2FA-49A8-A0D1-956BCB7C4961 screenshot Screenshots/<name>.png
```

Verify all five PNG files exist and visually inspect them before reporting completion.

- [x] **Step 6: Inspect runtime logs**

Review the newest XcodeBuildMCP runtime and OS logs for crashes, SwiftUI state warnings, constraint failures, and main-thread violations. Treat known iOS Simulator font fallback noise separately from app errors.
