import SwiftUI

enum LedgerType: String, CaseIterable, Codable, Identifiable {
    case expense
    case income
    case saving
    case debt

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .expense: return "出账"
        case .income: return "入账"
        case .saving: return "攒豆豆"
        case .debt: return "借贷"
        }
    }

    var iconName: String {
        switch self {
        case .expense: return "receipt.fill"
        case .income: return "wallet.pass.fill"
        case .saving: return "sparkles"
        case .debt: return "arrow.left.arrow.right.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .expense: return AppTheme.expensePrimary
        case .income: return AppTheme.incomePrimary
        case .saving: return AppTheme.savingPrimary
        case .debt: return AppTheme.debtPrimary
        }
    }

    var categories: [String] {
        switch self {
        case .expense:
            return ["餐饮", "交通", "购物", "燃气费", "电费", "生活缴费", "娱乐", "医疗", "房租", "其他出账"]
        case .income:
            return ["工资", "副业", "红包", "报销", "投资收益", "其他入账"]
        case .saving:
            return ["存钱", "目标储蓄", "备用金", "理财转入", "其他攒豆豆"]
        case .debt:
            return ["借出", "借入", "还款", "收回借款", "信用卡", "花呗 / 白条", "其他借贷"]
        }
    }
}
