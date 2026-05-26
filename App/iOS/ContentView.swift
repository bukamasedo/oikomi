import OikomiKit
import SwiftData
import SwiftUI

struct ContentView: View {

    @State private var showingOnboarding = !OnboardingState.isCompleted

    @Environment(\.scenePhase) private var scenePhase

    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt == nil })
    private var activeSessions: [WorkoutSession]

    /// レストタイマーの真実のソース。全タブ共通の下部 inset で表示するため、
    /// `WorkoutTabView` のローカル State ではなくここで観察する。
    @State private var restStore = RestTimerStore.shared

    @State private var selectedTab: Tab = .home

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
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView(isPresented: $showingOnboarding)
        }
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
