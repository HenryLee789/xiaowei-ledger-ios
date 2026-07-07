import Foundation

@MainActor
final class AIEntryViewModel: ObservableObject {
    @Published var inputText = ""
    @Published private(set) var isParsing = false
    @Published var parsedDraft: AIParsedLedgerDraft?
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
        parsedDraft = nil
        defer {
            isParsing = false
        }

        do {
            let result = try await service.parseLedgerText(inputText, settings: settings, apiKey: apiKey)
            parsedDraft = try AIParseResultValidator.validatedDraft(from: result, now: Date(), calendar: calendar)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cancelResult() {
        parsedDraft = nil
        errorMessage = nil
    }

    func clearAfterSave() {
        inputText = ""
        parsedDraft = nil
        errorMessage = nil
    }
}
