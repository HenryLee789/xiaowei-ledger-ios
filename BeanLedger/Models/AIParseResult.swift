import Foundation

struct AIParseResult: Codable, Equatable {
    var amount: Double?
    var type: LedgerType?
    var category: String?
    var note: String
    var dateText: String
    var confidence: Double?
    var needsConfirmation: Bool
    var questions: [String]

    init(
        amount: Double?,
        type: LedgerType?,
        category: String?,
        note: String,
        dateText: String,
        confidence: Double?,
        needsConfirmation: Bool,
        questions: [String]
    ) {
        self.amount = amount
        self.type = type
        self.category = category
        self.note = note
        self.dateText = dateText
        self.confidence = confidence
        self.needsConfirmation = needsConfirmation
        self.questions = questions
    }

    enum CodingKeys: String, CodingKey {
        case amount
        case type
        case category
        case note
        case dateText
        case confidence
        case needsConfirmation
        case questions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        amount = Self.decodeOptionalDouble(for: .amount, from: container)
        confidence = Self.decodeOptionalDouble(for: .confidence, from: container)

        if let typeValue = try? container.decodeIfPresent(String.self, forKey: .type) {
            type = LedgerType(rawValue: typeValue)
        } else {
            type = nil
        }

        category = try? container.decodeIfPresent(String.self, forKey: .category)
        note = (try? container.decodeIfPresent(String.self, forKey: .note)) ?? ""
        dateText = (try? container.decodeIfPresent(String.self, forKey: .dateText)) ?? "今天"
        needsConfirmation = (try? container.decodeIfPresent(Bool.self, forKey: .needsConfirmation)) ?? true
        questions = (try? container.decodeIfPresent([String].self, forKey: .questions)) ?? []
    }

    private static func decodeOptionalDouble(for key: CodingKeys, from container: KeyedDecodingContainer<CodingKeys>) -> Double? {
        if let value = try? container.decodeIfPresent(Double.self, forKey: key) {
            return value
        }
        if let text = try? container.decodeIfPresent(String.self, forKey: key) {
            return Double(text.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }
}

enum AIEntryExamples {
    static let prompts = [
        "早餐包子豆浆12",
        "午饭花了28",
        "地铁通勤6",
        "打车去客户那边42.8",
        "超市买日用品136.5",
        "奶茶18",
        "工资到账8500",
        "报销餐费128",
        "存500到备用金",
        "还信用卡1200",
        "工资8500，午饭28，打车42.8"
    ]
}

enum AIParsePayload {
    static func decodeResults(from data: Data) throws -> [AIParseResult] {
        let decoder = JSONDecoder()

        if let envelope = try? decoder.decode(AIParseRecordsEnvelope.self, from: data),
           let records = envelope.decodedRecords {
            return records
        }

        if let records = try? decoder.decode([AIParseResult].self, from: data) {
            return records
        }

        return [try decoder.decode(AIParseResult.self, from: data)]
    }
}

private struct AIParseRecordsEnvelope: Decodable {
    var records: [AIParseResult]?
    var items: [AIParseResult]?
    var transactions: [AIParseResult]?
    var entries: [AIParseResult]?
    var results: [AIParseResult]?

    var decodedRecords: [AIParseResult]? {
        for candidate in [records, items, transactions, entries, results] {
            if let candidate {
                return candidate
            }
        }
        return nil
    }
}

struct AIParsedLedgerDraft: Equatable {
    var amount: Double
    var type: LedgerType
    var category: String
    var note: String
    var date: Date
    var dateText: String
    var confidence: Double
    var questions: [String]
}

enum AIParseValidationError: LocalizedError, Equatable {
    case missingAmount
    case missingType

    var errorDescription: String? {
        switch self {
        case .missingAmount:
            return "请补充金额"
        case .missingType:
            return "请补充收支类型"
        }
    }
}

enum AIParseResultValidator {
    static func validatedDrafts(
        from results: [AIParseResult],
        now: Date = Date(),
        calendar: Calendar = .current
    ) throws -> [AIParsedLedgerDraft] {
        try results.map {
            try validatedDraft(from: $0, now: now, calendar: calendar)
        }
    }

    static func validatedDraft(
        from result: AIParseResult,
        now: Date = Date(),
        calendar: Calendar = .current
    ) throws -> AIParsedLedgerDraft {
        guard let amount = result.amount, amount > 0 else {
            throw AIParseValidationError.missingAmount
        }
        guard let type = result.type else {
            throw AIParseValidationError.missingType
        }

        let cleanedCategory = result.category?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let category = type.categories.contains(cleanedCategory) ? cleanedCategory : type.fallbackCategory
        let cleanedNote = result.note.trimmingCharacters(in: .whitespacesAndNewlines)
        let note = String(cleanedNote.prefix(60))
        let dateText = result.dateText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "今天" : result.dateText
        let confidence = min(max(result.confidence ?? 0.7, 0), 1)

        return AIParsedLedgerDraft(
            amount: amount,
            type: type,
            category: category,
            note: note,
            date: NaturalLanguageDateParser.parse(dateText, now: now, calendar: calendar),
            dateText: dateText,
            confidence: confidence,
            questions: result.questions
        )
    }
}

enum AIResponseJSONExtractor {
    enum ExtractionError: LocalizedError {
        case missingJSONObject

        var errorDescription: String? {
            switch self {
            case .missingJSONObject:
                return "模型返回的内容不是 JSON"
            }
        }
    }

    static func extractJSONData(from content: String) throws -> Data {
        try Data(extractJSONString(from: content).utf8)
    }

    static func extractJSONString(from content: String) throws -> String {
        let cleaned = content
            .replacingOccurrences(of: "```json", with: "```", options: [.caseInsensitive])
            .replacingOccurrences(of: "```JSON", with: "```")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.hasPrefix("```"),
           let firstNewline = cleaned.firstIndex(of: "\n"),
           let closingRange = cleaned.range(of: "```", options: .backwards),
           closingRange.lowerBound > firstNewline {
            return String(cleaned[firstNewline..<closingRange.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let objectStart = cleaned.firstIndex(of: "{")
        let arrayStart = cleaned.firstIndex(of: "[")
        let start: String.Index?
        let closingCharacter: Character

        switch (objectStart, arrayStart) {
        case let (object?, array?):
            if object < array {
                start = object
                closingCharacter = "}"
            } else {
                start = array
                closingCharacter = "]"
            }
        case let (object?, nil):
            start = object
            closingCharacter = "}"
        case let (nil, array?):
            start = array
            closingCharacter = "]"
        case (nil, nil):
            start = nil
            closingCharacter = "}"
        }

        guard let start,
              let end = cleaned.lastIndex(of: closingCharacter),
              start <= end else {
            throw ExtractionError.missingJSONObject
        }
        return String(cleaned[start...end])
    }
}

private extension LedgerType {
    var fallbackCategory: String {
        switch self {
        case .expense:
            return "其他出账"
        case .income:
            return "其他入账"
        case .saving:
            return "其他攒豆豆"
        case .debt:
            return "其他借贷"
        }
    }
}
