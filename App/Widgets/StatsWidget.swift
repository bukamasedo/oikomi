import OikomiKit
import SwiftData
import SwiftUI
import WidgetKit

/// ホーム画面・ロック画面・StandBy・Smart Stack 対応の統計ウィジェット。
///
/// 仕様書 §4.1.4: 「ウィジェット: 小・中・大・ロック画面・StandBy 対応」。
/// 今週の達成日数 / 連続活動週数 / 今週のセッション数 / 今週ボリューム / 直近 PR / HRV を表示する。
struct StatsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "OikomiStatsWidget", provider: StatsProvider()) { entry in
            StatsWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Oikomi 統計")
        .description("今週の達成日数とトレーニング状況を表示")
        .supportedFamilies(supportedFamilies)
    }

    private var supportedFamilies: [WidgetFamily] {
        #if os(watchOS)
            return [
                .accessoryCircular, .accessoryRectangular, .accessoryInline,
                .accessoryCorner,
            ]
        #else
            return [
                .systemSmall, .systemMedium,
                .accessoryCircular, .accessoryRectangular, .accessoryInline,
            ]
        #endif
    }
}

struct StatsEntry: TimelineEntry {
    let date: Date
    /// 今週の実施日数。同日複数セッションは 1 日扱い。
    let weekDays: Int
    /// ユーザー設定の週次目標日数（リング満員の基準）。
    let weeklyTarget: Int
    /// 連続活動週数。0 のときはサブラベル非表示。
    let consecutiveWeeks: Int
    let weekSessionCount: Int
    let weekVolume: Double
    let latestPRExerciseName: String?
    let latestPRWeight: Double?
    /// 直近の HRV（SDNN, ms）。HealthSnapshot が無い / Pro 未契約なら nil。
    let latestHRV: Double?
    /// Pro 機能 (HealthKit 読み取り) が有効か。Free ユーザーには HRV プレースホルダを出す。
    let isProActive: Bool
}

struct StatsProvider: TimelineProvider {

    func placeholder(in context: Context) -> StatsEntry {
        StatsEntry(
            date: Date(),
            weekDays: 3,
            weeklyTarget: 4,
            consecutiveWeeks: 6,
            weekSessionCount: 4,
            weekVolume: 12500,
            latestPRExerciseName: "ベンチプレス",
            latestPRWeight: 100,
            latestHRV: 42,
            isProActive: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (StatsEntry) -> Void) {
        let entry = MainActor.assumeIsolated { readEntry() } ?? placeholder(in: context)
        completion(entry)
    }

    func getTimeline(
        in context: Context, completion: @escaping @Sendable (Timeline<StatsEntry>) -> Void
    ) {
        let entry = MainActor.assumeIsolated { readEntry() } ?? placeholder(in: context)
        // 主リロード経路はアプリ側の WidgetCenter.reloadTimelines。
        // ここは長時間 foreground に出ないケースの保険なので 15 分に短縮。
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
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
            let range = Analytics.currentWeekRange()
            let weekDays = Analytics.weeklySessionDays(sessions: completed, in: range)
            let consecutiveWeeks = Analytics.consecutiveActiveWeeks(sessions: completed)
            let thisWeekSessions = completed.filter { range.contains($0.startedAt) }.count
            let weekVolume = Analytics.volumeByMuscleGroup(sets: allSets, in: range)
                .values.reduce(0, +)
            var prDescriptor = FetchDescriptor<PersonalRecord>(
                sortBy: [SortDescriptor(\.achievedAt, order: .reverse)]
            )
            prDescriptor.fetchLimit = 1
            let latestPR = try context.fetch(prDescriptor).first

            let isProActive = UserDefaults.standard.bool(
                forKey: SubscriptionManager.lastKnownProActiveKey
            )
            var latestHRV: Double?
            if isProActive {
                var hrvDescriptor = FetchDescriptor<HealthSnapshot>(
                    sortBy: [SortDescriptor(\.date, order: .reverse)]
                )
                hrvDescriptor.fetchLimit = 1
                latestHRV = (try? context.fetch(hrvDescriptor).first?.hrvSDNN) ?? nil
            }

            return StatsEntry(
                date: Date(),
                weekDays: weekDays,
                weeklyTarget: WeeklyTrainingTarget.currentTarget(),
                consecutiveWeeks: consecutiveWeeks,
                weekSessionCount: thisWeekSessions,
                weekVolume: weekVolume,
                latestPRExerciseName: latestPR?.exercise?.name,
                latestPRWeight: latestPR?.weight,
                latestHRV: latestHRV,
                isProActive: isProActive
            )
        } catch {
            return nil
        }
    }
}

struct StatsWidgetView: View {
    let entry: StatsEntry

    @Environment(\.widgetFamily) var family

    /// 週次目標に対する達成進捗（0〜1）。リング表示の正規化に使う。
    private var weekProgress: Double {
        guard entry.weeklyTarget > 0 else { return 0 }
        return max(0, min(1, Double(entry.weekDays) / Double(entry.weeklyTarget)))
    }

    private var isWeekComplete: Bool { entry.weekDays >= entry.weeklyTarget }

    var body: some View {
        switch family {
        case .accessoryCircular:
            circular
        case .accessoryRectangular:
            rectangular
        case .accessoryInline:
            inline
        default:
            #if os(watchOS)
                if family == .accessoryCorner {
                    corner
                } else {
                    // watchOS では accessory ファミリーのみサポート。fallback も circular に。
                    circular
                }
            #else
                if family == .systemMedium {
                    medium
                } else {
                    small
                }
            #endif
        }
    }

    // MARK: - Home Screen sizes (iOS only)

    #if !os(watchOS)
        @ViewBuilder
        private var small: some View {
            VStack(alignment: .leading, spacing: WidgetSpacing.s) {
                weekHero(compact: false)

                Spacer(minLength: WidgetSpacing.s)

                if entry.consecutiveWeeks > 0 {
                    Label("\(entry.consecutiveWeeks) 週連続", systemImage: "flame.fill")
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(WidgetColor.brand)
                        .lineLimit(1)
                } else {
                    HStack(spacing: WidgetSpacing.s) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(WidgetColor.brand)
                        Text("今週 \(entry.weekSessionCount) セッション")
                            .font(.caption.monospacedDigit().weight(.medium))
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }

        @ViewBuilder
        private var medium: some View {
            HStack(spacing: WidgetSpacing.l) {
                weekHero(compact: true)
                    .frame(maxWidth: 96)

                VStack(alignment: .leading, spacing: WidgetSpacing.s) {
                    if entry.consecutiveWeeks > 0 {
                        Label("\(entry.consecutiveWeeks) 週連続", systemImage: "flame.fill")
                            .font(.caption.monospacedDigit().weight(.semibold))
                            .foregroundStyle(WidgetColor.brand)
                    } else {
                        Text("今週")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(entry.weekSessionCount)")
                            .font(.title2.monospacedDigit().weight(.semibold))
                        Text("セッション")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(
                            "\(entry.weekVolume.formatted(.number.precision(.fractionLength(0))))"
                        )
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        Text("kg")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    hrvBadge
                }

                Spacer(minLength: WidgetSpacing.s)

                if let name = entry.latestPRExerciseName, let weight = entry.latestPRWeight {
                    prChip(name: name, weight: weight)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

        /// 今週の達成 ring + X/Y 数字 + ラベル。Apple Fitness Move リング風。
        @ViewBuilder
        private func weekHero(compact: Bool) -> some View {
            let ringSize: CGFloat = compact ? 76 : 92
            ZStack {
                Circle()
                    .stroke(WidgetColor.brand.opacity(0.18), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: weekProgress)
                    .stroke(
                        AngularGradient(
                            colors: [WidgetColor.brand, WidgetColor.brandSecondary, WidgetColor.brand],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Image(systemName: isWeekComplete ? "checkmark.seal.fill" : "figure.strengthtraining.traditional")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(WidgetColor.brand)
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text("\(entry.weekDays)")
                            .font(.title.monospacedDigit().weight(.bold))
                        Text("/\(entry.weeklyTarget)")
                            .font(.caption.monospacedDigit().weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    Text("今週")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: ringSize, height: ringSize)
        }

        @ViewBuilder
        private func prChip(name: String, weight: Double) -> some View {
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 2) {
                    Image(systemName: "trophy.fill")
                        .font(.caption2)
                        .foregroundStyle(WidgetColor.brandSecondary)
                    Text("直近 PR")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Text(name)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Text("\(weight.formatted()) kg")
                    .font(.caption.monospacedDigit())
            }
        }

        @ViewBuilder
        private var hrvBadge: some View {
            if entry.isProActive {
                if let hrv = entry.latestHRV {
                    Label(
                        "HRV \(hrv.formatted(.number.precision(.fractionLength(0))))ms",
                        systemImage: "waveform.path.ecg"
                    )
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                } else {
                    Label("HRV —", systemImage: "waveform.path.ecg")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            } else {
                Label("HRV Pro", systemImage: "star.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(WidgetColor.proAccent)
            }
        }
    #endif

    // MARK: - Accessory family (iOS Lock Screen / Watch Smart Stack)

    @ViewBuilder
    private var circular: some View {
        ZStack {
            Circle()
                .stroke(WidgetColor.brand.opacity(0.25), lineWidth: 2)
            Circle()
                .trim(from: 0, to: weekProgress)
                .stroke(WidgetColor.brand, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: -2) {
                Image(systemName: isWeekComplete ? "checkmark.seal.fill" : "figure.strengthtraining.traditional")
                    .font(.caption2)
                    .foregroundStyle(WidgetColor.brand)
                Text("\(entry.weekDays)/\(entry.weeklyTarget)")
                    .font(.callout.monospacedDigit().weight(.semibold))
            }
        }
        .widgetAccentable()
    }

    @ViewBuilder
    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            Label("今週 \(entry.weekDays) / \(entry.weeklyTarget) 日", systemImage: "figure.strengthtraining.traditional")
                .font(.caption.monospacedDigit().weight(.semibold))
                .widgetAccentable()
            if entry.consecutiveWeeks > 0 {
                Label("\(entry.consecutiveWeeks) 週連続・\(entry.weekSessionCount) セッション", systemImage: "flame.fill")
                    .font(.caption2.monospacedDigit())
                    .lineLimit(1)
            } else {
                Text("\(entry.weekSessionCount) セッション・\(Int(entry.weekVolume)) kg")
                    .font(.caption2.monospacedDigit())
                    .lineLimit(1)
            }
            if let name = entry.latestPRExerciseName {
                Text("PR: \(name)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    /// watchOS の文字盤コーナー（Infograph 等）に配置される極小スロット。
    /// 中央のアイコン + widgetLabel に進捗を出すのが Apple HIG 推奨スタイル。
    #if os(watchOS)
        @ViewBuilder
        private var corner: some View {
            Image(systemName: isWeekComplete ? "checkmark.seal.fill" : "figure.strengthtraining.traditional")
                .font(.title3.weight(.semibold))
                .widgetAccentable()
                .widgetLabel {
                    Gauge(value: weekProgress) {
                        Text("今週")
                    } currentValueLabel: {
                        Text("\(entry.weekDays)/\(entry.weeklyTarget)")
                            .monospacedDigit()
                    }
                    .gaugeStyle(.accessoryLinearCapacity)
                }
        }
    #endif

    @ViewBuilder
    private var inline: some View {
        if entry.consecutiveWeeks > 0 {
            Label(
                "今週 \(entry.weekDays)/\(entry.weeklyTarget) 日 · \(entry.consecutiveWeeks) 週連続",
                systemImage: "figure.strengthtraining.traditional"
            )
        } else {
            Label(
                "今週 \(entry.weekDays)/\(entry.weeklyTarget) 日 · \(entry.weekSessionCount) セッション",
                systemImage: "figure.strengthtraining.traditional"
            )
        }
    }
}
