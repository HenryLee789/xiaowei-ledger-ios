import SwiftUI

struct BudgetView: View {
    @ObservedObject var viewModel: LedgerViewModel

    @State private var totalBudgetText = ""
    @State private var categoryInputs: [String: String] = [:]

    private let categories = LedgerType.expense.categories

    var body: some View {
        ZStack {
            DottedBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.spacingLarge) {
                    titleHeader
                    totalBudgetCard
                    categoryBudgetCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, AppTheme.floatingTabBarBottomInset)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: syncInputs)
    }

    private var titleHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("预算")
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundStyle(AppTheme.text)
                Text("给本月花花设一条温柔边界")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Spacer()
            Image(systemName: "target")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppTheme.expensePrimary)
                .frame(width: 56, height: 56)
                .background(AppTheme.expenseSoftBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private var totalBudgetCard: some View {
        budgetEditorCard(title: "本月总预算", category: nil, amountText: $totalBudgetText)
    }

    private var categoryBudgetCard: some View {
        CuteCardView {
            VStack(alignment: .leading, spacing: 16) {
                Text("出账分类预算")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(AppTheme.text)

                VStack(spacing: 12) {
                    ForEach(categories, id: \.self) { category in
                        BudgetCategoryRow(
                            category: category,
                            amountText: Binding(
                                get: { categoryInputs[category] ?? "" },
                                set: { categoryInputs[category] = sanitizedAmount($0) }
                            ),
                            budgetAmount: viewModel.budget(for: category)?.amount ?? 0,
                            usedAmount: viewModel.expenseUsed(category: category),
                            saveAction: {
                                saveBudget(category: category, text: categoryInputs[category] ?? "")
                            }
                        )
                    }
                }
            }
        }
    }

    private func budgetEditorCard(title: String, category: String?, amountText: Binding<String>) -> some View {
        CuteCardView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(title)
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(AppTheme.text)
                    Spacer()
                    Text(Date().monthTitle)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.expensePrimary)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 12)
                        .background(AppTheme.expenseSoftBackground, in: Capsule())
                }

                BudgetProgressView(
                    budgetAmount: viewModel.budget(for: category)?.amount ?? 0,
                    usedAmount: viewModel.expenseUsed(category: category)
                )

                HStack(spacing: 10) {
                    TextField("输入预算金额", text: amountText)
                        .decimalPadKeyboard()
                        .font(.system(size: 15, weight: .semibold))
                        .padding(13)
                        .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                        .onChange(of: amountText.wrappedValue) { value in
                            amountText.wrappedValue = sanitizedAmount(value)
                        }

                    Button {
                        saveBudget(category: category, text: amountText.wrappedValue)
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 46, height: 46)
                            .background(AppTheme.expensePrimary, in: Circle())
                    }
                    .buttonStyle(CutePressButtonStyle())
                    .accessibilityLabel("保存预算")
                }
            }
        }
    }

    private func saveBudget(category: String?, text: String) {
        do {
            try viewModel.setBudget(category: category, amountText: text)
            viewModel.showToast("预算已保存")
            syncInputs()
        } catch {
            viewModel.showToast(error.localizedDescription)
        }
    }

    private func syncInputs() {
        totalBudgetText = budgetText(viewModel.budget(for: nil)?.amount)
        categoryInputs = Dictionary(uniqueKeysWithValues: categories.map { category in
            (category, budgetText(viewModel.budget(for: category)?.amount))
        })
    }

    private func budgetText(_ amount: Double?) -> String {
        guard let amount, amount > 0 else { return "" }
        return String(format: "%.0f", locale: Locale(identifier: "en_US_POSIX"), amount)
    }

    private func sanitizedAmount(_ input: String) -> String {
        var result = ""
        var hasDecimalPoint = false
        for character in input {
            if character.isNumber {
                result.append(character)
            } else if character == ".", !hasDecimalPoint {
                hasDecimalPoint = true
                result.append(character)
            }
        }
        return result
    }
}

private struct BudgetCategoryRow: View {
    let category: String
    @Binding var amountText: String
    let budgetAmount: Double
    let usedAmount: Double
    var saveAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(category)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(AppTheme.text)
                Spacer()
                TextField("预算", text: $amountText)
                    .decimalPadKeyboard()
                    .font(.system(size: 13, weight: .semibold))
                    .multilineTextAlignment(.trailing)
                    .frame(width: 86)
                    .padding(.vertical, 9)
                    .padding(.horizontal, 10)
                    .background(Color.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
                Button(action: saveAction) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(AppTheme.expensePrimary, in: Circle())
                }
                .buttonStyle(CutePressButtonStyle())
            }

            BudgetProgressView(budgetAmount: budgetAmount, usedAmount: usedAmount, compact: true)
        }
        .padding(13)
        .background(Color.white.opacity(0.68), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct BudgetProgressView: View {
    let budgetAmount: Double
    let usedAmount: Double
    var compact = false

    private var remaining: Double {
        budgetAmount - usedAmount
    }

    private var progress: Double {
        guard budgetAmount > 0 else { return 0 }
        return usedAmount / budgetAmount
    }

    private var tint: Color {
        if budgetAmount <= 0 { return AppTheme.expensePrimary }
        if progress >= 1 { return AppTheme.budgetOverLimit }
        if progress >= 0.8 { return AppTheme.budgetWarning }
        return AppTheme.budgetSafe
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 7 : 10) {
            HStack {
                metric("已用", CurrencyFormatter.string(from: usedAmount), AppTheme.expenseAmountColor)
                Spacer()
                metric(remaining >= 0 ? "剩余" : "超出", CurrencyFormatter.string(from: abs(remaining)), tint)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.expenseSoftBackground)
                    Capsule()
                        .fill(tint)
                        .frame(width: proxy.size.width * min(max(progress, budgetAmount > 0 ? 0.04 : 0), 1))
                }
            }
            .frame(height: compact ? 8 : 10)

            if budgetAmount > 0 {
                Text(progress >= 1 ? "已经超预算，慢慢收一下小票" : progress >= 0.8 ? "接近 80%，要稍微留意啦" : "预算状态很稳")
                    .font(.system(size: compact ? 10 : 12, weight: .bold))
                    .foregroundStyle(tint)
            } else {
                Text("还没有设置预算")
                    .font(.system(size: compact ? 10 : 12, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }

    private func metric(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: compact ? 10 : 11, weight: .bold))
                .foregroundStyle(AppTheme.secondaryText)
            Text(value)
                .font(.system(size: compact ? 13 : 17, weight: .heavy))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
    }
}

#if DEBUG
struct BudgetView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BudgetView(viewModel: LedgerViewModel())
        }
    }
}
#endif
