import SwiftUI

struct StatsView: View {
    @ObservedObject var viewModel: LedgerViewModel

    private let monthDate = Date()

    private var maxTypeTotal: Double {
        max(LedgerType.allCases.map { typeTotalForProgress($0) }.max() ?? 1, 1)
    }

    var body: some View {
        ZStack {
            DottedBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.spacingLarge) {
                    titleHeader
                    featureEntrances
                    typeStatsCard
                    TrendChartView(viewModel: viewModel)
                    categoryCard(title: "出账按二级类目", type: .expense, symbol: "receipt.fill")
                    categoryCard(title: "入账按二级类目", type: .income, symbol: "wallet.pass.fill")
                    savingAndDebt
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, AppTheme.floatingTabBarBottomInset)
            }
        }
        .hideNavigationBarForPrototype()
    }

    private var titleHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("统计")
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundStyle(AppTheme.text)
                Text("把小账本变成一罐彩色豆豆")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Spacer()
        }
    }

    private var typeStatsCard: some View {
        CuteCardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("本月各一级类型金额")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(AppTheme.text)
                    Spacer()
                    Text(Date().monthTitle)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.cherry)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 12)
                        .background(AppTheme.primary.opacity(0.16), in: Capsule())
                }

                VStack(spacing: 14) {
                    ForEach(LedgerType.allCases) { type in
                        ProgressStatRow(
                            title: type.displayName,
                            value: typeAmountText(for: type),
                            progress: typeTotalForProgress(type) / maxTypeTotal,
                            systemImage: type.iconName,
                            tint: type.tint,
                            softTint: AppTheme.softBackground(for: type),
                            progressTint: AppTheme.progressColor(for: type),
                            valueColor: typeAmountColor(for: type)
                        )
                    }
                }
            }
        }
    }

    private var featureEntrances: some View {
        CuteCardView {
            VStack(alignment: .leading, spacing: 14) {
                Text("更多小工具")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(AppTheme.text)

                HStack(spacing: 10) {
                    featureLink(title: "预算", symbol: "target", tint: AppTheme.expensePrimary) {
                        BudgetView(viewModel: viewModel)
                    }
                    featureLink(title: "定时记账", symbol: "clock.badge.checkmark", tint: AppTheme.cherry) {
                        RecurringRecordsView(viewModel: viewModel)
                    }
                    featureLink(title: "收支日历", symbol: "calendar", tint: AppTheme.incomePrimary) {
                        LedgerCalendarView(viewModel: viewModel)
                    }
                }
            }
        }
    }

    private func featureLink<Destination: View>(title: String, symbol: String, tint: Color, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink(destination: destination()) {
            VStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(tint)
                    .frame(width: 40, height: 40)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                Text(title)
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.68), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(CutePressButtonStyle())
    }

    private func categoryCard(title: String, type: LedgerType, symbol: String) -> some View {
        CuteCardView {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: symbol)
                        .foregroundStyle(type.tint)
                        .frame(width: 34, height: 34)
                        .background(AppTheme.softBackground(for: type), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    Text(title)
                        .font(.system(size: 19, weight: .heavy))
                        .foregroundStyle(AppTheme.text)
                    Spacer()
                }

                VStack(spacing: 12) {
                    ForEach(topCategories(for: type), id: \.name) { item in
                        CategoryBarRow(
                            name: item.name,
                            valueText: categoryAmountText(for: type, category: item.name, value: item.value),
                            progress: item.progress,
                            tint: AppTheme.progressColor(for: type),
                            valueColor: categoryAmountColor(for: type, category: item.name)
                        )
                    }
                }
            }
        }
    }

    private var savingAndDebt: some View {
        HStack(spacing: 12) {
            CuteCardView(padding: 15, cornerRadius: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(LedgerType.saving.tint)
                        .frame(width: 38, height: 38)
                        .background(AppTheme.softBackground(for: .saving), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                    Text("攒豆豆累计")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(CurrencyFormatter.signedString(from: viewModel.savingTotal, sign: "+"))
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(AppTheme.savingAmountColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                    Text("小罐子进度很乖")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            CuteCardView(padding: 15, cornerRadius: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(LedgerType.debt.tint)
                        .frame(width: 38, height: 38)
                        .background(AppTheme.softBackground(for: .debt), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                    Text("借贷净额")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(CurrencyFormatter.signedString(fromSigned: viewModel.debtNetTotal))
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(AppTheme.debtNetAmountColor(for: viewModel.debtNetTotal))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                    Text("便签往来已记录")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func topCategories(for type: LedgerType) -> [(name: String, value: Double, progress: Double)] {
        let totals = type.categories
            .map { category in
                (name: category, value: viewModel.categoryTotal(type: type, category: category, inMonth: monthDate))
            }
            .filter { $0.value > 0 }
            .sorted { $0.value > $1.value }
            .prefix(5)

        let maxValue = max(totals.map(\.value).max() ?? 1, 1)
        return totals.map { item in
            (name: item.name, value: item.value, progress: item.value / maxValue)
        }
    }

    private func typeAmountText(for type: LedgerType) -> String {
        switch type {
        case .expense:
            return CurrencyFormatter.signedString(from: viewModel.total(for: type, inMonth: monthDate), sign: "-")
        case .income:
            return CurrencyFormatter.signedString(from: viewModel.total(for: type, inMonth: monthDate), sign: "+")
        case .saving:
            return CurrencyFormatter.signedString(from: viewModel.total(for: type, inMonth: monthDate), sign: "+")
        case .debt:
            return CurrencyFormatter.signedString(fromSigned: viewModel.netDebtTotal(inMonth: monthDate))
        }
    }

    private func typeAmountColor(for type: LedgerType) -> Color {
        if type == .debt {
            return AppTheme.debtPrimary
        }
        return AppTheme.amountColor(for: type)
    }

    private func typeTotalForProgress(_ type: LedgerType) -> Double {
        if type == .debt {
            return abs(viewModel.netDebtTotal(inMonth: monthDate))
        }
        return viewModel.total(for: type, inMonth: monthDate)
    }

    private func categoryAmountText(for type: LedgerType, category: String, value: Double) -> String {
        switch categoryPolarity(for: type, category: category) {
        case .positive:
            return CurrencyFormatter.signedString(from: value, sign: "+")
        case .negative:
            return CurrencyFormatter.signedString(from: value, sign: "-")
        case .neutral:
            return CurrencyFormatter.string(from: value)
        }
    }

    private func categoryAmountColor(for type: LedgerType, category: String) -> Color {
        AppTheme.amountColor(for: type, polarity: categoryPolarity(for: type, category: category))
    }

    private func categoryPolarity(for type: LedgerType, category: String) -> AmountPolarity {
        switch type {
        case .expense:
            return .negative
        case .income, .saving:
            return .positive
        case .debt:
            switch category {
            case "借入", "收回借款":
                return .positive
            case "借出", "还款", "信用卡", "花呗 / 白条":
                return .negative
            default:
                return .neutral
            }
        }
    }
}

private struct ProgressStatRow: View {
    let title: String
    let value: String
    let progress: Double
    let systemImage: String
    let tint: Color
    let softTint: Color
    let progressTint: Color
    var valueColor: Color = AppTheme.text

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(tint)
                    .frame(width: 30, height: 30)
                    .background(softTint, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.text)
                Spacer()
                Text(value)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(valueColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(softTint)
                    Capsule()
                        .fill(progressTint)
                        .frame(width: proxy.size.width * min(max(progress, 0.05), 1))
                }
            }
            .frame(height: 9)
        }
    }
}

private struct CategoryBarRow: View {
    let name: String
    let valueText: String
    let progress: Double
    let tint: Color
    let valueColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.text)
                Spacer()
                Text(valueText)
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(valueColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(AppTheme.softBackground)
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(tint.opacity(0.82))
                        .frame(width: proxy.size.width * min(max(progress, 0.08), 1))
                }
            }
            .frame(height: 10)
        }
    }
}

#if DEBUG
struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView(viewModel: LedgerViewModel())
    }
}
#endif
