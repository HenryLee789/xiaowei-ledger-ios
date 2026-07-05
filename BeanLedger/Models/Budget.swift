import Foundation

struct Budget: Identifiable, Codable, Hashable {
    let id: UUID
    var month: String
    var category: String?
    var amount: Double
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        month: String,
        category: String?,
        amount: Double,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.month = month
        self.category = category
        self.amount = amount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

