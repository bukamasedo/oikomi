import OikomiKit
import SwiftData
import SwiftUI
import WidgetKit

/// ホーム画面・ロック画面・StandBy・Smart Stack 対応の統計ウィジェット。
///
/// 仕様書 §4.1.4: 「ウィジェット: 小・中・大・ロック画面・StandBy 対応」。
/// small / accessory は今週の達成日数・連続週・セッション数・ボリューム・直近 PR を、
/// medium（横長）は「今日のコンディション」（レディネス + HRV / 安静時心拍 / 睡眠）を表示する。
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
    /// 今週の総ボリューム（kg）。表示時に `weightUnit` で変換する。
    let weekVolume: Double
    let latestPRExerciseName: String?
    /// 直近 PR の重量（kg）。表示時に `weightUnit` で変換する。
    let latestPRWeight: Double?
    /// Pro 機能 (HealthKit 読み取り) が有効か。Free ユーザーにはコンディションの Pro 訴求を出す。
    let isProActive: Bool
    /// ユーザー設定の表示単位。`UnitPreference.current()` から取得。
    let weightUnit: WeightUnit

    // MARK: - 今日のコンディション（medium 用）
    // アプリ本体が算出し App Group に保存したスナップショット（`ConditionSnapshotStore`）由来。
    // 当日分が無い（アプリ未起動 / 日付またぎ）場合は全て nil。

    /// レディネススコア（0-100）。nil = 今日のスナップショット無し。
    let conditionValue: Int?
    let conditionBand: ReadinessScore.Band?
    /// データ不足時の注記。3 信号そろいなら nil。
    let conditionSourceNote: String?
    let conditionHRV: Double?
    let conditionRHR: Double?
    let conditionSleepHours: Double?

    // MARK: - 本日のルーティン（systemSmall 用）
    // アプリの `HomeView.todayRoutines` と同じ「曜日スケジュール済みの先頭ルーティン」。
    // タップで `oikomi://routine/start?id=` を開きアプリ本体が `startSession` する。

    /// 開始ディープリンク用のルーティン ID。nil = 本日のルーティンなし。
    let todayRoutineID: UUID?
    let todayRoutineName: String?
    let todayRoutineExerciseCount: Int
    /// 想定セット数の合計（`plannedSets` 合計、`HomeView.routineSummary` と同算出）。
    let todayRoutineSetCount: Int
    /// 進行中セッション（`endedAt == nil`）があればそのルーティン名。表示を「進行中」に切り替える。
    let activeSessionRoutineName: String?
    /// 進行中セッションが存在するか。ルーティン未紐付けでも true になりうる。
    let hasActiveSession: Bool
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
            isProActive: true,
            weightUnit: UnitPreference.current(),
            conditionValue: 72,
            conditionBand: .high,
            conditionSourceNote: nil,
            conditionHRV: 48,
            conditionRHR: 58,
            conditionSleepHours: 7.2,
            todayRoutineID: UUID(),
            todayRoutineName: "胸の日",
            todayRoutineExerciseCount: 3,
            todayRoutineSetCount: 9,
            activeSessionRoutineName: nil,
            hasActiveSession: false
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
            let thisWeekSessions = completed.count(where: { range.contains($0.startedAt) })
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

            // 横長ウィジェット用の「今日のコンディション」。当日分のみ採用。
            let condition = ConditionSnapshotStore.todaySnapshot()

            // 進行中セッション（systemSmall を「進行中」表示に切り替える）。
            let activeSession = sessions.first { $0.endedAt == nil }

            // 本日のルーティン。`HomeView.todayRoutines` と同じ並び＋曜日フィルタの先頭。
            var routineDescriptor = FetchDescriptor<Routine>(
                sortBy: [
                    SortDescriptor(\.lastUsedAt, order: .reverse),
                    SortDescriptor(\.createdAt),
                ]
            )
            routineDescriptor.fetchLimit = 50
            let todayRoutine = try context.fetch(routineDescriptor)
                .first { $0.isScheduled(on: Date()) }
            let todayExercises = todayRoutine?.orderedExercises ?? []

            return StatsEntry(
                date: Date(),
                weekDays: weekDays,
                weeklyTarget: WeeklyTrainingTarget.currentTarget(),
                consecutiveWeeks: consecutiveWeeks,
                weekSessionCount: thisWeekSessions,
                weekVolume: weekVolume,
                latestPRExerciseName: latestPR?.exercise?.localizedName,
                latestPRWeight: latestPR?.weight,
                isProActive: isProActive,
                weightUnit: UnitPreference.current(),
                conditionValue: condition?.value,
                conditionBand: condition.flatMap { ReadinessScore.Band(rawValue: $0.band) },
                conditionSourceNote: condition?.sourceNote,
                conditionHRV: condition?.hrv,
                conditionRHR: condition?.restingHeartRate,
                conditionSleepHours: condition?.sleepHours,
                todayRoutineID: todayRoutine?.id,
                todayRoutineName: todayRoutine?.name,
                todayRoutineExerciseCount: todayExercises.count,
                todayRoutineSetCount: todayExercises.reduce(0) { $0 + $1.plannedSets },
                activeSessionRoutineName: activeSession?.routine?.name,
                hasActiveSession: activeSession != nil
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
        /// 本日のルーティンを表示し、ウィジェット全体タップで開始（アプリ起動）へディープリンク。
        /// systemSmall は Link/Button 非対応のため widgetURL の単一タップターゲットで構成する。
        @ViewBuilder
        private var small: some View {
            Group {
                if entry.hasActiveSession {
                    smallActive
                } else if let name = entry.todayRoutineName {
                    smallToday(name: name)
                } else {
                    smallEmpty
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .widgetURL(smallDeepLink)
        }

        /// 状態別のディープリンク先。開始は routine/start、それ以外は workout タブ。
        private var smallDeepLink: URL? {
            if !entry.hasActiveSession, let id = entry.todayRoutineID {
                return URL(string: "oikomi://routine/start?id=\(id.uuidString)")
            }
            return URL(string: "oikomi://workout")
        }

        private var smallHeader: some View {
            Label("本日のルーティン", systemImage: "figure.strengthtraining.traditional")
                .font(.caption.weight(.semibold))
                .labelStyle(.titleAndIcon)
                .foregroundStyle(WidgetColor.brand)
                .lineLimit(1)
        }

        /// 進行中セッションあり。タップでトレーニングタブを開く。
        @ViewBuilder
        private var smallActive: some View {
            VStack(alignment: .leading, spacing: WidgetSpacing.s) {
                smallHeader
                Spacer(minLength: 0)
                Label("進行中", systemImage: "circle.fill")
                    .font(.headline)
                    .foregroundStyle(WidgetColor.brand)
                    .lineLimit(1)
                Text(entry.activeSessionRoutineName ?? "ワークアウト")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Spacer(minLength: 0)
                Text("タップで開く")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }

        /// 本日のルーティンあり。タップで開始（アプリ起動 → startSession）。
        @ViewBuilder
        private func smallToday(name: String) -> some View {
            VStack(alignment: .leading, spacing: WidgetSpacing.s) {
                smallHeader
                Spacer(minLength: 0)
                Text(name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Text("\(entry.todayRoutineExerciseCount) 種目 · \(entry.todayRoutineSetCount) セット")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Label("開始", systemImage: "play.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, WidgetSpacing.l)
                    .padding(.vertical, WidgetSpacing.m)
                    .background(WidgetColor.brand, in: Capsule())
            }
        }

        /// 本日のルーティンなし。タップでトレーニングタブ（ルーティン選択）を開く。
        @ViewBuilder
        private var smallEmpty: some View {
            VStack(alignment: .leading, spacing: WidgetSpacing.s) {
                smallHeader
                Spacer(minLength: 0)
                Image(systemName: "calendar.badge.plus")
                    .font(.title2)
                    .foregroundStyle(WidgetColor.brand)
                Text("今日のルーティンなし")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Text("選んで始める")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
        }

        /// 横長（systemMedium）= 今日のコンディション。
        /// 本体 `TodayConditionCard` のスコアバー + 3 メトリクス構成をウィジェット向けに圧縮移植。
        @ViewBuilder
        private var medium: some View {
            VStack(alignment: .leading, spacing: WidgetSpacing.s) {
                Label("今日のコンディション", systemImage: "heart.text.square.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer(minLength: 0)
                if let value = entry.conditionValue {
                    conditionContent(value: value)
                } else if entry.isProActive {
                    conditionPending
                } else {
                    conditionLocked
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }

        // 本体 `OikomiFont` は UIKit 依存で参照不可。同じ見た目になるよう値を合わせる。
        private static let statValue = Font.system(.title, design: .rounded, weight: .semibold)
            .monospacedDigit()
        private static let statValueCompact = Font.system(
            .title3, design: .rounded, weight: .semibold
        ).monospacedDigit()
        private static let metricUnit = Font.caption.weight(.medium)

        /// スコアあり（当日データあり）の表示。本体 `TodayConditionCard` の readinessBar + metricsRow を移植。
        @ViewBuilder
        private func conditionContent(value: Int) -> some View {
            let tint = bandTint(entry.conditionBand)
            let progress = min(1.0, max(0.0, Double(value) / 100.0))
            VStack(alignment: .leading, spacing: WidgetSpacing.xl) {
                VStack(alignment: .leading, spacing: WidgetSpacing.s) {
                    HStack(spacing: WidgetSpacing.l) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(tint.opacity(0.15))
                                Capsule().fill(tint)
                                    .frame(width: max(0, geo.size.width * progress))
                            }
                        }
                        .frame(height: 10)

                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(value)")
                                .font(Self.statValue)
                                .foregroundStyle(.primary)
                            Text("/ 100")
                                .font(Self.metricUnit)
                                .foregroundStyle(.secondary)
                        }
                        .fixedSize()
                    }
                    if let note = entry.conditionSourceNote {
                        Text(note)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
                conditionMetrics
            }
        }

        /// Pro 契約済みだが当日スナップショット未取得（アプリ未起動 / 日付またぎ）。
        @ViewBuilder
        private var conditionPending: some View {
            VStack(alignment: .leading, spacing: WidgetSpacing.m) {
                VStack(alignment: .leading, spacing: WidgetSpacing.s) {
                    HStack(spacing: WidgetSpacing.m) {
                        Capsule()
                            .fill(.secondary.opacity(0.15))
                            .frame(height: 10)
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("—")
                                .font(Self.statValue)
                                .foregroundStyle(.secondary)
                            Text("/ 100")
                                .font(Self.metricUnit)
                                .foregroundStyle(.secondary)
                        }
                        .fixedSize()
                    }
                    Text("アプリを開くと計算します")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                conditionMetrics
            }
        }

        /// Free ユーザー向け Pro 訴求ロック表示。
        @ViewBuilder
        private var conditionLocked: some View {
            HStack(alignment: .top, spacing: WidgetSpacing.m) {
                Image(systemName: "lock.fill")
                    .font(.title3)
                    .foregroundStyle(WidgetColor.proAccent)
                VStack(alignment: .leading, spacing: WidgetSpacing.xs) {
                    Label("コンディション Pro", systemImage: "star.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WidgetColor.proAccent)
                    Text("HRV・安静時心拍・睡眠から今日の調子を Pro で表示します。")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }

        /// HRV / 安静時心拍 / 睡眠の 3 セル。divider 区切り。値が無ければ "—"。
        @ViewBuilder
        private var conditionMetrics: some View {
            HStack(alignment: .top, spacing: 0) {
                conditionMetricCell(
                    value: entry.conditionHRV.map { "\(Int($0.rounded()))" } ?? "—",
                    unit: "ms", title: "HRV", systemImage: "waveform.path.ecg",
                    tint: WidgetColor.metricHRV)
                metricDivider
                conditionMetricCell(
                    value: entry.conditionRHR.map { "\(Int($0.rounded()))" } ?? "—",
                    unit: "bpm", title: "安静時心拍", systemImage: "heart.fill",
                    tint: WidgetColor.metricRHR)
                metricDivider
                conditionMetricCell(
                    value: entry.conditionSleepHours.map {
                        $0.formatted(.number.precision(.fractionLength(1)))
                    } ?? "—",
                    unit: "h", title: "睡眠", systemImage: "moon.zzz.fill",
                    tint: WidgetColor.metricSleep)
            }
        }

        @ViewBuilder
        private func conditionMetricCell(
            value: String, unit: String, title: String, systemImage: String, tint: Color
        ) -> some View {
            VStack(spacing: 3) {
                HStack(spacing: 4) {
                    Image(systemName: systemImage)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(tint)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(value)
                            .font(Self.statValueCompact)
                        Text(unit)
                            .font(Self.metricUnit)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }

        private var metricDivider: some View {
            Rectangle()
                .fill(.secondary.opacity(0.2))
                .frame(width: 1)
                .padding(.vertical, WidgetSpacing.xs)
        }

        /// バンド色（本体 `TodayConditionCard.bandTint` と信号機マッピングを揃える）。
        private func bandTint(_ band: ReadinessScore.Band?) -> Color {
            switch band {
            case .low: return WidgetColor.bandLow
            case .high: return WidgetColor.bandHigh
            case .normal, nil: return WidgetColor.bandNormal
            }
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
                Text(
                    "\(entry.weekSessionCount) セッション・\(WeightFormatter.numberOnly(kilograms: entry.weekVolume, in: entry.weightUnit, fractionDigits: 0...0)) \(entry.weightUnit.symbol)"
                )
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
