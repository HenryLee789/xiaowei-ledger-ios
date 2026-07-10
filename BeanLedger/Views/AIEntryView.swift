import SwiftUI

struct AIEntryView: View {
    @ObservedObject var ledgerViewModel: LedgerViewModel
    @ObservedObject var settingsStore: AISettingsStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var aiViewModel = AIEntryViewModel()
    @State private var editingDraft: AIParsedDraftEditSelection?

    private let examples = AIEntryExamples.prompts

    var body: some View {
        ZStack {
            DottedBackground()
                .ignoresSafeArea(edges: [.top, .bottom])

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.spacingLarge) {
                    titleCard
                    inputCard

                    if aiViewModel.isParsing {
                        loadingCard
                    }

                    if let errorMessage = aiViewModel.errorMessage {
                        messageCard(errorMessage)
                    }

                    if !aiViewModel.parsedDrafts.isEmpty {
                        AIParseConfirmationView(
                            drafts: aiViewModel.parsedDrafts,
                            onSave: { save(aiViewModel.parsedDrafts) },
                            onEdit: { index, draft in
                                editingDraft = AIParsedDraftEditSelection(index: index, draft: draft)
                            },
                            onCancel: { aiViewModel.cancelResult() }
                        )
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, AppTheme.floatingTabBarBottomInset)
            }
        }
        .protectsTopSafeArea()
        .hideNavigationBarForPrototype()
        .sheet(item: $editingDraft) { selection in
            AIParsedDraftEditorView(draft: selection.draft) { updatedDraft in
                aiViewModel.updateDraft(updatedDraft, at: selection.index)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private var titleCard: some View {
        CuteCardView {
            HStack(alignment: .top, spacing: 14) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(AppTheme.cherry)
                        .frame(width: 38, height: 38)
                        .background(AppTheme.elevatedSurface.opacity(0.82), in: Circle())
                        .overlay(
                            Circle()
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                }
                .buttonStyle(CutePressButtonStyle())
                .accessibilityLabel("返回")
                .accessibilityIdentifier("ai.backButton")

                KittyMascotView(size: 58)
                VStack(alignment: .leading, spacing: 7) {
                    Text("AI 记账助手")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(AppTheme.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                    Text("直接说你花了什么，我来帮你整理")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineSpacing(3)
                }
                Spacer(minLength: 8)
            }
        }
    }

    private var inputCard: some View {
        CuteCardView {
            VStack(alignment: .leading, spacing: 14) {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $aiViewModel.inputText)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.text)
                        .frame(minHeight: 136)
                        .padding(10)
                        .scrollContentBackground(.hidden)
                        .background(AppTheme.elevatedSurface.opacity(0.78), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                        .accessibilityIdentifier("ai.inputTextEditor")

                    if aiViewModel.inputText.isEmpty {
                        Text("直接说你花了什么，我来帮你整理")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.secondaryText.opacity(0.72))
                            .padding(.top, 20)
                            .padding(.leading, 16)
                            .allowsHitTesting(false)
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(examples, id: \.self) { example in
                            Button {
                                aiViewModel.inputText = example
                            } label: {
                                Text(example)
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

                CuteButton(title: "解析账单", systemImage: "wand.and.stars") {
                    Task {
                        await aiViewModel.parse(settings: settingsStore.settings, apiKey: settingsStore.apiKey)
                    }
                }
                .disabled(aiViewModel.isParsing)
                .opacity(aiViewModel.isParsing ? 0.62 : 1)
                .accessibilityIdentifier("ai.parseButton")
            }
        }
    }

    private var loadingCard: some View {
        CuteCardView(padding: 16, cornerRadius: 22) {
            HStack(spacing: 12) {
                ProgressView()
                    .tint(AppTheme.cherry)
                Text("正在整理这笔账…")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(AppTheme.text)
                Spacer()
            }
        }
    }

    private func messageCard(_ message: String) -> some View {
        CuteCardView(padding: 16, cornerRadius: 22) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.bubble.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.cherry)
                Text(message)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.text)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
        }
    }

    private func save(_ drafts: [AIParsedLedgerDraft]) {
        do {
            try ledgerViewModel.addRecords(from: drafts)
            let message = drafts.count == 1 ? "已记好啦" : "已记好 \(drafts.count) 笔啦"
            ledgerViewModel.showToast(message)
            aiViewModel.clearAfterSave()
        } catch {
            aiViewModel.errorMessage = error.localizedDescription
        }
    }

}

private struct AIParsedDraftEditSelection: Identifiable {
    let index: Int
    let draft: AIParsedLedgerDraft

    var id: Int { index }
}

private struct AIParsedDraftEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let originalDraft: AIParsedLedgerDraft
    let onApply: (AIParsedLedgerDraft) -> Void

    @State private var amountText: String
    @State private var selectedType: LedgerType
    @State private var selectedCategory: String
    @State private var note: String
    @State private var date: Date
    @State private var validationMessage: String?

    init(draft: AIParsedLedgerDraft, onApply: @escaping (AIParsedLedgerDraft) -> Void) {
        originalDraft = draft
        self.onApply = onApply
        _amountText = State(initialValue: Self.editableAmountText(draft.amount))
        _selectedType = State(initialValue: draft.type)
        _selectedCategory = State(initialValue: draft.category)
        _note = State(initialValue: draft.note)
        _date = State(initialValue: draft.date)
    }

    var body: some View {
        ZStack {
            DottedBackground()
                .ignoresSafeArea(edges: [.top, .bottom])

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    headerCard
                    amountCard
                    typeAndCategoryCard
                    detailsCard
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

    private var headerCard: some View {
        CuteCardView(padding: 16, cornerRadius: 24) {
            HStack(spacing: 12) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppTheme.onAccentText)
                    .frame(width: 48, height: 48)
                    .background(AppTheme.buttonGradient, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text("调整识别结果")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(AppTheme.text)
                    Text("应用后仍需在确认卡片里保存")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Spacer()
            }
        }
    }

    private var amountCard: some View {
        CuteCardView(padding: 16, cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 10) {
                Text("金额")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
                TextField("0.00", text: $amountText)
                    .decimalPadKeyboard()
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.text)
                    .padding(14)
                    .background(AppTheme.elevatedSurface.opacity(0.78), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
                    .onChange(of: amountText) { newValue in
                        let sanitized = sanitizedAmount(newValue)
                        if sanitized != newValue {
                            amountText = sanitized
                        }
                        validationMessage = nil
                    }
                    .accessibilityIdentifier("ai.draftEditor.amountField")

                if let validationMessage {
                    Text(validationMessage)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.cherry)
                }
            }
        }
    }

    private var typeAndCategoryCard: some View {
        CuteCardView(padding: 16, cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 14) {
                Text("类型和类目")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(AppTheme.text)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 9) {
                        ForEach(LedgerType.allCases) { type in
                            CategoryPill(title: type.displayName, isSelected: selectedType == type, color: type.tint) {
                                selectedType = type
                                selectedCategory = type.categories[0]
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 9) {
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

    private var detailsCard: some View {
        CuteCardView(padding: 16, cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 14) {
                TextField("备注", text: $note)
                    .font(.system(size: 15, weight: .semibold))
                    .padding(14)
                    .background(AppTheme.elevatedSurface.opacity(0.78), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
                    .accessibilityIdentifier("ai.draftEditor.noteField")

                DatePicker("日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .font(.system(size: 14, weight: .bold))
                    .tint(AppTheme.cherry)
                    .padding(12)
                    .background(AppTheme.elevatedSurface.opacity(0.78), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            CuteButton(title: "取消", systemImage: "xmark.circle.fill", style: .secondary) {
                dismiss()
            }
            CuteButton(title: "应用调整", systemImage: "checkmark.circle.fill") {
                applyChanges()
            }
            .accessibilityIdentifier("ai.draftEditor.applyButton")
        }
    }

    private func applyChanges() {
        let normalized = amountText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let amount = Double(normalized), amount.isFinite, amount > 0 else {
            validationMessage = LedgerInputError.invalidAmount.localizedDescription
            return
        }

        let cleanedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        onApply(
            AIParsedLedgerDraft(
                amount: amount,
                type: selectedType,
                category: selectedCategory,
                note: String(cleanedNote.prefix(60)),
                date: date,
                dateText: originalDraft.dateText,
                confidence: originalDraft.confidence,
                questions: originalDraft.questions
            )
        )
        dismiss()
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

    private static func editableAmountText(_ amount: Double) -> String {
        if amount.rounded() == amount {
            return String(format: "%.0f", locale: Locale(identifier: "en_US_POSIX"), amount)
        }
        return String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), amount)
    }
}

#if DEBUG
struct AIEntryView_Previews: PreviewProvider {
    static var previews: some View {
        AIEntryView(ledgerViewModel: LedgerViewModel(), settingsStore: AISettingsStore())
    }
}
#endif
