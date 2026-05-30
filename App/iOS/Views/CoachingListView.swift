import OikomiKit
import SwiftUI

/// ホームの「コーチング」セクションから「すべて見る」で開く、全コーチング助言の一覧画面。
///
/// ホーム側で算出済みの `[CoachingAdvice]`（severity → impact 順）を、
/// 1 枚のグループ化カード内に区切り線つきの行として並べる（iOS 設定/ヘルスケア風）。
/// 1 件ごとにカード化すると断片的で読みにくいため、アプリ既存の「カード + インセット Divider」イディオムに揃える。
struct CoachingListView: View {

    let advice: [CoachingAdvice]

    var body: some View {
        ScrollView {
            if advice.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(advice.enumerated()), id: \.element.id) { index, item in
                        CoachingAdviceRow(advice: item)
                        if index < advice.count - 1 {
                            Divider()
                                .padding(.leading, OikomiSpacing.l + 22 + OikomiSpacing.m)
                        }
                    }
                }
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

/// 1 件の助言をコンパクトな行で表す。左端に severity 色のアイコン、右に見出し + 本文。
/// 行ごとの枠線は持たず、色は控えめなアクセント（先頭アイコン）としてのみ使う。
private struct CoachingAdviceRow: View {

    let advice: CoachingAdvice

    var body: some View {
        HStack(alignment: .top, spacing: OikomiSpacing.m) {
            Image(systemName: iconName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(severityColor)
                .frame(width: 22, alignment: .center)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: OikomiSpacing.xs) {
                Text(advice.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(advice.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, OikomiSpacing.l)
        .padding(.vertical, OikomiSpacing.m)
    }

    private var iconName: String {
        switch advice.severity {
        case .warning: return "exclamationmark.triangle.fill"
        case .success: return "checkmark.seal.fill"
        case .info: return "info.circle.fill"
        }
    }

    private var severityColor: Color {
        switch advice.severity {
        case .warning: return .orange
        case .success: return .green
        case .info: return .blue
        }
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
