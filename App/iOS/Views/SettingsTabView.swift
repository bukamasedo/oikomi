import SwiftUI

struct SettingsTabView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("アプリ") {
                    LabeledContent("バージョン") {
                        Text("0.1.0")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("今後実装予定") {
                    Label("HealthKit 連携", systemImage: "heart.text.square")
                        .foregroundStyle(.secondary)
                    Label("通知設定", systemImage: "bell")
                        .foregroundStyle(.secondary)
                    Label("iCloud 同期", systemImage: "icloud")
                        .foregroundStyle(.secondary)
                    Label("Pro へアップグレード", systemImage: "star")
                        .foregroundStyle(.secondary)
                }

                Section {
                    Text("Oikomi は開発中です。仕様書は docs/SPEC.md を参照してください。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("設定")
        }
    }
}

#Preview {
    SettingsTabView()
}
