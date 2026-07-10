import Foundation

enum LedgerInputError: LocalizedError {
    case invalidAmount
    case persistenceFailed(String)
    case invalidRecurringDate

    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "金额要大于 0 哦"
        case .persistenceFailed(let message):
            return "保存失败：\(message)"
        case .invalidRecurringDate:
            return "周期日期计算失败，请重新创建模板"
        }
    }
}

enum ClearAllDataConfirmation {
    static let requiredText = "清空全部数据"

    static func isConfirmed(_ input: String) -> Bool {
        input.trimmingCharacters(in: .whitespacesAndNewlines) == requiredText
    }
}

@MainActor
final class LedgerViewModel: ObservableObject {
    @Published private(set) var records: [LedgerRecord]
    @Published private(set) var budgets: [Budget]
    @Published private(set) var recurringTemplates: [RecurringRecordTemplate]
    @Published private(set) var dueRecurringTemplates: [RecurringRecordTemplate] = []
    @Published var isPresentingAddRecord = false
    @Published var toastMessage: String?
    @Published var addRecordDraft = AddRecordDraft()

    private let store: LedgerStore
    private let budgetStore: BudgetStore
    private let recurringStore: RecurringStore
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        let store = LedgerStore()
        let budgetStore = BudgetStore()
        let recurringStore = RecurringStore()
        self.store = store
        self.budgetStore = budgetStore
        self.recurringStore = recurringStore
        self.calendar = calendar
        self.records = store.records
        self.budgets = budgetStore.budgets
        self.recurringTemplates = recurringStore.templates
        checkDueRecurringTemplates()
    }

    init(store: LedgerStore, calendar: Calendar = .current) {
        let budgetStore = BudgetStore()
        let recurringStore = RecurringStore()
        self.store = store
        self.budgetStore = budgetStore
        self.recurringStore = recurringStore
        self.calendar = calendar
        self.records = store.records
        self.budgets = budgetStore.budgets
        self.recurringTemplates = recurringStore.templates
        checkDueRecurringTemplates()
    }

    init(store: LedgerStore, budgetStore: BudgetStore, recurringStore: RecurringStore, calendar: Calendar = .current) {
        self.store = store
        self.budgetStore = budgetStore
        self.recurringStore = recurringStore
        self.calendar = calendar
        self.records = store.records
        self.budgets = budgetStore.budgets
        self.recurringTemplates = recurringStore.templates
        checkDueRecurringTemplates()
    }

    init(records: [LedgerRecord], calendar: Calendar = .current) {
        let store = LedgerStore.inMemory(records: records)
        let budgetStore = BudgetStore.inMemory()
        let recurringStore = RecurringStore.inMemory()
        self.store = store
        self.budgetStore = budgetStore
        self.recurringStore = recurringStore
        self.calendar = calendar
        self.records = store.records
        self.budgets = budgetStore.budgets
        self.recurringTemplates = recurringStore.templates
    }

    var recentRecords: [LedgerRecord] {
        records.sorted { $0.date > $1.date }.prefix(5).map { $0 }
    }

    var todayExpenseTotal: Double {
        total(for: .expense, inToday: true)
    }

    var todayIncomeTotal: Double {
        total(for: .income, inToday: true)
    }

    var monthExpenseTotal: Double {
        total(for: .expense, inCurrentMonth: true)
    }

    var monthIncomeTotal: Double {
        total(for: .income, inCurrentMonth: true)
    }

    var savingTotal: Double {
        total(for: .saving)
    }

    var debtNetTotal: Double {
        netDebtTotal()
    }

    func netDebtTotal(inMonth monthDate: Date? = nil) -> Double {
        records
            .filter { record in
                guard record.type == .debt else { return false }
                if let monthDate {
                    return isSameMonth(record.date, monthDate)
                }
                return true
            }
            .map(debtSignedAmount)
            .reduce(0, +)
    }

    func total(for type: LedgerType, inToday: Bool = false, inCurrentMonth: Bool = false) -> Double {
        total(for: type, inToday: inToday, inMonth: inCurrentMonth ? Date() : nil)
    }

    func total(for type: LedgerType, inToday: Bool = false, inMonth monthDate: Date?) -> Double {
        records
            .filter { record in
                guard record.type == type else { return false }
                if inToday {
                    return calendar.isDate(record.date, inSameDayAs: Date())
                }
                if let monthDate {
                    return isSameMonth(record.date, monthDate)
                }
                return true
            }
            .map(\.amount)
            .reduce(0, +)
    }

    func categoryTotal(type: LedgerType, category: String) -> Double {
        categoryTotal(type: type, category: category, inMonth: nil)
    }

    func categoryTotal(type: LedgerType, category: String, inMonth monthDate: Date?) -> Double {
        records
            .filter { record in
                guard record.type == type && record.category == category else { return false }
                if let monthDate {
                    return isSameMonth(record.date, monthDate)
                }
                return true
            }
            .map(\.amount)
            .reduce(0, +)
    }

    func displayAmount(for record: LedgerRecord) -> String {
        switch amountPolarity(for: record) {
        case .positive:
            return CurrencyFormatter.signedString(from: record.amount, sign: "+")
        case .negative:
            return CurrencyFormatter.signedString(from: record.amount, sign: "-")
        case .neutral:
            return CurrencyFormatter.string(from: record.amount)
        }
    }

    func amountPolarity(for record: LedgerRecord) -> AmountPolarity {
        switch record.type {
        case .expense:
            return .negative
        case .income, .saving:
            return .positive
        case .debt:
            let signedAmount = debtSignedAmount(record)
            if signedAmount > 0 {
                return .positive
            }
            if signedAmount < 0 {
                return .negative
            }
            return .neutral
        }
    }

    func cashFlowAmount(for record: LedgerRecord) -> Double {
        switch record.type {
        case .expense:
            return -record.amount
        case .income, .saving:
            return record.amount
        case .debt:
            return debtSignedAmount(record)
        }
    }

    func debtSignedAmount(_ record: LedgerRecord) -> Double {
        record.signedAmount
    }

    func presentAddRecord(draft: AddRecordDraft = AddRecordDraft()) {
        addRecordDraft = draft
        isPresentingAddRecord = true
    }

    @discardableResult
    func addRecord(
        amount: Double,
        type: LedgerType,
        category: String,
        note: String,
        date: Date,
        imageData: Data? = nil
    ) throws -> LedgerRecord {
        guard amount.isFinite, amount > 0 else {
            throw LedgerInputError.invalidAmount
        }

        let recordID = UUID()
        let imageFilename: String?
        do {
            if let imageData {
                imageFilename = try RecordImageStore.saveImage(data: imageData, for: recordID)
            } else {
                imageFilename = nil
            }
        } catch {
            throw LedgerInputError.persistenceFailed(error.localizedDescription)
        }

        let record = LedgerRecord(
            id: recordID,
            amount: amount,
            type: type,
            category: category,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            date: date,
            createdAt: Date(),
            imageFilename: imageFilename
        )
        do {
            try store.add(record)
            syncFromStore()
            checkDueRecurringTemplates()
            return record
        } catch {
            RecordImageStore.deleteImage(filename: imageFilename)
            throw LedgerInputError.persistenceFailed(error.localizedDescription)
        }
    }

    @discardableResult
    func addRecord(
        amountText: String,
        type: LedgerType,
        category: String,
        note: String,
        date: Date,
        imageData: Data? = nil
    ) throws -> LedgerRecord {
        let normalized = amountText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let amount = Double(normalized), amount.isFinite, amount > 0 else {
            throw LedgerInputError.invalidAmount
        }
        return try addRecord(amount: amount, type: type, category: category, note: note, date: date, imageData: imageData)
    }

    @discardableResult
    func addRecord(from aiDraft: AIParsedLedgerDraft) throws -> LedgerRecord {
        try addRecord(
            amount: aiDraft.amount,
            type: aiDraft.type,
            category: aiDraft.category,
            note: aiDraft.note,
            date: aiDraft.date
        )
    }

    @discardableResult
    func addRecords(from aiDrafts: [AIParsedLedgerDraft]) throws -> [LedgerRecord] {
        guard aiDrafts.allSatisfy({ $0.amount.isFinite && $0.amount > 0 }) else {
            throw LedgerInputError.invalidAmount
        }
        let createdAt = Date()
        let recordsToAdd = aiDrafts.map { draft in
            LedgerRecord(
                amount: draft.amount,
                type: draft.type,
                category: draft.category,
                note: draft.note,
                date: draft.date,
                createdAt: createdAt
            )
        }

        do {
            try store.add(recordsToAdd)
            syncFromStore()
            checkDueRecurringTemplates()
            return recordsToAdd
        } catch {
            throw LedgerInputError.persistenceFailed(error.localizedDescription)
        }
    }

    func delete(_ record: LedgerRecord) throws {
        do {
            try store.delete(recordID: record.id)
            RecordImageStore.deleteImage(filename: record.imageFilename)
            syncFromStore()
            checkDueRecurringTemplates()
        } catch {
            throw LedgerInputError.persistenceFailed(error.localizedDescription)
        }
    }

    func clearAllRecords() throws {
        do {
            try store.clear()
            RecordImageStore.clearAllImages()
            syncFromStore()
            checkDueRecurringTemplates()
        } catch {
            throw LedgerInputError.persistenceFailed(error.localizedDescription)
        }
    }

    func clearAllData() throws {
        let recordSnapshot = store.records
        let budgetSnapshot = budgetStore.budgets
        var didClearRecords = false
        var didClearBudgets = false

        do {
            try store.clear()
            didClearRecords = true
            try budgetStore.clear()
            didClearBudgets = true
            try recurringStore.clear()
            RecordImageStore.clearAllImages()
            syncFromStore()
            syncBudgets()
            syncRecurringTemplates()
            checkDueRecurringTemplates()
        } catch {
            let originalMessage = error.localizedDescription
            var rollbackFailures: [String] = []

            if didClearBudgets {
                do {
                    try budgetStore.restore(budgetSnapshot)
                } catch {
                    rollbackFailures.append("预算回滚失败：\(error.localizedDescription)")
                }
            }
            if didClearRecords {
                do {
                    try store.restore(recordSnapshot)
                } catch {
                    rollbackFailures.append("账本回滚失败：\(error.localizedDescription)")
                }
            }

            syncFromStore()
            syncBudgets()
            syncRecurringTemplates()
            checkDueRecurringTemplates()

            let rollbackSuffix = rollbackFailures.isEmpty ? "" : "；\(rollbackFailures.joined(separator: "；"))"
            throw LedgerInputError.persistenceFailed(originalMessage + rollbackSuffix)
        }
    }

    func prepareExportFile() throws -> URL {
        do {
            return try store.exportJSONFile()
        } catch {
            throw LedgerInputError.persistenceFailed(error.localizedDescription)
        }
    }

    func prepareShareableJSONFile() throws -> URL {
        do {
            return try store.persistentJSONFile()
        } catch {
            throw LedgerInputError.persistenceFailed(error.localizedDescription)
        }
    }

    func exportJSONData() throws -> Data {
        do {
            return try store.exportJSONData()
        } catch {
            throw LedgerInputError.persistenceFailed(error.localizedDescription)
        }
    }

    func makeExport(format: ExportFormat) throws -> LedgerExportPayload {
        do {
            return try ExportService.makeExport(records: records, format: format)
        } catch {
            throw LedgerInputError.persistenceFailed(error.localizedDescription)
        }
    }

    func showToast(_ message: String) {
        toastMessage = message
    }

    func dismissToast() {
        toastMessage = nil
    }

    var jsonFileURL: URL? {
        store.fileURL
    }

    var budgetFileURL: URL? {
        budgetStore.fileURL
    }

    var recurringFileURL: URL? {
        recurringStore.fileURL
    }

    func noteSuggestions(for type: LedgerType, category: String, currentNote: String) -> [String] {
        let trimmedCurrent = currentNote.trimmingCharacters(in: .whitespacesAndNewlines)
        let recentRecords = records
            .filter { !$0.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .sorted { $0.date > $1.date }

        var seen = Set<String>()
        func uniqueNotes(from source: [LedgerRecord]) -> [String] {
            source.compactMap { record in
                let note = record.note.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !note.isEmpty, note != trimmedCurrent, !seen.contains(note) else { return nil }
                seen.insert(note)
                return note
            }
        }

        let sameCategory = uniqueNotes(from: recentRecords.filter { $0.type == type && $0.category == category })
        let others = uniqueNotes(from: recentRecords)
        return Array((sameCategory + others).prefix(5))
    }

    func dailyTotals(
        type: LedgerType,
        inMonth monthDate: Date = Date(),
        through cutoffDate: Date = Date()
    ) -> [(date: Date, total: Double)] {
        guard let range = calendar.range(of: .day, in: .month, for: monthDate),
              let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)),
              let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
            return []
        }

        let includedDayCount: Int
        if cutoffDate < monthStart {
            includedDayCount = 0
        } else if cutoffDate >= nextMonthStart {
            includedDayCount = range.count
        } else {
            let cutoffDay = calendar.startOfDay(for: cutoffDate)
            let elapsedDays = calendar.dateComponents([.day], from: monthStart, to: cutoffDay).day ?? 0
            includedDayCount = min(max(elapsedDays + 1, 0), range.count)
        }

        return range.prefix(includedDayCount).compactMap { day -> (date: Date, total: Double)? in
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) else { return nil }
            let total = records
                .filter { $0.type == type && calendar.isDate($0.date, inSameDayAs: date) }
                .map(\.amount)
                .reduce(0, +)
            return (date, total)
        }
    }

    func highestDailyTotal(
        type: LedgerType,
        inMonth monthDate: Date = Date(),
        through cutoffDate: Date = Date()
    ) -> Double {
        dailyTotals(type: type, inMonth: monthDate, through: cutoffDate).map(\.total).max() ?? 0
    }

    func averageDailyTotal(
        type: LedgerType,
        inMonth monthDate: Date = Date(),
        through cutoffDate: Date = Date()
    ) -> Double {
        let totals = dailyTotals(type: type, inMonth: monthDate, through: cutoffDate).map(\.total)
        guard !totals.isEmpty else { return 0 }
        return totals.reduce(0, +) / Double(totals.count)
    }

    func highestDailyExpense(inMonth monthDate: Date = Date()) -> Double {
        highestDailyTotal(type: .expense, inMonth: monthDate)
    }

    func averageDailyExpense(inMonth monthDate: Date = Date()) -> Double {
        averageDailyTotal(type: .expense, inMonth: monthDate)
    }

    func recordedDayCount(
        type: LedgerType? = nil,
        inMonth monthDate: Date = Date(),
        through cutoffDate: Date = Date()
    ) -> Int {
        let includedDays = Set(
            dailyTotals(type: type ?? .expense, inMonth: monthDate, through: cutoffDate)
                .map { calendar.startOfDay(for: $0.date) }
        )
        return Set(
            records
                .filter { record in
                    (type == nil || record.type == type) && includedDays.contains(calendar.startOfDay(for: record.date))
                }
                .map { calendar.startOfDay(for: $0.date) }
        ).count
    }

    func monthKey(for date: Date = Date()) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
    }

    func budget(for category: String?, monthDate: Date = Date()) -> Budget? {
        let key = monthKey(for: monthDate)
        return budgets.first { $0.month == key && $0.category == category }
    }

    func setBudget(category: String?, amountText: String, monthDate: Date = Date()) throws {
        let normalized = amountText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let amount = Double(normalized), amount.isFinite, amount >= 0 else {
            throw LedgerInputError.invalidAmount
        }

        do {
            try budgetStore.upsert(month: monthKey(for: monthDate), category: category, amount: amount)
            syncBudgets()
        } catch {
            throw LedgerInputError.persistenceFailed(error.localizedDescription)
        }
    }

    func expenseUsed(category: String?, monthDate: Date = Date()) -> Double {
        records
            .filter { record in
                guard record.type == .expense, isSameMonth(record.date, monthDate) else { return false }
                if let category {
                    return record.category == category
                }
                return true
            }
            .map(\.amount)
            .reduce(0, +)
    }

    func filteredRecords(using filter: RecordFilterState) -> [LedgerRecord] {
        let minimumAmount = Double(filter.minimumAmountText.trimmingCharacters(in: .whitespacesAndNewlines))
        let maximumAmount = Double(filter.maximumAmountText.trimmingCharacters(in: .whitespacesAndNewlines))
        let keyword = filter.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let startDate = calendar.startOfDay(for: filter.startDate)
        let endDateExclusive = calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.startOfDay(for: filter.endDate)
        ) ?? filter.endDate

        let filtered = records.filter { record in
            let matchesSearch = keyword.isEmpty ||
                record.note.localizedCaseInsensitiveContains(keyword) ||
                record.category.localizedCaseInsensitiveContains(keyword) ||
                record.type.displayName.localizedCaseInsensitiveContains(keyword) ||
                CurrencyFormatter.string(from: record.amount).localizedCaseInsensitiveContains(keyword) ||
                String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), record.amount).contains(keyword) ||
                String(format: "%.0f", locale: Locale(identifier: "en_US_POSIX"), record.amount).contains(keyword)
            let matchesMonth = isSameMonth(record.date, filter.selectedMonth)
            let matchesType = filter.selectedType == nil || record.type == filter.selectedType
            let matchesCategory = filter.selectedCategory == nil || record.category == filter.selectedCategory
            let matchesMinimum = minimumAmount == nil || record.amount >= (minimumAmount ?? 0)
            let matchesMaximum = maximumAmount == nil || record.amount <= (maximumAmount ?? Double.greatestFiniteMagnitude)
            let matchesStart = !filter.useStartDate || record.date >= startDate
            let matchesEnd = !filter.useEndDate || record.date < endDateExclusive
            return matchesSearch && matchesMonth && matchesType && matchesCategory && matchesMinimum && matchesMaximum && matchesStart && matchesEnd
        }

        switch filter.sortOption {
        case .newestFirst:
            return filtered.sorted { $0.date > $1.date }
        case .oldestFirst:
            return filtered.sorted { $0.date < $1.date }
        case .amountHighToLow:
            return filtered.sorted { $0.amount > $1.amount }
        case .amountLowToHigh:
            return filtered.sorted { $0.amount < $1.amount }
        }
    }

    func totalAmount(for type: LedgerType, in records: [LedgerRecord]) -> Double {
        records
            .filter { $0.type == type }
            .map(\.amount)
            .reduce(0, +)
    }

    func debtNetTotal(in records: [LedgerRecord]) -> Double {
        records
            .filter { $0.type == .debt }
            .map(\.signedAmount)
            .reduce(0, +)
    }

    func addRecurringTemplate(
        title: String,
        amountText: String,
        type: LedgerType,
        category: String,
        note: String,
        frequency: RecurringFrequency,
        startDate: Date,
        isEnabled: Bool
    ) throws {
        let normalized = amountText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let amount = Double(normalized), amount.isFinite, amount > 0 else {
            throw LedgerInputError.invalidAmount
        }
        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let template = RecurringRecordTemplate(
            title: cleanedTitle.isEmpty ? "\(category)周期账单" : cleanedTitle,
            amount: amount,
            type: type,
            category: category,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            frequency: frequency,
            startDate: startDate,
            isEnabled: isEnabled
        )

        do {
            try recurringStore.add(template)
            syncRecurringTemplates()
            checkDueRecurringTemplates()
        } catch {
            throw LedgerInputError.persistenceFailed(error.localizedDescription)
        }
    }

    func checkDueRecurringTemplates() {
        syncRecurringTemplates()
        let now = Date()
        dueRecurringTemplates = recurringTemplates
            .filter { $0.isEnabled && $0.nextDueDate <= now }
            .sorted { $0.nextDueDate < $1.nextDueDate }
    }

    func generateRecurringRecord(_ template: RecurringRecordTemplate) throws {
        let generatedRecord = try addRecord(
            amount: template.amount,
            type: template.type,
            category: template.category,
            note: template.note.isEmpty ? template.title : template.note,
            date: min(template.nextDueDate, Date())
        )
        do {
            try advanceRecurringTemplate(template)
        } catch {
            let advanceError = error
            do {
                try delete(generatedRecord)
            } catch {
                throw LedgerInputError.persistenceFailed(
                    "周期模板推进失败：\(advanceError.localizedDescription)；新记录回滚失败：\(error.localizedDescription)"
                )
            }
            throw advanceError
        }
    }

    func skipRecurringTemplate(_ template: RecurringRecordTemplate) throws {
        try advanceRecurringTemplate(template)
    }

    func setRecurringTemplateEnabled(_ template: RecurringRecordTemplate, isEnabled: Bool) throws {
        var updated = template
        updated.isEnabled = isEnabled
        do {
            try recurringStore.update(updated)
            syncRecurringTemplates()
            checkDueRecurringTemplates()
        } catch {
            throw LedgerInputError.persistenceFailed(error.localizedDescription)
        }
    }

    func deleteRecurringTemplate(_ template: RecurringRecordTemplate) throws {
        do {
            try recurringStore.delete(templateID: template.id)
            syncRecurringTemplates()
            checkDueRecurringTemplates()
        } catch {
            throw LedgerInputError.persistenceFailed(error.localizedDescription)
        }
    }

    private func syncFromStore() {
        records = store.records
    }

    private func syncBudgets() {
        budgets = budgetStore.budgets
    }

    private func syncRecurringTemplates() {
        recurringTemplates = recurringStore.templates
    }

    private func advanceRecurringTemplate(_ template: RecurringRecordTemplate) throws {
        var updated = template
        let nextDueDate = updated.frequency.nextDate(after: updated.nextDueDate, calendar: calendar)
        guard nextDueDate > updated.nextDueDate else {
            throw LedgerInputError.invalidRecurringDate
        }
        updated.nextDueDate = nextDueDate

        do {
            try recurringStore.update(updated)
            syncRecurringTemplates()
            checkDueRecurringTemplates()
        } catch {
            throw LedgerInputError.persistenceFailed(error.localizedDescription)
        }
    }

    private func isSameMonth(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.component(.year, from: lhs) == calendar.component(.year, from: rhs)
            && calendar.component(.month, from: lhs) == calendar.component(.month, from: rhs)
    }
}
