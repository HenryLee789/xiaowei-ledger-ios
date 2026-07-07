import Foundation

@main
struct Stage2LedgerLogicTests {
    @MainActor
    static func main() throws {
        try testDefaultStoreStartsEmpty()
        try testStorePersistsAddDeleteAndClear()
        try testViewModelAddsRecordsAndCalculatesTotals()
        try testDisplayAmountSigns()
        try testAIResponseJSONExtractorHandlesMarkdown()
        try testAIParseResultValidationFallsBackAndTruncates()
        try testAIParseResultValidationRequiresAmountAndType()
        try testNaturalLanguageDateParserHandlesRelativeAndSpecificDates()
        try testViewModelAddsConfirmedAIRecord()
        print("Stage2LedgerLogicTests passed")
    }

    @MainActor
    private static func testDefaultStoreStartsEmpty() throws {
        let store = LedgerStore.inMemory(records: [])
        assertEqual(store.records.count, 0, "in-memory store should start empty when no records are provided")
    }

    @MainActor
    private static func testStorePersistsAddDeleteAndClear() throws {
        let fileURL = temporaryLedgerURL()
        try? FileManager.default.removeItem(at: fileURL)

        let record = LedgerRecord(
            amount: 18.5,
            type: .expense,
            category: "餐饮",
            note: "测试午餐",
            date: fixedDate(day: 5, hour: 12)
        )

        let store = LedgerStore(fileURL: fileURL)
        assertEqual(store.records.count, 0, "new file-backed store should start empty")

        try store.add(record)
        let reloaded = LedgerStore(fileURL: fileURL)
        assertEqual(reloaded.records.count, 1, "store should reload saved JSON records")
        assertEqual(reloaded.records[0].note, "测试午餐", "stored note should round-trip through JSON")

        try reloaded.delete(recordID: record.id)
        let afterDelete = LedgerStore(fileURL: fileURL)
        assertEqual(afterDelete.records.count, 0, "deleted record should be removed from persisted JSON")

        try afterDelete.add(record)
        try afterDelete.clear()
        let afterClear = LedgerStore(fileURL: fileURL)
        assertEqual(afterClear.records.count, 0, "clear should persist an empty record list")
    }

    @MainActor
    private static func testViewModelAddsRecordsAndCalculatesTotals() throws {
        let fileURL = temporaryLedgerURL()
        try? FileManager.default.removeItem(at: fileURL)
        let store = LedgerStore(fileURL: fileURL)
        let viewModel = LedgerViewModel(store: store, calendar: calendar)
        let today = Date()

        try viewModel.addRecord(amount: 30, type: .expense, category: "餐饮", note: "早餐", date: today)
        try viewModel.addRecord(amount: 200, type: .income, category: "红包", note: "红包", date: today)
        try viewModel.addRecord(amount: 80, type: .saving, category: "存钱", note: "小罐子", date: today)
        try viewModel.addRecord(amount: 50, type: .debt, category: "借出", note: "借出", date: today)
        try viewModel.addRecord(amount: 20, type: .debt, category: "借入", note: "借入", date: today)

        assertEqual(viewModel.records.count, 5, "view model should contain added records")
        assertEqual(viewModel.todayExpenseTotal, 30, "today expense total should use real records")
        assertEqual(viewModel.todayIncomeTotal, 200, "today income total should use real records")
        assertEqual(viewModel.monthExpenseTotal, 30, "monthly expense total should use real records")
        assertEqual(viewModel.monthIncomeTotal, 200, "monthly income total should use real records")
        assertEqual(viewModel.savingTotal, 80, "saving total should use real records")
        assertEqual(viewModel.debtNetTotal, -30, "debt net should apply debt category directions")

        guard let first = viewModel.records.first else {
            throw TestFailure("expected records to exist before delete")
        }
        try viewModel.delete(first)
        assertEqual(viewModel.records.count, 4, "delete should remove one record")

        let reloaded = LedgerStore(fileURL: fileURL)
        assertEqual(reloaded.records.count, 4, "delete should persist through JSON")
    }

    @MainActor
    private static func testDisplayAmountSigns() throws {
        let viewModel = LedgerViewModel(records: [], calendar: calendar)
        let date = fixedDate(day: 5, hour: 8)

        assertEqual(
            viewModel.displayAmount(for: LedgerRecord(amount: 28, type: .expense, category: "餐饮", note: "", date: date)),
            "-¥28.00",
            "expense records should display a negative currency sign"
        )
        assertEqual(
            viewModel.displayAmount(for: LedgerRecord(amount: 3500, type: .income, category: "工资", note: "", date: date)),
            "+¥3,500.00",
            "income records should display a positive currency sign"
        )
        assertEqual(
            viewModel.displayAmount(for: LedgerRecord(amount: 500, type: .saving, category: "存钱", note: "", date: date)),
            "+¥500.00",
            "saving records should display a positive currency sign"
        )
        assertEqual(
            viewModel.displayAmount(for: LedgerRecord(amount: 120, type: .debt, category: "借入", note: "", date: date)),
            "+¥120.00",
            "positive debt categories should display a positive currency sign"
        )
        assertEqual(
            viewModel.displayAmount(for: LedgerRecord(amount: 80, type: .debt, category: "还款", note: "", date: date)),
            "-¥80.00",
            "negative debt categories should display a negative currency sign"
        )
        assertEqual(
            viewModel.displayAmount(for: LedgerRecord(amount: 60, type: .debt, category: "其他借贷", note: "", date: date)),
            "¥60.00",
            "neutral debt categories should not force a positive or negative sign"
        )
    }

    private static func testAIResponseJSONExtractorHandlesMarkdown() throws {
        let content = """
        ```json
        {
          "amount": 28,
          "type": "expense",
          "category": "餐饮",
          "note": "兰州拉面",
          "dateText": "今天中午",
          "confidence": 0.92,
          "needsConfirmation": true,
          "questions": []
        }
        ```
        """

        let data = try AIResponseJSONExtractor.extractJSONData(from: content)
        let result = try JSONDecoder().decode(AIParseResult.self, from: data)

        assertEqual(result.amount, 28, "extractor should preserve amount inside markdown JSON")
        assertEqual(result.type, .expense, "extractor should decode ledger type from JSON")
        assertEqual(result.category, "餐饮", "extractor should preserve category")
        assertEqual(result.needsConfirmation, true, "extractor should preserve confirmation flag")
    }

    private static func testAIParseResultValidationFallsBackAndTruncates() throws {
        let longNote = String(repeating: "很", count: 80)
        let result = AIParseResult(
            amount: 1200,
            type: .debt,
            category: "不存在的类目",
            note: longNote,
            dateText: "昨天晚上",
            confidence: nil,
            needsConfirmation: true,
            questions: []
        )

        let draft = try AIParseResultValidator.validatedDraft(
            from: result,
            now: fixedDate(day: 7, hour: 10),
            calendar: calendar
        )

        assertEqual(draft.amount, 1200, "validator should keep positive amount")
        assertEqual(draft.type, .debt, "validator should keep valid type")
        assertEqual(draft.category, "其他借贷", "validator should fallback invalid debt category")
        assertEqual(draft.note.count, 60, "validator should truncate long notes")
        assertEqual(draft.confidence, 0.7, "validator should default missing confidence")
        assertEqual(calendar.component(.day, from: draft.date), 6, "validator should parse yesterday date text")
        assertEqual(calendar.component(.hour, from: draft.date), 20, "validator should parse evening to a reasonable hour")
    }

    private static func testAIParseResultValidationRequiresAmountAndType() throws {
        let missingAmount = AIParseResult(
            amount: nil,
            type: .expense,
            category: "餐饮",
            note: "午饭",
            dateText: "今天",
            confidence: 0.8,
            needsConfirmation: true,
            questions: ["请补充金额"]
        )
        assertThrowsMessage(
            try AIParseResultValidator.validatedDraft(from: missingAmount, now: fixedDate(day: 7, hour: 10), calendar: calendar),
            "请补充金额",
            "missing amount should ask for amount"
        )

        let missingType = AIParseResult(
            amount: 28,
            type: nil,
            category: "餐饮",
            note: "午饭",
            dateText: "今天",
            confidence: 0.8,
            needsConfirmation: true,
            questions: []
        )
        assertThrowsMessage(
            try AIParseResultValidator.validatedDraft(from: missingType, now: fixedDate(day: 7, hour: 10), calendar: calendar),
            "请补充收支类型",
            "missing type should ask for ledger type"
        )
    }

    private static func testNaturalLanguageDateParserHandlesRelativeAndSpecificDates() throws {
        let now = fixedDate(day: 7, hour: 10)

        let todayNoon = NaturalLanguageDateParser.parse("今天中午", now: now, calendar: calendar)
        assertEqual(calendar.component(.day, from: todayNoon), 7, "today noon should stay on current day")
        assertEqual(calendar.component(.hour, from: todayNoon), 12, "today noon should map to noon")

        let dayBeforeYesterday = NaturalLanguageDateParser.parse("前天晚上", now: now, calendar: calendar)
        assertEqual(calendar.component(.day, from: dayBeforeYesterday), 5, "day before yesterday should subtract two days")
        assertEqual(calendar.component(.hour, from: dayBeforeYesterday), 20, "evening should map to a reasonable hour")

        let specificDate = NaturalLanguageDateParser.parse("7月5日", now: now, calendar: calendar)
        assertEqual(calendar.component(.year, from: specificDate), 2026, "specific date should use current year")
        assertEqual(calendar.component(.month, from: specificDate), 7, "specific date should parse month")
        assertEqual(calendar.component(.day, from: specificDate), 5, "specific date should parse day")
    }

    @MainActor
    private static func testViewModelAddsConfirmedAIRecord() throws {
        let fileURL = temporaryLedgerURL()
        try? FileManager.default.removeItem(at: fileURL)
        let store = LedgerStore(fileURL: fileURL)
        let viewModel = LedgerViewModel(store: store, calendar: calendar)
        let draft = AIParsedLedgerDraft(
            amount: 28,
            type: .expense,
            category: "餐饮",
            note: "兰州拉面",
            date: fixedDate(day: 7, hour: 12),
            dateText: "今天中午",
            confidence: 0.92,
            questions: []
        )

        try viewModel.addRecord(from: draft)

        assertEqual(viewModel.records.count, 1, "confirmed AI draft should save exactly one ledger record")
        assertEqual(viewModel.records[0].amount, 28, "confirmed AI draft should save amount")
        assertEqual(viewModel.records[0].type, .expense, "confirmed AI draft should save type")
        assertEqual(viewModel.records[0].category, "餐饮", "confirmed AI draft should save category")
        assertEqual(viewModel.records[0].note, "兰州拉面", "confirmed AI draft should save note")
    }

    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        return calendar
    }()

    private static func fixedDate(day: Int, hour: Int) -> Date {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = 2026
        components.month = 7
        components.day = day
        components.hour = hour
        components.minute = 0
        return calendar.date(from: components)!
    }

    private static func temporaryLedgerURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("BeanLedgerStage2Tests-\(UUID().uuidString).json")
    }

    private static func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
        if actual != expected {
            fatalError("\(message). Expected \(expected), got \(actual)")
        }
    }

    private static func assertThrowsMessage<T>(_ operation: @autoclosure () throws -> T, _ expectedMessage: String, _ message: String) {
        do {
            _ = try operation()
            fatalError("\(message). Expected error \(expectedMessage), but operation succeeded")
        } catch {
            if error.localizedDescription != expectedMessage {
                fatalError("\(message). Expected error \(expectedMessage), got \(error.localizedDescription)")
            }
        }
    }
}

struct TestFailure: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}
