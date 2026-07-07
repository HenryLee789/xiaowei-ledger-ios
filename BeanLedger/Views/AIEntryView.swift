import SwiftUI

struct AIEntryView: View {
    @ObservedObject var ledgerViewModel: LedgerViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settingsStore = AISettingsStore()
    @StateObject private var aiViewModel = AIEntryViewModel()

    private let examples = [
        "今天午饭花了28",
        "工资到账8500",
        "存了500到攒豆豆",
        "还信用卡1200"
    ]

    var body: some View {
        ZStack {
            DottedBackground()
                .ignoresSafeArea()

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

                    if let draft = aiViewModel.parsedDraft {
                        AIParseConfirmationView(
                            draft: draft,
                            onSave: { save(draft) },
                            onEdit: { edit(draft) },
                            onCancel: { aiViewModel.cancelResult() }
                        )
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, AppTheme.floatingTabBarBottomInset)
            }
        }
        .hideNavigationBarForPrototype()
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
                        .background(Color.white.opacity(0.82), in: Circle())
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
                        .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
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

    private func save(_ draft: AIParsedLedgerDraft) {
        do {
            try ledgerViewModel.addRecord(from: draft)
            ledgerViewModel.showToast("已记好啦")
            aiViewModel.clearAfterSave()
        } catch {
            aiViewModel.errorMessage = error.localizedDescription
        }
    }

    private func edit(_ draft: AIParsedLedgerDraft) {
        ledgerViewModel.presentAddRecord(
            draft: AddRecordDraft(
                amountText: amountText(for: draft.amount),
                note: draft.note,
                date: draft.date,
                type: draft.type,
                category: draft.category
            )
        )
    }

    private func amountText(for amount: Double) -> String {
        if amount.rounded() == amount {
            return String(format: "%.0f", locale: Locale(identifier: "en_US_POSIX"), amount)
        }
        return String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), amount)
    }
}

#if DEBUG
struct AIEntryView_Previews: PreviewProvider {
    static var previews: some View {
        AIEntryView(ledgerViewModel: LedgerViewModel())
    }
}
#endif
