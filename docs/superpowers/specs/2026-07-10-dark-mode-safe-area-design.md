# BeanLedger Dark Mode And Safe Area Design

## Scope

This pass changes only SwiftUI presentation concerns:

- Add complete Light/Dark Mode color adaptation.
- Prevent scrolling content and headers from entering the status-bar region.
- Preserve the selected C direction: deep berry dark surfaces with brighter semantic ledger colors.
- Preserve all business logic, persistence models, AppIcon, app identity, navigation, and user workflows.
- Do not commit, push, publish, export an IPA, or create a release.

## Color Architecture

All interface colors will live in `BeanLedger/Assets.xcassets` as semantic color sets with `Any` and `Dark` appearances. `AppTheme.swift` will contain only `Color("ResourceName")` aliases, opacity composition, gradients, spacing, and semantic color routing. The `Color(hex:)` initializer will be removed.

The selected dark direction uses these core values:

| Semantic role | Light | Dark |
| --- | --- | --- |
| App background | `#FFF7FA` | `#1A1118` |
| Soft background | `#FFEAF2` | `#251821` |
| Card background | `#FFFFFF` | `#2C1C27` |
| Input/elevated surface | `#FFF1F6` | `#35222F` |
| Primary text | `#44363C` | `#FFF3F7` |
| Secondary text | `#8A747C` | `#C9B5BE` |
| Border | `#FFD3E0` | `#67384E` |
| Brand primary | `#FFB6C9` | `#FF9FBE` |
| Brand deep | `#FF8FB3` | `#F26A9B` |
| Brand cherry | `#E94B70` | `#FF729C` |

Ledger semantics remain stable while dark values gain contrast:

| Ledger role | Light | Dark |
| --- | --- | --- |
| Expense | `#D99A00` | `#FFD166` |
| Income | `#4A90E2` | `#72C1FF` |
| Saving | `#C65BCF` | `#F08CFF` |
| Debt | `#8B5CF6` | `#B79AFF` |

Supporting resources cover soft semantic backgrounds, progress colors, budget states, on-accent text, overlay scrims, illustration surfaces, and gradient endpoints. View files will not contain `Color.white`, `Color.black`, `Color(hex:)`, or literal RGB values.

## Component Adaptation

Shared cards, inputs, chips, buttons, charts, calendar cells, overlays, and illustration backgrounds will use semantic theme roles. Titles remain `PrimaryText`; only amounts, icons, tags, and progress indicators use expense/income/saving/debt colors. Saturated buttons continue to use a dynamic `OnAccentText` resource.

The following UI paths are covered:

- Home, quick entry, summaries, and recent records.
- Add Record and recurring-record editors.
- Records, search, and filter controls.
- Stats, trends, budget, and calendar.
- AI entry, AI draft editor, parse confirmation, and AI settings.
- Settings overlays, toast, thumbnails, empty states, and recurring sheets.

## Safe Area Design

Background layers may extend under the top and bottom system regions, but interactive and scrolling content may not. Unqualified `.ignoresSafeArea()` will be removed.

Tab-root screens that hide the navigation bar will use a shared top-safe-area barrier. The modifier inserts a small opaque semantic background beneath the status bar and extends that background into the top system region. It reduces the content safe area, keeps the first header below the Dynamic Island/notch, and masks scrolling content before it reaches time, signal, or battery indicators.

Navigation-driven pages and sheets retain the system-provided safe area. Their background ignores only explicitly named edges; their `ScrollView` and action bars continue to respect the system insets.

## Verification

- Add a source regression test for required dynamic color resources, forbidden hard-coded colors, and top-safe-area protection on tab roots.
- Run existing quick-entry, decoration, UI-state, and ledger-logic tests.
- Run `xcodebuild build` for Debug and require `BUILD SUCCEEDED`.
- Run on iPhone 17 Simulator in Light and Dark appearances.
- Inspect Home, Add Record, Records, Stats, Budget, Calendar, AI Entry, AI Settings, and AI confirmation surfaces.
- Rapidly scroll Home and verify the header does not cover the status bar, jump, or produce black edges.
- Save the requested screenshots under `Screenshots/`.
