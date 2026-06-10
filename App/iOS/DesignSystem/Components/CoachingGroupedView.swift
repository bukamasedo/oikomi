import OikomiKit
import SwiftUI

/// コーチング助言を「カテゴリ見出し（アイコン付き）＋ 対象ごとの簡潔な行」でまとめて描画する共有ビュー。
///
/// 「ボリューム不足」「PR 更新の可能性」のような同種の助言を 1 つの見出しの下にグループ化し、
/// 各対象を「肩 … 先週比 38%」のような subject + detail の 1 行で並べる。
/// 対象を持たない助言（休息・体組成フェーズなど subject == nil）は `message` をそのまま表示する。
///
/// ホーム（カード内）と一覧（`CoachingListView`）で見た目を共有するため、外枠（カード/見出し）は持たない。
struct CoachingGroupedView: View {

    let groups: [CoachingAdviceGroup]

    /// 各グループで表示する対象の上限。nil なら全件。ホームはコンパクトに保つため指定する。
    var maxItemsPerGroup: Int? = nil

    /// `trend`（kg 系列）をスパークライン表示する際の変換先単位。ホームから渡す。
    var weightUnit: WeightUnit = .kg

    var body: some View {
        VStack(alignment: .leading, spacing: OikomiSpacing.m) {
            ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                if index > 0 {
                    Rectangle()
                        .fill(OikomiColor.separator.opacity(0.6))
                        .frame(height: 1)
                        .padding(.leading, 42)
                        .padding(.vertical, OikomiSpacing.xs)
                }
                groupView(group)
            }
        }
    }

    @ViewBuilder
    private func groupView(_ group: CoachingAdviceGroup) -> some View {
        let items = maxItemsPerGroup.map { Array(group.items.prefix($0)) } ?? group.items
        let hidden = group.items.count - items.count

        VStack(alignment: .leading, spacing: OikomiSpacing.s) {
            // カテゴリ見出し: severity 色のバッジタイル＋タイトル＋（複数なら）件数チップ。
            // カード外の見出しは廃し、カード内のこれに集約する。
            HStack(spacing: OikomiSpacing.s) {
                ZStack {
                    RoundedRectangle(cornerRadius: OikomiRadius.tile, style: .continuous)
                        .fill(group.severity.coachingTint.opacity(0.16))
                    Image(systemName: group.severity.coachingIconName)
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(group.severity.coachingTint)
                }
                .frame(width: 30, height: 30)

                Text(group.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                if group.items.count > 1 {
                    Text("\(group.items.count)")
                        .font(.caption2.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(group.severity.coachingTint)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(group.severity.coachingTint.opacity(0.14), in: Capsule())
                }

                Spacer(minLength: 0)
            }

            // グループ内に推移グラフを持つ行があるときだけ、全行でグラフ列を確保して右端を揃える。
            // グラフを持たないグループ（ボリュームなど）では余白を作らずコンパクトに保つ。
            let groupHasTrend = group.items.contains { ($0.trend?.count ?? 0) >= 2 }
            ForEach(items) { item in
                itemRow(item, reserveTrendColumn: groupHasTrend)
            }

            if hidden > 0 {
                Text(String(localized: "ほか \(hidden) 件"))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    /// 全行で揃えるグラフ列の固定幅（中央列）。
    private static let trendColumnWidth: CGFloat = 56
    /// グラフ列を確保する行で、数値 pill を右寄せ配置する固定幅（右端列）。
    /// "150.0kg 狙い" / "横ばい NN 回" など実際の detail が省略されない幅にする。
    private static let detailColumnWidth: CGFloat = 104

    /// 対象を持つ助言は「subject … グラフ … detail」の 1 行、持たない助言は説明文を表示する。
    ///
    /// `reserveTrendColumn` が true の間は、グラフ列（中央）と detail 列（右端）を固定幅にし、
    /// グラフが無い行でも空き列を確保して、行をまたいでグラフと数値の位置を揃える。
    @ViewBuilder
    private func itemRow(_ item: CoachingAdvice, reserveTrendColumn: Bool) -> some View {
        if let subject = item.subject {
            HStack(alignment: .center, spacing: OikomiSpacing.s) {
                Text(subject)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer(minLength: OikomiSpacing.s)

                // グラフは中央列に固定配置。グラフが無い行も列だけ確保して位置を揃える。
                if reserveTrendColumn {
                    Group {
                        if let trend = item.trend, trend.count >= 2 {
                            MiniSparkline(
                                series: trend.map { weightUnit.fromKilograms($0) },
                                tint: item.severity.coachingTint
                            )
                        } else {
                            Color.clear
                        }
                    }
                    .frame(width: CoachingGroupedView.trendColumnWidth, height: 22)
                }

                if let detail = item.detail {
                    detailPill(detail, tint: item.severity.coachingTint)
                        .frame(
                            width: reserveTrendColumn ? CoachingGroupedView.detailColumnWidth : nil,
                            alignment: .trailing)
                }
            }
        } else {
            Text(item.message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// 数値（"先週比 38%" / "85kg 狙い" など）を severity 色の pill で表示する。
    private func detailPill(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(tint)
            .lineLimit(1)
            .padding(.horizontal, OikomiSpacing.s)
            .padding(.vertical, 3)
            .background(tint.opacity(0.12), in: Capsule())
    }
}

/// severity → アイコン/色。チップ・一覧・グループ表示で共有する。
extension CoachingAdvice.Severity {
    var coachingIconName: String {
        switch self {
        case .warning: return "exclamationmark.triangle.fill"
        case .success: return "checkmark.seal.fill"
        case .info: return "info.circle.fill"
        }
    }

    var coachingTint: Color {
        switch self {
        case .warning: return .orange
        case .success: return .green
        case .info: return .blue
        }
    }
}

#Preview("Grouped") {
    let advice = [
        CoachingAdvice(
            title: "ボリューム不足", message: "肩", severity: .warning, impact: 30,
            subject: "肩", detail: "先週比 38%"),
        CoachingAdvice(
            title: "ボリューム不足", message: "腕", severity: .warning, impact: 20,
            subject: "上腕二頭筋", detail: "先週比 42%"),
        CoachingAdvice(
            title: "PR 更新の可能性", message: "ベンチ", severity: .info, impact: 15,
            subject: "ベンチプレス", detail: "85.0kg 狙い"),
        CoachingAdvice(
            title: "今日は回復優先",
            message: "コンディションスコアが 32 と低めです。前回比 80% 程度で軽めに。",
            severity: .warning, impact: 10),
    ]
    return CoachingGroupedView(groups: Analytics.groupedCoaching(advice))
        .padding(OikomiSpacing.l)
        .background(
            RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous)
                .fill(OikomiColor.cardBackground)
        )
        .padding()
        .background(OikomiColor.appBackground)
}
