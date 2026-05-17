import SwiftUI

struct WatchContentView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("ルーティン開始") {
                    Text("ワークアウト中")
                }
                NavigationLink("直近セッション") {
                    Text("履歴")
                }
            }
            .navigationTitle("Oikomi")
        }
    }
}

#Preview {
    WatchContentView()
}
