import OikomiKit
import SwiftUI

/// ホームの「コーチング」セクションから「すべて見る」で開く、全コーチング助言の一覧画面。
///
/// ホーム側で算出済みの `[CoachingAdvice]`（severity → impact 順）をそのまま縦に並べて表示する。
/// 表示専用のためデータ取得はせず、ホームのスナップショットを引き継ぐ。
struct CoachingListView: View {

    let advice: [CoachingAdvice]

    var body: some View {
        ScrollView {
            if advice.isEmpty {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: OikomiSpacing.m) {
                    ForEach(advice) { item in
                        CoachingChip(advice: item, fillsWidth: true)
                    }
                }
                .padding(.horizontal, OikomiSpacing.l)
                .padding(.vertical, OikomiSpacing.l)
            }
        }
        .scrollContentBackground(.hidden)
        .background(OikomiColor.appBackground)
        .navigationTitle("コーチング")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: OikomiSpacing.m) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("今はアドバイスがありません")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, OikomiSpacing.xxl)
    }
}

#Preview {
    NavigationStack {
        CoachingListView(advice: [
            CoachingAdvice(
                title: "今日は回復優先",
                message: "コンディションスコアが 32 と低めです。前回比 80% 程度の重量で軽めに組むことを検討してください。",
                severity: .warning,
                impact: 6800
            ),
            CoachingAdvice(
                title: "重量を上げてみましょう",
                message: "ベンチプレスは直近2回とも余裕（RPE 6 以下）でした。次回は 60kg → 62.5kg を目安に。",
                severity: .info,
                impact: 52
            ),
            CoachingAdvice(
                title: "安定したペース",
                message: "今週の背中は先週とほぼ同じボリュームを維持できています。",
                severity: .success,
                impact: 1200
            ),
        ])
    }
}
