import SwiftUI
import UIKit

struct SettingsView: View {
    @ObservedObject var viewModel: LedgerViewModel
    @State private var isShowingClearConfirmation = false

    var body: some View {
        ZStack {
            DottedBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.spacingLarge) {
                    appCard
                    AISettingsView()
                    styleCard
                    mascotAssetCard
                    actionCard
                    copyrightCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, AppTheme.floatingTabBarBottomInset)
            }
        }
        .hideNavigationBarForPrototype()
        .alert("清空全部数据？", isPresented: $isShowingClearConfirmation) {
            Button("先不清空", role: .cancel) {}
            Button("清空", role: .destructive) {
                clearAllRecords()
            }
        } message: {
            Text("清空后会把本地 JSON 账本写成空列表，这个操作后续可以再加备份恢复。")
        }
    }

    private var appCard: some View {
        CuteCardView {
            HStack(spacing: 16) {
                KittyMascotView(size: 78)
                VStack(alignment: .leading, spacing: 6) {
                    Text("小魏记账簿")
                        .font(.system(size: 27, weight: .heavy))
                        .foregroundStyle(AppTheme.text)
                    Text("原生 SwiftUI 记账本")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.cherry)
                    Text("版本号 \(appVersion)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Spacer()
            }
        }
    }

    private var styleCard: some View {
        CuteCardView {
            VStack(alignment: .leading, spacing: 12) {
                Label("UI 风格说明", systemImage: "paintpalette.fill")
                    .font(.system(size: 19, weight: .heavy))
                    .foregroundStyle(AppTheme.text)

                Text("原创粉色可爱风：粉白配色、大圆角卡片、胶囊按钮、猫耳轮廓、豆豆罐和轻柔小票卡片。")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var actionCard: some View {
        CuteCardView {
            VStack(alignment: .leading, spacing: 14) {
                Text("数据工具")
                    .font(.system(size: 19, weight: .heavy))
                    .foregroundStyle(AppTheme.text)

                CuteButton(title: "导出 JSON 数据", systemImage: "square.and.arrow.up.fill", style: .secondary) {
                    presentShareSheet(format: .json)
                }

                CuteButton(title: "导出 CSV 数据", systemImage: "tablecells.fill", style: .secondary) {
                    presentShareSheet(format: .csv)
                }

                CuteButton(title: "清空全部数据", systemImage: "trash.fill", style: .danger) {
                    isShowingClearConfirmation = true
                }
            }
        }
    }

    private var mascotAssetCard: some View {
        CuteCardView {
            VStack(alignment: .leading, spacing: 12) {
                Label("角色素材说明", systemImage: "photo.on.rectangle.angled")
                    .font(.system(size: 19, weight: .heavy))
                    .foregroundStyle(AppTheme.text)

                Text(mascotAssetDescription)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var copyrightCard: some View {
        CuteCardView {
            VStack(alignment: .leading, spacing: 10) {
                Label("版权说明", systemImage: "checkmark.seal.fill")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(AppTheme.text)
                Text("本地角色素材仅建议个人自用；公开分发、上传 GitHub、商业使用或上架 App Store 前，请自行确认授权。")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var mascotAssetDescription: String {
        if UIImage(named: "hello_kitty_mascot") != nil {
            return "当前检测到本地 hello_kitty_mascot，会优先显示这份本地角色素材。"
        }
        return "当前未检测到本地角色图片，会自动显示 SwiftUI 原创小猫占位。"
    }

    private func presentShareSheet(format: ExportFormat) {
        do {
            let url = try writeExportFile(format: format)
            let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            topMostViewController()?.present(controller, animated: true)
        } catch {
            viewModel.showToast(error.localizedDescription)
        }
    }

    private func writeExportFile(format: ExportFormat) throws -> URL {
        let payload = try viewModel.makeExport(format: format)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(payload.filename)
        try payload.data.write(to: url, options: [.atomic])
        return url
    }

    private func topMostViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        guard let root = scene?.windows.first(where: \.isKeyWindow)?.rootViewController else {
            return nil
        }

        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }

    private func clearAllRecords() {
        do {
            try viewModel.clearAllRecords()
            viewModel.showToast("已清空全部数据")
        } catch {
            viewModel.showToast(error.localizedDescription)
        }
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(viewModel: LedgerViewModel())
    }
}
#endif
