import OikomiKit
import SwiftUI

/// 履歴フィードの 1 ワークアウトを表す行。
///
/// ルーティン名を主見出しに、日付 + 曜日 + 時刻をサブタイトルに、主要種目とセット・所要時間を続ける、
/// 一般的なリスト行レイアウト。カードの枠（背景・余白）は持たず、複数行を 1 枚のカードにまとめる親側が付与する。
struct WorkoutHistoryRow: View {

    let session: WorkoutSession

    /// 「6月3日(火) 14:30」のようなメタ行。
    private var dateTimeText: String {
        let date = session.startedAt.formatted(.dateTime.month(.abbreviated).day())
        let weekday = session.startedAt.formatted(.dateTime.weekday(.short))
        let time = session.startedAt.formatted(.dateTime.hour().minute())
        return "\(date)(\(weekday)) \(time)"
    }

    private var durationText: String {
        guard let endedAt = session.endedAt else { return "—" }
        let s = Int(endedAt.timeIntervalSince(session.startedAt))
        let m = s / 60
        let h = m / 60
        if h > 0 { return "\(h)h \(m % 60)m" }
        return "\(m) 分"
    }

    private var primaryExerciseNames: String {
        let names = (session.sets ?? [])
            .compactMap { $0.exercise?.name }
        var seen = Set<String>()
        var ordered: [String] = []
        for n in names where seen.insert(n).inserted {
            ordered.append(n)
            if ordered.count >= 3 { break }
        }
        return ordered.joined(separator: " / ")
    }

    var body: some View {
        HStack(alignment: .top, spacing: OikomiSpacing.m) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.routine?.name ?? "ルーティンなし")
                    .font(.headline)
                    .lineLimit(1)

                Text(dateTimeText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !primaryExerciseNames.isEmpty {
                    Text(primaryExerciseNames)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: OikomiSpacing.m) {
                    Label("\(session.sets?.count ?? 0) セット", systemImage: "list.bullet")
                    Label(durationText, systemImage: "clock")
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: OikomiSpacing.s)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
    }
}

/// `WorkoutHistoryRow` に標準カードの枠（背景・余白）を付けた単体カード。
/// コンテキストメニューのプレビューなど、行を単独で見せる用途で使う。
struct WorkoutHistoryCard: View {

    let session: WorkoutSession

    var body: some View {
        WorkoutHistoryRow(session: session)
            .padding(OikomiSpacing.l)
            .background(
                OikomiColor.cardBackground,
                in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
    }
}
