import SwiftUI

struct AppRootView: View {
    @StateObject private var viewModel = LedgerViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var isShowingRecurringDue = false

    var body: some View {
        TabView {
            NavigationStack {
                HomeView(viewModel: viewModel)
            }
            .tabItem {
                Label("首页", systemImage: "house.fill")
            }

            NavigationStack {
                RecordsView(viewModel: viewModel)
            }
            .tabItem {
                Label("全部记录", systemImage: "list.bullet.rectangle.portrait.fill")
            }

            NavigationStack {
                StatsView(viewModel: viewModel)
            }
            .tabItem {
                Label("统计", systemImage: "chart.bar.xaxis")
            }

            NavigationStack {
                SettingsView(viewModel: viewModel)
            }
            .tabItem {
                Label("设置", systemImage: "gearshape.fill")
            }
        }
        .tint(AppTheme.cherry)
        .overlay(alignment: .top) {
            if let message = viewModel.toastMessage {
                ToastView(message: message)
                    .padding(.top, 12)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.dismissToast()
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $viewModel.isPresentingAddRecord) {
            AddRecordView(viewModel: viewModel, draft: viewModel.addRecordDraft)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingRecurringDue) {
            RecurringDueSheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            refreshRecurringDueSheet()
        }
        .onChange(of: scenePhase) { newPhase in
            guard newPhase == .active else { return }
            refreshRecurringDueSheet()
        }
        .onOpenURL { url in
            guard url.scheme == "beanledger", url.host == "add" || url.path == "/add" else { return }
            viewModel.presentAddRecord()
        }
    }

    private func refreshRecurringDueSheet() {
        viewModel.checkDueRecurringTemplates()
        isShowingRecurringDue = !viewModel.dueRecurringTemplates.isEmpty && !viewModel.isPresentingAddRecord
    }
}

#if DEBUG
struct AppRootView_Previews: PreviewProvider {
    static var previews: some View {
        AppRootView()
    }
}
#endif
