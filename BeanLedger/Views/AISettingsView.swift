import SwiftUI
import UIKit

struct AISettingsView: View {
    @ObservedObject private var settingsStore: AISettingsStore
    @State private var apiKeyDraft = ""

    init(settingsStore: AISettingsStore) {
        self.settingsStore = settingsStore
    }

    var body: some View {
        CuteCardView {
            VStack(alignment: .leading, spacing: 16) {
                header
                baseURLFields
                apiKeyField
                modelFields
                fallbackToggle

                #if DEBUG
                mockToggle
                #endif

                if let message = settingsStore.settingsMessage {
                    statusText(message)
                }
                if let message = settingsStore.modelListMessage {
                    statusText(message)
                }
            }
        }
        .onAppear {
            apiKeyDraft = settingsStore.apiKey
        }
        .onChange(of: settingsStore.settings.fallbackBaseURL) { newValue in
            if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                settingsStore.settings.useFallbackWhenPrimaryFails = false
            }
        }
        .onChange(of: settingsStore.apiKey) { newValue in
            if apiKeyDraft != newValue {
                apiKeyDraft = newValue
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles.rectangle.stack.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppTheme.cherry)
                .frame(width: 42, height: 42)
                .background(AppTheme.primary.opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("AI 设置")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(AppTheme.text)
                Text("配置你自己的 OpenAI 兼容接口")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Spacer()
        }
    }

    private var baseURLFields: some View {
        VStack(alignment: .leading, spacing: 10) {
            labeledTextField(
                title: "API Base URL",
                placeholder: AISettings.apiBaseURLPlaceholder,
                text: $settingsStore.settings.apiBaseURL,
                keyboard: .URL
            )

            Text("App 不内置 API 服务地址，请填写你自己的 OpenAI 兼容接口。")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            labeledTextField(
                title: "备用 Base URL",
                placeholder: AISettings.fallbackBaseURLPlaceholder,
                text: $settingsStore.settings.fallbackBaseURL,
                keyboard: .URL
            )
        }
    }

    private var apiKeyField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("API Key")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(AppTheme.text)
            SecureField("粘贴你的 API Key", text: $apiKeyDraft)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(size: 15, weight: .semibold))
                .padding(13)
                .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
                .accessibilityIdentifier("aiSettings.apiKeyField")

            smallActionButton(title: "保存 API Key", systemImage: "key.fill") {
                settingsStore.saveAPIKey(apiKeyDraft)
            }
            .accessibilityIdentifier("aiSettings.saveAPIKeyButton")
        }
    }

    private var modelFields: some View {
        VStack(alignment: .leading, spacing: 10) {
            labeledTextField(
                title: "模型名称",
                placeholder: "手动输入模型名",
                text: $settingsStore.settings.selectedModel,
                keyboard: .default
            )

            if !settingsStore.availableModels.isEmpty {
                Picker("选择模型", selection: $settingsStore.settings.selectedModel) {
                    ForEach(settingsStore.availableModels) { model in
                        Text(model.id).tag(model.id)
                    }
                }
                .pickerStyle(.menu)
                .tint(AppTheme.cherry)
            }

            CuteButton(
                title: settingsStore.isFetchingModels ? "正在拉取模型…" : "拉取模型列表",
                systemImage: "arrow.down.circle.fill",
                style: .secondary
            ) {
                Task {
                    await settingsStore.fetchModels()
                }
            }
            .disabled(settingsStore.isFetchingModels)
            .opacity(settingsStore.isFetchingModels ? 0.62 : 1)
            .accessibilityIdentifier("aiSettings.fetchModelsButton")
        }
    }

    private var fallbackToggle: some View {
        let hasFallbackURL = !settingsStore.settings.fallbackBaseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return Toggle(isOn: $settingsStore.settings.useFallbackWhenPrimaryFails) {
            VStack(alignment: .leading, spacing: 3) {
                Text("主地址失败后自动使用备用地址")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.text)
                if !hasFallbackURL {
                    Text("填写备用 Base URL 后可开启")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
        .tint(AppTheme.cherry)
        .disabled(!hasFallbackURL)
        .opacity(hasFallbackURL ? 1 : 0.58)
        .padding(12)
        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityIdentifier("aiSettings.fallbackToggle")
    }

    #if DEBUG
    private var mockToggle: some View {
        Toggle(isOn: $settingsStore.settings.enableMockParsing) {
            VStack(alignment: .leading, spacing: 3) {
                Text("开发 Mock 解析")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.text)
                Text("默认关闭，只用于本地验证界面")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .tint(AppTheme.cherry)
        .padding(12)
        .background(AppTheme.primary.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityIdentifier("aiSettings.mockToggle")
    }
    #endif

    private func labeledTextField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        keyboard: UIKeyboardType
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(AppTheme.text)
            TextField(placeholder, text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(keyboard)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.text)
                .padding(13)
                .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        }
    }

    private func smallActionButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(AppTheme.cherry)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .padding(.vertical, 9)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.82), in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        }
        .buttonStyle(CutePressButtonStyle())
    }

    private func statusText(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(AppTheme.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
    }
}

#if DEBUG
struct AISettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            DottedBackground().ignoresSafeArea()
            AISettingsView(settingsStore: AISettingsStore())
                .padding()
        }
    }
}
#endif
