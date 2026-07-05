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

    init(fileURL: URL? = RecurringStore.defaultFileURL, seedTemplates: [RecurringRecordTemplate] = []) {
        self.fileURL = fileURL
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        if let loadedTemplates = Self.loadTemplates(from: fileURL, decoder: decoder) {
            templates = loadedTemplates
        } else {
            templates = seedTemplates
        }
    }

    static func inMemory(templates: [RecurringRecordTemplate] = []) -> RecurringStore {
        RecurringStore(fileURL: nil, seedTemplates: templates)
    }

    func add(_ template: RecurringRecordTemplate) throws {
        templates.insert(template, at: 0)
        try persist()
    }

    func update(_ template: RecurringRecordTemplate) throws {
        guard let index = templates.firstIndex(where: { $0.id == template.id }) else { return }
        templates[index] = template
        try persist()
    }

    func delete(templateID: UUID) throws {
        templates.removeAll { $0.id == templateID }
        try persist()
    }

    private func persist() throws {
        guard let fileURL else { return }

        do {
            let folderURL = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            let data = try encoder.encode(templates)
            try data.write(to: fileURL, options: [.atomic])
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
            throw error
        }
    }

    private static func loadTemplates(from fileURL: URL?, decoder: JSONDecoder) -> [RecurringRecordTemplate]? {
        guard let fileURL, FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode([RecurringRecordTemplate].self, from: data)
        } catch {
            return []
        }
    }
}

