import SwiftUI

struct AIParseConfirmationView: View {
    let draft: AIParsedLedgerDraft
    let onSave: () -> Void
    let onEdit: () -> Void
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
                        Text("我整理好了，确认一下吧")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundStyle(AppTheme.text)
                        Text("确认后才会写入本地账本")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
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

                VStack(spacing: 10) {
                    CuteButton(title: "确认记账", systemImage: "checkmark.circle.fill") {
                        onSave()
                    }
                    .accessibilityIdentifier("ai.confirmSaveButton")

                    HStack(spacing: 10) {
                        CuteButton(title: "手动调整", systemImage: "slider.horizontal.3", style: .secondary) {
                            onEdit()
                        }
                        CuteButton(title: "先不记", systemImage: "xmark.circle.fill", style: .secondary) {
                            onCancel()
                        }
                    }
                }
            }
        }
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
