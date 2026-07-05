import SwiftUI

struct RecurringRecordsView: View {
    @ObservedObject var viewModel: LedgerViewModel
    @State private var isShowingEditor = false

    var body: some View {
        ZStack {
            DottedBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.spacingLarge) {
                    titleHeader
                    dueCard
                    templatesCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, AppTheme.floatingTabBarBottomInset)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingEditor) {
            RecurringRecordEditorView(viewModel: viewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            viewModel.checkDueRecurringTemplates()
        }
    }

    private var titleHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("定时记账")
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundStyle(AppTheme.text)
                Text("房租、工资、会员费，到期再确认生成")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Spacer()
            Button {
                isShowingEditor = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(AppTheme.buttonGradient, in: Circle())
            }
            .buttonStyle(CutePressButtonStyle())
        }
    }

    private var dueCard: some View {
        CuteCardView {
            VStack(alignment: .leading, spacing: 14) {
                Text("待确认")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(AppTheme.text)

                if viewModel.dueRecurringTemplates.isEmpty {
                    simpleEmpty(title: "没有到期账单", message: "模板到期时会在这里等你确认")
                } else {
                    VStack(spacing: 12) {
                        ForEach(viewModel.dueRecurringTemplates) { template in
                            RecurringTemplateRow(template: template, viewModel: viewModel, mode: .due)
                        }
                    }
                }
            }
        }
    }

    private var templatesCard: some View {
        CuteCardView {
            VStack(alignment: .leading, spacing: 14) {
                Text("周期账单模板")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(AppTheme.text)

                if viewModel.recurringTemplates.isEmpty {
                    simpleEmpty(title: "还没有模板", message: "点右上角加号，创建固定账单")
                } else {
                    VStack(spacing: 12) {
                        ForEach(viewModel.recurringTemplates) { template in
                            RecurringTemplateRow(template: template, viewModel: viewModel, mode: .template)
                        }
                    }
                }
            }
        }
    }

    private func simpleEmpty(title: String, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppTheme.primaryDeep)
            Text(title)
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(AppTheme.text)
            Text(message)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct RecurringDueSheet: View {
    @ObservedObject var viewModel: LedgerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            DottedBackground()
                .ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("到期账单")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(AppTheme.text)
                    Text("确认后才会生成真实账目")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)

                    if viewModel.dueRecurringTemplates.isEmpty {
                        EmptyStateView(title: "没有待确认账单", message: "稍后再来看看")
                    } else {
                        VStack(spacing: 12) {
                            ForEach(viewModel.dueRecurringTemplates) { template in
                                RecurringTemplateRow(template: template, viewModel: viewModel, mode: .due)
                            }
                        }
                    }

                    CuteButton(title: "先关掉", systemImage: "xmark.circle.fill", style: .secondary) {
                        dismiss()
                    }
                }
                .padding(18)
            }
        }
    }
}

private struct RecurringTemplateRow: View {
    enum Mode {
        case due
        case template
    }

    let template: RecurringRecordTemplate
    @ObservedObject var viewModel: LedgerViewModel
    let mode: Mode

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: template.type.iconName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(template.type.tint)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.softBackground(for: template.type), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.title)
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(AppTheme.text)
                    Text("\(template.frequency.displayName) · \(template.category) · 下次 \(template.nextDueDate.recordTime)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Spacer()
                Text(CurrencyFormatter.string(from: template.amount))
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(AppTheme.amountColor(for: template.type))
            }

            if mode == .due {
                HStack(spacing: 10) {
                    smallAction("生成记录", "checkmark.circle.fill", AppTheme.cherry) {
                        do {
                            try viewModel.generateRecurringRecord(template)
                            viewModel.showToast("周期账单已生成")
                        } catch {
                            viewModel.showToast(error.localizedDescription)
                        }
                    }
                    smallAction("跳过本次", "arrowshape.turn.up.forward.fill", AppTheme.secondaryText) {
                        do {
                            try viewModel.skipRecurringTemplate(template)
                            viewModel.showToast("已跳过本次")
                        } catch {
                            viewModel.showToast(error.localizedDescription)
                        }
                    }
                }
            } else {
                HStack(spacing: 10) {
                    smallAction(template.isEnabled ? "关闭模板" : "已关闭", "pause.circle.fill", AppTheme.secondaryText) {
                        do {
                            try viewModel.disableRecurringTemplate(template)
                            viewModel.showToast("模板已关闭")
                        } catch {
                            viewModel.showToast(error.localizedDescription)
                        }
                    }
                    smallAction("删除", "trash.fill", AppTheme.cherry) {
                        do {
                            try viewModel.deleteRecurringTemplate(template)
                            viewModel.showToast("模板已删除")
                        } catch {
                            viewModel.showToast(error.localizedDescription)
                        }
                    }
                }
            }
        }
        .padding(13)
        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.border.opacity(0.8), lineWidth: 1)
        )
    }

    private func smallAction(_ title: String, _ symbol: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(color == AppTheme.cherry ? .white : color)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(color == AppTheme.cherry ? color : color.opacity(0.12), in: Capsule())
        }
        .buttonStyle(CutePressButtonStyle())
    }
}

#if DEBUG
struct RecurringRecordsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RecurringRecordsView(viewModel: LedgerViewModel())
        }
    }
}
#endif

