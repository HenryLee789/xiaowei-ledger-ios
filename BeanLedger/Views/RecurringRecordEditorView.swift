import SwiftUI

struct RecurringRecordEditorView: View {
    @ObservedObject var viewModel: LedgerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var amount = ""
    @State private var note = ""
    @State private var selectedType: LedgerType = .expense
    @State private var selectedCategory = LedgerType.expense.categories[0]
    @State private var frequency: RecurringFrequency = .monthly
    @State private var startDate = Date()
    @State private var isEnabled = true
    @State private var validationMessage: String?

    var body: some View {
        ZStack {
            DottedBackground()
                .ignoresSafeArea(edges: [.top, .bottom])

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    header
                    basicCard
                    typeCard
                    frequencyCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, AppTheme.sheetActionBottomInset)
            }
        }
        .safeAreaInset(edge: .bottom) {
            actionButtons
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 10)
                .background(.ultraThinMaterial)
        }
    }

    private var header: some View {
        CuteCardView(padding: 16, cornerRadius: 24) {
            HStack(spacing: 12) {
                Image(systemName: "clock.badge.plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(AppTheme.cherry)
                    .frame(width: 54, height: 54)
                    .background(AppTheme.primary.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text("创建周期账单")
                        .font(.system(size: 23, weight: .heavy))
                        .foregroundStyle(AppTheme.text)
                    Text("到期后手动确认生成记录")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Spacer()
            }
        }
    }

    private var basicCard: some View {
        CuteCardView(padding: 16, cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 12) {
                labeledField("名称", placeholder: "例如：房租 / 工资 / 会员费", text: $title)
                labeledField("金额", placeholder: "0.00", text: $amount, isAmount: true)
                labeledField("备注", placeholder: "写点小备注", text: $note)

                if let validationMessage {
                    Text(validationMessage)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.cherry)
                }
            }
        }
    }

    private var typeCard: some View {
        CuteCardView(padding: 16, cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 14) {
                Text("类型和类目")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(AppTheme.text)

                HStack(spacing: 8) {
                    ForEach(LedgerType.allCases) { type in
                        Button {
                            selectedType = type
                            selectedCategory = type.categories[0]
                        } label: {
                            Text(type.displayName)
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundStyle(selectedType == type ? AppTheme.onAccentText : type.tint)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(selectedType == type ? type.tint : AppTheme.softBackground(for: type), in: Capsule())
                        }
                        .buttonStyle(CutePressButtonStyle())
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(selectedType.categories, id: \.self) { category in
                            CategoryPill(title: category, isSelected: selectedCategory == category, color: selectedType.tint) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var frequencyCard: some View {
        CuteCardView(padding: 16, cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 14) {
                Text("周期")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(AppTheme.text)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(RecurringFrequency.allCases) { item in
                            CategoryPill(title: item.displayName, isSelected: frequency == item, color: AppTheme.cherry) {
                                frequency = item
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }

                DatePicker("开始日期", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                    .font(.system(size: 14, weight: .bold))
                    .tint(AppTheme.cherry)
                    .padding(12)
                    .background(AppTheme.elevatedSurface.opacity(0.78), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                Toggle("启用模板", isOn: $isEnabled)
                    .font(.system(size: 14, weight: .bold))
                    .tint(AppTheme.cherry)
                    .padding(12)
                    .background(AppTheme.elevatedSurface.opacity(0.78), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            CuteButton(title: "先不建啦", systemImage: "xmark.circle.fill", style: .secondary) {
                dismiss()
            }
            CuteButton(title: "保存模板", systemImage: "checkmark.circle.fill") {
                save()
            }
        }
    }

    private func labeledField(_ title: String, placeholder: String, text: Binding<String>, isAmount: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.secondaryText)
            TextField(placeholder, text: text)
                .font(.system(size: 15, weight: .semibold))
                .padding(14)
                .background(AppTheme.elevatedSurface.opacity(0.78), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
                .if(isAmount) { view in
                    view.decimalPadKeyboard()
                }
                .onChange(of: text.wrappedValue) { value in
                    if isAmount {
                        text.wrappedValue = sanitizedAmount(value)
                    }
                }
        }
    }

    private func save() {
        do {
            try viewModel.addRecurringTemplate(
                title: title,
                amountText: amount,
                type: selectedType,
                category: selectedCategory,
                note: note,
                frequency: frequency,
                startDate: startDate,
                isEnabled: isEnabled
            )
            viewModel.showToast("周期模板已保存")
            dismiss()
        } catch {
            validationMessage = error.localizedDescription
        }
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

private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#if DEBUG
struct RecurringRecordEditorView_Previews: PreviewProvider {
    static var previews: some View {
        RecurringRecordEditorView(viewModel: LedgerViewModel())
    }
}
#endif
