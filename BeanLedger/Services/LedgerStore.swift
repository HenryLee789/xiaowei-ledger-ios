import Foundation

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

    init(fileURL: URL? = LedgerStore.defaultFileURL, seedRecords: [LedgerRecord] = []) {
        self.fileURL = fileURL
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        if let loadedRecords = Self.loadRecords(from: fileURL, decoder: decoder) {
            self.records = loadedRecords
        } else {
            self.records = seedRecords
        }
    }

    static func inMemory(records: [LedgerRecord] = []) -> LedgerStore {
        LedgerStore(fileURL: nil, seedRecords: records)
    }

    func add(_ record: LedgerRecord) throws {
        records.insert(record, at: 0)
        try persist()
    }

    func delete(recordID: UUID) throws {
        records.removeAll { $0.id == recordID }
        try persist()
    }

    func clear() throws {
        records.removeAll()
        try persist()
    }

    func reload() {
        if let loadedRecords = Self.loadRecords(from: fileURL, decoder: decoder) {
            records = loadedRecords
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
        try encoder.encode(records)
    }

    func persistentJSONFile() throws -> URL {
        guard let fileURL else {
            return try exportJSONFile()
        }

        try persist()
        return fileURL
    }

    private func persist() throws {
        guard let fileURL else { return }

        do {
            let folderURL = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            let data = try encoder.encode(records)
            try data.write(to: fileURL, options: [.atomic])
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
            throw error
        }
    }

    private static func loadRecords(from fileURL: URL?, decoder: JSONDecoder) -> [LedgerRecord]? {
        guard let fileURL, FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode([LedgerRecord].self, from: data)
        } catch {
            return []
        }
    }

    private static func exportTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }
}
