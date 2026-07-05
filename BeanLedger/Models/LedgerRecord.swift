import Foundation

struct LedgerRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var amount: Double
    var type: LedgerType
    var category: String
    var note: String
    var date: Date
    var createdAt: Date
    var imageFilename: String?

    init(
        id: UUID = UUID(),
        amount: Double,
        type: LedgerType,
        category: String,
        note: String,
        date: Date,
        createdAt: Date? = nil,
        imageFilename: String? = nil
    ) {
        self.id = id
        self.amount = amount
        self.type = type
        self.category = category
        self.note = note
        self.date = date
        self.createdAt = createdAt ?? date
        self.imageFilename = imageFilename
    }
}

extension LedgerRecord {
    var signedAmount: Double {
        switch type {
        case .expense:
            return -amount
        case .income, .saving:
            return amount
        case .debt:
            switch category {
            case "借入", "收回借款":
                return amount
            case "借出", "还款", "信用卡", "花呗 / 白条":
                return -amount
            default:
                return 0
            }
        }
    }
}
