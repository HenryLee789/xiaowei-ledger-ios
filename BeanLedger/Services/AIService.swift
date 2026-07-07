import Foundation

struct AIService {
    enum ServiceError: LocalizedError {
        case missingAPIKey
        case missingModel
        case emptyInput
        case invalidBaseURL
        case requestFailed(String)
        case fallbackFailed(primary: String, fallback: String)
        case httpStatus(Int, String)
        case missingContent
        case invalidJSON

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "请先在设置里填写 API Key"
            case .missingModel:
                return "请先选择或填写模型"
            case .emptyInput:
                return "先说说这笔账吧"
            case .invalidBaseURL:
                return "API 地址不正确"
            case .requestFailed(let message):
                return "网络请求失败：\(message)"
            case .fallbackFailed(let primary, let fallback):
                return "主地址失败：\(primary)；备用地址失败：\(fallback)"
            case .httpStatus(let statusCode, let body):
                if body.isEmpty {
                    return "API 返回错误：\(statusCode)"
                }
                return "API 返回错误：\(statusCode)，\(body)"
            case .missingContent:
                return "模型没有返回解析结果"
            case .invalidJSON:
                return "模型返回的内容不是 JSON"
            }
        }
    }

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func parseLedgerText(_ input: String, settings: AISettings, apiKey: String) async throws -> [AIParseResult] {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else {
            throw ServiceError.emptyInput
        }

        #if DEBUG
        if settings.enableMockParsing {
            return Self.mockParseResults(for: trimmedInput)
        }
        #endif

        try validateCredentials(settings: settings, apiKey: apiKey, needsModel: true)
        let content = try await performWithFallback(settings: settings) { baseURL in
            try await requestChatCompletion(input: trimmedInput, baseURL: baseURL, settings: settings, apiKey: apiKey)
        }
        do {
            let data = try AIResponseJSONExtractor.extractJSONData(from: content)
            return try AIParsePayload.decodeResults(from: data)
        } catch is AIResponseJSONExtractor.ExtractionError {
            throw ServiceError.invalidJSON
        } catch {
            throw ServiceError.invalidJSON
        }
    }

    func fetchModels(settings: AISettings, apiKey: String) async throws -> [AIModel] {
        try validateCredentials(settings: settings, apiKey: apiKey, needsModel: false)
        return try await performWithFallback(settings: settings) { baseURL in
            let url = try endpointURL(baseURL: baseURL, pathComponents: ["models"])
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            let response: ModelsResponse = try await decodedResponse(for: request)
            return response.data
                .map { AIModel(id: $0.id) }
                .filter { !$0.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        }
    }

    private func validateCredentials(settings: AISettings, apiKey: String, needsModel: Bool) throws {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ServiceError.missingAPIKey
        }
        if needsModel, settings.selectedModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ServiceError.missingModel
        }
    }

    private func performWithFallback<T>(
        settings: AISettings,
        operation: (String) async throws -> T
    ) async throws -> T {
        let primaryBaseURL = settings.apiBaseURL
        do {
            return try await operation(primaryBaseURL)
        } catch {
            let primaryError = error
            guard settings.useFallbackWhenPrimaryFails,
                  normalizedBaseURL(settings.fallbackBaseURL) != normalizedBaseURL(primaryBaseURL) else {
                throw error
            }
            do {
                return try await operation(settings.fallbackBaseURL)
            } catch {
                let fallbackError = error
                let primaryMessage = (primaryError as? LocalizedError)?.errorDescription ?? primaryError.localizedDescription
                let fallbackMessage = (fallbackError as? LocalizedError)?.errorDescription ?? fallbackError.localizedDescription
                throw ServiceError.fallbackFailed(primary: primaryMessage, fallback: fallbackMessage)
            }
        }
    }

    private func requestChatCompletion(
        input: String,
        baseURL: String,
        settings: AISettings,
        apiKey: String
    ) async throws -> String {
        let url = try endpointURL(baseURL: baseURL, pathComponents: ["chat", "completions"])
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            ChatCompletionRequest(
                model: settings.selectedModel.trimmingCharacters(in: .whitespacesAndNewlines),
                messages: [
                    .init(role: "system", content: Self.systemPrompt),
                    .init(role: "user", content: input)
                ],
                temperature: 0.1
            )
        )

        let response: ChatCompletionResponse = try await decodedResponse(for: request)
        guard let content = response.choices.first?.message.content,
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ServiceError.missingContent
        }
        return content
    }

    private func decodedResponse<T: Decodable>(for request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ServiceError.requestFailed(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.requestFailed("没有收到有效响应")
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8)
                .map { String($0.prefix(160)) } ?? ""
            throw ServiceError.httpStatus(httpResponse.statusCode, body)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw ServiceError.invalidJSON
        }
    }

    private func endpointURL(baseURL: String, pathComponents: [String]) throws -> URL {
        guard var url = URL(string: normalizedBaseURL(baseURL)),
              url.scheme?.hasPrefix("http") == true,
              url.host != nil else {
            throw ServiceError.invalidBaseURL
        }

        for component in pathComponents {
            url.appendPathComponent(component)
        }
        return url
    }

    private func normalizedBaseURL(_ baseURL: String) -> String {
        var text = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        while text.hasSuffix("/") {
            text.removeLast()
        }
        return text
    }
}

private extension AIService {
    static let systemPrompt = """
    你是“小魏记账簿”的自然语言记账解析助手。请把用户输入解析成记账 JSON。只能输出 JSON，不要输出 Markdown，不要解释。

    JSON schema:
    {
      "records": [
        {
          "amount": 28.0,
          "type": "expense",
          "category": "餐饮",
          "note": "兰州拉面",
          "dateText": "今天中午",
          "confidence": 0.92,
          "needsConfirmation": true,
          "questions": []
        }
      ],
      "needsConfirmation": true,
      "questions": []
    }

    如果用户一句话里包含多笔互相独立的账，例如“发了工资，又买了外卖”，必须在 records 里按发生顺序返回多条记录；不要合并金额，不要丢弃其中任何一笔，也不要限制 records 数量。type 只能是 expense、income、saving、debt。amount 必须是正数；无法识别时设为 null。category 只能映射到现有类目：出账：餐饮、交通、购物、生活缴费、娱乐、医疗、房租、其他出账；入账：工资、副业、红包、报销、投资收益、其他入账；攒豆豆：存钱、目标储蓄、备用金、理财转入、其他攒豆豆；借贷：借出、借入、还款、收回借款、信用卡、花呗 / 白条、其他借贷。每条记录和顶层 needsConfirmation 都固定 true。
    """

    static func mockParseResults(for input: String) -> [AIParseResult] {
        let clauses = mockClauses(for: input)
        if clauses.count > 1 {
            return clauses.map { mockParseResult(for: $0) }
        }

        let contexts = amountContexts(in: input)
        if contexts.count > 1 {
            return contexts.map { context in
                let mapping = mockTypeAndCategory(for: context.text)
                return AIParseResult(
                    amount: context.amount,
                    type: mapping.type,
                    category: mapping.category,
                    note: mockNote(for: context.text, type: mapping.type, category: mapping.category),
                    dateText: mockDateText(for: context.text),
                    confidence: 0.86,
                    needsConfirmation: true,
                    questions: []
                )
            }
        }

        return [mockParseResult(for: input)]
    }

    static func mockParseResult(for input: String) -> AIParseResult {
        let amount = firstAmount(in: input)
        let mapping = mockTypeAndCategory(for: input)
        let note = mockNote(for: input, type: mapping.type, category: mapping.category)
        return AIParseResult(
            amount: amount,
            type: mapping.type,
            category: mapping.category,
            note: note,
            dateText: mockDateText(for: input),
            confidence: amount == nil ? 0.35 : 0.86,
            needsConfirmation: true,
            questions: amount == nil ? ["请补充金额"] : []
        )
    }

    static func mockClauses(for input: String) -> [String] {
        var normalized = input
            .replacingOccurrences(of: "，", with: "\n")
            .replacingOccurrences(of: ",", with: "\n")
            .replacingOccurrences(of: "；", with: "\n")
            .replacingOccurrences(of: ";", with: "\n")
            .replacingOccurrences(of: "。", with: "\n")
            .replacingOccurrences(of: "\n又", with: "\n")
            .replacingOccurrences(of: "\n然后", with: "\n")
            .replacingOccurrences(of: "\n还", with: "\n")

        if amountContexts(in: normalized).count > 1 {
            normalized = normalized
                .replacingOccurrences(of: "又", with: "\n")
                .replacingOccurrences(of: "然后", with: "\n")
        }

        return normalized
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && firstAmount(in: $0) != nil }
    }

    static func amountContexts(in input: String) -> [(amount: Double, text: String)] {
        let pattern = #"(\d+(?:\.\d+)?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        let matches = regex.matches(in: input, range: NSRange(input.startIndex..., in: input))
        return matches.compactMap { match in
            guard let amountRange = Range(match.range(at: 1), in: input),
                  let amount = Double(input[amountRange]) else {
                return nil
            }

            let lowerBound = input.index(amountRange.lowerBound, offsetBy: -12, limitedBy: input.startIndex) ?? input.startIndex
            let upperBound = input.index(amountRange.upperBound, offsetBy: 12, limitedBy: input.endIndex) ?? input.endIndex
            return (amount, String(input[lowerBound..<upperBound]))
        }
    }

    static func firstAmount(in input: String) -> Double? {
        let pattern = #"(\d+(?:\.\d+)?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)),
              let range = Range(match.range(at: 1), in: input) else {
            return nil
        }
        return Double(input[range])
    }

    static func mockTypeAndCategory(for input: String) -> (type: LedgerType?, category: String?) {
        if input.contains("工资") || input.contains("到账") || input.contains("收入") {
            return (.income, "工资")
        }
        if input.contains("攒豆豆") || input.contains("存了") || input.contains("存钱") || input.contains("攒钱") {
            return (.saving, "存钱")
        }
        if input.contains("信用卡") {
            return (.debt, "信用卡")
        }
        if input.contains("还款") || input.contains("还钱") {
            return (.debt, "还款")
        }
        if input.contains("地铁") || input.contains("公交") || input.contains("打车") {
            return (.expense, "交通")
        }
        if input.contains("药") || input.contains("医院") {
            return (.expense, "医疗")
        }
        if input.contains("饭") || input.contains("餐") || input.contains("面") || input.contains("咖啡") || input.contains("奶茶") || input.contains("外卖") {
            return (.expense, "餐饮")
        }
        return (.expense, "其他出账")
    }

    static func mockNote(for input: String, type: LedgerType?, category: String?) -> String {
        if let remarkRange = input.range(of: "备注") {
            return String(input[remarkRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if category == "餐饮", input.contains("兰州拉面") {
            return "兰州拉面"
        }
        if category == "餐饮", input.contains("豫小七") {
            return "豫小七外卖"
        }
        if type == .income, input.contains("发") && input.contains("工资") {
            return "今天发工资"
        }
        if type == .income {
            return "工资到账"
        }
        if type == .saving {
            return "存钱"
        }
        if category == "信用卡" {
            return "还信用卡"
        }
        return input
    }

    static func mockDateText(for input: String) -> String {
        if input.contains("前天") { return input.contains("晚上") ? "前天晚上" : "前天" }
        if input.contains("昨天") { return input.contains("晚上") ? "昨天晚上" : "昨天" }
        if input.contains("中午") { return "今天中午" }
        if input.contains("晚上") { return "今天晚上" }
        return "今天"
    }

    struct ChatCompletionRequest: Encodable {
        let model: String
        let messages: [Message]
        let temperature: Double

        struct Message: Encodable {
            let role: String
            let content: String
        }
    }

    struct ChatCompletionResponse: Decodable {
        let choices: [Choice]

        struct Choice: Decodable {
            let message: Message
        }

        struct Message: Decodable {
            let content: String?
        }
    }

    struct ModelsResponse: Decodable {
        let data: [Model]

        struct Model: Decodable {
            let id: String
        }
    }
}
