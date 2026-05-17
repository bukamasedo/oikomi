import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("ホーム", systemImage: "house") }

            WorkoutTabView()
                .tabItem { Label("トレーニング", systemImage: "figure.strengthtraining.traditional") }

            HistoryView()
                .tabItem { Label("履歴", systemImage: "calendar") }
        }
    }
}

#Preview {
    ContentView()
}
