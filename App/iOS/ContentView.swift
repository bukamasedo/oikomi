import SwiftData
import SwiftUI
import OikomiKit

struct ContentView: View {

    @Environment(\.modelContext) private var modelContext
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
        .onReceive(NotificationCenter.default.publisher(for: WCSyncBridge.dataDidChangeNotification)) { _ in
            // Watch / iPhone 相手から変更通知を受け取った時、SwiftData にリフレッシュを促す
            // @Query は内部ストア変更で自動更新するため、refresh で CloudKit fetch を促進
            modelContext.processPendingChanges()
        }
    }
}

#Preview {
    ContentView()
}
