import Foundation

@MainActor
final class RecurringStore: ObservableObject {
    nonisolated static var defaultFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("BeanLedgerRecurringTemplates.json")
    }

    @Published private(set) var templates: [RecurringRecordTemplate]
    @Published private(set) var lastErrorMessage: String?

    let fileURL: URL?

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var loadFailureMessage: String?

    init(fileURL: URL? = RecurringStore.defaultFileURL, seedTemplates: [RecurringRecordTemplate] = []) {
        self.fileURL = fileURL
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        switch Self.loadTemplates(from: fileURL, decoder: decoder) {
        case .loaded(let loadedTemplates):
            templates = loadedTemplates
        case .missing:
            templates = seedTemplates
        case .failed(let message):
            templates = seedTemplates
            loadFailureMessage = message
            lastErrorMessage = message
        }
    }

    static func inMemory(templates: [RecurringRecordTemplate] = []) -> RecurringStore {
        RecurringStore(fileURL: nil, seedTemplates: templates)
    }

    func add(_ template: RecurringRecordTemplate) throws {
        let previousTemplates = templates
        templates.insert(template, at: 0)
        do {
            try persist()
        } catch {
            templates = previousTemplates
            throw error
        }
    }

    func update(_ template: RecurringRecordTemplate) throws {
        guard let index = templates.firstIndex(where: { $0.id == template.id }) else { return }
        let previousTemplates = templates
        templates[index] = template
        do {
            try persist()
        } catch {
            templates = previousTemplates
            throw error
        }
    }

    func delete(templateID: UUID) throws {
        let previousTemplates = templates
        templates.removeAll { $0.id == templateID }
        do {
            try persist()
        } catch {
            templates = previousTemplates
            throw error
        }
    }

    func clear() throws {
        let previousTemplates = templates
        templates.removeAll()
        do {
            try persist(allowReplacingCorruptFile: true)
        } catch {
            templates = previousTemplates
            throw error
        }
    }

    func restore(_ snapshot: [RecurringRecordTemplate]) throws {
        let previousTemplates = templates
        templates = snapshot
        do {
            try persist(allowReplacingCorruptFile: true)
        } catch {
            templates = previousTemplates
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
            let data = try encoder.encode(templates)
            try data.write(to: fileURL, options: [.atomic])
            loadFailureMessage = nil
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
            throw error
        }
    }

    private static func loadTemplates(from fileURL: URL?, decoder: JSONDecoder) -> JSONStoreLoadResult<[RecurringRecordTemplate]> {
        guard let fileURL, FileManager.default.fileExists(atPath: fileURL.path) else {
            return .missing
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return .loaded(try decoder.decode([RecurringRecordTemplate].self, from: data))
        } catch {
            JSONCorruptionBackup.backupIfPresent(fileURL: fileURL)
            return .failed("周期模板 JSON 读取失败，已保留损坏文件备份；请先恢复数据后再继续写入。")
        }
    }
}
