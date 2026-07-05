import SwiftUI

struct RecordsView: View {
    @ObservedObject var viewModel: LedgerViewModel

    @State private var filter = RecordFilterState()
    private let calendar = Calendar.current

    private var filteredRecords: [LedgerRecord] {
        viewModel.filteredRecords(using: filter)
    }

    private var categoryOptions: [String] {
        if let selectedType = filter.selectedType {
            return selectedType.categories
        }
        return Array(Set(viewModel.records.map(\.category))).sorted()
    }

    var body: some View {
        ZStack {
            DottedBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.spacingLarge) {
                    titleHeader
                    FilterPanelView(
                        filter: $filter,
                        categoryOptions: categoryOptions,
                        moveMonth: moveMonth,
                        clearFilters: clearFilters
                    )
                    totalCard
                    recordsList
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, AppTheme.floatingTabBarBottomInset)
            }
        }
        .hideNavigationBarForPrototype()
    }

    private var titleHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 5) {
                Text("全部记录")
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundStyle(AppTheme.text)
                Text("搜索金额、类目、备注，把小票筛出来")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Spacer()
            KittyMascotView(size: 58)
        }
    }

    private var totalCard: some View {
        CuteCardView {
            VStack(alignment: .leading, spacing: 15) {
                HStack(spacing: 14) {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(AppTheme.cherry)
                        .frame(width: 48, height: 48)
                        .background(AppTheme.primary.opacity(0.16), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("筛选结果")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.secondaryText)
                        Text("\(filteredRecords.count) 笔")
                            .font(.system(size: 25, weight: .heavy))
                            .foregroundStyle(AppTheme.text)
                    }
                    Spacer()
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    summaryChip("出账合计", CurrencyFormatter.signedString(from: viewModel.totalAmount(for: .expense, in: filteredRecords), sign: "-"), AppTheme.expenseAmountColor, LedgerType.expense.iconName)
                    summaryChip("入账合计", CurrencyFormatter.signedString(from: viewModel.totalAmount(for: .income, in: filteredRecords), sign: "+"), AppTheme.incomeAmountColor, LedgerType.income.iconName)
                    summaryChip("攒豆豆合计", CurrencyFormatter.signedString(from: viewModel.totalAmount(for: .saving, in: filteredRecords), sign: "+"), AppTheme.savingAmountColor, LedgerType.saving.iconName)
                    let debtNet = viewModel.debtNetTotal(in: filteredRecords)
                    summaryChip("借贷净额", CurrencyFormatter.signedString(fromSigned: debtNet), AppTheme.debtNetAmountColor(for: debtNet), LedgerType.debt.iconName)
                }
            }
        }
    }

    private var recordsList: some View {
        VStack(spacing: 12) {
            if filteredRecords.isEmpty {
                EmptyStateView(title: "没有找到记录", message: "换一个筛选条件，或者清空筛选试试")
            } else {
                ForEach(filteredRecords) { record in
                    DeletableRecordRow(record: record, viewModel: viewModel) {
                        delete(record)
                    }
                }
            }
        }
    }

    private func summaryChip(_ title: String, _ value: String, _ color: Color, _ symbol: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
                Text(value)
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Color.white.opacity(0.68), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func moveMonth(by value: Int) {
        filter.selectedMonth = calendar.date(byAdding: .month, value: value, to: filter.selectedMonth) ?? filter.selectedMonth
    }

    private func clearFilters() {
        filter.reset()
    }

    private func delete(_ record: LedgerRecord) {
        do {
            try viewModel.delete(record)
            viewModel.showToast("已删除这笔")
        } catch {
            viewModel.showToast(error.localizedDescription)
        }
    }
}

#if DEBUG
struct RecordsView_Previews: PreviewProvider {
    static var previews: some View {
        RecordsView(viewModel: LedgerViewModel())
    }
}
#endif

