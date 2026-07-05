import SwiftUI

struct AddRecordView: View {
    @ObservedObject var viewModel: LedgerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var amount = ""
    @State private var note = ""
    @State private var date = Date()
    @State private var selectedType: LedgerType = .expense
    @State private var selectedCategory = LedgerType.expense.categories[0]
    @State private var validationMessage: String?

    init(viewModel: LedgerViewModel, draft: AddRecordDraft = AddRecordDraft()) {
        self.viewModel = viewModel
        _amount = State(initialValue: draft.amountText)
        _note = State(initialValue: draft.note)
        _date = State(initialValue: draft.date)
        _selectedType = State(initialValue: draft.type)
        _selectedCategory = State(initialValue: draft.category)
    }

    var body: some View {
        ZStack(alignment: .top) {
            DottedBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    titleCard
                    amountCard
                    typeSelector
                    categorySelector
                    detailCard
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

    private var titleCard: some View {
        CuteCardView(padding: 16, cornerRadius: 24) {
            HStack(spacing: 14) {
                KittyMascotView(size: 58)
                VStack(alignment: .leading, spacing: 5) {
                    Text("记一笔小账")
                        .font(.system(size: 23, weight: .heavy))
                        .foregroundStyle(AppTheme.text)
                    Text("像贴一张粉色便签一样轻松")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Spacer()
                BowView(size: 28)
            }
        }
    }

    private var amountCard: some View {
        CuteCardView(padding: 16, cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 10) {
                Text("金额")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("¥")
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundStyle(AppTheme.cherry)
                    TextField("0.00", text: $amount)
                        .decimalPadKeyboard()
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.text)
                        .minimumScaleFactor(0.6)
                        .accessibilityIdentifier("addRecord.amountField")
                        .onChange(of: amount) { newValue in
                            let sanitized = sanitizedAmount(newValue)
                            if sanitized != newValue {
                                amount = sanitized
                                return
                            }
                            if let amountValue = Double(sanitized), amountValue > 0 {
                                validationMessage = nil
                            }
                        }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(AppTheme.border, lineWidth: 1)
                )

                if let validationMessage {
                    Text(validationMessage)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.cherry)
                }
            }
        }
    }

    private var typeSelector: some View {
        CuteCardView(padding: 16, cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("一级类型")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(AppTheme.text)

                HStack(spacing: 8) {
                    ForEach(LedgerType.allCases) { type in
                        AddTypeButton(type: type, isSelected: selectedType == type) {
                            selectedType = type
                            selectedCategory = type.categories[0]
                        }
                    }
                }
            }
        }
    }

    private var categorySelector: some View {
        CuteCardView(padding: 16, cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("二级类目")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(AppTheme.text)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(selectedType.categories, id: \.self) { category in
                            CategoryPill(
                                title: category,
                                isSelected: selectedCategory == category,
                                color: selectedType.tint
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var detailCard: some View {
        CuteCardView(padding: 16, cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("备注")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.secondaryText)
                    TextField("写点可爱的小备注", text: $note)
                        .font(.system(size: 15, weight: .semibold))
                        .padding(14)
                        .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                        .accessibilityIdentifier("addRecord.noteField")

                    noteSuggestions
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("日期")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.secondaryText)
                    DatePicker("日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(AppTheme.cherry)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                }
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            CuteButton(title: "先不记啦", systemImage: "xmark.circle.fill", style: .secondary) {
                dismiss()
            }
            CuteButton(title: "保存这笔", systemImage: "checkmark.circle.fill", style: .primary) {
                saveRecord()
            }
            .accessibilityIdentifier("addRecord.saveButton")
        }
    }

    @ViewBuilder
    private var noteSuggestions: some View {
        let suggestions = viewModel.noteSuggestions(for: selectedType, category: selectedCategory, currentNote: note)
        if !suggestions.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("备注提示")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button {
                                note = suggestion
                            } label: {
                                Text(suggestion)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(AppTheme.cherry)
                                    .lineLimit(1)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(AppTheme.primary.opacity(0.12), in: Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(AppTheme.border, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(CutePressButtonStyle())
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func saveRecord() {
        do {
            try viewModel.addRecord(
                amountText: amount,
                type: selectedType,
                category: selectedCategory,
                note: note,
                date: date
            )
            viewModel.showToast("已记好啦")
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

private struct AddTypeButton: View {
    let type: LedgerType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(type.displayName)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(isSelected ? .white : type.tint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? type.tint : AppTheme.softBackground(for: type))
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.white.opacity(0.45) : type.tint.opacity(0.24), lineWidth: 1)
                )
        }
        .buttonStyle(CutePressButtonStyle())
    }
}

#if DEBUG
struct AddRecordView_Previews: PreviewProvider {
    static var previews: some View {
        AddRecordView(viewModel: LedgerViewModel())
    }
}
#endif
