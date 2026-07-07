import SwiftUI

struct AIParseConfirmationView: View {
    let drafts: [AIParsedLedgerDraft]
    let onSave: () -> Void
    let onEdit: (AIParsedLedgerDraft) -> Void
    let onCancel: () -> Void

    var body: some View {
        CuteCardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(AppTheme.cherry)
                        .frame(width: 44, height: 44)
                        .background(AppTheme.primary.opacity(0.15), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundStyle(AppTheme.text)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("确认后才会写入本地账本")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }

                VStack(spacing: 14) {
                    ForEach(Array(drafts.enumerated()), id: \.offset) { index, draft in
                        recordBlock(index: index, draft: draft)
                    }
                }

                VStack(spacing: 10) {
                    CuteButton(title: saveTitle, systemImage: "checkmark.circle.fill") {
                        onSave()
                    }
                    .accessibilityIdentifier("ai.confirmSaveButton")

                    CuteButton(title: "先不记", systemImage: "xmark.circle.fill", style: .secondary) {
                        onCancel()
                    }
                }
            }
        }
    }

    private var title: String {
        drafts.count == 1 ? "我整理好了，确认一下吧" : "我整理好了 \(drafts.count) 笔，确认一下吧"
    }

    private var saveTitle: String {
        drafts.count == 1 ? "确认记账" : "确认记账 \(drafts.count) 笔"
    }

    private func recordBlock(index: Int, draft: AIParsedLedgerDraft) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text("第 \(index + 1) 笔")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(AppTheme.text)
                Text(draft.type.displayName)
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(draft.type.tint)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background(AppTheme.softBackground(for: draft.type), in: Capsule())
                Spacer(minLength: 8)
                Button {
                    onEdit(draft)
                } label: {
                    Label("调整", systemImage: "slider.horizontal.3")
                        .font(.system(size: 12, weight: .heavy))
                        .lineLimit(1)
                        .foregroundStyle(AppTheme.cherry)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 10)
                        .background(Color.white.opacity(0.82), in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                }
                .buttonStyle(CutePressButtonStyle())
            }

            VStack(spacing: 10) {
                confirmationRow(title: "金额", value: CurrencyFormatter.string(from: draft.amount), color: AppTheme.amountColor(for: draft.type))
                confirmationRow(title: "类型", value: draft.type.displayName, color: draft.type.tint)
                confirmationRow(title: "类目", value: draft.category, color: draft.type.tint)
                confirmationRow(title: "备注", value: draft.note.isEmpty ? "没有备注的小账" : draft.note, color: AppTheme.text)
                confirmationRow(title: "日期", value: formattedDate(draft.date), color: AppTheme.text)
                confirmationRow(title: "AI 置信度", value: "\(Int((draft.confidence * 100).rounded()))%", color: AppTheme.cherry)
            }

            if !draft.questions.isEmpty {
                Text(draft.questions.joined(separator: "，"))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.cherry)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(.top, index == 0 ? 0 : 2)
        .accessibilityIdentifier("ai.confirmRecord.\(index)")
    }

    private func confirmationRow(title: String, value: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.secondaryText)
                .frame(width: 76, alignment: .leading)
            Text(value)
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
        }
        .padding(12)
        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.border.opacity(0.75), lineWidth: 1)
        )
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: date)
    }
}
