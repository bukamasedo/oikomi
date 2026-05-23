import OikomiKit
import SwiftUI

/// 履歴フィードの 1 行に置く、1 ワークアウトサマリーカード。Apple Fitness の Workout 履歴カード風。
///
/// 左に時刻 / 曜日、中央にルーティン名と主要種目、右に総セット・所要時間。
struct WorkoutHistoryCard: View {

    let session: WorkoutSession

    private var dateText: String {
        session.startedAt.formatted(.dateTime.month(.abbreviated).day())
    }

    private var weekdayText: String {
        session.startedAt.formatted(.dateTime.weekday(.short))
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
            VStack(spacing: 2) {
                Text(weekdayText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(dateText)
                    .font(.subheadline.weight(.semibold))
            }
            .frame(width: 56)
            .padding(.vertical, OikomiSpacing.s)
            .background(
                OikomiColor.elevatedBackground,
                in: RoundedRectangle(cornerRadius: OikomiRadius.tile, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(session.routine?.name ?? "ルーティンなし")
                    .font(.headline)
                    .lineLimit(1)
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
        .padding(OikomiSpacing.l)
        .background(
            OikomiColor.cardBackground, in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
    }
}
