import SwiftData
import SwiftUI
import WidgetKit
import OikomiKit

/// ホーム画面・ロック画面・StandBy 対応のスタティック統計ウィジェット。
///
/// 仕様書 §4.1.4: 「ウィジェット: 小・中・大・ロック画面・StandBy 対応」。
/// v0.1 では「連続記録日数 / 今週のセッション数 / 直近 PR」を表示する小型ウィジェット。
struct StatsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "OikomiStatsWidget", provider: StatsProvider()) { entry in
            StatsWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Oikomi 統計")
        .description("連続記録日数と今週のトレーニング状況を表示")
        .supportedFamilies([
            .systemSmall, .systemMedium,
            .accessoryCircular, .accessoryRectangular, .accessoryInline,
        ])
    }
}

struct StatsEntry: TimelineEntry {
    let date: Date
    let streakDays: Int
    let weekSessionCount: Int
    let weekVolume: Double
    let latestPRExerciseName: String?
    let latestPRWeight: Double?
}

struct StatsProvider: TimelineProvider {

    func placeholder(in context: Context) -> StatsEntry {
        StatsEntry(
            date: Date(),
            streakDays: 3,
            weekSessionCount: 4,
            weekVolume: 12500,
            latestPRExerciseName: "ベンチプレス",
            latestPRWeight: 100
        )
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (StatsEntry) -> Void) {
        let entry = MainActor.assumeIsolated { readEntry() } ?? placeholder(in: context)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<StatsEntry>) -> Void) {
        let entry = MainActor.assumeIsolated { readEntry() } ?? placeholder(in: context)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    @MainActor
    private func readEntry() -> StatsEntry? {
        do {
            let container = try SharedModelContainer.bootstrap()
            let context = container.mainContext
            let sessions = try context.fetch(FetchDescriptor<WorkoutSession>())
            let completed = sessions.filter { $0.endedAt != nil }
            let allSets = completed.flatMap { $0.sets ?? [] }
            let streak = Analytics.streakDays(sessions: completed)
            let range = Analytics.currentWeekRange()
            let thisWeekSessions = completed.filter { range.contains($0.startedAt) }.count
            let weekVolume = Analytics.volumeByMuscleGroup(sets: allSets, in: range)
                .values.reduce(0, +)
            var prDescriptor = FetchDescriptor<PersonalRecord>(
                sortBy: [SortDescriptor(\.achievedAt, order: .reverse)]
            )
            prDescriptor.fetchLimit = 1
            let latestPR = try context.fetch(prDescriptor).first
            return StatsEntry(
                date: Date(),
                streakDays: streak,
                weekSessionCount: thisWeekSessions,
                weekVolume: weekVolume,
                latestPRExerciseName: latestPR?.exercise?.name,
                latestPRWeight: latestPR?.weight
            )
        } catch {
            return nil
        }
    }
}

struct StatsWidgetView: View {
    let entry: StatsEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            circular
        case .accessoryRectangular:
            rectangular
        case .accessoryInline:
            inline
        case .systemMedium:
            medium
        default:
            small
        }
    }

    @ViewBuilder
    private var small: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("連続記録", systemImage: "flame.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.orange)
            Text("\(entry.streakDays) 日")
                .font(.title.monospacedDigit().weight(.semibold))

            Spacer(minLength: 4)

            HStack(spacing: 4) {
                Text("今週")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(entry.weekSessionCount) セッション")
                    .font(.caption.monospacedDigit().weight(.medium))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var medium: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Label("連続", systemImage: "flame.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
                Text("\(entry.streakDays) 日")
                    .font(.title.monospacedDigit().weight(.semibold))
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text("今週")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("\(entry.weekSessionCount) セッション")
                    .font(.body.monospacedDigit())
                Text("\(entry.weekVolume.formatted(.number.precision(.fractionLength(0)))) kg")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let name = entry.latestPRExerciseName, let weight = entry.latestPRWeight {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("直近 PR")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(name)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                    Text("\(weight.formatted())kg")
                        .font(.caption.monospacedDigit())
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var circular: some View {
        ZStack {
            Circle().stroke(Color.orange.opacity(0.3), lineWidth: 2)
            VStack(spacing: -2) {
                Image(systemName: "flame.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                Text("\(entry.streakDays)")
                    .font(.title3.monospacedDigit().weight(.semibold))
            }
        }
    }

    @ViewBuilder
    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("\(entry.streakDays) 日連続", systemImage: "flame.fill")
                .font(.caption.weight(.semibold))
            Text("今週 \(entry.weekSessionCount) セッション")
                .font(.caption2)
            if let name = entry.latestPRExerciseName {
                Text("直近 PR: \(name)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private var inline: some View {
        Label("\(entry.streakDays) 日連続 · 今週 \(entry.weekSessionCount) 回", systemImage: "flame.fill")
    }
}
