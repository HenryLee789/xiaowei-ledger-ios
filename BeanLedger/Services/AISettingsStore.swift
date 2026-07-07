import Foundation
import Security

protocol AIAPIKeyStorage {
    func readAPIKey() throws -> String
    func saveAPIKey(_ apiKey: String) throws
    func deleteAPIKey() throws
}

enum AIKeychainError: LocalizedError {
    case unexpectedStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .unexpectedStatus:
            return "API Key 保存失败"
        }
    }
}

struct KeychainAIAPIKeyStorage: AIAPIKeyStorage {
    private let service = "com.henry.BeanLedger.ai"
    private let account = "api-key"

    func readAPIKey() throws -> String {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound {
            return ""
        }
        guard status == errSecSuccess else {
            throw AIKeychainError.unexpectedStatus(status)
        }
        guard let data = item as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            return ""
        }
        return apiKey
    }

    func saveAPIKey(_ apiKey: String) throws {
        if apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            try deleteAPIKey()
            return
        }

        let data = Data(apiKey.utf8)
        var query = baseQuery
        let updateAttributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }
        guard updateStatus == errSecItemNotFound else {
            throw AIKeychainError.unexpectedStatus(updateStatus)
        }

        let addAttributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        query.merge(addAttributes) { _, new in new }
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw AIKeychainError.unexpectedStatus(addStatus)
        }
    }

    func deleteAPIKey() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AIKeychainError.unexpectedStatus(status)
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

@MainActor
final class AISettingsStore: ObservableObject {
    @Published var settings: AISettings {
        didSet {
            persistSettings()
        }
    }
    @Published var apiKey: String
    @Published private(set) var availableModels: [AIModel] = []
    @Published private(set) var isFetchingModels = false
    @Published var modelListMessage: String?
    @Published var settingsMessage: String?

    private let userDefaults: UserDefaults
    private let apiKeyStorage: AIAPIKeyStorage
    private let service: AIService
    private let settingsKey = "BeanLedger.AISettings.v1"

    init(
        userDefaults: UserDefaults = .standard,
        apiKeyStorage: AIAPIKeyStorage = KeychainAIAPIKeyStorage(),
        service: AIService = AIService()
    ) {
        self.userDefaults = userDefaults
        self.apiKeyStorage = apiKeyStorage
        self.service = service

        var loadedSettings: AISettings
        if let data = userDefaults.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(AISettings.self, from: data) {
            loadedSettings = decoded
        } else {
            loadedSettings = AISettings()
        }

        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-BeanLedgerAIMock") {
            loadedSettings.enableMockParsing = true
        }
        #endif

        self.settings = loadedSettings
        self.apiKey = (try? apiKeyStorage.readAPIKey()) ?? ""
    }

    func saveAPIKey(_ newValue: String) {
        apiKey = newValue
        do {
            try apiKeyStorage.saveAPIKey(newValue)
            settingsMessage = newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "已清空 API Key" : "API Key 已保存到本机"
        } catch {
            settingsMessage = error.localizedDescription
        }
    }

    func usePrimaryBaseURL() {
        settings.apiBaseURL = AISettings.defaultAPIBaseURL
    }

    func useFallbackBaseURL() {
        settings.apiBaseURL = AISettings.defaultFallbackBaseURL
    }

    func fetchModels() async {
        isFetchingModels = true
        modelListMessage = nil
        defer {
            isFetchingModels = false
        }

        do {
            let models = try await service.fetchModels(settings: settings, apiKey: apiKey)
            availableModels = models
            if settings.selectedModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               let firstModel = models.first {
                settings.selectedModel = firstModel.id
            }
            modelListMessage = models.isEmpty ? "没有拉到模型，可手动输入" : "已拉取 \(models.count) 个模型"
        } catch {
            modelListMessage = error.localizedDescription
        }
    }

    private func persistSettings() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        userDefaults.set(data, forKey: settingsKey)
    }
}
