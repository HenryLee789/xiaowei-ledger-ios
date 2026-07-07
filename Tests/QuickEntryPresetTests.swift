import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let quickEntryURL = root.appendingPathComponent("BeanLedger/Views/QuickEntryView.swift")
let source = try String(contentsOf: quickEntryURL, encoding: .utf8)

assertContains("@State private var selectedAmount: Double? = 50", "quick entry should default to the first requested amount")
assertContains("@State private var selectedCategory = \"燃气费\"", "quick entry should default to the first requested category")
assertContains("private let amounts: [Double] = [50, 100, 150, 200, 300, 400, 500, 2700]", "quick entry amounts should match the requested presets")
assertContains("private let categories = [\"燃气费\", \"电费\", \"房租\"]", "quick entry categories should only include the requested utility presets")

let forbiddenPresetTokens = [
    "private let categories = [\"餐饮\"",
    "\"交通\"",
    "\"购物\"",
    "\"工资\"",
    "\"存钱\""
]

for token in forbiddenPresetTokens where source.contains(token) {
    fatalError("quick entry should not keep old preset category token: \(token)")
}

print("QuickEntryPresetTests passed")

private func assertContains(_ token: String, _ message: String) {
    if !source.contains(token) {
        fatalError("\(message). Missing token: \(token)")
    }
}
