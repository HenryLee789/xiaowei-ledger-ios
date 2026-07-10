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
    private var loadFailureMessage: String?

    init(fileURL: URL? = BudgetStore.defaultFileURL, seedBudgets: [Budget] = []) {
        self.fileURL = fileURL
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        switch Self.loadBudgets(from: fileURL, decoder: decoder) {
        case .loaded(let loadedBudgets):
            budgets = loadedBudgets
        case .missing:
            budgets = seedBudgets
        case .failed(let message):
            budgets = seedBudgets
            loadFailureMessage = message
            lastErrorMessage = message
        }
    }

    static func inMemory(budgets: [Budget] = []) -> BudgetStore {
        BudgetStore(fileURL: nil, seedBudgets: budgets)
    }

    func upsert(month: String, category: String?, amount: Double) throws {
        guard amount >= 0 else { return }

        let previousBudgets = budgets
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
        do {
            try persist()
        } catch {
            budgets = previousBudgets
            throw error
        }
    }

    func clear() throws {
        let previousBudgets = budgets
        budgets.removeAll()
        do {
            try persist(allowReplacingCorruptFile: true)
        } catch {
            budgets = previousBudgets
            throw error
        }
    }

    func restore(_ snapshot: [Budget]) throws {
        let previousBudgets = budgets
        budgets = snapshot
        do {
            try persist(allowReplacingCorruptFile: true)
        } catch {
            budgets = previousBudgets
            throw error
        }
    }

    private func persist(allowReplacingCorruptFile: Bool = false) throws {
        guard let fileURL else { return }
        if let loadFailureMessage, !allowReplacingCorruptFile {
            throw JSONStorePersistenceError.corruptFileNeedsRecovery(loadFailureMessage)
        }

        do {
            let folderURL = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            let data = try encoder.encode(budgets)
            try data.write(to: fileURL, options: [.atomic])
            loadFailureMessage = nil
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
            throw error
        }
    }

    private static func loadBudgets(from fileURL: URL?, decoder: JSONDecoder) -> JSONStoreLoadResult<[Budget]> {
        guard let fileURL, FileManager.default.fileExists(atPath: fileURL.path) else {
            return .missing
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return .loaded(try decoder.decode([Budget].self, from: data))
        } catch {
            JSONCorruptionBackup.backupIfPresent(fileURL: fileURL)
            return .failed("预算 JSON 读取失败，已保留损坏文件备份；请先恢复数据后再继续写入。")
        }
    }
}
