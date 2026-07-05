import Foundation

struct AddRecordDraft {
    var amountText: String
    var note: String
    var date: Date
    var type: LedgerType
    var category: String

    init(
        amountText: String = "",
        note: String = "",
        date: Date = Date(),
        type: LedgerType = .expense,
        category: String = LedgerType.expense.categories[0]
    ) {
        self.amountText = amountText
        self.note = note
        self.date = date
        self.type = type
        self.category = category
    }
}

