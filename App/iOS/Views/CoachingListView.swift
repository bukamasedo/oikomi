import OikomiKit
import SwiftUI

/// ホームの「コーチング」セクションから「すべて見る」で開く、全コーチング助言の一覧画面。
///
/// ホーム側で算出済みの `[CoachingAdvice]`（severity → impact 順）を、
/// 1 枚のグループ化カード内に区切り線つきの行として並べる（iOS 設定/ヘルスケア風）。
/// 1 件ごとにカード化すると断片的で読みにくいため、アプリ既存の「カード + インセット Divider」イディオムに揃える。
struct CoachingListView: View {

    let advice: [CoachingAdvice]

    var weightUnit: WeightUnit = .kg

    var body: some View {
        ScrollView {
            if advice.isEmpty {
                emptyState
            } else {
                // ホームのコーチングカードと同じグループ化表示。一覧は全件・全対象を出す。
                CoachingGroupedView(
                    groups: Analytics.groupedCoaching(advice), weightUnit: weightUnit
                )
                .padding(OikomiSpacing.l)
                .background(
                    OikomiColor.cardBackground,
                    in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous)
                )
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
