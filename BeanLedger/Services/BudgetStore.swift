import Foundation

@MainActor
final class BudgetStore: ObservableObject {
    nonisolated static var defaultFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("BeanLedgerBudgets.json")
    }

    @Published private(set) var budgets: [Budget]
    @Published private(set) var lastErrorMessage: String?

    let fileURL: URL?

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileURL: URL? = BudgetStore.defaultFileURL, seedBudgets: [Budget] = []) {
        self.fileURL = fileURL
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        if let loadedBudgets = Self.loadBudgets(from: fileURL, decoder: decoder) {
            budgets = loadedBudgets
        } else {
            budgets = seedBudgets
        }
    }

    static func inMemory(budgets: [Budget] = []) -> BudgetStore {
        BudgetStore(fileURL: nil, seedBudgets: budgets)
    }

    func upsert(month: String, category: String?, amount: Double) throws {
        guard amount >= 0 else { return }

        if let index = budgets.firstIndex(where: { $0.month == month && $0.category == category }) {
            budgets[index].amount = amount
            budgets[index].updatedAt = Date()
        } else {
            budgets.append(Budget(month: month, category: category, amount: amount))
        }

        budgets.sort { lhs, rhs in
            switch (lhs.category, rhs.category) {
            case (nil, _?):
                return true
            case (_?, nil):
                return false
            default:
                return (lhs.category ?? "") < (rhs.category ?? "")
            }
        }
        try persist()
    }

    func clear() throws {
        budgets.removeAll()
        try persist()
    }

    private func persist() throws {
        guard let fileURL else { return }

        do {
            let folderURL = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            let data = try encoder.encode(budgets)
            try data.write(to: fileURL, options: [.atomic])
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
            throw error
        }
    }

    private static func loadBudgets(from fileURL: URL?, decoder: JSONDecoder) -> [Budget]? {
        guard let fileURL, FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode([Budget].self, from: data)
        } catch {
            return []
        }
    }
}

