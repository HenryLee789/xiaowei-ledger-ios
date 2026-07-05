import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: LedgerViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            DottedBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.spacingLarge) {
                    header
                    QuickEntryView(viewModel: viewModel)
                    summaryGrid
                    recentSection
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, AppTheme.floatingTabBarBottomInset)
            }
        }
        .hideNavigationBarForPrototype()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("小魏记账簿")
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundStyle(.white)
                    Text(Date().homeTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.88))
                    Text("今天也要认真记账呀")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppTheme.text)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(Color.white.opacity(0.72), in: Capsule())
                }

                Spacer(minLength: 10)

                KittyMascotView(size: 86)
                    .padding(.top, 4)
            }

            HStack(spacing: 12) {
                CuteButton(title: "记一笔", systemImage: "plus.circle.fill") {
                    viewModel.presentAddRecord()
                }
                .accessibilityIdentifier("home.addRecordButton")

                beanJar
            }
        }
        .padding(22)
        .background(AppTheme.headerGradient)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .cuteShadow()
    }

    private var beanJar: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.system(size: 13, weight: .bold))
            Text("攒豆豆")
                .font(.system(size: 13, weight: .bold))
                .lineLimit(1)
        }
        .foregroundStyle(AppTheme.savingPrimary)
        .padding(.vertical, 13)
        .padding(.horizontal, 13)
        .background(AppTheme.savingSoftBackground.opacity(0.9), in: Capsule())
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            SummaryCard(
                title: "今日出账",
                value: CurrencyFormatter.signedString(from: viewModel.todayExpenseTotal, sign: "-"),
                subtitle: "粉色小票已收好",
                systemImage: LedgerType.expense.iconName,
                tint: LedgerType.expense.tint,
                valueColor: AppTheme.expenseAmountColor,
                iconBackground: AppTheme.softBackground(for: .expense)
            )
            SummaryCard(
                title: "今日入账",
                value: CurrencyFormatter.signedString(from: viewModel.todayIncomeTotal, sign: "+"),
                subtitle: "钱包鼓起来啦",
                systemImage: LedgerType.income.iconName,
                tint: LedgerType.income.tint,
                valueColor: AppTheme.incomeAmountColor,
                iconBackground: AppTheme.softBackground(for: .income)
            )
            SummaryCard(
                title: "本月出账",
                value: CurrencyFormatter.signedString(from: viewModel.monthExpenseTotal, sign: "-"),
                subtitle: "本月花花记录",
                systemImage: "calendar.badge.minus",
                tint: LedgerType.expense.tint,
                valueColor: AppTheme.expenseAmountColor,
                iconBackground: AppTheme.softBackground(for: .expense)
            )
            SummaryCard(
                title: "本月入账",
                value: CurrencyFormatter.signedString(from: viewModel.monthIncomeTotal, sign: "+"),
                subtitle: "收入小花园",
                systemImage: "calendar.badge.plus",
                tint: LedgerType.income.tint,
                valueColor: AppTheme.incomeAmountColor,
                iconBackground: AppTheme.softBackground(for: .income)
            )
            SummaryCard(
                title: "攒豆豆累计",
                value: CurrencyFormatter.signedString(from: viewModel.savingTotal, sign: "+"),
                subtitle: "豆豆罐亮晶晶",
                systemImage: LedgerType.saving.iconName,
                tint: LedgerType.saving.tint,
                valueColor: AppTheme.savingAmountColor,
                iconBackground: AppTheme.softBackground(for: .saving)
            )
            SummaryCard(
                title: "借贷净额",
                value: CurrencyFormatter.signedString(fromSigned: viewModel.debtNetTotal),
                subtitle: "往来便签已归档",
                systemImage: LedgerType.debt.iconName,
                tint: LedgerType.debt.tint,
                valueColor: AppTheme.debtNetAmountColor(for: viewModel.debtNetTotal),
                iconBackground: AppTheme.softBackground(for: .debt)
            )
        }
    }

    private var recentSection: some View {
        CuteCardView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("最近记账")
                            .font(.system(size: 21, weight: .heavy))
                            .foregroundStyle(AppTheme.text)
                        Text("每一笔都是小魏账本的足迹")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    Spacer()
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.cherry)
                        .frame(width: 42, height: 42)
                        .background(AppTheme.primary.opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                if viewModel.recentRecords.isEmpty {
                    EmptyStateView(title: "还没有记账", message: "点一下记一笔，把第一颗豆豆放进账本")
                } else {
                    VStack(spacing: 10) {
                        ForEach(viewModel.recentRecords) { record in
                            DeletableRecordRow(record: record, viewModel: viewModel) {
                                delete(record)
                            }
                        }
                    }
                }
            }
        }
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

struct RecordReceiptRow: View {
    let record: LedgerRecord
    @ObservedObject var viewModel: LedgerViewModel

    var body: some View {
        HStack(spacing: 12) {
            RecordThumbnailView(record: record, size: 42)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(record.type.displayName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(record.type.tint)
                    Text(record.category)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Text(record.note.isEmpty ? "没有备注的小账" : record.note)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(1)
                Text(record.date.recordTime)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer(minLength: 8)

            Text(viewModel.displayAmount(for: record))
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(AppTheme.amountColor(for: record, polarity: viewModel.amountPolarity(for: record)))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.border.opacity(0.7), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        )
    }
}

struct DeletableRecordRow: View {
    let record: LedgerRecord
    @ObservedObject var viewModel: LedgerViewModel
    var onDelete: () -> Void

    @State private var offset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .trailing) {
            Button(action: onDelete) {
                Label("删除", systemImage: "trash.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 78, height: 58)
                    .background(AppTheme.cherry, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .opacity(offset < -12 ? 1 : 0)
            .accessibilityLabel("删除")

            RecordReceiptRow(record: record, viewModel: viewModel)
                .offset(x: offset)
                .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .gesture(
                    DragGesture(minimumDistance: 16)
                        .onChanged { value in
                            if value.translation.width < 0 {
                                offset = max(value.translation.width, -88)
                            }
                        }
                        .onEnded { value in
                            withAnimation(.spring(response: 0.26, dampingFraction: 0.8)) {
                                offset = value.translation.width < -44 ? -88 : 0
                            }
                        }
                )
                .allowsHitTesting(offset > -70)
        }
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(viewModel: LedgerViewModel())
    }
}
#endif
