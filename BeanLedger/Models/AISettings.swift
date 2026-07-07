import Foundation

struct AISettings: Codable, Equatable {
    static let defaultAPIBaseURL = "https://cc.zaizai.pet:8888/v1"
    static let defaultFallbackBaseURL = "https://cc.zaizai.uno:8888/v1"

    var apiBaseURL: String
    var fallbackBaseURL: String
    var selectedModel: String
    var useFallbackWhenPrimaryFails: Bool
    var enableMockParsing: Bool

    init(
        apiBaseURL: String = AISettings.defaultAPIBaseURL,
        fallbackBaseURL: String = AISettings.defaultFallbackBaseURL,
        selectedModel: String = "",
        useFallbackWhenPrimaryFails: Bool = true,
        enableMockParsing: Bool = false
    ) {
        self.apiBaseURL = apiBaseURL
        self.fallbackBaseURL = fallbackBaseURL
        self.selectedModel = selectedModel
        self.useFallbackWhenPrimaryFails = useFallbackWhenPrimaryFails
        self.enableMockParsing = enableMockParsing
    }
}
