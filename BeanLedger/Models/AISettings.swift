import Foundation

struct AISettings: Codable, Equatable {
    static let defaultAPIBaseURL = ""
    static let defaultFallbackBaseURL = ""
    static let apiBaseURLPlaceholder = "例如 https://api.openai.com/v1"
    static let fallbackBaseURLPlaceholder = "可选，例如 https://api.openai.com/v1"

    var apiBaseURL: String
    var fallbackBaseURL: String
    var selectedModel: String
    var useFallbackWhenPrimaryFails: Bool
    var enableMockParsing: Bool

    init(
        apiBaseURL: String = AISettings.defaultAPIBaseURL,
        fallbackBaseURL: String = AISettings.defaultFallbackBaseURL,
        selectedModel: String = "",
        useFallbackWhenPrimaryFails: Bool = false,
        enableMockParsing: Bool = false
    ) {
        self.apiBaseURL = apiBaseURL
        self.fallbackBaseURL = fallbackBaseURL
        self.selectedModel = selectedModel
        self.useFallbackWhenPrimaryFails = useFallbackWhenPrimaryFails
        self.enableMockParsing = enableMockParsing
    }

    var hasConfiguredBaseURL: Bool {
        !apiBaseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
