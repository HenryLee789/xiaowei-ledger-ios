import SwiftUI

struct QuickEntryView: View {
    @ObservedObject var viewModel: LedgerViewModel

    @State private var selectedAmount: Double? = 50
    @State private var customAmount = ""
    @State private var selectedCategory = "燃气费"

    private let amounts: [Double] = [50, 100, 150, 200, 300, 400, 500, 2700]
    private let categories = ["燃气费", "电费", "房租"]

    var body: some View {
        CuteCardView {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("快速记账")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundStyle(AppTheme.text)
                        Text("常用金额和类目先填好，少点几下")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    Spacer()
                    Image(systemName: "bolt.heart.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.cherry)
                        .frame(width: 42, height: 42)
                        .background(AppTheme.primary.opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("金额")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(AppTheme.text)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 9) {
                            ForEach(amounts, id: \.self) { amount in
                                quickPill(
                                    title: CurrencyFormatter.string(from: amount),
                                    isSelected: selectedAmount == amount && customAmount.isEmpty,
                                    color: AppTheme.cherry
                                ) {
                                    selectedAmount = amount
                                    customAmount = ""
                                }
                            }
                            quickPill(
                                title: "自定义",
                                isSelected: selectedAmount == nil || !customAmount.isEmpty,
                                color: AppTheme.primaryDeep
                            ) {
                                selectedAmount = nil
                            }
                        }
                        .padding(.vertical, 2)
                    }

                    if selectedAmount == nil || !customAmount.isEmpty {
                        TextField("输入自定义金额", text: $customAmount)
                            .decimalPadKeyboard()
                            .font(.system(size: 15, weight: .semibold))
                            .padding(12)
                            .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(AppTheme.border, lineWidth: 1)
                            )
                            .onChange(of: customAmount) { value in
                                let cleaned = sanitizedAmount(value)
                                if cleaned != value {
                                    customAmount = cleaned
                                }
                            }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("常用类目")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(AppTheme.text)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 9) {
                            ForEach(categories, id: \.self) { category in
                                let type = ledgerType(for: category)
                                quickPill(title: category, isSelected: selectedCategory == category, color: type.tint) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                CuteButton(title: "快速记一笔", systemImage: "sparkles") {
                    openDraft()
                }
                .accessibilityIdentifier("home.quickEntryButton")
            }
        }
    }

    private func quickPill(title: String, isSelected: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(isSelected ? .white : color)
                .lineLimit(1)
                .padding(.vertical, 9)
                .padding(.horizontal, 13)
                .background(isSelected ? color : color.opacity(0.12), in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.white.opacity(0.4) : color.opacity(0.24), lineWidth: 1)
                )
        }
        .buttonStyle(CutePressButtonStyle())
    }

    private func openDraft() {
        let type = ledgerType(for: selectedCategory)
        let amountText: String
        if let selectedAmount, customAmount.isEmpty {
            amountText = String(format: "%.0f", locale: Locale(identifier: "en_US_POSIX"), selectedAmount)
        } else {
            amountText = customAmount
        }
        viewModel.presentAddRecord(
            draft: AddRecordDraft(
                amountText: amountText,
                date: Date(),
                type: type,
                category: selectedCategory
            )
        )
    }

    private func ledgerType(for category: String) -> LedgerType {
        LedgerType.allCases.first { $0.categories.contains(category) } ?? .expense
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

#if DEBUG
struct QuickEntryView_Previews: PreviewProvider {
    static var previews: some View {
        QuickEntryView(viewModel: LedgerViewModel())
    }
}
#endif
