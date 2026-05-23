import OikomiKit
import SwiftData
import SwiftUI

struct ContentView: View {

    @State private var showingOnboarding = !OnboardingState.isCompleted

    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt == nil })
    private var activeSessions: [WorkoutSession]

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("ホーム", systemImage: "house.fill") }

            WorkoutTabView()
                .tabItem {
                    Label("トレーニング", systemImage: "figure.strengthtraining.traditional")
                }
                .badge(activeSessions.isEmpty ? 0 : 1)

            HistoryView()
                .tabItem { Label("履歴", systemImage: "calendar") }

            AnalysisTabView()
                .tabItem { Label("分析", systemImage: "chart.xyaxis.line") }

            SettingsTabView()
                .tabItem { Label("設定", systemImage: "gearshape.fill") }
        }
        .tint(OikomiColor.brandPrimary)
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView(isPresented: $showingOnboarding)
        }
    }
}

#Preview {
    ContentView()
}
