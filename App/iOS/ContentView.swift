import OikomiKit
import SwiftData
import SwiftUI

struct ContentView: View {

    @State private var showingOnboarding = !OnboardingState.isCompleted

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt == nil })
    private var activeSessions: [WorkoutSession]

    /// レストタイマーの真実のソース。全タブ共通の下部 inset で表示するため、
    /// `WorkoutTabView` のローカル State ではなくここで観察する。
    @State private var restStore = RestTimerStore.shared

    @State private var selectedTab: Tab = .history

    enum Tab: Hashable {
        case home, workout, history, analysis, settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem { Label("ホーム", systemImage: "house.fill") }
                .tag(Tab.home)
                .restTimerOverlay(active: !activeSessions.isEmpty, onSkip: skipRestTimer)

            WorkoutTabView()
                .tabItem {
                    Label("トレーニング", systemImage: "figure.strengthtraining.traditional")
                }
                .badge(activeSessions.isEmpty ? 0 : 1)
                .tag(Tab.workout)
                .restTimerOverlay(active: !activeSessions.isEmpty, onSkip: skipRestTimer)

            HistoryView()
                .tabItem { Label("履歴", systemImage: "calendar") }
                .tag(Tab.history)
                .restTimerOverlay(active: !activeSessions.isEmpty, onSkip: skipRestTimer)

            AnalysisTabView()
                .tabItem { Label("分析", systemImage: "chart.xyaxis.line") }
                .tag(Tab.analysis)
                .restTimerOverlay(active: !activeSessions.isEmpty, onSkip: skipRestTimer)

            SettingsTabView()
                .tabItem { Label("設定", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
                .restTimerOverlay(active: !activeSessions.isEmpty, onSkip: skipRestTimer)
        }
        .tint(OikomiColor.brandPrimary)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                restStore.expireIfPast()
            }
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView(isPresented: $showingOnboarding)
        }
    }

    /// ウィジェット / Live Activity からのディープリンクを処理する。
    /// `oikomi://routine/start?id=<UUID>` は該当ルーティンでセッションを開始し、
    /// それ以外（`oikomi://workout` 含む）は単にトレーニングタブを開く。
    /// 開始失敗時もタブ遷移は行う（ウィジェット起点でアラート提示の手段が乏しいため）。
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "oikomi" else { return }

        if url.host == "routine", url.pathComponents.contains("start"),
            let idString = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "id" })?.value,
            let id = UUID(uuidString: idString)
        {
            startRoutine(id: id)
        }

        selectedTab = .workout
    }

    private func startRoutine(id: UUID) {
        let descriptor = FetchDescriptor<Routine>(
            predicate: #Predicate { $0.id == id }
        )
        guard let routine = try? modelContext.fetch(descriptor).first else { return }
        let repo = WorkoutSessionRepository(context: modelContext)
        try? repo.startSession(routine: routine)
    }

    private func skipRestTimer() {
        restStore.cancel()
        RestTimerNotifier.cancel()
        WCSyncBridge.shared.sendRestTimerCancel()
        Task { @MainActor in
            await WorkoutActivityController.shared.clearRestEnd()
        }
    }
}

/// 各タブ View の bottom safe area にレストタイマーカードを挿入する modifier。
/// TabView 全体に `.safeAreaInset` を貼ると TabBar の下に積まれてしまうため、
/// タブ単位で貼ることで TabBar の真上にフラットな box を配置する。
private struct RestTimerOverlayModifier: ViewModifier {

    let active: Bool
    let onSkip: () -> Void

    @State private var restStore = RestTimerStore.shared

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if active, let endAt = restStore.endAt {
                    RestTimerCard(
                        endAt: endAt,
                        totalSeconds: restStore.totalSeconds,
                        onSkip: onSkip
                    )
                    .padding(.horizontal, OikomiSpacing.l)
                    .padding(.bottom, OikomiSpacing.s)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: restStore.endAt)
    }
}

extension View {
    fileprivate func restTimerOverlay(active: Bool, onSkip: @escaping () -> Void) -> some View {
        modifier(RestTimerOverlayModifier(active: active, onSkip: onSkip))
    }
}

#Preview {
    ContentView()
}
