import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

func source(_ relativePath: String) throws -> String {
    try String(contentsOf: root.appendingPathComponent(relativePath), encoding: .utf8)
}

func require(_ token: String, in text: String, _ message: String) {
    guard text.contains(token) else {
        fatalError("\(message). Missing token: \(token)")
    }
}

func forbid(_ token: String, in text: String, _ message: String) {
    guard !text.contains(token) else {
        fatalError("\(message). Forbidden token: \(token)")
    }
}

let appRoot = try source("BeanLedger/Views/AppRootView.swift")
let home = try source("BeanLedger/Views/HomeView.swift")
let aiEntry = try source("BeanLedger/Views/AIEntryView.swift")
let settings = try source("BeanLedger/Views/SettingsView.swift")
let aiSettings = try source("BeanLedger/Views/AISettingsView.swift")
let trend = try source("BeanLedger/Views/TrendChartView.swift")
let stats = try source("BeanLedger/Views/StatsView.swift")
let budget = try source("BeanLedger/Views/BudgetView.swift")
let recordImageStore = try source("BeanLedger/Services/RecordImageStore.swift")
let photoPicker = try source("BeanLedger/Views/Components/PhotoLibraryPicker.swift")

require(
    "@StateObject private var aiSettingsStore = AISettingsStore()",
    in: appRoot,
    "the app root should own the single shared AI settings store"
)
require(
    "HomeView(viewModel: viewModel, aiSettingsStore: aiSettingsStore)",
    in: appRoot,
    "the home flow should receive the shared AI settings store"
)
require(
    "SettingsView(viewModel: viewModel, aiSettingsStore: aiSettingsStore)",
    in: appRoot,
    "the settings flow should receive the shared AI settings store"
)
require(
    ".task(id: viewModel.toastMessage)",
    in: appRoot,
    "toast dismissal should restart and cancel with the current message"
)
forbid(
    "DispatchQueue.main.asyncAfter",
    in: appRoot,
    "an older toast timer should not dismiss a newer toast"
)
require(
    "AIEntryView(ledgerViewModel: viewModel, settingsStore: aiSettingsStore)",
    in: home,
    "the AI entry screen should receive the root-owned settings store"
)
forbid(
    "@StateObject private var settingsStore = AISettingsStore()",
    in: aiEntry,
    "the AI entry screen should not keep a stale private settings store"
)
forbid(
    "@StateObject private var aiSettingsStore = AISettingsStore()",
    in: settings,
    "the settings screen should not create a second settings store"
)
forbid(
    "ledgerViewModel.presentAddRecord(",
    in: aiEntry,
    "adjusting an AI draft should not open the save-to-ledger flow"
)
require(
    ".onChange(of: settingsStore.apiKey)",
    in: aiSettings,
    "external API-key resets should update the secure-field draft"
)
require(
    "highestDailyTotal(type: selectedType)",
    in: trend,
    "trend high-water metric should follow the selected ledger type"
)
require(
    "averageDailyTotal(type: selectedType)",
    in: trend,
    "trend average metric should follow the selected ledger type"
)
require(
    "recordedDayCount(type: selectedType)",
    in: trend,
    "trend recorded-day metric should follow the selected ledger type"
)
forbid("highestDailyExpense()", in: trend, "trend UI should not stay hard-coded to expense metrics")
forbid("averageDailyExpense()", in: trend, "trend UI should not stay hard-coded to expense metrics")
forbid("max(progress, 0.05)", in: stats, "zero totals should render a zero-width statistics bar")
forbid("budgetAmount > 0 ? 0.04 : 0", in: budget, "unused budgets should render a zero-width progress bar")
require(
    "guard let presenter = topMostViewController()",
    in: settings,
    "export should report when the system share sheet cannot be presented"
)
require(
    "账本数据已清空，但 API Key 清除失败",
    in: settings,
    "clear-all should accurately report partial API-key cleanup failure"
)
require("import ImageIO", in: recordImageStore, "record images should be downsampled without full-size decoding")
require(
    "CGImageSourceCreateThumbnailAtIndex",
    in: recordImageStore,
    "record images should use ImageIO thumbnail generation"
)
require(
    "NSCache<NSString, UIImage>",
    in: recordImageStore,
    "record thumbnails should not be synchronously reloaded from disk on every render"
)
require(
    "safeFileURL(for:",
    in: recordImageStore,
    "persisted image filenames should be validated before file access"
)
require(
    "RecordImageStore.previewImage(data:",
    in: photoPicker,
    "photo picker previews should use the downsampled image path"
)
forbid("UIImage(data: data)", in: photoPicker, "photo picker should not decode full-resolution images for thumbnails")

print("UIStateSourceTests passed")
