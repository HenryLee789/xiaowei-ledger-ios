import Foundation

struct RecurringRecordTemplate: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var amount: Double
    var type: LedgerType
    var category: String
    var note: String
    var frequency: RecurringFrequency
    var startDate: Date
    var nextDueDate: Date
    var isEnabled: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        type: LedgerType,
        category: String,
        note: String,
        frequency: RecurringFrequency,
        startDate: Date,
        nextDueDate: Date? = nil,
        isEnabled: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.type = type
        self.category = category
        self.note = note
        self.frequency = frequency
        self.startDate = startDate
        self.nextDueDate = nextDueDate ?? startDate
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }
}

