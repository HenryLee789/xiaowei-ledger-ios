import SwiftUI

struct TrendChartView: View {
    @ObservedObject var viewModel: LedgerViewModel
    @State private var selectedType: LedgerType = .expense

    private var data: [(date: Date, total: Double)] {
        viewModel.dailyTotals(type: selectedType)
    }

    private var hasData: Bool {
        data.contains { $0.total > 0 }
    }

    var body: some View {
        CuteCardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("本月趋势")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundStyle(AppTheme.text)
                        Text("每天的小账起伏都收在这里")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    Spacer()
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(selectedType.tint)
                        .frame(width: 42, height: 42)
                        .background(AppTheme.softBackground(for: selectedType), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                HStack(spacing: 10) {
                    CategoryPill(title: "出账趋势", isSelected: selectedType == .expense, color: LedgerType.expense.tint) {
                        selectedType = .expense
                    }
                    CategoryPill(title: "入账趋势", isSelected: selectedType == .income, color: LedgerType.income.tint) {
                        selectedType = .income
                    }
                }

                if hasData {
                    TrendLineChart(data: data, tint: AppTheme.progressColor(for: selectedType))
                        .frame(height: 170)
                        .padding(.top, 4)

                    HStack(spacing: 10) {
                        trendMetric(title: "最高单日出账", value: CurrencyFormatter.string(from: viewModel.highestDailyExpense()), color: AppTheme.expenseAmountColor)
                        trendMetric(title: "平均每日出账", value: CurrencyFormatter.string(from: viewModel.averageDailyExpense()), color: AppTheme.expenseAmountColor)
                        trendMetric(title: "记账天数", value: "\(viewModel.recordedDayCount()) 天", color: AppTheme.cherry)
                    }
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(AppTheme.primaryDeep)
                        Text("本月还没有趋势")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundStyle(AppTheme.text)
                        Text("新增几笔记录后，小折线就会亮起来")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .background(Color.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
    }

    private func trendMetric(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(2)
            Text(value)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct TrendLineChart: View {
    let data: [(date: Date, total: Double)]
    let tint: Color

    private var maxValue: Double {
        max(data.map(\.total).max() ?? 1, 1)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.72))
                VStack(spacing: proxy.size.height / 4) {
                    ForEach(0..<4, id: \.self) { _ in
                        Rectangle()
                            .fill(AppTheme.border.opacity(0.45))
                            .frame(height: 1)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 18)

                Path { path in
                    let points = chartPoints(in: proxy.size)
                    guard let first = points.first else { return }
                    path.move(to: first)
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(tint, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))

                Path { path in
                    let points = chartPoints(in: proxy.size)
                    guard let first = points.first, let last = points.last else { return }
                    path.move(to: CGPoint(x: first.x, y: proxy.size.height - 18))
                    path.addLine(to: first)
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                    path.addLine(to: CGPoint(x: last.x, y: proxy.size.height - 18))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(0.26), tint.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                ForEach(Array(chartPoints(in: proxy.size).enumerated()), id: \.offset) { _, point in
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                        .overlay(Circle().stroke(tint, lineWidth: 2))
                        .position(point)
                }
            }
        }
    }

    private func chartPoints(in size: CGSize) -> [CGPoint] {
        guard data.count > 1 else { return [] }
        let horizontalInset: CGFloat = 16
        let verticalInset: CGFloat = 18
        let width = max(size.width - horizontalInset * 2, 1)
        let height = max(size.height - verticalInset * 2, 1)
        return data.enumerated().map { index, item in
            let x = horizontalInset + width * CGFloat(index) / CGFloat(max(data.count - 1, 1))
            let ratio = CGFloat(item.total / maxValue)
            let y = verticalInset + height * (1 - ratio)
            return CGPoint(x: x, y: y)
        }
    }
}

#if DEBUG
struct TrendChartView_Previews: PreviewProvider {
    static var previews: some View {
        TrendChartView(viewModel: LedgerViewModel())
    }
}
#endif
