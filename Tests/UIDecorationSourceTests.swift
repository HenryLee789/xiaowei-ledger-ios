import Foundation

try runUIDecorationSourceTests()

private func runUIDecorationSourceTests() throws {
    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let scanRoots = [
        root.appendingPathComponent("BeanLedger/Views"),
        root.appendingPathComponent("BeanLedger/Assets.xcassets")
    ]
    let forbiddenTokens = [
        "BowView",
        "hello_kitty_bow",
        "hello_kitty_icon",
        "case bow",
        "蝴蝶结"
    ]
    var violations: [String] = []
    let mascotAsset = root.appendingPathComponent("BeanLedger/Assets.xcassets/hello_kitty_mascot.imageset/hello_kitty_mascot.png")

    if !FileManager.default.fileExists(atPath: mascotAsset.path) {
        violations.append("Restore HelloKitty mascot asset: \(relativePath(mascotAsset, root: root))")
    }

    for scanRoot in scanRoots {
        guard let enumerator = FileManager.default.enumerator(
            at: scanRoot,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            continue
        }

        for case let fileURL as URL in enumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey])
            if resourceValues.isDirectory == true {
                if ["hello_kitty_bow.imageset", "hello_kitty_icon.imageset"].contains(fileURL.lastPathComponent) {
                    violations.append("Remove forbidden asset directory: \(relativePath(fileURL, root: root))")
                }
                continue
            }

            guard ["swift", "json"].contains(fileURL.pathExtension) else { continue }
            let contents = try String(contentsOf: fileURL, encoding: .utf8)

            for token in forbiddenTokens where contents.contains(token) {
                violations.append("\(relativePath(fileURL, root: root)) contains forbidden token \(token)")
            }
        }
    }

    if !violations.isEmpty {
        fatalError("Red bow decoration should not appear anywhere in app UI sources:\n\(violations.joined(separator: "\n"))")
    }

    print("UIDecorationSourceTests passed")
}

private func relativePath(_ url: URL, root: URL) -> String {
    url.path.replacingOccurrences(of: root.path + "/", with: "")
}
