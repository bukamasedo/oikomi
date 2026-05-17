import SwiftUI

struct ContentView: View {

    @State private var showingOnboarding = !OnboardingState.isCompleted

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("ホーム", systemImage: "house") }

            WorkoutTabView()
                .tabItem { Label("トレーニング", systemImage: "figure.strengthtraining.traditional") }

            HistoryView()
                .tabItem { Label("履歴", systemImage: "calendar") }

            AnalysisTabView()
                .tabItem { Label("分析", systemImage: "chart.xyaxis.line") }

            SettingsTabView()
                .tabItem { Label("設定", systemImage: "gearshape") }
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView(isPresented: $showingOnboarding)
        }
    }
}

#Preview {
    ContentView()
}
