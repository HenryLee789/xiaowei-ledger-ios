import Foundation

enum SortOption: String, CaseIterable, Identifiable {
    case newestFirst
    case oldestFirst
    case amountHighToLow
    case amountLowToHigh

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .newestFirst: return "最新优先"
        case .oldestFirst: return "最旧优先"
        case .amountHighToLow: return "金额高到低"
        case .amountLowToHigh: return "金额低到高"
        }
    }
}

