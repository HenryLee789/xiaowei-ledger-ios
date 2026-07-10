import Foundation

enum JSONCorruptionBackup {
    static func backupIfPresent(fileURL: URL) {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return
        }

        let backupURL = fileURL.deletingLastPathComponent()
            .appendingPathComponent("\(fileURL.lastPathComponent).corrupt-\(timestamp())")
        try? FileManager.default.copyItem(at: fileURL, to: backupURL)
    }

    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }
}

enum JSONStoreLoadResult<Value> {
    case missing
    case loaded(Value)
    case failed(String)
}

enum JSONStorePersistenceError: LocalizedError {
    case corruptFileNeedsRecovery(String)

    var errorDescription: String? {
        switch self {
        case .corruptFileNeedsRecovery(let message):
            return message
        }
    }
}

@MainActor
final class LedgerStore: ObservableObject {
    nonisolated static var defaultFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("BeanLedgerRecords.json")
    }

    @Published private(set) var records: [LedgerRecord]
    @Published private(set) var lastErrorMessage: String?

    let fileURL: URL?

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var loadFailureMessage: String?

    init(fileURL: URL? = LedgerStore.defaultFileURL, seedRecords: [LedgerRecord] = []) {
        self.fileURL = fileURL
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        switch Self.loadRecords(from: fileURL, decoder: decoder) {
        case .loaded(let loadedRecords):
            self.records = loadedRecords
        case .missing:
            self.records = seedRecords
        case .failed(let message):
            self.records = seedRecords
            self.loadFailureMessage = message
            self.lastErrorMessage = message
        }
    }

    static func inMemory(records: [LedgerRecord] = []) -> LedgerStore {
        LedgerStore(fileURL: nil, seedRecords: records)
    }

    func add(_ record: LedgerRecord) throws {
        let previousRecords = records
        records.insert(record, at: 0)
        do {
            try persist()
        } catch {
            records = previousRecords
            throw error
        }
    }

    func add(_ newRecords: [LedgerRecord]) throws {
        guard !newRecords.isEmpty else { return }
        let previousRecords = records
        records.insert(contentsOf: newRecords, at: 0)
        do {
            try persist()
        } catch {
            records = previousRecords
            throw error
        }
    }

    func delete(recordID: UUID) throws {
        let previousRecords = records
        records.removeAll { $0.id == recordID }
        do {
            try persist()
        } catch {
            records = previousRecords
            throw error
        }
    }

    func clear() throws {
        let previousRecords = records
        records.removeAll()
        do {
            try persist(allowReplacingCorruptFile: true)
        } catch {
            records = previousRecords
            throw error
        }
    }

    func restore(_ snapshot: [LedgerRecord]) throws {
        let previousRecords = records
        records = snapshot
        do {
            try persist(allowReplacingCorruptFile: true)
        } catch {
            records = previousRecords
            throw error
        }
    }

    func reload() {
        switch Self.loadRecords(from: fileURL, decoder: decoder) {
        case .loaded(let loadedRecords):
            records = loadedRecords
            loadFailureMessage = nil
            lastErrorMessage = nil
        case .missing:
            break
        case .failed(let message):
            loadFailureMessage = message
            lastErrorMessage = message
        }
    }

    func exportJSONFile() throws -> URL {
        let exportURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("BeanLedger-\(Self.exportTimestamp()).json")
        let data = try exportJSONData()
        try data.write(to: exportURL, options: [.atomic])
        return exportURL
    }

    func exportJSONData() throws -> Data {
        if let loadFailureMessage {
            throw JSONStorePersistenceError.corruptFileNeedsRecovery(loadFailureMessage)
        }
        return try encoder.encode(records)
    }

    func persistentJSONFile() throws -> URL {
        guard let fileURL else {
            return try exportJSONFile()
        }

        try persist()
        return fileURL
    }

    private func persist(allowReplacingCorruptFile: Bool = false) throws {
        guard let fileURL else { return }
        if let loadFailureMessage, !allowReplacingCorruptFile {
            throw JSONStorePersistenceError.corruptFileNeedsRecovery(loadFailureMessage)
        }

        do {
            let folderURL = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            let data = try encoder.encode(records)
            try data.write(to: fileURL, options: [.atomic])
            loadFailureMessage = nil
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
            throw error
        }
    }

    private static func loadRecords(from fileURL: URL?, decoder: JSONDecoder) -> JSONStoreLoadResult<[LedgerRecord]> {
        guard let fileURL, FileManager.default.fileExists(atPath: fileURL.path) else {
            return .missing
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return .loaded(try decoder.decode([LedgerRecord].self, from: data))
        } catch {
            JSONCorruptionBackup.backupIfPresent(fileURL: fileURL)
            return .failed("账本 JSON 读取失败，已保留损坏文件备份；请先恢复数据后再继续写入。")
        }
    }

    private static func exportTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }
}
