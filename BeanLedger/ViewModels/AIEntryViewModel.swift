import Foundation

@MainActor
final class AIEntryViewModel: ObservableObject {
    @Published var inputText = ""
    @Published private(set) var isParsing = false
    @Published var parsedDrafts: [AIParsedLedgerDraft] = []
    @Published var errorMessage: String?

    private let service: AIService
    private let calendar: Calendar

    init(service: AIService = AIService(), calendar: Calendar = .current) {
        self.service = service
        self.calendar = calendar
    }

    func parse(settings: AISettings, apiKey: String) async {
        isParsing = true
        errorMessage = nil
        parsedDrafts = []
        defer {
            isParsing = false
        }

        do {
            let results = try await service.parseLedgerText(inputText, settings: settings, apiKey: apiKey)
            let drafts = try AIParseResultValidator.validatedDrafts(from: results, now: Date(), calendar: calendar)
            if drafts.isEmpty {
                errorMessage = "没有识别到账单"
            } else {
                parsedDrafts = drafts
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cancelResult() {
        parsedDrafts = []
        errorMessage = nil
    }

    func updateDraft(_ draft: AIParsedLedgerDraft, at index: Int) {
        guard parsedDrafts.indices.contains(index) else { return }
        parsedDrafts[index] = draft
        errorMessage = nil
    }

    func clearAfterSave() {
        inputText = ""
        parsedDrafts = []
        errorMessage = nil
    }
}
