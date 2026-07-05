import SwiftUI

enum AppTheme {
    static let background = Color(hex: "FFF7FA")
    static let softBackground = Color(hex: "FFEAF2")
    static let card = Color.white.opacity(0.92)
    static let primary = Color(hex: "FFB6C9")
    static let primaryDeep = Color(hex: "FF8FB3")
    static let cherry = Color(hex: "E94B70")
    static let lavender = Color(hex: "D7C6FF")
    static let lemon = Color(hex: "FFE6A6")
    static let sky = Color(hex: "BFE9FF")
    static let mint = Color(hex: "C9F4DE")
    static let expensePrimary = Color(hex: "D99A00")
    static let expenseSoftBackground = Color(hex: "FFF4D6")
    static let expenseProgressColor = Color(hex: "E0A800")
    static let incomePrimary = Color(hex: "4A90E2")
    static let incomeSoftBackground = Color(hex: "EAF4FF")
    static let incomeProgressColor = Color(hex: "4A90E2")
    static let savingPrimary = Color(hex: "C65BCF")
    static let savingSoftBackground = Color(hex: "FCEBFF")
    static let savingProgressColor = Color(hex: "C65BCF")
    static let debtPrimary = Color(hex: "8B5CF6")
    static let debtSoftBackground = Color(hex: "F0EAFF")
    static let debtProgressColor = Color(hex: "8B5CF6")
    static let incomeTint = incomePrimary
    static let savingTint = savingPrimary
    static let debtTint = debtPrimary
    static let incomeAmountColor = incomePrimary
    static let expenseAmountColor = expensePrimary
    static let savingAmountColor = savingPrimary
    static let neutralAmountColor = Color(hex: "44363C")
    static let budgetWarning = Color(hex: "E88A2A")
    static let budgetOverLimit = Color(hex: "E95B73")
    static let budgetSafe = Color(hex: "69B885")
    static let text = Color(hex: "44363C")
    static let secondaryText = Color(hex: "8A747C")
    static let border = Color(hex: "FFD3E0")
    static let shadow = Color(hex: "FF8FB3").opacity(0.18)

    static let cornerSmall: CGFloat = 14
    static let cornerMedium: CGFloat = 20
    static let cornerLarge: CGFloat = 28
    static let spacingSmall: CGFloat = 8
    static let spacing: CGFloat = 14
    static let spacingLarge: CGFloat = 22
    static let floatingTabBarBottomInset: CGFloat = 132
    static let sheetActionBottomInset: CGFloat = 150

    static var headerGradient: LinearGradient {
        LinearGradient(
            colors: [primaryDeep, primary, Color(hex: "FFDCE8")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var buttonGradient: LinearGradient {
        LinearGradient(
            colors: [primaryDeep, cherry],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var dangerGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "FF7D9D"), Color(hex: "D9435B")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var paperGradient: LinearGradient {
        LinearGradient(
            colors: [Color.white, Color(hex: "FFF1F6")],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static func amountColor(for polarity: AmountPolarity) -> Color {
        switch polarity {
        case .positive:
            return incomeAmountColor
        case .negative:
            return expenseAmountColor
        case .neutral:
            return neutralAmountColor
        }
    }

    static func amountColor(for record: LedgerRecord, polarity: AmountPolarity) -> Color {
        if record.type == .saving {
            return savingAmountColor
        }
        if record.type == .debt && polarity == .neutral {
            return debtPrimary
        }
        return amountColor(for: polarity)
    }

    static func amountColor(for type: LedgerType, polarity: AmountPolarity? = nil) -> Color {
        switch type {
        case .expense:
            return expenseAmountColor
        case .income:
            return incomeAmountColor
        case .saving:
            return savingAmountColor
        case .debt:
            guard let polarity else { return debtPrimary }
            return polarity == .neutral ? debtPrimary : amountColor(for: polarity)
        }
    }

    static func debtNetAmountColor(for amount: Double) -> Color {
        if amount > 0 {
            return incomeAmountColor
        }
        if amount < 0 {
            return expenseAmountColor
        }
        return debtPrimary
    }

    static func softBackground(for type: LedgerType) -> Color {
        switch type {
        case .expense:
            return expenseSoftBackground
        case .income:
            return incomeSoftBackground
        case .saving:
            return savingSoftBackground
        case .debt:
            return debtSoftBackground
        }
    }

    static func progressColor(for type: LedgerType) -> Color {
        switch type {
        case .expense:
            return expenseProgressColor
        case .income:
            return incomeProgressColor
        case .saving:
            return savingProgressColor
        case .debt:
            return debtProgressColor
        }
    }
}

extension Color {
    init(hex: String, alpha: Double = 1) {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)

        let red: UInt64
        let green: UInt64
        let blue: UInt64

        switch sanitized.count {
        case 3:
            red = (value >> 8) * 17
            green = ((value >> 4) & 0xF) * 17
            blue = (value & 0xF) * 17
        default:
            red = value >> 16
            green = (value >> 8) & 0xFF
            blue = value & 0xFF
        }

        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: alpha
        )
    }
}

extension View {
    func cuteShadow() -> some View {
        shadow(color: AppTheme.shadow, radius: 16, x: 0, y: 8)
    }

    func cuteCardBackground(cornerRadius: CGFloat = AppTheme.cornerLarge) -> some View {
        background(AppTheme.paperGradient)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppTheme.border.opacity(0.7), lineWidth: 1)
            )
            .cuteShadow()
    }

    @ViewBuilder
    func decimalPadKeyboard() -> some View {
        #if os(iOS)
        keyboardType(.decimalPad)
        #else
        self
        #endif
    }

    @ViewBuilder
    func hideNavigationBarForPrototype() -> some View {
        #if os(iOS)
        toolbar(.hidden, for: .navigationBar)
        #else
        self
        #endif
    }
}

struct DottedBackground: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppTheme.background
                ForEach(0..<42, id: \.self) { index in
                    Circle()
                        .fill(index.isMultiple(of: 3) ? AppTheme.primary.opacity(0.16) : AppTheme.lemon.opacity(0.20))
                        .frame(width: CGFloat(4 + (index % 4) * 2), height: CGFloat(4 + (index % 4) * 2))
                        .position(
                            x: CGFloat((index * 61) % max(Int(geometry.size.width), 1)),
                            y: CGFloat((index * 89) % max(Int(geometry.size.height), 1))
                        )
                }
            }
        }
    }
}
