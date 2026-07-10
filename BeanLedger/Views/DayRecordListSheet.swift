import SwiftUI

struct DayRecordListSheet: View {
    let day: Date
    let records: [LedgerRecord]
    @ObservedObject var viewModel: LedgerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            DottedBackground()
                .ignoresSafeArea(edges: [.top, .bottom])

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(day.dayTitle)
                                .font(.system(size: 26, weight: .heavy))
                                .foregroundStyle(AppTheme.text)
                            Text("当天账目")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundStyle(AppTheme.cherry)
                        }
                    }

                    HStack(spacing: 10) {
                        dayMetric("出账", total(.expense), AppTheme.expenseAmountColor)
                        dayMetric("入账", total(.income), AppTheme.incomeAmountColor)
                    }

                    if records.isEmpty {
                        EmptyStateView(title: "这天还没有账目", message: "日历上保持清清爽爽")
                    } else {
                        VStack(spacing: 10) {
                            ForEach(records) { record in
                                RecordReceiptRow(record: record, viewModel: viewModel)
                            }
                        }
                    }
                }
                .padding(18)
            }
        }
    }

    private func dayMetric(_ title: String, _ value: Double, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.secondaryText)
            Text(CurrencyFormatter.string(from: value))
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.elevatedSurface.opacity(0.78), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func total(_ type: LedgerType) -> Double {
        records
            .filter { $0.type == type }
            .map(\.amount)
            .reduce(0, +)
    }
}

