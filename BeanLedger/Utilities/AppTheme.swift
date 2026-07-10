import SwiftUI

enum AppTheme {
    static let background = Color("AppBackground")
    static let softBackground = Color("SoftBackground")
    static let card = Color("CardBackground")
    static let elevatedSurface = Color("ElevatedSurface")
    static let text = Color("PrimaryText")
    static let secondaryText = Color("SecondaryText")
    static let border = Color("Border")
    static let shadow = Color("Shadow").opacity(0.18)
    static let onAccentText = Color("OnAccentText")
    static let overlayScrim = Color("OverlayScrim")
    static let illustrationSurface = Color("IllustrationSurface")
    static let primary = Color("BrandPrimary")
    static let primaryDeep = Color("BrandPrimaryDeep")
    static let cherry = Color("BrandCherry")
    static let lavender = Color("BrandLavender")
    static let lemon = Color("BrandLemon")
    static let sky = Color("BrandSky")
    static let mint = Color("BrandMint")
    static let headerGradientEnd = Color("HeaderGradientEnd")
    static let dangerStart = Color("DangerStart")
    static let dangerEnd = Color("DangerEnd")
    static let expensePrimary = Color("ExpensePrimary")
    static let expenseSoftBackground = Color("ExpenseSoftBackground")
    static let expenseProgressColor = Color("ExpenseProgress")
    static let incomePrimary = Color("IncomePrimary")
    static let incomeSoftBackground = Color("IncomeSoftBackground")
    static let incomeProgressColor = Color("IncomeProgress")
    static let savingPrimary = Color("SavingPrimary")
    static let savingSoftBackground = Color("SavingSoftBackground")
    static let savingProgressColor = Color("SavingProgress")
    static let debtPrimary = Color("DebtPrimary")
    static let debtSoftBackground = Color("DebtSoftBackground")
    static let debtProgressColor = Color("DebtProgress")
    static let incomeTint = incomePrimary
    static let savingTint = savingPrimary
    static let debtTint = debtPrimary
    static let incomeAmountColor = incomePrimary
    static let expenseAmountColor = expensePrimary
    static let savingAmountColor = savingPrimary
    static let neutralAmountColor = Color("NeutralAmount")
    static let budgetWarning = Color("BudgetWarning")
    static let budgetOverLimit = Color("BudgetOverLimit")
    static let budgetSafe = Color("BudgetSafe")

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
            colors: [primaryDeep, primary, headerGradientEnd],
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
            colors: [dangerStart, dangerEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var paperGradient: LinearGradient {
        LinearGradient(
            colors: [card, elevatedSurface],
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

    func protectsTopSafeArea() -> some View {
        modifier(TopSafeAreaProtection())
    }
}

private struct TopSafeAreaProtection: ViewModifier {
    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .top, spacing: 0) {
            AppTheme.background
                .frame(height: 8)
                .frame(maxWidth: .infinity)
                .background(AppTheme.background.ignoresSafeArea(edges: .top))
        }
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
