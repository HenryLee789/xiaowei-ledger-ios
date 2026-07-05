import Foundation

@main
struct Stage2LedgerLogicTests {
    @MainActor
    static func main() throws {
        try testDefaultStoreStartsEmpty()
        try testStorePersistsAddDeleteAndClear()
        try testViewModelAddsRecordsAndCalculatesTotals()
        try testDisplayAmountSigns()
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

        try viewModel.addRecord(amount: 30, type: .expense, category: "餐饮", note: "早餐", date: fixedDate(day: 5, hour: 8))
        try viewModel.addRecord(amount: 200, type: .income, category: "红包", note: "红包", date: fixedDate(day: 5, hour: 9))
        try viewModel.addRecord(amount: 80, type: .saving, category: "存钱", note: "小罐子", date: fixedDate(day: 5, hour: 10))
        try viewModel.addRecord(amount: 50, type: .debt, category: "借出", note: "借出", date: fixedDate(day: 5, hour: 11))
        try viewModel.addRecord(amount: 20, type: .debt, category: "借入", note: "借入", date: fixedDate(day: 5, hour: 12))

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
}

struct TestFailure: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}
