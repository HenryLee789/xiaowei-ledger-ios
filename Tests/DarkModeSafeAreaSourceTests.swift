import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let fileManager = FileManager.default

let requiredColors = [
    "AppBackground",
    "SoftBackground",
    "CardBackground",
    "ElevatedSurface",
    "PrimaryText",
    "SecondaryText",
    "Border",
    "Shadow",
    "OnAccentText",
    "OverlayScrim",
    "IllustrationSurface",
    "BrandPrimary",
    "BrandPrimaryDeep",
    "BrandCherry",
    "BrandLavender",
    "BrandLemon",
    "BrandSky",
    "BrandMint",
    "HeaderGradientEnd",
    "DangerStart",
    "DangerEnd",
    "ExpensePrimary",
    "ExpenseSoftBackground",
    "ExpenseProgress",
    "IncomePrimary",
    "IncomeSoftBackground",
    "IncomeProgress",
    "SavingPrimary",
    "SavingSoftBackground",
    "SavingProgress",
    "DebtPrimary",
    "DebtSoftBackground",
    "DebtProgress",
    "NeutralAmount",
    "BudgetWarning",
    "BudgetOverLimit",
    "BudgetSafe"
]

for colorName in requiredColors {
    let colorURL = root.appendingPathComponent(
        "BeanLedger/Assets.xcassets/\(colorName).colorset/Contents.json"
    )
    guard fileManager.fileExists(atPath: colorURL.path) else {
        fatalError("Missing dynamic color resource: \(colorName)")
    }

    let data = try Data(contentsOf: colorURL)
    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          let colors = json["colors"] as? [[String: Any]] else {
        fatalError("Invalid color asset JSON: \(colorName)")
    }

    guard colors.contains(where: { $0["appearances"] == nil }) else {
        fatalError("\(colorName) needs an Any appearance")
    }
    guard colors.contains(where: { color in
        guard let appearances = color["appearances"] as? [[String: String]] else { return false }
        return appearances.contains { $0["appearance"] == "luminosity" && $0["value"] == "dark" }
    }) else {
        fatalError("\(colorName) needs a Dark appearance")
    }
}

let appTheme = try source("BeanLedger/Utilities/AppTheme.swift")
for colorName in requiredColors {
    require(
        "Color(\"\(colorName)\")",
        in: appTheme,
        "AppTheme must expose \(colorName) through the asset catalog"
    )
}

let scanRoots = [
    root.appendingPathComponent("BeanLedger/Utilities"),
    root.appendingPathComponent("BeanLedger/Views")
]
let forbiddenTokens = [
    "Color(hex:",
    ".ignoresSafeArea()"
]
let forbiddenStaticColorRegex = try NSRegularExpression(pattern: #"\.(white|black)\b"#)

for scanRoot in scanRoots {
    guard let enumerator = fileManager.enumerator(
        at: scanRoot,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: [.skipsHiddenFiles]
    ) else {
        continue
    }

    for case let fileURL as URL in enumerator where fileURL.pathExtension == "swift" {
        let contents = try String(contentsOf: fileURL, encoding: .utf8)
        for token in forbiddenTokens where contents.contains(token) {
            fatalError("\(relativePath(fileURL)) contains forbidden UI token: \(token)")
        }
        let fullRange = NSRange(contents.startIndex..., in: contents)
        if forbiddenStaticColorRegex.firstMatch(in: contents, range: fullRange) != nil {
            fatalError("\(relativePath(fileURL)) contains a hard-coded white or black color")
        }
    }
}

for protectedRoot in [
    "BeanLedger/Views/HomeView.swift",
    "BeanLedger/Views/RecordsView.swift",
    "BeanLedger/Views/StatsView.swift",
    "BeanLedger/Views/SettingsView.swift",
    "BeanLedger/Views/AIEntryView.swift"
] {
    require(
        ".protectsTopSafeArea()",
        in: try source(protectedRoot),
        "\(protectedRoot) must protect content from the status bar"
    )
}

print("DarkModeSafeAreaSourceTests passed")

func source(_ relativePath: String) throws -> String {
    try String(contentsOf: root.appendingPathComponent(relativePath), encoding: .utf8)
}

func require(_ token: String, in text: String, _ message: String) {
    guard text.contains(token) else {
        fatalError("\(message). Missing token: \(token)")
    }
}

func relativePath(_ url: URL) -> String {
    url.path.replacingOccurrences(of: root.path + "/", with: "")
}
