import Foundation

@main
struct Stage2LedgerLogicTests {
    @MainActor
    static func main() throws {
        try testDefaultStoreStartsEmpty()
        try testStorePersistsAddDeleteAndClear()
        try testCorruptLedgerStoreBlocksOverwrite()
        try testViewModelAddsRecordsAndCalculatesTotals()
        try testMonthToDateTrendMetricsRespectTypeAndCurrentDay()
        try testFilterEndDateIncludesTheEntireDay()
        try testDisplayAmountSigns()
        try testCSVExportNeutralizesSpreadsheetFormulas()
        try testEditableAmountFormattingPreservesCents()
        try testAIResponseJSONExtractorHandlesMarkdown()
        try testAIResponseJSONExtractorSkipsNonJSONBracketsAndTrailingText()
        try testAIParsePayloadDecodesMultipleRecords()
        try testAIParsePayloadKeepsLongRecordLists()
        try testAIEntryExamplesUseCommonPrompts()
        try testAISettingsRequireUserProvidedEndpoint()
        try testAISettingsStoreKeepsLastSavedAPIKeyOnFailure()
        try testAISettingsResetClearsOrdinarySettingsWhenKeyDeletionFails()
        try testAIParseResultValidationFallsBackAndTruncates()
        try testAIParseResultValidationRequiresAmountAndType()
        try testAIParseResultValidationBuildsMultipleDrafts()
        try testAIEntryViewModelUpdatesOneDraftInPlace()
        try testNaturalLanguageDateParserHandlesRelativeAndSpecificDates()
        try testQuickEntryUtilityCategoriesAreValidExpenses()
        try testNonFiniteAmountsAreRejected()
        try testViewModelAddsConfirmedAIRecord()
        try testViewModelAddsConfirmedAIRecords()
        try testViewModelAddsManyConfirmedAIRecords()
        try testClearAllDataClearsAdjacentStores()
        try testClearAllDataRollsBackEarlierStoresWhenLaterStoreFails()
        try testRecurringRecordAdvancesOnePeriodAtATime()
        try testRecurringGenerationRollsBackRecordWhenTemplateAdvanceFails()
        try testRecurringTemplateCanBeReenabled()
        try testClearAllDataConfirmationRequiresExactText()
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
    private static func testCorruptLedgerStoreBlocksOverwrite() throws {
        let fileURL = temporaryLedgerURL()
        try? FileManager.default.removeItem(at: fileURL)
        try Data("not-json".utf8).write(to: fileURL)

        let store = LedgerStore(fileURL: fileURL)
        assertEqual(store.records.count, 0, "corrupt store should not expose invalid records")
        assertEqual(store.lastErrorMessage != nil, true, "corrupt store should publish a load error")

        let originalContents = try String(contentsOf: fileURL, encoding: .utf8)
        let record = LedgerRecord(
            amount: 18.5,
            type: .expense,
            category: "餐饮",
            note: "测试午餐",
            date: fixedDate(day: 5, hour: 12)
        )
        assertThrowsContaining(
            try store.add(record),
            "账本 JSON 读取失败",
            "corrupt store should block ordinary writes"
        )
        let afterWriteAttempt = try String(contentsOf: fileURL, encoding: .utf8)
        assertEqual(afterWriteAttempt, originalContents, "corrupt JSON should not be overwritten by an ordinary add")

        let backups = try FileManager.default.contentsOfDirectory(at: fileURL.deletingLastPathComponent(), includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasPrefix(fileURL.lastPathComponent + ".corrupt-") }
        assertEqual(backups.isEmpty, false, "corrupt JSON should be copied to a timestamped backup")
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
    private static func testMonthToDateTrendMetricsRespectTypeAndCurrentDay() throws {
        let records = [
            LedgerRecord(amount: 31, type: .expense, category: "餐饮", note: "月初", date: fixedDate(day: 1, hour: 9)),
            LedgerRecord(amount: 69, type: .expense, category: "交通", note: "今天", date: fixedDate(day: 10, hour: 9)),
            LedgerRecord(amount: 1000, type: .expense, category: "购物", note: "未来", date: fixedDate(day: 20, hour: 9)),
            LedgerRecord(amount: 500, type: .income, category: "副业", note: "入账", date: fixedDate(day: 10, hour: 10))
        ]
        let viewModel = LedgerViewModel(records: records, calendar: calendar)
        let reportDate = fixedDate(day: 10, hour: 12)

        let expenseTotals = viewModel.dailyTotals(type: .expense, inMonth: reportDate, through: reportDate)
        assertEqual(expenseTotals.count, 10, "current-month trend should stop at the current day")
        assertEqual(expenseTotals.map(\.total).reduce(0, +), 100, "future records should not enter month-to-date totals")
        assertEqual(
            viewModel.highestDailyTotal(type: .expense, inMonth: reportDate, through: reportDate),
            69,
            "highest daily metric should follow the requested type"
        )
        assertEqual(
            viewModel.averageDailyTotal(type: .expense, inMonth: reportDate, through: reportDate),
            10,
            "daily average should divide by elapsed days instead of the full month"
        )
        assertEqual(
            viewModel.recordedDayCount(type: .expense, inMonth: reportDate, through: reportDate),
            2,
            "recorded-day count should only include the selected type"
        )
        assertEqual(
            viewModel.recordedDayCount(type: .income, inMonth: reportDate, through: reportDate),
            1,
            "income trend should use income recording days"
        )
    }

    @MainActor
    private static func testFilterEndDateIncludesTheEntireDay() throws {
        let finalFractionalSecond = fixedDate(day: 8, hour: 0).addingTimeInterval(-0.1)
        let record = LedgerRecord(
            amount: 18,
            type: .expense,
            category: "餐饮",
            note: "深夜账单",
            date: finalFractionalSecond
        )
        let viewModel = LedgerViewModel(records: [record], calendar: calendar)
        var filter = RecordFilterState()
        filter.selectedMonth = fixedDate(day: 7, hour: 12)
        filter.useEndDate = true
        filter.endDate = fixedDate(day: 7, hour: 12)

        assertEqual(
            viewModel.filteredRecords(using: filter).count,
            1,
            "end-date filters should include records throughout the final fractional second of the day"
        )
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

    private static func testCSVExportNeutralizesSpreadsheetFormulas() throws {
        let record = LedgerRecord(
            amount: 28,
            type: .expense,
            category: "@危险类目",
            note: "=2+2",
            date: fixedDate(day: 7, hour: 12)
        )

        let payload = try ExportService.makeExport(records: [record], format: .csv)
        guard let csv = String(data: payload.data, encoding: .utf8) else {
            throw TestFailure("expected UTF-8 CSV export")
        }

        assertEqual(csv.contains(",'@危险类目,'=2+2,"), true, "CSV export should neutralize formula-like text cells")
        assertEqual(csv.contains(",28.00,-28.00,"), true, "CSV export should keep numeric amount cells numeric")
        assertEqual(csv.contains(",@危险类目,=2+2,"), false, "CSV export should not expose executable formula-like cells")
    }

    private static func testEditableAmountFormattingPreservesCents() throws {
        assertEqual(CurrencyFormatter.inputString(from: 2700), "2700", "whole input amounts should omit decimal zeros")
        assertEqual(CurrencyFormatter.inputString(from: 100.5), "100.5", "editable amounts should preserve one decimal place")
        assertEqual(CurrencyFormatter.inputString(from: 100.25), "100.25", "editable amounts should preserve cents")
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

    private static func testAIResponseJSONExtractorSkipsNonJSONBracketsAndTrailingText() throws {
        let content = """
        解析结果 [仅供确认]：
        {
          "amount": 28,
          "type": "expense",
          "category": "餐饮",
          "note": "字符串里有 } 也不能提前结束",
          "dateText": "今天中午",
          "confidence": 0.92,
          "needsConfirmation": true,
          "questions": []
        }
        后续说明 }
        """

        let data = try AIResponseJSONExtractor.extractJSONData(from: content)
        let result = try JSONDecoder().decode(AIParseResult.self, from: data)

        assertEqual(result.amount, 28, "extractor should skip earlier non-JSON bracket text")
        assertEqual(result.note, "字符串里有 } 也不能提前结束", "extractor should respect braces inside JSON strings")
    }

    private static func testAIParsePayloadDecodesMultipleRecords() throws {
        let content = """
        {
          "records": [
            {
              "amount": 6926,
              "type": "income",
              "category": "工资",
              "note": "今天发工资",
              "dateText": "今天",
              "confidence": 0.95,
              "needsConfirmation": true,
              "questions": []
            },
            {
              "amount": 29.47,
              "type": "expense",
              "category": "餐饮",
              "note": "豫小七外卖",
              "dateText": "今天中午",
              "confidence": 0.9,
              "needsConfirmation": true,
              "questions": []
            }
          ],
          "needsConfirmation": true,
          "questions": []
        }
        """

        let data = try AIResponseJSONExtractor.extractJSONData(from: content)
        let results = try AIParsePayload.decodeResults(from: data)

        assertEqual(results.count, 2, "multi-record AI payload should decode both ledger records")
        assertEqual(results[0].amount, 6926, "first decoded record should keep salary amount")
        assertEqual(results[0].type, .income, "first decoded record should be income")
        assertEqual(results[0].category, "工资", "first decoded record should map to salary")
        assertEqual(results[1].amount, 29.47, "second decoded record should keep takeaway amount")
        assertEqual(results[1].type, .expense, "second decoded record should be expense")
        assertEqual(results[1].category, "餐饮", "second decoded record should map takeaway to food")
    }

    private static func testAIParsePayloadKeepsLongRecordLists() throws {
        let rows = (1...25)
            .map { index in
                """
                {
                  "amount": \(index),
                  "type": "expense",
                  "category": "餐饮",
                  "note": "第\(index)笔",
                  "dateText": "今天",
                  "confidence": 0.88,
                  "needsConfirmation": true,
                  "questions": []
                }
                """
            }
            .joined(separator: ",")
        let data = Data("{\"records\":[\(rows)],\"needsConfirmation\":true,\"questions\":[]}".utf8)

        let results = try AIParsePayload.decodeResults(from: data)

        assertEqual(results.count, 25, "AI payload should not cap long record lists at two records")
        assertEqual(results.first?.amount, 1, "long payload should keep the first record")
        assertEqual(results.last?.amount, 25, "long payload should keep the final record")
    }

    private static func testAIEntryExamplesUseCommonPrompts() throws {
        assertEqual(
            AIEntryExamples.prompts.contains { $0.contains("豫小七") },
            false,
            "AI entry examples should avoid the old shop-specific takeaway prompt"
        )
        assertEqual(
            AIEntryExamples.prompts.count >= 8,
            true,
            "AI entry examples should provide several common prompts"
        )
    }

    private static func testAISettingsRequireUserProvidedEndpoint() throws {
        let settings = AISettings()

        assertEqual(settings.apiBaseURL, "", "AI settings should not ship with a private API base URL")
        assertEqual(settings.fallbackBaseURL, "", "AI settings should not ship with a private fallback URL")
        assertEqual(settings.useFallbackWhenPrimaryFails, false, "fallback retry should be opt-in when no fallback URL is configured")
        assertEqual(settings.hasConfiguredBaseURL, false, "default AI settings should require user configuration before network calls")
    }

    @MainActor
    private static func testAISettingsStoreKeepsLastSavedAPIKeyOnFailure() throws {
        let suiteName = "BeanLedgerAISettingsTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            throw TestFailure("expected isolated user defaults")
        }
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let keyStorage = TestAIAPIKeyStorage(value: "old-key")
        let store = AISettingsStore(userDefaults: userDefaults, apiKeyStorage: keyStorage)
        assertEqual(store.apiKey, "old-key", "settings store should load the last saved API key")

        keyStorage.shouldFailSave = true
        store.saveAPIKey("  new-key\n")
        assertEqual(store.apiKey, "old-key", "failed Keychain writes should not replace the in-memory saved key")
        assertEqual(keyStorage.value, "old-key", "failed Keychain writes should preserve the persisted key")

        keyStorage.shouldFailSave = false
        store.saveAPIKey("  new-key\n")
        assertEqual(store.apiKey, "new-key", "successful Keychain writes should trim pasted whitespace")
        assertEqual(keyStorage.value, "new-key", "trimmed API key should be persisted")
    }

    @MainActor
    private static func testAISettingsResetClearsOrdinarySettingsWhenKeyDeletionFails() throws {
        let suiteName = "BeanLedgerAISettingsResetTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            throw TestFailure("expected isolated user defaults")
        }
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let keyStorage = TestAIAPIKeyStorage(value: "old-key")
        let store = AISettingsStore(userDefaults: userDefaults, apiKeyStorage: keyStorage)
        store.settings = AISettings(
            apiBaseURL: "https://example.com/v1",
            fallbackBaseURL: "https://backup.example.com/v1",
            selectedModel: "test-model",
            useFallbackWhenPrimaryFails: true,
            enableMockParsing: true
        )
        store.modelListMessage = "stale model message"
        keyStorage.shouldFailDelete = true

        do {
            try store.resetAllSettings()
            fatalError("reset should still report a failed Keychain deletion")
        } catch {
            // Expected: the caller still needs to report that the secure key remains.
        }
        assertEqual(store.settings, AISettings(), "ordinary AI settings should still reset when Keychain deletion fails")
        assertEqual(store.modelListMessage, nil, "reset should clear stale model-list feedback")
        assertEqual(store.apiKey, "old-key", "a key that could not be deleted should remain visible in memory")
        assertEqual(keyStorage.value, "old-key", "a failed Keychain deletion should preserve the stored key")
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

    private static func testAIParseResultValidationBuildsMultipleDrafts() throws {
        let results = [
            AIParseResult(
                amount: 6926,
                type: .income,
                category: "工资",
                note: "今天发工资",
                dateText: "今天",
                confidence: 0.95,
                needsConfirmation: true,
                questions: []
            ),
            AIParseResult(
                amount: 29.47,
                type: .expense,
                category: "餐饮",
                note: "豫小七外卖",
                dateText: "今天中午",
                confidence: 0.9,
                needsConfirmation: true,
                questions: []
            )
        ]

        let drafts = try AIParseResultValidator.validatedDrafts(
            from: results,
            now: fixedDate(day: 7, hour: 12),
            calendar: calendar
        )

        assertEqual(drafts.count, 2, "validator should build one draft for each AI record")
        assertEqual(drafts[0].type, .income, "first draft should be income")
        assertEqual(drafts[0].category, "工资", "first draft should keep salary category")
        assertEqual(drafts[1].type, .expense, "second draft should be expense")
        assertEqual(drafts[1].category, "餐饮", "second draft should keep food category")
        assertEqual(drafts[1].amount, 29.47, "second draft should keep decimal takeaway amount")
    }

    @MainActor
    private static func testAIEntryViewModelUpdatesOneDraftInPlace() throws {
        let originalDrafts = [
            AIParsedLedgerDraft(
                amount: 28,
                type: .expense,
                category: "餐饮",
                note: "午饭",
                date: fixedDate(day: 7, hour: 12),
                dateText: "今天中午",
                confidence: 0.9,
                questions: []
            ),
            AIParsedLedgerDraft(
                amount: 42,
                type: .expense,
                category: "交通",
                note: "打车",
                date: fixedDate(day: 7, hour: 13),
                dateText: "今天下午",
                confidence: 0.88,
                questions: []
            )
        ]
        let updatedDraft = AIParsedLedgerDraft(
            amount: 30,
            type: .expense,
            category: "餐饮",
            note: "调整后的午饭",
            date: fixedDate(day: 7, hour: 12),
            dateText: "今天中午",
            confidence: 0.9,
            questions: []
        )
        let viewModel = AIEntryViewModel(calendar: calendar)
        viewModel.parsedDrafts = originalDrafts

        viewModel.updateDraft(updatedDraft, at: 0)

        assertEqual(viewModel.parsedDrafts.count, 2, "editing one AI draft should keep the batch size")
        assertEqual(viewModel.parsedDrafts[0], updatedDraft, "editing should replace the selected AI draft")
        assertEqual(viewModel.parsedDrafts[1], originalDrafts[1], "editing should not mutate other AI drafts")
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

    private static func testQuickEntryUtilityCategoriesAreValidExpenses() throws {
        assertEqual(
            LedgerType.expense.categories.contains("燃气费"),
            true,
            "quick-entry gas bills should remain selectable in the shared expense category contract"
        )
        assertEqual(
            LedgerType.expense.categories.contains("电费"),
            true,
            "quick-entry electricity bills should remain selectable in the shared expense category contract"
        )
    }

    @MainActor
    private static func testNonFiniteAmountsAreRejected() throws {
        let invalidAIResult = AIParseResult(
            amount: .infinity,
            type: .expense,
            category: "餐饮",
            note: "异常金额",
            dateText: "今天",
            confidence: 0.8,
            needsConfirmation: true,
            questions: []
        )
        assertThrowsMessage(
            try AIParseResultValidator.validatedDraft(from: invalidAIResult, now: fixedDate(day: 7, hour: 10), calendar: calendar),
            "请补充金额",
            "AI validation should reject non-finite amounts"
        )

        let viewModel = LedgerViewModel(
            store: LedgerStore.inMemory(),
            budgetStore: BudgetStore.inMemory(),
            recurringStore: RecurringStore.inMemory(),
            calendar: calendar
        )
        assertThrowsMessage(
            try viewModel.addRecord(amount: .infinity, type: .expense, category: "餐饮", note: "异常金额", date: fixedDate(day: 7, hour: 10)),
            "金额要大于 0 哦",
            "manual record entry should reject non-finite amounts"
        )
        assertThrowsMessage(
            try viewModel.setBudget(category: nil, amountText: "inf"),
            "金额要大于 0 哦",
            "budget entry should reject non-finite amounts"
        )
        assertThrowsMessage(
            try viewModel.addRecurringTemplate(
                title: "异常模板",
                amountText: "inf",
                type: .expense,
                category: "餐饮",
                note: "",
                frequency: .monthly,
                startDate: fixedDate(day: 7, hour: 10),
                isEnabled: true
            ),
            "金额要大于 0 哦",
            "recurring entry should reject non-finite amounts"
        )
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

    @MainActor
    private static func testViewModelAddsConfirmedAIRecords() throws {
        let fileURL = temporaryLedgerURL()
        try? FileManager.default.removeItem(at: fileURL)
        let store = LedgerStore(fileURL: fileURL)
        let viewModel = LedgerViewModel(store: store, calendar: calendar)
        let drafts = [
            AIParsedLedgerDraft(
                amount: 6926,
                type: .income,
                category: "工资",
                note: "今天发工资",
                date: fixedDate(day: 7, hour: 9),
                dateText: "今天",
                confidence: 0.95,
                questions: []
            ),
            AIParsedLedgerDraft(
                amount: 29.47,
                type: .expense,
                category: "餐饮",
                note: "豫小七外卖",
                date: fixedDate(day: 7, hour: 12),
                dateText: "今天中午",
                confidence: 0.9,
                questions: []
            )
        ]

        try viewModel.addRecords(from: drafts)

        assertEqual(viewModel.records.count, 2, "confirmed AI drafts should save every ledger record")
        assertEqual(viewModel.monthIncomeTotal, 6926, "salary draft should update income totals")
        assertEqual(viewModel.monthExpenseTotal, 29.47, "takeaway draft should update expense totals")
        assertEqual(viewModel.records.map(\.type).contains(.income), true, "saved AI records should include income")
        assertEqual(viewModel.records.map(\.type).contains(.expense), true, "saved AI records should include expense")
    }

    @MainActor
    private static func testViewModelAddsManyConfirmedAIRecords() throws {
        let fileURL = temporaryLedgerURL()
        try? FileManager.default.removeItem(at: fileURL)
        let store = LedgerStore(fileURL: fileURL)
        let viewModel = LedgerViewModel(store: store, calendar: calendar)
        let drafts = (1...25).map { index in
            AIParsedLedgerDraft(
                amount: Double(index),
                type: .expense,
                category: "餐饮",
                note: "第\(index)笔",
                date: fixedDate(day: 7, hour: 12),
                dateText: "今天",
                confidence: 0.88,
                questions: []
            )
        }

        let records = try viewModel.addRecords(from: drafts)

        assertEqual(records.count, 25, "batch AI save should return every created record")
        assertEqual(viewModel.records.count, 25, "batch AI save should persist more than twenty records")
        assertEqual(viewModel.monthExpenseTotal, 325, "batch AI save should update totals for every record")
    }

    @MainActor
    private static func testClearAllDataClearsAdjacentStores() throws {
        let ledgerURL = temporaryLedgerURL()
        let budgetURL = temporaryStoreURL(prefix: "BeanLedgerBudgetStage2Tests")
        let recurringURL = temporaryStoreURL(prefix: "BeanLedgerRecurringStage2Tests")
        try? FileManager.default.removeItem(at: ledgerURL)
        try? FileManager.default.removeItem(at: budgetURL)
        try? FileManager.default.removeItem(at: recurringURL)

        let store = LedgerStore(fileURL: ledgerURL)
        let budgetStore = BudgetStore(fileURL: budgetURL)
        let recurringStore = RecurringStore(fileURL: recurringURL)
        let viewModel = LedgerViewModel(store: store, budgetStore: budgetStore, recurringStore: recurringStore, calendar: calendar)

        try viewModel.addRecord(amount: 30, type: .expense, category: "餐饮", note: "早餐", date: fixedDate(day: 7, hour: 8))
        try viewModel.setBudget(category: nil, amountText: "1000")
        try viewModel.addRecurringTemplate(
            title: "房租",
            amountText: "2700",
            type: .expense,
            category: "房租",
            note: "月租",
            frequency: .monthly,
            startDate: fixedDate(day: 1, hour: 9),
            isEnabled: true
        )

        assertEqual(viewModel.records.count, 1, "test setup should create one record")
        assertEqual(viewModel.budgets.count, 1, "test setup should create one budget")
        assertEqual(viewModel.recurringTemplates.count, 1, "test setup should create one recurring template")

        try viewModel.clearAllData()

        assertEqual(viewModel.records.count, 0, "clear all should clear ledger records")
        assertEqual(viewModel.budgets.count, 0, "clear all should clear budgets")
        assertEqual(viewModel.recurringTemplates.count, 0, "clear all should clear recurring templates")
        assertEqual(LedgerStore(fileURL: ledgerURL).records.count, 0, "clear all should persist empty records")
        assertEqual(BudgetStore(fileURL: budgetURL).budgets.count, 0, "clear all should persist empty budgets")
        assertEqual(RecurringStore(fileURL: recurringURL).templates.count, 0, "clear all should persist empty recurring templates")
    }

    @MainActor
    private static func testClearAllDataRollsBackEarlierStoresWhenLaterStoreFails() throws {
        let ledgerURL = temporaryLedgerURL()
        let blockedBudgetURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("BeanLedgerBlockedBudget-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: blockedBudgetURL, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: ledgerURL)
            try? FileManager.default.removeItem(at: blockedBudgetURL)
        }

        let record = LedgerRecord(
            amount: 88,
            type: .expense,
            category: "燃气费",
            note: "燃气账单",
            date: fixedDate(day: 7, hour: 10)
        )
        let store = LedgerStore(fileURL: ledgerURL)
        try store.add(record)
        let budgetStore = BudgetStore(
            fileURL: blockedBudgetURL,
            seedBudgets: [Budget(month: "2026-07", category: nil, amount: 1000)]
        )
        let viewModel = LedgerViewModel(
            store: store,
            budgetStore: budgetStore,
            recurringStore: RecurringStore.inMemory(),
            calendar: calendar
        )

        assertThrowsContaining(
            try viewModel.clearAllData(),
            "保存失败",
            "clear all should surface a later-store persistence failure"
        )

        assertEqual(viewModel.records.count, 1, "failed clear all should keep the in-memory ledger snapshot")
        assertEqual(
            LedgerStore(fileURL: ledgerURL).records.count,
            1,
            "failed clear all should restore ledger records already cleared on disk"
        )
        assertEqual(viewModel.budgets.count, 1, "failed clear all should keep the budget snapshot")
    }

    @MainActor
    private static func testRecurringRecordAdvancesOnePeriodAtATime() throws {
        guard let startDate = calendar.date(byAdding: .month, value: -3, to: Date()) else {
            throw TestFailure("expected calendar to create an overdue start date")
        }
        let template = RecurringRecordTemplate(
            title: "房租",
            amount: 2700,
            type: .expense,
            category: "房租",
            note: "月租",
            frequency: .monthly,
            startDate: startDate
        )
        let viewModel = LedgerViewModel(
            store: LedgerStore.inMemory(),
            budgetStore: BudgetStore.inMemory(),
            recurringStore: RecurringStore.inMemory(templates: [template]),
            calendar: calendar
        )

        viewModel.checkDueRecurringTemplates()
        assertEqual(viewModel.dueRecurringTemplates.count, 1, "overdue recurring template should be due")

        try viewModel.generateRecurringRecord(template)

        guard let updated = viewModel.recurringTemplates.first else {
            throw TestFailure("expected recurring template to remain after generating one record")
        }
        let expectedNextDueDate = template.frequency.nextDate(after: template.nextDueDate, calendar: calendar)
        assertEqual(updated.nextDueDate, expectedNextDueDate, "generating one recurring record should advance exactly one period")
        assertEqual(viewModel.records.count, 1, "generating one recurring template should create one ledger record")
        assertEqual(viewModel.dueRecurringTemplates.count, 1, "older missed recurring periods should remain due after one generation")
    }

    @MainActor
    private static func testRecurringGenerationRollsBackRecordWhenTemplateAdvanceFails() throws {
        let blockedRecurringURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("BeanLedgerBlockedRecurring-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: blockedRecurringURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: blockedRecurringURL) }

        let template = RecurringRecordTemplate(
            title: "房租",
            amount: 2700,
            type: .expense,
            category: "房租",
            note: "月租",
            frequency: .monthly,
            startDate: fixedDate(day: 1, hour: 9)
        )
        let viewModel = LedgerViewModel(
            store: LedgerStore.inMemory(),
            budgetStore: BudgetStore.inMemory(),
            recurringStore: RecurringStore(fileURL: blockedRecurringURL, seedTemplates: [template]),
            calendar: calendar
        )

        assertThrowsContaining(
            try viewModel.generateRecurringRecord(template),
            "保存失败",
            "recurring generation should surface template persistence failure"
        )
        assertEqual(
            viewModel.records.count,
            0,
            "failed template advancement should roll back the record that was just generated"
        )
        assertEqual(
            viewModel.dueRecurringTemplates.count,
            1,
            "failed template advancement should leave the original template due"
        )
    }

    @MainActor
    private static func testRecurringTemplateCanBeReenabled() throws {
        let template = RecurringRecordTemplate(
            title: "房租",
            amount: 2700,
            type: .expense,
            category: "房租",
            note: "月租",
            frequency: .monthly,
            startDate: fixedDate(day: 1, hour: 9),
            isEnabled: false
        )
        let viewModel = LedgerViewModel(
            store: LedgerStore.inMemory(),
            budgetStore: BudgetStore.inMemory(),
            recurringStore: RecurringStore.inMemory(templates: [template]),
            calendar: calendar
        )

        try viewModel.setRecurringTemplateEnabled(template, isEnabled: true)

        assertEqual(viewModel.recurringTemplates.first?.isEnabled, true, "disabled recurring templates should be re-enabled")
        assertEqual(viewModel.dueRecurringTemplates.count, 1, "re-enabled overdue templates should return to the due list")
    }

    private static func testClearAllDataConfirmationRequiresExactText() throws {
        assertEqual(ClearAllDataConfirmation.requiredText, "清空全部数据", "clear confirmation should expose the required phrase")
        assertEqual(ClearAllDataConfirmation.isConfirmed("清空全部数据"), true, "exact phrase should confirm clearing data")
        assertEqual(ClearAllDataConfirmation.isConfirmed("  清空全部数据  "), true, "surrounding whitespace should be ignored")
        assertEqual(ClearAllDataConfirmation.isConfirmed("清空数据"), false, "partial phrase should not confirm clearing data")
        assertEqual(ClearAllDataConfirmation.isConfirmed(""), false, "empty phrase should not confirm clearing data")
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

    private static func temporaryStoreURL(prefix: String) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("\(prefix)-\(UUID().uuidString).json")
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

    private static func assertThrowsContaining<T>(_ operation: @autoclosure () throws -> T, _ expectedText: String, _ message: String) {
        do {
            _ = try operation()
            fatalError("\(message). Expected error containing \(expectedText), but operation succeeded")
        } catch {
            if !error.localizedDescription.contains(expectedText) {
                fatalError("\(message). Expected error containing \(expectedText), got \(error.localizedDescription)")
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

private final class TestAIAPIKeyStorage: AIAPIKeyStorage {
    var value: String
    var shouldFailSave = false
    var shouldFailDelete = false

    init(value: String) {
        self.value = value
    }

    func readAPIKey() throws -> String {
        value
    }

    func saveAPIKey(_ apiKey: String) throws {
        if shouldFailSave {
            throw TestFailure("simulated Keychain save failure")
        }
        value = apiKey
    }

    func deleteAPIKey() throws {
        if shouldFailDelete {
            throw TestFailure("simulated Keychain delete failure")
        }
        value = ""
    }
}
